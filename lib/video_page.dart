import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({Key? key}) : super(key: key);
  @override
  State createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> {
  late PageController _pageController;
  int currentPageIndex = 0; //当前播放索引
  int currentIndex = 0; //当前播放索引
  List<VideoData> videoDataList = []; //视频数据列表
  List<VideoType> videoTypeList = []; //视频分类数据列表

  @override
  void initState() {
    loadData(false);
    loadVideoType();
    _pageController = PageController(initialPage: currentIndex);
    _pageController.addListener(_onPageScroll);
    super.initState();
  }

  void _onPageScroll() {
    final pageIndex = _pageController.page?.round();
    if (pageIndex != null && pageIndex != currentPageIndex) {
      currentPageIndex = pageIndex;
      print('=========> currentPageIndex: ${currentPageIndex}');
      if (currentPageIndex == videoDataList.length - 2) {
        loadData(true);
      }
    }
  }

  /// 视频数据 API请求
  Future<void> loadData(bool isLoadMore) async {
    // 延迟200ms 模拟网络请求
    await Future.delayed(const Duration(milliseconds: 200));
    if (isLoadMore) {
      print('=========> loadData');
      List<VideoData> newVideoDataList = [];
      newVideoDataList.clear();
      newVideoDataList.addAll(videoDataList);
      newVideoDataList.addAll(testVideoData);
      setState(() {
        videoDataList = newVideoDataList;
      });
    } else {
      setState(() {
        videoDataList = testVideoData;
      });
    }
  }

  /// 视频类型 API请求
  Future<void> loadVideoType() async {
    // 延迟200ms 模拟网络请求
    await Future.delayed(const Duration(milliseconds: 200));
    videoTypeList = testVideoType;
    setState(() {});
  }

  @override
  void dispose() {
    _pageController.removeListener(_onPageScroll);
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    return Scaffold(
        resizeToAvoidBottomInset: false, //很重要,不加键盘弹出视频会被挤压
        body: Stack(
          children: [
            PageView.builder(
              scrollDirection: Axis.vertical,
              itemCount: videoDataList.length,
              controller: _pageController,
              onPageChanged: (currentPage) {
                //页面发生改变的回调
              },
              itemBuilder: (context, index) {
                return VideoPlayerFullPage(
                  size: size,
                  videoData: videoDataList[index],
                  videoTypes: videoTypeList,
                );
              },
            ),
            header(
              context,
              videoTypeList,
            ),
          ],
        ));
  }

  Widget header(BuildContext context, List<VideoType> videoTypes) {
    var size = MediaQuery.of(context).size;
    return Padding(
      padding: const EdgeInsets.only(left: 15, top: 10, bottom: 10),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      if (Navigator.canPop(context)) {
                        Navigator.pop(context);
                      }
                    }),
                GestureDetector(
                  onTap: () {
                    onSearchClick();
                  },
                  child: Container(
                    width: size.width - 100,
                    padding: const EdgeInsets.only(
                        left: 15, right: 15, top: 5, bottom: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0),
                      color: const Color(0x80444444),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.search,
                          color: Colors.white,
                        ),
                        SizedBox(
                          width: 5,
                        ),
                        Text(
                          '搜索社群',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0, // 主轴(水平)方向间距
              runSpacing: 2.0, // 纵轴（垂直）方向间距
              children: videoTypes.map((item) {
                return GestureDetector(
                  onTap: () {
                    onVideoTypesClick(item);
                  },
                  child: Container(
                    padding: const EdgeInsets.only(
                        left: 12, right: 12, top: 4, bottom: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20.0), // 设置圆角
                      color: const Color(0xFF69DCE5), // 设置背景颜色
                    ),
                    child: Text(
                      item.typeName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶部视频类型 点击
  Future<void> onVideoTypesClick(VideoType videoType) async {
    print('=====> 点击了视频类型');
  }

  /// 搜索点击
  Future<void> onSearchClick() async {
    print('=====> 点击了搜索');
  }
}

class VideoPlayerFullPage extends StatefulWidget {
  final List<VideoType> videoTypes; //视频顶部分类
  final VideoData? videoData;

  const VideoPlayerFullPage({
    Key? key,
    required this.size,
    required this.videoTypes,
    required this.videoData,
  }) : super(key: key);

  final Size size;

  @override
  State createState() => _VideoPlayerFullPageState();
}

class _VideoPlayerFullPageState extends State<VideoPlayerFullPage> {
  late VideoPlayerController videoController;
  bool isInitPlaying = false;
  bool isBuffering = false;
  List<CommentData> comments = []; //评论数据列表
  double videoWidth = 0;
  double videoHeight = 0;
  double _currentSliderValue = 0.0;

  @override
  void initState() {
    videoController = VideoPlayerController.network(widget.videoData!.videoUrl)
      ..initialize().then((value) {
        videoController.play();
        videoController.setLooping(true);
        setState(() {
          _currentSliderValue = 0.0;
          isInitPlaying = true;
          videoWidth = videoController.value.size.width;
          videoHeight = videoController.value.size.height;
        });
      });
    videoController.addListener(videoListener);
    super.initState();
  }

  void videoListener() {
    setState(() {
      isBuffering = videoController.value.isBuffering;
      _currentSliderValue = videoController.value.position.inSeconds.toDouble();
    });
  }

  @override
  void dispose() {
    videoController.removeListener(videoListener);
    videoController.dispose();
    super.dispose();
  }

  /// 底部视频话题 点击
  Future<void> onVideoTagsClick(VideoTag videoTag) async {
    print('=====> 点击了视频话题');
  }

  ///点赞
  Future<void> onLikeClick(VideoData videoData) async {
    print('=====> 点击了点赞');
  }

  ///评论
  Future<void> onCommentClick(BuildContext context, VideoData videoData) async {
    print('=====> 点击了评论');
    // 延迟200ms 模拟网络请求
    await Future.delayed(const Duration(milliseconds: 200));
    comments = testCommentData;
    showCommentBottomSheet(context, comments, videoData);
  }

  ///观看人数
  Future<void> onWatchClick(VideoData videoData) async {
    print('=====> 点击了观看人数');
  }

  ///分享
  Future<void> onShareClick(VideoData videoData) async {
    print('=====> 点击了分享');
  }

  ///加好友
  Future<void> onAddFriendClick(VideoData videoData) async {
    print('=====> 点击了加好友');
  }

  ///发布人名称点击
  Future<void> onUserNameClick(VideoData videoData) async {
    print('=====> 点击了发布人名称');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey,
      height: widget.size.height,
      width: widget.size.width,
      child: widget.videoData == null
          ? Center(
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20.0),
                  color: const Color(0x80444444),
                ),
                child: Column(
                  children: const [
                    SizedBox(
                      height: 20,
                    ),
                    Icon(
                      Icons.error_outline,
                      size: 50,
                    ),
                    SizedBox(
                      height: 70,
                    ),
                    Text(
                      '无数据',
                      style: TextStyle(fontSize: 20, color: Colors.white),
                    ),
                  ],
                ),
              ),
            )
          : GestureDetector(
              onTap: () {
                print('============>视频点击 ');
                setState(() {
                  videoController.value.isPlaying
                      ? videoController.pause()
                      : videoController.play();
                });
              },
              child: Container(
                height: widget.size.height,
                width: widget.size.width,
                decoration: const BoxDecoration(color: Colors.black),
                child: Stack(
                  children: <Widget>[
                    videoWidth > videoHeight
                        ? Center(
                            child: AspectRatio(
                              aspectRatio: videoController.value.aspectRatio,
                              child: VideoPlayer(videoController),
                            ),
                          )
                        : AspectRatio(
                            aspectRatio: videoController.value.aspectRatio,
                            child: VideoPlayer(videoController),
                          ),
                    Center(
                      child: !videoController.value.isPlaying && !isInitPlaying
                          ? Image.network(
                              widget.videoData!.albumImg,
                              width: widget.size.width,
                              height: widget.size.height,
                              fit: BoxFit.cover,
                            )
                          : const SizedBox(),
                    ),
                    Center(
                      child: Container(
                        decoration: const BoxDecoration(),
                        child: isPlaying(),
                      ),
                    ),
                    isBuffering || !videoController.value.isInitialized
                        ? const Center(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                color: Color(0xFF69DCE5),
                              ),
                            ),
                          )
                        : const SizedBox(),
                    Padding(
                      padding:
                          const EdgeInsets.only(left: 0, top: 10, bottom: 10),
                      child: SafeArea(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Expanded(
                              child: Row(
                                children: <Widget>[
                                  bottomPanel(
                                    widget.size,
                                    widget.videoData!,
                                  ),
                                  rightPanel(
                                    context,
                                    widget.size,
                                    widget.videoData!,
                                  )
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 10,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3, // 轨道高度
                                  trackShape:
                                      const RoundedRectSliderTrackShape(), // 轨道形状，可以自定义
                                  activeTrackColor:
                                      const Color(0xFF444444), // 激活的轨道颜色
                                  inactiveTrackColor:
                                      const Color(0x80444444), // 未激活的轨道颜色
                                  thumbColor: const Color(0xFF999999), // 滑块颜色
                                  thumbShape: const RoundSliderThumbShape(
                                      //  滑块形状，可以自定义
                                      enabledThumbRadius: 4 // 滑块大小
                                      ),
                                  overlayShape: const RoundSliderOverlayShape(
                                    overlayRadius: 10, // 设置滑块的覆盖层半径
                                  ),
                                ),
                                child: Slider(
                                  value: _currentSliderValue,
                                  min: 0.0,
                                  max: videoController.value.duration.inSeconds
                                      .toDouble(),
                                  onChanged: (value) {
                                    setState(() {
                                      _currentSliderValue = value;
                                      videoController.seekTo(
                                          Duration(seconds: value.toInt()));
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    videoWidth > videoHeight
                        ? GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => FullScreenVideoPage(
                                        videoController: videoController)),
                              );
                            },
                            child: Padding(
                                padding:
                                    const EdgeInsets.only(top: 500, left: 150),
                                child: SizedBox(
                                  width: 110,
                                  height: 40,
                                  child: Container(
                                      decoration: BoxDecoration(
                                        borderRadius:
                                            BorderRadius.circular(20.0),
                                        color: const Color(0x80444444),
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: const [
                                          SizedBox(
                                            width: 3,
                                          ),
                                          Icon(
                                            Icons.fullscreen,
                                            color: Colors.white,
                                          ),
                                          Text(
                                            '全屏观看',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                          SizedBox(
                                            width: 3,
                                          ),
                                        ],
                                      )),
                                )))
                        : const SizedBox(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget isPlaying() {
    if (videoController.value.isInitialized) {
      return videoController.value.isPlaying
          ? const SizedBox()
          : Image.asset(
              'assets/images/icon_play.png',
              width: 80,
              height: 80,
            );
    } else {
      return const SizedBox();
    }
  }

  String _formatDuration(Duration duration) {
    return '${duration.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  Widget bottomPanel(Size size, VideoData videoData) {
    return Container(
      width: size.width * 0.8,
      height: size.height,
      padding: const EdgeInsets.only(left: 15),
      decoration: const BoxDecoration(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          GestureDetector(
            onTap: () {
              onUserNameClick(videoData);
            },
            child: Text(
              '@${videoData.userName}',
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Container(
            margin: const EdgeInsets.only(right: 30),
            child: Row(
              children: [
                videoData.type == "1"
                    ? Container(
                        padding: const EdgeInsets.only(
                            left: 4, right: 4, top: 2, bottom: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3.0), // 设置圆角
                          color: const Color(0xFF8B452B), // 设置背景颜色
                        ),
                        child: const Text(
                          '精',
                          style: TextStyle(
                            color: Color(0xFFF47947),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : const SizedBox(),
                const SizedBox(
                  width: 10,
                ),
                Text(
                  videoData.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '  ·  ${videoData.time}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Container(
            margin: const EdgeInsets.only(right: 30),
            child: Text(
              videoData.description,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          Wrap(
            spacing: 8.0, // 主轴(水平)方向间距
            runSpacing: 2.0, // 纵轴（垂直）方向间距
            children: videoData.videoTags.map((item) {
              return GestureDetector(
                onTap: () {
                  onVideoTagsClick(item);
                },
                child: Container(
                  padding: const EdgeInsets.only(
                      left: 6, right: 6, top: 3, bottom: 3),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20.0), // 设置圆角
                    color: const Color(0xFF69DCE5), // 设置背景颜色
                  ),
                  child: Text(
                    '#${item.tagName}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }

  Widget rightPanel(BuildContext context, Size size, VideoData videoData) {
    return Expanded(
      child: SizedBox(
        height: size.height,
        child: Column(
          children: <Widget>[
            Container(
              height: size.height * 0.4,
            ),
            Expanded(
                child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                getProfile(videoData),
                getLike(videoData, 25.0),
                getComment(context, videoData, 25.0),
                getWatch(videoData, 25.0),
                getShare(videoData, 25.0),
                const SizedBox(
                  height: 60,
                ),
              ],
            ))
          ],
        ),
      ),
    );
  }

  Widget getLike(VideoData videoData, double size) {
    return GestureDetector(
      onTap: () {
        onLikeClick(videoData);
      },
      child: Column(
        children: <Widget>[
          videoData.likeStatus == "1"
              ?
              //已点赞
              Image.asset(
                  'assets/images/icon_like.png',
                  width: size,
                  height: size,
                )
              //未点赞
              : Image.asset(
                  'assets/images/icon_like.png',
                  width: size,
                  height: size,
                ),
          const SizedBox(
            height: 5,
          ),
          Text(
            videoData.likes,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          )
        ],
      ),
    );
  }

  Widget getComment(BuildContext context, VideoData videoData, double size) {
    return GestureDetector(
      onTap: () {
        onCommentClick(context, videoData);
      },
      child: Column(
        children: <Widget>[
          Image.asset(
            'assets/images/icon_comment.png',
            width: size,
            height: size,
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            videoData.comments,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          )
        ],
      ),
    );
  }

  Widget getWatch(VideoData videoData, double size) {
    return GestureDetector(
      onTap: () {
        onWatchClick(videoData);
      },
      child: Column(
        children: <Widget>[
          Image.asset(
            'assets/images/icon_watch.png',
            width: size,
            height: size,
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            videoData.watchers,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          )
        ],
      ),
    );
  }

  Widget getShare(VideoData videoData, double size) {
    return GestureDetector(
      onTap: () {
        onShareClick(videoData);
      },
      child: Column(
        children: <Widget>[
          Image.asset(
            'assets/images/icon_share.png',
            width: size,
            height: size,
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            videoData.shares,
            style: const TextStyle(
                color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
          )
        ],
      ),
    );
  }

  Widget getProfile(VideoData videoData) {
    return GestureDetector(
      onTap: () {
        onAddFriendClick(videoData);
      },
      child: SizedBox(
        width: 50,
        height: 60,
        child: Stack(
          children: <Widget>[
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  shape: BoxShape.circle,
                  image: DecorationImage(
                      image: NetworkImage(videoData.userAvatarUrl),
                      fit: BoxFit.cover)),
            ),
            Positioned(
                bottom: 3,
                left: 18,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: Color(0xFF69DCE5)),
                  child: const Center(
                      child: Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 15,
                  )),
                ))
          ],
        ),
      ),
    );
  }

  void showCommentBottomSheet(BuildContext context, List<CommentData> comments,
      VideoData videoData) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      enableDrag: true,
      isScrollControlled: true,
      builder: (_) => CommentBottomSheet(
        commentData: comments,
        videoData: videoData,
      ),
    );
  }
}

class CommentBottomSheet extends StatefulWidget {
  final List<CommentData> commentData;
  final VideoData videoData;

  const CommentBottomSheet({
    Key? key,
    required this.commentData,
    required this.videoData,
  }) : super(key: key);

  @override
  State<CommentBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentBottomSheet> {
  List<CommentData> comments = [];
  VideoData? videoData;
  TextEditingController textEditingController = TextEditingController();
  FocusNode focusNode = FocusNode();
  String hint = "写评论";
  @override
  void initState() {
    comments = widget.commentData;
    videoData = widget.videoData;
    super.initState();
  }

  /// 发送评论
  onSendComment(String input) {
    print('========> 发送评论：$input');
  }

  /// 点赞评论
  onLikeComment(CommentData commentData) {
    print('========> 点赞评论');
  }

  /// 回复评论
  onReplayComment(CommentData commentData) {
    print('========> 回复评论');
  }

  /// 回复评论中的回复
  onReplayCommentReplay(CommentData commentData, CommentData replayComment) {
    print('========> 回复评论中的回复');
  }

  /// 查看全部评论
  onWatchAllComment(CommentData commentData) {
    print('========> 查看全部评论');
    for (int i = 0; i < comments.length; i++) {}
  }

  /// 底部输入框 点赞
  onBottomLike() {
    print('========> 底部输入框 点赞');
  }

  /// 底部输入框 分享
  onBottomShare() {
    print('========> 底部输入框 分享');
  }

  /// 底部输入框 收藏
  onBottomFavorite() {
    print('========> 底部输入框 收藏');
  }

  /// 底部输入框 评论
  onBottomComment() {
    print('========> 底部输入框 评论');
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: Stack(
        children: [
          // 评论列表
          Padding(
            padding: const EdgeInsets.only(top: 60, bottom: 70),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: comments.length,
              itemBuilder: (BuildContext context, int index) {
                return CommentItem(comments[index], comments, index);
              },
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: // 评论数
                Container(
              padding: const EdgeInsets.only(
                  top: 16, left: 16, right: 16, bottom: 0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                color: Colors.white,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${comments.length}条评论',
                        style:
                            const TextStyle(fontSize: 15, color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 16, right: 16),
                    child: const Divider(
                      height: 1,
                      color: Colors.grey,
                    ),
                  )
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: // 输入框和操作栏
                Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom),
              child: Row(
                children: [
                  Flexible(
                    child: TextField(
                      controller: textEditingController,
                      focusNode: focusNode,
                      onSubmitted: submitComment,
                      onEditingComplete: () {
                        submitComment(textEditingController.text);
                      },
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: hint,
                        filled: true,
                        isDense: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  SizedBox(
                    width: 40,
                    child: GestureDetector(
                        onTap: () {
                          onBottomFavorite();
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_border,
                              color: Color(0xFF9F9F9F),
                            ),
                            Text(
                              '${videoData?.favorites}',
                              style: const TextStyle(
                                color: Color(0xFF9F9F9F),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )),
                  ),
                  SizedBox(
                    width: 40,
                    child: GestureDetector(
                        onTap: () {
                          onBottomShare();
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.ios_share_outlined,
                              color: Color(0xFF9F9F9F),
                            ),
                            Text(
                              '${videoData?.shares}',
                              style: const TextStyle(
                                color: Color(0xFF9F9F9F),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )),
                  ),
                  SizedBox(
                    width: 40,
                    child: GestureDetector(
                        onTap: () {
                          onBottomComment();
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.comment_outlined,
                              color: Color(0xFF9F9F9F),
                            ),
                            Text(
                              '${videoData?.comments}',
                              style: const TextStyle(
                                color: Color(0xFF9F9F9F),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )),
                  ),
                  SizedBox(
                    width: 40,
                    child: GestureDetector(
                        onTap: () {
                          onBottomLike();
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.thumb_up_alt_outlined,
                              color: Color(0xFF9F9F9F),
                            ),
                            Text(
                              '${videoData?.likes}',
                              style: const TextStyle(
                                color: Color(0xFF9F9F9F),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void submitComment(String inputText) {
    if (textEditingController.text.isEmpty) return;
    onSendComment(textEditingController.text);
    textEditingController.clear();
    hint = '写评论';
    focusNode.unfocus();
  }

  Widget CommentItem(
      CommentData commentData, List<CommentData> comments, int index) {
    var size = MediaQuery.of(context).size;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    shape: BoxShape.circle,
                    image: DecorationImage(
                        image: NetworkImage(commentData.userAvatarUrl),
                        fit: BoxFit.cover)),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            commentData.userName,
                            style: const TextStyle(
                                fontSize: 18, color: Colors.black),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            commentData.time,
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(width: 120),
                      // 点赞数量
                      GestureDetector(
                        onTap: () {
                          onLikeComment(commentData);
                        },
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            commentData.likeStatus == "1"
                                ? const Icon(
                                    Icons.thumb_up,
                                    color: Color(0xFF67DCE7),
                                  )
                                : const Icon(
                                    Icons.thumb_up_off_alt_outlined,
                                    color: Colors.grey,
                                  ),
                            const SizedBox(width: 4),
                            Text(
                              commentData.likes,
                              style: TextStyle(
                                fontSize: 17,
                                color: commentData.likeStatus == "1"
                                    ? const Color(0xFF67DCE7)
                                    : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      commentData.type == "1"
                          ? Container(
                              padding: const EdgeInsets.only(
                                  left: 4, right: 4, top: 2, bottom: 2),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(3.0), // 设置圆角
                                color: const Color(0xFFFFF0EC), // 设置背景颜色
                              ),
                              child: const Text(
                                '精',
                                style: TextStyle(
                                  color: Color(0xFFED7F55),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            )
                          : const SizedBox(),
                      const SizedBox(
                        width: 5,
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            hint = "回复 ${commentData.userName} : ";
                          });
                          FocusScope.of(context).requestFocus(focusNode);

                          onReplayComment(commentData);
                        },
                        child: SizedBox(
                          width: size.width - 148,
                          child: Text(
                            commentData.content,
                            style: const TextStyle(
                              fontSize: 17,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 30),
                    ],
                  ),

                  const SizedBox(height: 8),
                  // 回复内容
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5.0), // 设置圆角
                      color: const Color(0xFFF3F3F3),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ...List.generate(
                          commentData.replayList.length,
                          (index) => ReplyItem(commentData,
                              commentData.replayList[index], size.width),
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        // 查看全部回复
                        GestureDetector(
                            onTap: () {
                              // 处理查看全部回复逻辑
                              onWatchAllComment(commentData);
                            },
                            child: Row(
                              children: [
                                Text(
                                  '全部${commentData.replayList.length}条回复',
                                  style: const TextStyle(
                                      color: Colors.black, fontSize: 15),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    size: 15, color: Colors.black),
                              ],
                            )),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          index == comments.length - 1
              ? Container(
                  margin: const EdgeInsets.only(top: 10),
                  child: const Text(
                    '- 没有更多了哦 -',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        fontWeight: FontWeight.bold),
                  ),
                )
              : const SizedBox(),
        ],
      ),
    );
  }

  Widget ReplyItem(
      CommentData commentData, CommentData replayComment, double width) {
    return GestureDetector(
      onTap: () {
        setState(() {
          hint = "回复 ${replayComment.userName} : ";
        });
        FocusScope.of(context).requestFocus(focusNode);

        onReplayCommentReplay(commentData, replayComment);
      },
      child: SizedBox(
        width: width - 120,
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: replayComment.userName,
                style: const TextStyle(
                  color: Color(0xFF67DCE7),
                  fontSize: 14,
                ),
              ),
              const TextSpan(
                text: ' 回复 ',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF707070),
                ),
              ),
              TextSpan(
                text: replayComment.replayName,
                style: const TextStyle(
                  color: Color(0xFF67DCE7),
                  fontSize: 14,
                ),
              ),
              TextSpan(
                text: ' : ${replayComment.replayContent}',
                style: const TextStyle(
                  color: Color(0xFF707070),
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FullScreenVideoPage extends StatefulWidget {
  final VideoPlayerController videoController;

  const FullScreenVideoPage({Key? key, required this.videoController})
      : super(key: key);

  @override
  _FullScreenVideoPageState createState() => _FullScreenVideoPageState();
}

class _FullScreenVideoPageState extends State<FullScreenVideoPage> {
  double _currentSliderValue = 0.0;
  bool isBuffering = false;
  bool isInitPlaying = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
    ]);
    setState(() {
      _currentSliderValue = 0.0;
      isInitPlaying = true;
    });
    widget.videoController.addListener(videoListener);
  }

  void videoListener() {
    setState(() {
      isBuffering = widget.videoController.value.isBuffering;
      _currentSliderValue =
          widget.videoController.value.position.inSeconds.toDouble();
    });
  }

  @override
  void dispose() {
    widget.videoController.removeListener(videoListener);
    super.dispose();
  }

  Widget isPlaying() {
    if (widget.videoController.value.isInitialized) {
      return widget.videoController.value.isPlaying
          ? const SizedBox()
          : Image.asset(
              'assets/images/icon_play.png',
              width: 80,
              height: 80,
            );
    } else {
      return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        child: Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () {
              setState(() {
                widget.videoController.value.isPlaying
                    ? widget.videoController.pause()
                    : widget.videoController.play();
              });
            },
            child: Stack(
              children: [
                VideoPlayer(widget.videoController),
                Padding(
                  padding: const EdgeInsets.only(top: 25, right: 20),
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      size: 30,
                    ),
                    color: Colors.white,
                    onPressed: () {
                      SystemChrome.setPreferredOrientations([
                        DeviceOrientation.portraitUp,
                      ]);
                      Navigator.pop(context);
                    },
                  ),
                ),
                Center(
                  child: Container(
                    decoration: const BoxDecoration(),
                    child: isPlaying(),
                  ),
                ),
                isBuffering || !widget.videoController.value.isInitialized
                    ? const Center(
                        child: SizedBox(
                          width: 50,
                          height: 50,
                          child: CircularProgressIndicator(
                            color: Color(0xFF69DCE5),
                          ),
                        ),
                      )
                    : const SizedBox(),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    height: 10,
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3, // 轨道高度
                        trackShape:
                            const RoundedRectSliderTrackShape(), // 轨道形状，可以自定义
                        activeTrackColor: const Color(0xFF444444), // 激活的轨道颜色
                        inactiveTrackColor: const Color(0x80444444),
                        thumbColor: const Color(0xFF999999), // 未激活的轨道颜色
                        thumbShape: const RoundSliderThumbShape(
                            //  滑块形状，可以自定义
                            enabledThumbRadius: 4 // 滑块大小
                            ),
                        overlayShape: const RoundSliderOverlayShape(
                          overlayRadius: 10, // 设置滑块的覆盖层半径
                        ),
                      ),
                      child: Slider(
                        value: _currentSliderValue,
                        min: 0.0,
                        max: widget.videoController.value.duration.inSeconds
                            .toDouble(),
                        onChanged: (value) {
                          setState(() {
                            _currentSliderValue = value;
                            widget.videoController
                                .seekTo(Duration(seconds: value.toInt()));
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        onWillPop: () async {
          SystemChrome.setPreferredOrientations([
            DeviceOrientation.portraitUp,
          ]);
          Navigator.pop(context);
          return false;
        });
  }
}

class VideoData {
  final String id; // 唯一id
  final String uid; // 发布人 uid
  final String type; //type = 1 视频加 精
  final String videoUrl; //视频地址
  final String albumImg; //视频第一帧封面
  final String userName; //发布者名
  final String userAvatarUrl; //发布者头像
  final String description; //视频描述
  final String title; //视频标题
  final String likes; //视频点赞数
  final String likeStatus; //0未点赞 1 已点赞
  final String comments; //视频评论数
  final String shares; //视频分享数
  final String watchers; //视频观看数
  final String favorites; //视频收藏数
  final String time; //视频发布时间
  final List<VideoTag> videoTags; //视频关联话题

  VideoData({
    required this.id,
    required this.uid,
    required this.type,
    required this.videoUrl,
    required this.albumImg,
    required this.userName,
    required this.userAvatarUrl,
    required this.description,
    required this.title,
    required this.likes,
    required this.likeStatus,
    required this.comments,
    required this.shares,
    required this.watchers,
    required this.favorites,
    required this.time,
    required this.videoTags,
  });
}

class VideoTag {
  final String tagId; //视频关联话题id
  final String tagName; //视频关联话题名
  VideoTag({
    required this.tagId,
    required this.tagName,
  });
}

class VideoType {
  final String typeId; //视频分类id
  final String typeName; //视频分类名
  VideoType({
    required this.typeId,
    required this.typeName,
  });
}

class CommentData {
  final String id; // 唯一id
  final String uid; // 评论用户uid
  final String userName; // 评论用户uid
  final String userAvatarUrl; // 评论用户uid
  final String time; // 发布评论时间
  final String type; //type = 1 评论加 精
  final String content; //评论文案
  final String likes; //评论点赞数
  final String likeStatus; //0未点赞 1 已点赞
  final String replayName; //被回复者
  final String replayUid; //被回复者 uid
  final String replayContent; //回复内容
  final List<CommentData> replayList;

  CommentData({
    required this.id,
    required this.uid,
    required this.userName,
    required this.userAvatarUrl,
    required this.time,
    required this.type,
    required this.content,
    required this.likes,
    required this.likeStatus,
    required this.replayName,
    required this.replayUid,
    required this.replayContent,
    required this.replayList,
  });
}

/// 测试数据

List<CommentData> testCommentData = <CommentData>[
  CommentData(
    id: "2524525",
    uid: "5254453",
    userName: "晴子",
    userAvatarUrl:
        "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
    time: "2023/01/17 14:30:22",
    type: "1",
    content: "有情趣又热爱生活的人真好有情趣又热爱生活",
    likes: "100",
    likeStatus: "1",
    replayName: "虾仁",
    replayUid: "11111",
    replayContent: "奔驰发布全新旅行车更适合大家出行要不要试驾",
    replayList: [
      CommentData(
        id: "2545",
        uid: "11541",
        userName: "用户1",
        userAvatarUrl:
            "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
        time: "2023/01/17 14:30:22",
        type: "1",
        content: "有情趣又热爱生活的人真好有情趣又热爱生活",
        likes: "100",
        likeStatus: "0",
        replayName: "虾仁",
        replayUid: "11111",
        replayContent: "奔驰发布全新旅行车更适合大家出行要不要试驾",
        replayList: [],
      ),
      CommentData(
        id: "5383",
        uid: "57225",
        userName: "用户2",
        userAvatarUrl:
            "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
        time: "2023/01/17 14:30:22",
        type: "1",
        content: "有情趣又热爱生活的人真好有情趣又热爱生活",
        likes: "100",
        likeStatus: "0",
        replayName: "虾仁",
        replayUid: "11111",
        replayContent: "奔驰发布全新旅行车更适合大家出行要不要试驾",
        replayList: [],
      ),
      CommentData(
        id: "42458",
        uid: "245454",
        userName: "用户3",
        userAvatarUrl:
            "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
        time: "2023/01/17 14:30:22",
        type: "1",
        content: "有情趣又热爱生活的人真好有情趣又热爱生活",
        likes: "100",
        likeStatus: "0",
        replayName: "虾仁",
        replayUid: "11111",
        replayContent: "奔驰发布全新旅行车更适合大家出行要不要试驾",
        replayList: [],
      ),
    ],
  ),
  CommentData(
    id: "56535",
    uid: "52482",
    userName: "虾仁",
    userAvatarUrl:
        "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
    time: "2023/01/17 14:30:22",
    type: "1",
    content: "有情趣又热爱生活的人真好有情趣又热爱生活",
    likes: "100",
    likeStatus: "0",
    replayName: "虾仁",
    replayUid: "11111",
    replayContent: "奔驰发布全新旅行车更适合大家出行要不要试驾",
    replayList: [
      CommentData(
        id: "5353",
        uid: "24535",
        userName: "用户4",
        userAvatarUrl:
            "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
        time: "2023/01/17 14:30:22",
        type: "1",
        content: "有情趣又热爱生活的人真好有情趣又热爱生活",
        likes: "100",
        likeStatus: "0",
        replayName: "虾仁",
        replayUid: "11111",
        replayContent: "奔驰发布全新旅行车更适合大家出行要不要试驾",
        replayList: [],
      ),
      CommentData(
        id: "5355",
        uid: "35434",
        userName: "用户5",
        userAvatarUrl:
            "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
        time: "2023/01/17 14:30:22",
        type: "1",
        content: "有情趣又热爱生活的人真好有情趣又热爱生活",
        likes: "100",
        likeStatus: "0",
        replayName: "虾仁",
        replayUid: "11111",
        replayContent: "奔驰发布全新旅行车更适合大家出行要不要试驾",
        replayList: [],
      ),
      CommentData(
        id: "5452",
        uid: "35572",
        userName: "用户6",
        userAvatarUrl:
            "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
        time: "2023/01/17 14:30:22",
        type: "1",
        content: "有情趣又热爱生活的人真好有情趣又热爱生活",
        likes: "100",
        likeStatus: "0",
        replayName: "虾仁",
        replayUid: "11111",
        replayContent: "奔驰发布全新旅行车更适合大家出行要不要试驾",
        replayList: [],
      ),
    ],
  ),
  CommentData(
    id: "87886",
    uid: "6765",
    userName: "晴子",
    userAvatarUrl:
        "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
    time: "2023/01/17 14:30:22",
    type: "1",
    content: "有情趣又热爱生活的人真好有情趣又热爱生活",
    likes: "100",
    likeStatus: "0",
    replayName: "虾仁",
    replayUid: "11111",
    replayContent: "奔驰发布全新旅行车更适合大家出行要不要试驾",
    replayList: [
      CommentData(
        id: "8768",
        uid: "68737",
        userName: "用户7",
        userAvatarUrl:
            "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
        time: "2023/01/17 14:30:22",
        type: "1",
        content: "有情趣又热爱生活的人真好有情趣又热爱生活",
        likes: "100",
        likeStatus: "0",
        replayName: "虾仁",
        replayUid: "11111",
        replayContent: "奔驰发布全新旅行车更适合大家出行要不要试驾",
        replayList: [],
      ),
      CommentData(
        id: "68727",
        uid: "68778",
        userName: "用户8",
        userAvatarUrl:
            "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
        time: "2023/01/17 14:30:22",
        type: "1",
        content: "有情趣又热爱生活的人真好有情趣又热爱生活",
        likes: "100",
        likeStatus: "0",
        replayName: "虾仁",
        replayUid: "11111",
        replayContent: "奔驰发布全新旅行车更适合大家出行要不要试驾",
        replayList: [],
      ),
      CommentData(
        id: "12821",
        uid: "8755",
        userName: "用户9",
        userAvatarUrl:
            "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
        time: "2023/01/17 14:30:22",
        type: "1",
        content: "有情趣又热爱生活的人真好有情趣又热爱生活",
        likes: "100",
        likeStatus: "0",
        replayName: "虾仁",
        replayUid: "11111",
        replayContent: "奔驰发布全新旅行车更适合大家出行要不要试驾",
        replayList: [],
      ),
    ],
  ),
];

List<VideoType> testVideoType = <VideoType>[
  VideoType(typeId: "1111", typeName: "热门"),
  VideoType(typeId: "1111", typeName: "分类一"),
  VideoType(typeId: "1111", typeName: "分类二"),
  VideoType(typeId: "1111", typeName: "分类三"),
  VideoType(typeId: "1111", typeName: "分类四"),
];

List<VideoData> testVideoData = <VideoData>[
  VideoData(
      id: "111",
      uid: "1233",
      type: "1",
      videoUrl: "https://static.ybhospital.net/test-video-2.mp4",
      albumImg:
          "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fc-ssl.duitang.com%2Fuploads%2Fblog%2F202107%2F05%2F20210705100427_ee4b8.thumb.1000_0.jpg&refer=http%3A%2F%2Fc-ssl.duitang.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=jpeg?sec=1628415177&t=87962cc902fb5925da0a4d60d4c48ca9",
      userName: "发布人名称",
      userAvatarUrl:
          "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
      description: "春日的暖阳，花开进度80%，准备和爱车路过全世界，感受独具魅力的岭南文化!",
      title: "视频标题",
      likes: "130",
      likeStatus: "1",
      comments: "186",
      shares: "135",
      watchers: "328",
      favorites: "636",
      time: "2023年12月16日",
      videoTags: [
        VideoTag(tagId: "1111", tagName: "今天去哪玩"),
        VideoTag(tagId: "1111", tagName: "南京车友圈"),
        VideoTag(tagId: "1111", tagName: "活动名称"),
      ]),
  VideoData(
      id: "111",
      uid: "1233",
      type: "1",
      videoUrl: "https://static.ybhospital.net/test-video-3.mp4",
      albumImg:
          "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fc-ssl.duitang.com%2Fuploads%2Fblog%2F202107%2F05%2F20210705100427_ee4b8.thumb.1000_0.jpg&refer=http%3A%2F%2Fc-ssl.duitang.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=jpeg?sec=1628415177&t=87962cc902fb5925da0a4d60d4c48ca9",
      userName: "发布人名称",
      userAvatarUrl:
          "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
      description: "春日的暖阳，花开进度80%，准备和爱车路过全世界，感受独具魅力的岭南文化!",
      title: "视频标题",
      likes: "130",
      likeStatus: "1",
      comments: "165",
      shares: "135",
      watchers: "320",
      favorites: "105",
      time: "2023年12月16日",
      videoTags: [
        VideoTag(tagId: "1111", tagName: "今天去哪玩"),
        VideoTag(tagId: "1111", tagName: "南京车友圈"),
        VideoTag(tagId: "1111", tagName: "活动名称"),
      ]),
  VideoData(
      id: "111",
      uid: "1233",
      type: "1",
      videoUrl: "https://static.ybhospital.net/test-video-4.mp4",
      albumImg:
          "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fc-ssl.duitang.com%2Fuploads%2Fblog%2F202107%2F05%2F20210705100427_ee4b8.thumb.1000_0.jpg&refer=http%3A%2F%2Fc-ssl.duitang.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=jpeg?sec=1628415177&t=87962cc902fb5925da0a4d60d4c48ca9",
      userName: "发布人名称",
      userAvatarUrl:
          "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
      description: "春日的暖阳，花开进度80%，准备和爱车路过全世界，感受独具魅力的岭南文化!",
      title: "视频标题",
      likes: "150",
      likeStatus: "1",
      comments: "185",
      shares: "136",
      watchers: "280",
      favorites: "500",
      time: "2023年12月16日",
      videoTags: [
        VideoTag(tagId: "1111", tagName: "今天去哪玩"),
        VideoTag(tagId: "1111", tagName: "南京车友圈"),
        VideoTag(tagId: "1111", tagName: "活动名称"),
      ]),
  VideoData(
      id: "111",
      uid: "1233",
      type: "1",
      videoUrl: "https://static.ybhospital.net/test-video-5.mp4",
      albumImg:
          "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fc-ssl.duitang.com%2Fuploads%2Fblog%2F202107%2F05%2F20210705100427_ee4b8.thumb.1000_0.jpg&refer=http%3A%2F%2Fc-ssl.duitang.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=jpeg?sec=1628415177&t=87962cc902fb5925da0a4d60d4c48ca9",
      userName: "发布人名称",
      userAvatarUrl:
          "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
      description: "春日的暖阳，花开进度80%，准备和爱车路过全世界，感受独具魅力的岭南文化!",
      title: "视频标题",
      likes: "365",
      likeStatus: "1",
      comments: "425",
      shares: "253",
      watchers: "854",
      favorites: "524",
      time: "2023年12月16日",
      videoTags: [
        VideoTag(tagId: "1111", tagName: "今天去哪玩"),
        VideoTag(tagId: "1111", tagName: "南京车友圈"),
        VideoTag(tagId: "1111", tagName: "活动名称"),
      ]),
  VideoData(
      id: "111",
      uid: "1233",
      type: "1",
      videoUrl: "https://static.ybhospital.net/test-video-6.mp4",
      albumImg:
          "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fc-ssl.duitang.com%2Fuploads%2Fblog%2F202107%2F05%2F20210705100427_ee4b8.thumb.1000_0.jpg&refer=http%3A%2F%2Fc-ssl.duitang.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=jpeg?sec=1628415177&t=87962cc902fb5925da0a4d60d4c48ca9",
      userName: "发布人名称",
      userAvatarUrl:
          "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
      description: "春日的暖阳，花开进度80%，准备和爱车路过全世界，感受独具魅力的岭南文化!",
      title: "视频标题",
      likes: "352",
      likeStatus: "1",
      comments: "585",
      shares: "425",
      watchers: "825",
      favorites: "245",
      time: "2023年12月16日",
      videoTags: [
        VideoTag(tagId: "1111", tagName: "今天去哪玩"),
        VideoTag(tagId: "1111", tagName: "南京车友圈"),
        VideoTag(tagId: "1111", tagName: "活动名称"),
      ]),
  VideoData(
      id: "2525",
      uid: "35435",
      type: "1",
      videoUrl: "https://media.w3.org/2010/05/sintel/trailer.mp4",
      albumImg:
          "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fc-ssl.duitang.com%2Fuploads%2Fblog%2F202107%2F05%2F20210705100427_ee4b8.thumb.1000_0.jpg&refer=http%3A%2F%2Fc-ssl.duitang.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=jpeg?sec=1628415177&t=87962cc902fb5925da0a4d60d4c48ca9",
      userName: "发布人名称",
      userAvatarUrl:
          "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
      description: "春日的暖阳，花开进度80%，准备和爱车路过全世界，感受独具魅力的岭南文化!",
      title: "视频标题",
      likes: "252",
      likeStatus: "1",
      comments: "424",
      shares: "245",
      watchers: "453",
      favorites: "523",
      time: "2023年12月16日",
      videoTags: [
        VideoTag(tagId: "1111", tagName: "今天去哪玩"),
        VideoTag(tagId: "1111", tagName: "南京车友圈"),
        VideoTag(tagId: "1111", tagName: "活动名称"),
      ]),
  VideoData(
      id: "2525",
      uid: "35435",
      type: "1",
      videoUrl: "https://jomin-web.web.app/resource/video/video_iu.mp4",
      albumImg:
          "https://gimg2.baidu.com/image_search/src=http%3A%2F%2Fc-ssl.duitang.com%2Fuploads%2Fblog%2F202107%2F05%2F20210705100427_ee4b8.thumb.1000_0.jpg&refer=http%3A%2F%2Fc-ssl.duitang.com&app=2002&size=f9999,10000&q=a80&n=0&g=0n&fmt=jpeg?sec=1628415177&t=87962cc902fb5925da0a4d60d4c48ca9",
      userName: "发布人名称",
      userAvatarUrl:
          "https://p16-tiktokcdn-com.akamaized.net/aweme/720x720/tiktok-obj/1663771856684033.jpeg",
      description: "春日的暖阳，花开进度80%，准备和爱车路过全世界，感受独具魅力的岭南文化!",
      title: "视频标题",
      likes: "252",
      likeStatus: "1",
      comments: "424",
      shares: "245",
      watchers: "453",
      favorites: "523",
      time: "2023年12月16日",
      videoTags: [
        VideoTag(tagId: "1111", tagName: "今天去哪玩"),
        VideoTag(tagId: "1111", tagName: "南京车友圈"),
        VideoTag(tagId: "1111", tagName: "活动名称"),
      ]),
];
