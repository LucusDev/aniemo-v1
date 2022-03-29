import 'package:animely/core/constants/constants.dart';
import 'package:animely/core/models/anime.dart';
import 'package:animely/core/models/episode.dart';
import 'package:animely/core/models/network_return_result.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:helper/helper.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;

extension StringExtension on String {
  String capitalize() {
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  String addPrefixToUrl() {
    if (startsWith('http')) {
      return this;
    }
    return 'https://$this';
  }
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//Stream Links
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<NetworkResult> getStreamLink(Episode ep) async {
  String link1 = '';
  for (var i in ep.servers) {
    if (i.name == "main") {
      link1 = i.iframe;
    }
  }
  if (link1.isEmpty) throw Exception("No Link");
  if (!link1.startsWith("https://")) {
    link1 = "https://" + link1;
  }

  http.get(Uri.parse(link1));
  try {
    final realURL = link1;
    final res = await http.get(Uri.parse(realURL));

    Episode returnValue = ep;
    final rp =
        RegExp(r"https:\/\/.+\.m3u8", caseSensitive: false, multiLine: true);
    if (rp.allMatches(res.body).isEmpty) {
      String l = '';
      for (var i in ep.servers) {
        if (i.name == "main") {
          l = i.iframe;
        }
      }
      final link = await _getStreamingLink2(l);
      late NetworkResult<Episode> r;
      link.when(success: (value) {
        List<Servers> servers = ep.servers;
        value.forEach((key, value) {
          if (key == Constant.resolution) {
            servers.add(Servers(name: "stream_link", iframe: value));
          } else {
            servers.add(Servers(name: key, iframe: value));
          }
        });
        returnValue = ep.copyWith(servers: servers, type: EpisodeType.network);
        r = NetworkResult<Episode>(
            state: NetworkState.success, data: returnValue);
      }, error: (String? e) {
        throw Exception();
      });
      return r;
    } else {
      for (var element in rp.allMatches(res.body)) {
        List<Servers> servers = ep.servers;
        servers.add(Servers(name: "stream_link", iframe: element.group(0)!));
        returnValue = ep.copyWith(servers: servers, type: EpisodeType.network);
        break;
      }
      return NetworkResult<Episode>(
          state: NetworkState.success, data: returnValue);
    }
  } catch (e) {
    return NetworkResult(data: "$e", state: NetworkState.error);
  }
}

Future<Result<String>> _getStreamingLink(String iframeUrl) async {
  String rV = '';
  int count = 0;
  late final HeadlessInAppWebView headlessWebView;
  headlessWebView = HeadlessInAppWebView(
    initialUrlRequest: URLRequest(
      url: Uri.parse(
        iframeUrl.addPrefixToUrl(),
      ),
    ),
    onWebViewCreated: (controller) {},
    onLoadStart: (controller, url) async {
      print(url.toString());
      if (!url.toString().contains('gogoplay')) {
        await controller.loadUrl(
            urlRequest: URLRequest(
          url: Uri.parse(
            iframeUrl.addPrefixToUrl(),
          ),
        ));
        return;
      }
    },
    onProgressChanged: (controller, progress) {
      if (kDebugMode) {
        print(progress);
      }
    },
    // ignore: no_leading_underscores_for_local_identifiers
    onLoadStop: (_c, url) async {
      try {
        if (!url.toString().contains('gogoplay')) return;
        // await _c.evaluateJavascript(
        //     source:
        //         'document.querySelector(".jw-icon.jw-icon-inline.jw-button-color.jw-reset.jw-icon-playback").click()');
        await _c.evaluateJavascript(
            source: 'document.querySelector(".jw-video.jw-reset").click()');

        final jstring = await _c
            .evaluateJavascript(source: '''window.document.body.innerHTML''');
        final doc = parser.parse(jstring);
        final videoTag = doc.getElementsByTagName('video');
        if (videoTag.isNotEmpty) {
          if (videoTag.first.attributes['src'] != null) {
            // if (kDebugMode) {
            print('ans is here' + videoTag.first.attributes['src']!);
            rV = videoTag.first.attributes['src']!;
            _c.stopLoading();
            headlessWebView.dispose();
            // }
          } else {
            count++;
            print("reloading");
            print(count);
            await _c.loadUrl(
              urlRequest: URLRequest(
                url: Uri.parse(
                  iframeUrl.addPrefixToUrl(),
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('error $e');
        }
      }
    },
  );

  await headlessWebView.run();
  while (headlessWebView.isRunning() && count <= 10) {
    await Future.delayed(const Duration(milliseconds: 300));
  }
  headlessWebView.dispose();
  if (rV.isEmpty) return const Result.error();
  return Result.success(rV);
}

Future<Result<Map<String, String>>> _getStreamingLink2(String iframeUrl) async {
  String _url = iframeUrl;
  if (!_url.startsWith("https://")) {
    _url = "https://" + _url;
  }
  print(_url);
  String realURL =
      'https://gogoplay5.com/download?id=${Uri.parse(_url).queryParameters['id']}';

  final Map<String, String> returnValue = await _getDownloadLinks(realURL);
  return Result.success(returnValue);
}

Future<Map<String, String>> _getDownloadLinks(String link) async {
  Map<String, String> rV1 = {};
  late HeadlessInAppWebView _w;
  _w = HeadlessInAppWebView(
    initialUrlRequest: URLRequest(url: Uri.parse(link)),
    onLoadStop: (controller, url) async {
      print(link);
      String rV = await controller.evaluateJavascript(
          source: "window.document.body.innerHTML");
      final $ = parser.parse(rV);
      final Map<String, String> returnValue = {};
      $
          .querySelectorAll(
              "#main .content .content_c .content_c_bg .mirror_link .dowload a")
          .forEach((element) {
        // print(element);
        if (element.text.contains("360")) {
          returnValue['360'] = element.attributes['href']!;
        } else if (element.text.contains("480")) {
          returnValue['480'] = element.attributes['href']!;
        } else if (element.text.contains("720")) {
          returnValue['720'] = element.attributes['href']!;
        } else if (element.text.contains("1080")) {
          returnValue['1080'] = element.attributes['href']!;
        }
      });
      rV1 = returnValue;
      controller.stopLoading();
      await _w.dispose();
    },
  );
  await _w.run();
  while (_w.isRunning()) {
    await Future.delayed(const Duration(milliseconds: 300));
  }
  _w.dispose();

  return rV1;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//animeEpisodeHandler
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<NetworkResult> animeEpisodeHandler(String id) async {
  try {
    final res = await http.get(Uri.parse(Constant.url + '/$id'));
    final body = res.body;
    final $ = parser.parse(body);
    final List<Servers> servers = [];
    $.querySelectorAll('div#wrapper_bg').asMap().forEach((index, element) {
      final $element = element;
      $element
          .querySelectorAll('div.anime_muti_link ul li')
          .asMap()
          .forEach((j, el) {
        final $el = el;
        String? name = $el
            .querySelector('a')!
            .text
            .substring(0, $el.querySelector('a')!.text.lastIndexOf('C'))
            .trim();
        var iframe = $el.querySelector('a')!.attributes['data-video'];
        if (iframe!.startsWith('//')) {
          iframe =
              $el.querySelector('a')!.attributes['data-video']!.substring(2);
          if (iframe.contains("embedplus")) {
            name = "main";
          }
        }
        servers.add(Servers(name: name, iframe: iframe));
      });
    });
    return NetworkResult<Episode>(
        state: NetworkState.success,
        data: Episode(id: id, servers: servers, type: EpisodeType.iframe));
  } catch (e) {
    return NetworkResult(data: "$e", state: NetworkState.error);
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//animeHandler
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

Future<NetworkResult> animeHandler(String id) async {
  try {
    //prepare
    final res = await http.get(Uri.parse('${Constant.url}category/$id'));
    final body = res.body;
    final $ = parser.parse(body);
    final animeInfo = $.querySelector(".anime_info_body_bg")!;

    ///values
    final img = animeInfo.querySelector("img")!.attributes['src'];
    final title = animeInfo.querySelector("h1")!.text;
    final totalEpisode = int.tryParse($
        .querySelectorAll(".anime_video_body #episode_page li")
        .last
        .text
        .trim()
        .split("-")
        .last);
    String? status;
    final List<String> episodes = [];
    String? synopsis;
    String? otherName;
    int? released;
    List<String>? genres = [];

    //logic
    if (totalEpisode != null) {
      for (var i = 0; i < totalEpisode; i++) {
        episodes.add("$id-episode-${i + 1}");
      }
    }

    animeInfo.querySelectorAll('.type').forEach((element) {
      final type = element.querySelector("span")!.text;
      if (type.toLowerCase().contains("summary")) {
        synopsis = element.text.split("\n").last;
      } else if (type.toLowerCase().contains("status")) {
        status = element.querySelector("a")!.text;
      } else if (type.toLowerCase().contains("released")) {
        released =
            int.tryParse(element.text.replaceAll('"', "").split(" ").last);
      } else if (type.toLowerCase().contains("other name")) {
        otherName = element.text.replaceAll("Other name:", "");
      } else if (type.toLowerCase().contains("genre")) {
        final geLi = element.querySelectorAll("a");
        for (var element in geLi) {
          if (element.attributes['title'] != null) {
            genres.add(element.attributes['title']!);
          }
        }
      }
    });

    return NetworkResult<Anime>(
        state: NetworkState.success,
        data: Anime(
          episodes: episodes,
          id: id,
          img: img ?? "",
          title: title,
          totalEpisodes: totalEpisode ?? 0,
          synopsis: synopsis ?? "",
          status: status ?? "unknown",
          released: released ?? 0,
          otherName: otherName ?? "",
          genres: genres,
          isFullInfo: true,
        ));
  } catch (e) {
    return NetworkResult<String>(state: NetworkState.error, data: "$e");
  }
}
