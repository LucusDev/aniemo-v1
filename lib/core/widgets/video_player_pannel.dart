// ignore_for_file: must_call_super, camel_case_types
import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:animely/navigation/test_screen.dart';
import 'package:fijkplayer/fijkplayer.dart';
import 'package:fijkplayer_skin/slider.dart';
import 'package:flutter/material.dart';
import 'package:wakelock/wakelock.dart';

import 'package:fijkplayer_skin/schema.dart' show VideoSourceFormat;
import 'package:fijkplayer_skin/slider.dart'
    show NewFijkSliderColors, NewFijkSlider;

double speed = 1.0;
bool lockStuff = false;
bool hideLockStuff = false;
const double barHeight = 50.0;
final double barFillingHeight =
    MediaQueryData.fromWindow(window).padding.top + barHeight;
final double barGap = barFillingHeight - barHeight;

abstract class ShowConfigAbs {
  late bool nextBtn;
  late bool speedBtn;
  late bool drawerBtn;
  late bool lockBtn;
  late bool topBar;
  late bool autoNext;
  late bool bottomPro;
  late bool stateAuto;
  late bool isAutoPlay;
}

class WithPlayerChangeSource {}

String _duration2String(Duration duration) {
  if (duration.inMilliseconds < 0) return "-: negtive";

  String twoDigits(int n) {
    if (n >= 10) return "$n";
    return "0$n";
  }

  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
  int inHours = duration.inHours;
  return inHours > 0
      ? "$inHours:$twoDigitMinutes:$twoDigitSeconds"
      : "$twoDigitMinutes:$twoDigitSeconds";
}

class CustomFijkPanel extends StatefulWidget {
  final FijkPlayer player;
  final Size viewSize;
  final Rect texturePos;
  final BuildContext? pageContent;
  final String playerTitle;
  final Function? onChangeVideo;
  final int curTabIdx;
  final int curActiveIdx;
  final ShowConfigAbs showConfig;
  final VideoSourceFormat? videoFormat;

  const CustomFijkPanel({
    Key? key,
    required this.player,
    required this.viewSize,
    required this.texturePos,
    this.pageContent,
    this.playerTitle = "",
    required this.showConfig,
    this.onChangeVideo,
    required this.videoFormat,
    required this.curTabIdx,
    required this.curActiveIdx,
  }) : super(key: key);

  @override
  _CustomFijkPanelState createState() => _CustomFijkPanelState();
}

class _CustomFijkPanelState extends State<CustomFijkPanel>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  FijkPlayer get player => widget.player;
  ShowConfigAbs get showConfig => widget.showConfig;
  VideoSourceFormat get _videoSourceTabs => widget.videoFormat!;

  bool _lockStuff = lockStuff;
  bool _hideLockStuff = hideLockStuff;
  bool _drawerState = false;
  Timer? _hideLockTimer;

  FijkState? _playerState;
  bool _isPlaying = false;

  StreamSubscription? _currentPosSubs;

  AnimationController? _animationController;
  Animation<Offset>? _animation;
  late TabController _tabController;

  void initEvent() {
    _tabController = TabController(
      length: _videoSourceTabs.video!.length,
      vsync: this,
    );
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 280),
      vsync: this,
    );
    // init animation
    _animation = Tween(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(_animationController!);
    // is not null
    if (_videoSourceTabs.video!.isNotEmpty) {
      // init plater state
      setState(() {
        _playerState = player.value.state;
      });
      if (player.value.duration.inMilliseconds > 0 && !_isPlaying) {
        setState(() {
          _isPlaying = true;
        });
      }
      // is not null
      // if (_videoSourceTabs.video!.isNotEmpty) {
      // autoplay and existurl
      if (showConfig.isAutoPlay && !_isPlaying) {
        int curTabIdx = widget.curTabIdx;
        int curActiveIdx = widget.curActiveIdx;
        changeCurPlayVideo(curTabIdx, curActiveIdx);
      }
      player.addListener(_playerValueChanged);
      Wakelock.enable();
      // }
    }
  }

  @override
  void initState() {
    super.initState();
    initEvent();
  }

  @override
  void dispose() {
    player.removeListener(_playerValueChanged);
    _currentPosSubs?.cancel();
    _hideLockTimer?.cancel();
    _tabController.dispose();
    _animationController!.dispose();
    Wakelock.disable();
    super.dispose();
  }

  void _playerValueChanged() {
    if (player.value.duration.inMilliseconds > 0 && !_isPlaying) {
      setState(() {
        _isPlaying = true;
      });
    }
    setState(() {
      _playerState = player.value.state;
    });
  }

  void changeDrawerState(bool state) {
    if (state) {
      setState(() {
        _drawerState = state;
      });
    }
    Future.delayed(const Duration(milliseconds: 100), () {
      _animationController!.forward();
    });
  }

  // 切换UI lock显示状态
  void changeLockState(bool state) {
    setState(() {
      _lockStuff = state;
      if (state == true) {
        _hideLockStuff = true;
        _cancelAndRestartLockTimer();
      }
    });
  }

  // 切换播放源
  Future<void> changeCurPlayVideo(int tabIdx, int activeIdx) async {
    print("coe on man!!!!!!!!!!!!");
    // await player.stop();
    await player.reset().then((_) {
      String curTabActiveUrl =
          _videoSourceTabs.video![tabIdx]!.list![activeIdx]!.url!;
      player.setDataSource(
        curTabActiveUrl,
        autoPlay: true,
      );
      widget.onChangeVideo!(tabIdx, activeIdx);
    });
  }

  void _cancelAndRestartLockTimer() {
    if (_hideLockStuff == true) {
      _startHideLockTimer();
    }
    setState(() {
      _hideLockStuff = !_hideLockStuff;
    });
  }

  void _startHideLockTimer() {
    _hideLockTimer?.cancel();
    _hideLockTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _hideLockStuff = true;
      });
    });
  }

  // 锁 组件
  Widget _buidLockStateDetctor() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _cancelAndRestartLockTimer,
      child: SizedBox(
        // color: Colors.amberAccent,
        child: AnimatedOpacity(
          opacity: _hideLockStuff ? 0.0 : 0.7,
          duration: const Duration(milliseconds: 400),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20,
                top: showConfig.stateAuto && !player.value.fullScreen
                    ? barGap
                    : 0,
              ),
              child: IconButton(
                iconSize: 30,
                onPressed: () {
                  setState(() {
                    _lockStuff = false;
                    _hideLockStuff = true;
                  });
                },
                icon: const Icon(Icons.lock_open),
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 返回按钮
  Widget _buildTopBackBtn() {
    return Container(
      height: barHeight,
      alignment: Alignment.centerLeft,
      child: IconButton(
        icon: const Icon(Icons.arrow_back),
        padding: const EdgeInsets.only(
          left: 10.0,
          right: 10.0,
        ),
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        color: Colors.white,
        onPressed: () {
          if (widget.player.value.fullScreen) {
            player.exitFullScreen();
            // player.
          } else {
            if (widget.pageContent != null) {
              player.stop();
              Navigator.pop(widget.pageContent!);
            }
          }
        },
      ),
    );
  }

  // 抽屉组件 - 播放列表
  Widget _buildPlayerListDrawer() {
    return Container(
      alignment: Alignment.centerRight,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () async {
                await _animationController!.reverse();
                setState(() {
                  _drawerState = false;
                });
              },
            ),
          ),
          SlideTransition(
            position: _animation!,
            child: SizedBox(
              height: window.physicalSize.height,
              width: 320,
              child: _buildPlayDrawer(),
            ),
          ),
        ],
      ),
    );
  }

  // build 剧集
  Widget _buildPlayDrawer() {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(0, 0, 0, 0.4),
      // appBar: AppBar(
      //   backgroundColor: const Color.fromRGBO(0, 0, 0, 0.5),
      //   automaticallyImplyLeading: false,
      //   elevation: 0.1,
      //   title: TabBar(
      //     labelColor: Colors.white,
      //     labelStyle: const TextStyle(
      //       color: Colors.white,
      //       fontSize: 14,
      //     ),
      //     unselectedLabelColor: Colors.white,
      //     unselectedLabelStyle: const TextStyle(
      //       color: Colors.white,
      //       fontSize: 14,
      //     ),
      //     indicator: BoxDecoration(
      //       color: Colors.purple[700],
      //       borderRadius: const BorderRadius.all(Radius.circular(10)),
      //     ),
      //     tabs:
      //         _videoSourceTabs.video!.map((e) => Tab(text: e!.name!)).toList(),
      //     isScrollable: true,
      //     controller: _tabController,
      //   ),
      // ),
      body: Container(
        color: const Color.fromRGBO(0, 0, 0, 0.5),
        child: TabBarView(
          controller: _tabController,
          children: _createTabConList(),
        ),
      ),
    );
  }

  // 剧集 tabCon
  List<Widget> _createTabConList() {
    List<Widget> list = [];
    _videoSourceTabs.video!.asMap().keys.forEach((int tabIdx) {
      List<Widget> playListBtns = _videoSourceTabs.video![tabIdx]!.list!
          .asMap()
          .keys
          .map((int activeIdx) {
        return Padding(
          padding: const EdgeInsets.only(left: 5, right: 5),
          child: ElevatedButton(
            style: ButtonStyle(
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              elevation: MaterialStateProperty.all(0),
              backgroundColor: MaterialStateProperty.all(
                  tabIdx == widget.curTabIdx && activeIdx == widget.curActiveIdx
                      ? Colors.red
                      : Colors.blue),
            ),
            onPressed: () {
              int newTabIdx = tabIdx;
              int newActiveIdx = activeIdx;
              changeCurPlayVideo(newTabIdx, newActiveIdx);
            },
            child: Text(
              _videoSourceTabs.video![tabIdx]!.list![activeIdx]!.name!,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        );
      }).toList();
      list.add(
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(left: 5, right: 5),
            child: Wrap(
              alignment: WrapAlignment.start,
              direction: Axis.vertical,
              children: playListBtns,
            ),
          ),
        ),
      );
    });
    return list;
  }

  // 可以共用的架子
  Widget _buildPublicFrameWidget({
    required Widget slot,
    Color? bgColor,
  }) {
    return Container(
      color: bgColor,
      child: Stack(
        children: [
          showConfig.topBar
              ? Positioned(
                  left: 0,
                  top: 0,
                  right: 0,
                  child: Container(
                    height:
                        showConfig.stateAuto && !widget.player.value.fullScreen
                            ? barFillingHeight
                            : barHeight,
                    alignment: Alignment.topLeft,
                    child: SizedBox(
                      height: barHeight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: <Widget>[
                          player.value.fullScreen
                              ? _buildTopBackBtn()
                              : const SizedBox(width: 20),
                          Expanded(
                            child: Text(
                              widget.playerTitle,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.left,
                              style: const TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : Container(),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            top: 0,
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(
                    top: showConfig.stateAuto && !widget.player.value.fullScreen
                        ? barGap
                        : 0),
                child: slot,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorStateSlotWidget() {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: showConfig.stateAuto && !widget.player.value.fullScreen
                ? barGap
                : 0,
          ),
          const Icon(
            Icons.error,
            size: 50,
            color: Colors.white,
          ),
          const Text(
            "Video can't be played",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          ElevatedButton(
            style: ButtonStyle(
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              elevation: MaterialStateProperty.all(0),
              backgroundColor: MaterialStateProperty.all(Colors.white),
            ),
            onPressed: () {
              // changeCurPlayVideo(widget.curTabIdx, widget.curActiveIdx);
              //TODO
              showDialog(
                context: context,
                builder: (context) {
                  int tabIdx = 0;
                  List<Widget> playListBtns = _videoSourceTabs
                      .video![tabIdx]!.list!
                      .asMap()
                      .keys
                      .map((int activeIdx) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 5, right: 5),
                      child: ElevatedButton(
                        style: ButtonStyle(
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          elevation: MaterialStateProperty.all(0),
                          backgroundColor: MaterialStateProperty.all(
                              tabIdx == widget.curTabIdx &&
                                      activeIdx == widget.curActiveIdx
                                  ? Colors.red
                                  : Colors.blue),
                        ),
                        onPressed: () {
                          int newTabIdx = tabIdx;
                          int newActiveIdx = activeIdx;
                          changeCurPlayVideo(newTabIdx, newActiveIdx);
                          Navigator.pop(context);
                        },
                        child: Text(
                          _videoSourceTabs
                              .video![tabIdx]!.list![activeIdx]!.name!,
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }).toList();
                  return SimpleDialog(
                    backgroundColor: Colors.transparent,
                    children: playListBtns,
                  );
                },
              );
            },
            child: const Text(
              "Retry",
              style: TextStyle(color: Colors.black),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStateSlotWidget() {
    return const SizedBox(
      width: barHeight * 0.8,
      height: barHeight * 0.8,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation(Colors.white),
      ),
    );
  }

  Widget _buildIdleStateSlotWidget() {
    return IconButton(
      iconSize: barHeight * 1.2,
      icon: const Icon(Icons.play_arrow, color: Colors.white),
      padding: const EdgeInsets.only(left: 10.0, right: 10.0),
      onPressed: () async {
        int newTabIdx = widget.curTabIdx;
        int newActiveIdx = widget.curActiveIdx;
        await changeCurPlayVideo(newTabIdx, newActiveIdx);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Rect rect = player.value.fullScreen
        ? Rect.fromLTWH(
            0,
            0,
            widget.viewSize.width,
            widget.viewSize.height,
          )
        : Rect.fromLTRB(
            max(0.0, widget.texturePos.left),
            max(0.0, widget.texturePos.top),
            min(widget.viewSize.width, widget.texturePos.right),
            min(widget.viewSize.height, widget.texturePos.bottom),
          );

    List<Widget> ws = [];

    if (_playerState == FijkState.error) {
      ws.add(
        _buildPublicFrameWidget(
          slot: _buildErrorStateSlotWidget(),
          bgColor: Colors.black,
        ),
      );
    } else if ((_playerState == FijkState.asyncPreparing ||
            _playerState == FijkState.initialized) &&
        !_isPlaying) {
      ws.add(
        _buildPublicFrameWidget(
          slot: _buildLoadingStateSlotWidget(),
          bgColor: Colors.black,
        ),
      );
    } else if (_playerState == FijkState.idle && !_isPlaying) {
      ws.add(
        _buildPublicFrameWidget(
          slot: _buildIdleStateSlotWidget(),
          bgColor: Colors.black,
        ),
      );
    } else {
      if (_lockStuff == true &&
          showConfig.lockBtn &&
          widget.player.value.fullScreen) {
        ws.add(
          _buidLockStateDetctor(),
        );
      } else if (_drawerState == true && widget.player.value.fullScreen) {
        ws.add(
          _buildPlayerListDrawer(),
        );
      } else {
        ws.add(
          _buildGestureDetector(
            curActiveIdx: widget.curActiveIdx,
            curTabIdx: widget.curTabIdx,
            onChangeVideo: widget.onChangeVideo,
            player: widget.player,
            texturePos: widget.texturePos,
            showConfig: widget.showConfig,
            pageContent: widget.pageContent,
            playerTitle: widget.playerTitle,
            viewSize: widget.viewSize,
            videoFormat: widget.videoFormat,
            changeDrawerState: changeDrawerState,
            changeLockState: changeLockState,
          ),
        );
      }
    }

    return WillPopScope(
      child: Positioned.fromRect(
        rect: rect,
        child: Stack(
          children: ws,
        ),
      ),
      onWillPop: () async {
        if (!widget.player.value.fullScreen) widget.player.stop();
        return true;
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}

class _buildGestureDetector extends StatefulWidget {
  final FijkPlayer player;
  final Size viewSize;
  final Rect texturePos;
  final BuildContext? pageContent;
  final String playerTitle;
  final Function? onChangeVideo;
  final int curTabIdx;
  final int curActiveIdx;
  final Function changeDrawerState;
  final Function changeLockState;
  final ShowConfigAbs showConfig;
  final VideoSourceFormat? videoFormat;
  const _buildGestureDetector({
    Key? key,
    required this.player,
    required this.viewSize,
    required this.texturePos,
    this.pageContent,
    this.playerTitle = "",
    required this.showConfig,
    this.onChangeVideo,
    required this.curTabIdx,
    required this.curActiveIdx,
    required this.videoFormat,
    required this.changeDrawerState,
    required this.changeLockState,
  }) : super(key: key);

  @override
  _buildGestureDetectorState createState() => _buildGestureDetectorState();
}

class _buildGestureDetectorState extends State<_buildGestureDetector> {
  FijkPlayer get player => widget.player;
  ShowConfigAbs get showConfig => widget.showConfig;
  VideoSourceFormat get _videoSourceTabs => widget.videoFormat!;

  Duration _duration = const Duration();
  Duration _currentPos = const Duration();
  Duration _bufferPos = const Duration();

  // 滑动后值
  Duration _dargPos = const Duration();

  bool _isTouch = false;

  bool _playing = false;
  bool _prepared = false;
  String? _exception;

  double? updatePrevDx;
  double? updatePrevDy;
  int? updatePosX;

  bool? isDargVerLeft;

  double? updateDargVarVal;

  bool varTouchInitSuc = false;

  bool _buffering = false;

  double _seekPos = -1.0;

  StreamSubscription? _currentPosSubs;
  StreamSubscription? _bufferPosSubs;
  StreamSubscription? _bufferingSubs;

  Timer? _hideTimer;
  bool _hideStuff = true;

  bool _hideSpeedStu = true;
  double _speed = speed;

  bool _isHorizontalMove = false;

  Map<String, double> speedList = {
    "2.0": 2.0,
    "1.8": 1.8,
    "1.5": 1.5,
    "1.2": 1.2,
    "1.0": 1.0,
  };

  // 初始化构造函数
  _buildGestureDetectorState();

  void initEvent() {
    // 设置初始化的值，全屏与半屏切换后，重设
    setState(() {
      _speed = speed;
      // 每次重绘的时候，判断是否已经开始播放
      _hideStuff = !_playing ? false : true;
    });
    // 延时隐藏
    _startHideTimer();
  }

  @override
  void dispose() {
    player.removeListener(_playerValueChanged);
    _hideTimer?.cancel();
    _currentPosSubs?.cancel();
    _bufferPosSubs?.cancel();
    _bufferingSubs?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    initEvent();

    _duration = player.value.duration;
    _currentPos = player.currentPos;
    _bufferPos = player.bufferPos;
    _prepared = player.state.index >= FijkState.prepared.index;
    _playing = player.state == FijkState.started;
    _exception = player.value.exception.message;
    _buffering = player.isBuffering;

    player.addListener(_playerValueChanged);

    _currentPosSubs = player.onCurrentPosUpdate.listen((v) {
      setState(() {
        _currentPos = v;
        // 后加入，处理fijkplay reset后状态对不上的bug，
        _playing = true;
        _prepared = true;
      });
    });

    _bufferPosSubs = player.onBufferPosUpdate.listen((v) {
      setState(() {
        _bufferPos = v;
      });
    });

    _bufferingSubs = player.onBufferStateUpdate.listen((v) {
      setState(() {
        _buffering = v;
      });
    });
  }

  void _playerValueChanged() async {
    FijkValue value = player.value;
    if (value.duration != _duration) {
      setState(() {
        _duration = value.duration;
      });
    }
    // print('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    // print('++++++++ 是否开始播放 => ${value.state == FijkState.started} ++++++++');
    // print('+++++++++++++++++++ 播放器状态 => ${value.state} ++++++++++++++++++++');
    // print('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
    // 新状态
    bool playing = value.state == FijkState.started;
    bool prepared = value.prepared;
    String? exception = value.exception.message;
    // 状态不一致，修改
    if (playing != _playing ||
        prepared != _prepared ||
        exception != _exception) {
      setState(() {
        _playing = playing;
        _prepared = prepared;
        _exception = exception;
      });
    }
    // 播放完成
    bool playend = (value.state == FijkState.completed);
    bool isOverFlow = widget.curActiveIdx + 1 >=
        _videoSourceTabs.video![widget.curTabIdx]!.list!.length;
    // 播放完成 && tablen没有溢出 && curActive没有溢出
    if (playend && !isOverFlow && showConfig.autoNext) {
      int newTabIdx = widget.curTabIdx;
      int newActiveIdx = widget.curActiveIdx + 1;
      widget.onChangeVideo!(newTabIdx, newActiveIdx);
      // 切换播放源
      changeCurPlayVideo(newTabIdx, newActiveIdx);
    }
  }

  _onHorizontalDragStart(detills) {
    setState(() {
      updatePrevDx = detills.globalPosition.dx;
      updatePosX = _currentPos.inMilliseconds;
    });
  }

  _onHorizontalDragUpdate(detills) {
    double curDragDx = detills.globalPosition.dx;
    // 确定当前是前进或者后退
    int cdx = curDragDx.toInt();
    int pdx = updatePrevDx!.toInt();
    bool isBefore = cdx > pdx;

    // 计算手指滑动的比例
    int newInterval = pdx - cdx;
    double playerW = MediaQuery.of(context).size.width;
    int curIntervalAbs = newInterval.abs();
    double movePropCheck = (curIntervalAbs / playerW) * 100;

    // 计算进度条的比例
    double durProgCheck = _duration.inMilliseconds.toDouble() / 100;
    int checkTransfrom = (movePropCheck * durProgCheck).toInt();
    int dragRange =
        isBefore ? updatePosX! + checkTransfrom : updatePosX! - checkTransfrom;

    // 是否溢出 最大
    int lastSecond = _duration.inMilliseconds;
    if (dragRange >= _duration.inMilliseconds) {
      dragRange = lastSecond;
    }
    // 是否溢出 最小
    if (dragRange <= 0) {
      dragRange = 0;
    }
    //
    setState(() {
      _isHorizontalMove = true;
      _hideStuff = false;
      _isTouch = true;
      // 更新下上一次存的滑动位置
      updatePrevDx = curDragDx;
      // 更新时间
      updatePosX = dragRange.toInt();
      _dargPos = Duration(milliseconds: updatePosX!.toInt());
    });
  }

  _onHorizontalDragEnd(detills) {
    player.seekTo(_dargPos.inMilliseconds);
    setState(() {
      _isHorizontalMove = false;
      _isTouch = false;
      _hideStuff = true;
      _currentPos = _dargPos;
    });
  }

  _onVerticalDragStart(detills) async {
    double clientW = widget.viewSize.width;
    double curTouchPosX = detills.globalPosition.dx;

    setState(() {
      // 更新位置
      updatePrevDy = detills.globalPosition.dy;
      // 是否左边
      isDargVerLeft = (curTouchPosX > (clientW / 2)) ? false : true;
    });
    // 大于 右边 音量 ， 小于 左边 亮度
    if (!isDargVerLeft!) {
      // 音量
      await FijkVolume.getVol().then((double v) {
        varTouchInitSuc = true;
        setState(() {
          updateDargVarVal = v;
        });
      });
    } else {
      // 亮度
      await FijkPlugin.screenBrightness().then((double v) {
        varTouchInitSuc = true;
        setState(() {
          updateDargVarVal = v;
        });
      });
    }
  }

  // _onVerticalDragUpdate(detills) {
  //   if (!varTouchInitSuc) return null;
  //   double curDragDy = detills.globalPosition.dy;
  //   // 确定当前是前进或者后退
  //   int cdy = curDragDy.toInt();
  //   int pdy = updatePrevDy!.toInt();
  //   bool isBefore = cdy < pdy;
  //   // + -, 不满足, 上下滑动合法滑动值，> 3
  //   if (isBefore && pdy - cdy < 3 || !isBefore && cdy - pdy < 3) return null;
  //   // 区间
  //   double dragRange =
  //       isBefore ? updateDargVarVal! + 0.03 : updateDargVarVal! - 0.03;
  //   // 是否溢出
  //   if (dragRange > 1) {
  //     dragRange = 1.0;
  //   }
  //   if (dragRange < 0) {
  //     dragRange = 0.0;
  //   }
  //   setState(() {
  //     updatePrevDy = curDragDy;
  //     varTouchInitSuc = true;
  //     updateDargVarVal = dragRange;
  //     // 音量
  //     if (!isDargVerLeft!) {
  //       FijkVolume.setVol(dragRange);
  //     } else {
  //       FijkPlugin.setScreenBrightness(dragRange);
  //     }
  //   });
  // }

  _onVerticalDragEnd(detills) {
    setState(() {
      varTouchInitSuc = false;
    });
  }

  // 切换播放源
  Future<void> changeCurPlayVideo(int tabIdx, int activeIdx) async {
    print(
        "this is the method!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
    // await player.seekTo(0);
    await player.stop();
    setState(() {
      _buffering = false;
    });
    player.reset().then((_) {
      _speed = speed = 1.0;
      String curTabActiveUrl =
          _videoSourceTabs.video![tabIdx]!.list![activeIdx]!.url!;
      player.setDataSource(
        curTabActiveUrl,
        autoPlay: true,
      );
      // 回调
      widget.onChangeVideo!(tabIdx, activeIdx);
    });
  }

  void _playOrPause() {
    if (_playing == true) {
      player.pause();
    } else {
      player.start();
    }
  }

  void _cancelAndRestartTimer() {
    if (_hideStuff == true) {
      _startHideTimer();
    }

    setState(() {
      _hideStuff = !_hideStuff;
      if (_hideStuff == true) {
        _hideSpeedStu = true;
      }
    });
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 5), () {
      setState(() {
        _hideStuff = true;
        _hideSpeedStu = true;
      });
    });
  }

  // 底部控制栏 - 播放按钮
  Widget _buildPlayStateBtn(IconData iconData, Function cb) {
    return Ink(
      child: InkWell(
        onTap: () => cb(),
        child: SizedBox(
          height: 30,
          child: Padding(
            padding: const EdgeInsets.only(left: 5, right: 5),
            child: Icon(
              iconData,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  // 控制器ui 底部
  Widget _buildBottomBar(BuildContext context) {
    // 计算进度时间
    double duration = _duration.inMilliseconds.toDouble();
    double currentValue = _seekPos > 0
        ? _seekPos
        : (_isHorizontalMove
            ? _dargPos.inMilliseconds.toDouble()
            : _currentPos.inMilliseconds.toDouble());
    currentValue = min(currentValue, duration);
    currentValue = max(currentValue, 0);

    // 计算底部吸底进度
    double curConWidth = MediaQuery.of(context).size.width;
    double curTimePro = (currentValue / duration) * 100;
    double curBottomProW = (curConWidth / 100) * curTimePro;

    return Container(
      color: _hideStuff ? null : Colors.black.withOpacity(0.15),
      height: barHeight,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AnimatedOpacity(
              opacity: _hideStuff ? 0.0 : 0.8,
              duration: const Duration(milliseconds: 400),
              child: Container(
                height: barHeight,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomLeft,
                    colors: [
                      Color.fromRGBO(0, 0, 0, 0),
                      Color.fromRGBO(0, 0, 0, 0.4),
                    ],
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    const SizedBox(width: 7),
                    // 按钮 - 播放/暂停
                    _buildPlayStateBtn(
                      _playing ? Icons.pause : Icons.play_arrow,
                      _playOrPause,
                    ),
                    // 下一集
                    showConfig.nextBtn
                        ? _buildPlayStateBtn(
                            Icons.skip_next,
                            () {
                              bool isOverFlow = widget.curActiveIdx + 1 >=
                                  _videoSourceTabs
                                      .video![widget.curTabIdx]!.list!.length;
                              // 没有溢出的情况下
                              if (!isOverFlow) {
                                int newTabIdx = widget.curTabIdx;
                                int newActiveIdx = widget.curActiveIdx + 1;
                                // 切换播放源
                                changeCurPlayVideo(newTabIdx, newActiveIdx);
                              }
                            },
                          )
                        : Container(),
                    // 已播放时间
                    Padding(
                      padding: const EdgeInsets.only(right: 5.0, left: 5),
                      child: Text(
                        _duration2String(_currentPos),
                        style: const TextStyle(
                          fontSize: 14.0,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    // 播放进度 if 没有开始播放 占满，空ui， else fijkSlider widget
                    _duration.inMilliseconds == 0
                        ? Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 5, left: 5),
                              child: NewFijkSlider(
                                colors: const NewFijkSliderColors(
                                  cursorColor: Colors.blue,
                                  playedColor: Colors.blue,
                                ),
                                onChangeEnd: (double value) {},
                                value: 0,
                                onChanged: (double value) {},
                              ),
                            ),
                          )
                        : Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 5, left: 5),
                              child: NewFijkSlider(
                                colors: const NewFijkSliderColors(
                                  cursorColor: Colors.blue,
                                  playedColor: Colors.blue,
                                ),
                                value: currentValue,
                                cacheValue:
                                    _bufferPos.inMilliseconds.toDouble(),
                                min: 0.0,
                                max: duration,
                                onChanged: (v) {
                                  _startHideTimer();
                                  setState(() {
                                    _seekPos = v;
                                  });
                                },
                                onChangeEnd: (v) {
                                  setState(() {
                                    player.seekTo(v.toInt());
                                    // print("seek to $v");
                                    _currentPos = Duration(
                                        milliseconds: _seekPos.toInt());
                                    _seekPos = -1;
                                  });
                                },
                              ),
                            ),
                          ),

                    // 总播放时间
                    _duration.inMilliseconds == 0
                        ? const Text(
                            "00:00",
                            style: TextStyle(color: Colors.white),
                          )
                        : Padding(
                            padding: const EdgeInsets.only(right: 5.0, left: 5),
                            child: Text(
                              _duration2String(_duration),
                              style: const TextStyle(
                                fontSize: 14.0,
                                color: Colors.white,
                              ),
                            ),
                          ),
                    // 剧集按钮
                    widget.player.value.fullScreen && showConfig.drawerBtn
                        ? Ink(
                            padding: const EdgeInsets.all(5),
                            child: InkWell(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (context) {
                                    int tabIdx = 0;
                                    List<Widget> playListBtns = _videoSourceTabs
                                        .video![tabIdx]!.list!
                                        .asMap()
                                        .keys
                                        .map((int activeIdx) {
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                            left: 5, right: 5),
                                        child: ElevatedButton(
                                          style: ButtonStyle(
                                            shape: MaterialStateProperty.all(
                                              RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                            ),
                                            elevation:
                                                MaterialStateProperty.all(0),
                                            backgroundColor:
                                                MaterialStateProperty.all(
                                                    tabIdx == widget.curTabIdx &&
                                                            activeIdx ==
                                                                widget
                                                                    .curActiveIdx
                                                        ? Colors.red
                                                        : Colors.blue),
                                          ),
                                          onPressed: () {
                                            int newTabIdx = tabIdx;
                                            int newActiveIdx = activeIdx;
                                            changeCurPlayVideo(
                                                newTabIdx, newActiveIdx);
                                            Navigator.pop(context);
                                          },
                                          child: Text(
                                            _videoSourceTabs.video![tabIdx]!
                                                .list![activeIdx]!.name!,
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList();
                                    return SimpleDialog(
                                      backgroundColor: Colors.transparent,
                                      children: playListBtns,
                                    );
                                  },
                                );
                                // widget.changeDrawerState(true);
                              },
                              child: Container(
                                alignment: Alignment.center,
                                width: 40,
                                height: 30,
                                child: Text(
                                  "${_videoSourceTabs.video![0]!.list![widget.curActiveIdx]!.name}",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          )
                        : Container(),
                    // 倍数按钮
                    widget.player.value.fullScreen && showConfig.speedBtn
                        ? Ink(
                            padding: const EdgeInsets.all(5),
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _hideSpeedStu = !_hideSpeedStu;
                                });
                              },
                              child: Container(
                                alignment: Alignment.center,
                                width: 40,
                                height: 30,
                                child: Text(
                                  _speed.toString() + " X",
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                            ),
                          )
                        : Container(),

                    IconButton(
                        onPressed: () {
                          if (!player.value.fullScreen) {
                            player.enterFullScreen();
                          }
                          FlutterAndroidPip.enterPictureInPictureMode();
                        },
                        icon: const Icon(Icons.picture_in_picture_alt)),
                    _buildPlayStateBtn(
                      widget.player.value.fullScreen
                          ? Icons.fullscreen_exit
                          : Icons.fullscreen,
                      () {
                        if (widget.player.value.fullScreen) {
                          player.exitFullScreen();
                        } else {
                          player.enterFullScreen();
                          // 掉父组件回调
                          widget.changeDrawerState(false);
                        }
                      },
                    ),
                    const SizedBox(width: 7),
                    //
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: showConfig.bottomPro &&
                    _hideStuff &&
                    _duration.inMilliseconds != 0
                ? Container(
                    alignment: Alignment.bottomLeft,
                    height: 4,
                    color: Colors.white70,
                    child: Container(
                      color: Colors.blue,
                      width: curBottomProW is double ? curBottomProW : 0,
                      height: 4,
                    ),
                  )
                : Container(),
          )
        ],
      ),
    );
  }

  Widget _buildTopBackBtn() {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      padding: const EdgeInsets.only(
        left: 10.0,
        right: 10.0,
      ),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      color: Colors.white,
      onPressed: () {
        if (widget.player.value.fullScreen) {
          player.exitFullScreen();
        } else {
          // if (widget.pageContent == null) return null;
          // player.stop();
          // Navigator.pop(widget.pageContent!);
        }
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: _hideStuff ? null : Colors.black.withOpacity(0.15),
      child: AnimatedOpacity(
        opacity: _hideStuff ? 0.0 : 0.8,
        duration: const Duration(milliseconds: 400),
        child: Container(
          height: showConfig.stateAuto && !widget.player.value.fullScreen
              ? barFillingHeight
              : barHeight,
          alignment: Alignment.topLeft,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomLeft,
              colors: [
                Color.fromRGBO(0, 0, 0, 0.5),
                Color.fromRGBO(0, 0, 0, 0),
              ],
            ),
          ),
          child: SizedBox(
            height: barHeight,
            child: Row(
              children: <Widget>[
                player.value.fullScreen
                    ? _buildTopBackBtn()
                    : const SizedBox(
                        width: 20,
                      ),
                Expanded(
                  child: SizedBox(
                    child: Text(
                      widget.playerTitle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterPlayBtn() {
    return Container(
      color: _hideStuff ? null : Colors.black.withOpacity(0.15),
      height: double.infinity,
      width: double.infinity,
      child: Center(
        child: (_prepared && !_buffering)
            ? AnimatedOpacity(
                opacity: _hideStuff ? 0.0 : 0.7,
                duration: const Duration(milliseconds: 400),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      iconSize: barHeight,
                      icon: const Icon(Icons.replay_10, color: Colors.white),
                      padding: const EdgeInsets.all(10),
                      onPressed: () {
                        player.seekTo(player.currentPos.inMilliseconds - 10000);
                      },
                    ),
                    IconButton(
                      iconSize: barHeight,
                      icon: Icon(_playing ? Icons.pause : Icons.play_arrow,
                          color: Colors.white),
                      padding: const EdgeInsets.all(10),
                      onPressed: _playOrPause,
                    ),
                    IconButton(
                      iconSize: barHeight,
                      icon: const Icon(Icons.forward_10, color: Colors.white),
                      padding: const EdgeInsets.all(10),
                      onPressed: () {
                        player.seekTo(player.currentPos.inMilliseconds + 10000);
                      },
                    ),
                  ],
                ),
              )
            : const SizedBox(
                width: barHeight * 0.8,
                height: barHeight * 0.8,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              ),
      ),
    );
  }

  // build 滑动进度时间显示
  Widget _buildDargProgressTime() {
    return _isTouch
        ? Container(
            height: 40,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(
                Radius.circular(5),
              ),
              color: Color.fromRGBO(0, 0, 0, 0.8),
            ),
            child: Padding(
              padding: const EdgeInsets.only(left: 10, right: 10),
              child: Text(
                '${_duration2String(_dargPos)} / ${_duration2String(_duration)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
            ),
          )
        : Container();
  }

  // build 显示垂直亮度，音量
  // ignore: unused_element
  Widget _buildDargVolumeAndBrightness() {
    // 不显示
    if (!varTouchInitSuc) return Container();

    IconData iconData;
    // 判断当前值范围，显示的图标
    if (updateDargVarVal! <= 0) {
      iconData = !isDargVerLeft! ? Icons.volume_mute : Icons.brightness_low;
    } else if (updateDargVarVal! < 0.5) {
      iconData = !isDargVerLeft! ? Icons.volume_down : Icons.brightness_medium;
    } else {
      iconData = !isDargVerLeft! ? Icons.volume_up : Icons.brightness_high;
    }
    // 显示，亮度 || 音量
    return Card(
      color: const Color.fromRGBO(0, 0, 0, 0.8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              iconData,
              color: Colors.white,
            ),
            Container(
              width: 100,
              height: 3,
              margin: const EdgeInsets.only(left: 8),
              child: LinearProgressIndicator(
                value: updateDargVarVal,
                backgroundColor: Colors.white54,
                valueColor: const AlwaysStoppedAnimation(Colors.lightBlue),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // build 倍数列表
  List<Widget> _buildSpeedListWidget() {
    List<Widget> columnChild = [];
    speedList.forEach((String mapKey, double speedVals) {
      columnChild.add(
        Ink(
          child: InkWell(
            onTap: () {
              if (_speed != speedVals) {
                setState(() {
                  _speed = speed = speedVals;
                  _hideSpeedStu = true;
                  player.setSpeed(speedVals);
                });
              }
            },
            child: Container(
              alignment: Alignment.center,
              width: 50,
              height: 30,
              child: Text(
                mapKey + " X",
                style: TextStyle(
                  color: _speed == speedVals ? Colors.blue : Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      );
      columnChild.add(
        Padding(
          padding: const EdgeInsets.only(top: 5, bottom: 5),
          child: Container(
            width: 50,
            height: 1,
            color: Colors.white54,
          ),
        ),
      );
    });
    columnChild.removeAt(columnChild.length - 1);
    return columnChild;
  }

  // 播放器控制器 ui
  Widget _buildGestureDetector() {
    return GestureDetector(
      onTap: _cancelAndRestartTimer,
      behavior: HitTestBehavior.opaque,
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      onVerticalDragStart: _onVerticalDragStart,
      // onVerticalDragUpdate: _onVerticalDragUpdate,
      onVerticalDragEnd: _onVerticalDragEnd,
      child: AbsorbPointer(
        absorbing: _hideStuff,
        child: Column(
          children: <Widget>[
            // 播放器顶部控制器
            showConfig.topBar
                ? _buildTopBar()
                : Container(
                    height:
                        showConfig.stateAuto && !widget.player.value.fullScreen
                            ? barFillingHeight
                            : barHeight,
                  ),
            // 中间按钮
            Expanded(
              child: Stack(
                children: <Widget>[
                  // 顶部显示
                  Positioned(
                    top: widget.player.value.fullScreen ? 20 : 0,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // 显示左右滑动快进时间的块
                        _buildDargProgressTime(),
                        // 显示上下滑动音量亮度
                        // _buildDargVolumeAndBrightness()
                      ],
                    ),
                  ),
                  // 中间按钮
                  Align(
                    alignment: Alignment.center,
                    child: _buildCenterPlayBtn(),
                  ),
                  // 倍数选择
                  Positioned(
                    right: 35,
                    bottom: 0,
                    child: !_hideSpeedStu
                        ? Container(
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Column(
                                children: _buildSpeedListWidget(),
                              ),
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          )
                        : Container(),
                  ),
                  // 锁按钮
                  showConfig.lockBtn && widget.player.value.fullScreen
                      ? Align(
                          alignment: Alignment.centerLeft,
                          child: AnimatedOpacity(
                            opacity: _hideStuff ? 0.0 : 0.7,
                            duration: const Duration(milliseconds: 400),
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: IconButton(
                                iconSize: 30,
                                onPressed: () {
                                  // 更改 ui显示状态
                                  widget.changeLockState(true);
                                },
                                icon: const Icon(Icons.lock_outline),
                                color: Colors.white,
                              ),
                            ),
                          ),
                        )
                      : Container(),
                ],
              ),
            ),
            // 播放器底部控制器
            _buildBottomBar(context),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildGestureDetector();
  }
}
