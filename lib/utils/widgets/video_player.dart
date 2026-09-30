import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:gurukul/utils/widgets/custom_snackbar.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  DateTime? lastSnackBarTime;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    )..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: () {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        },
        child: Stack(
          children: [
            VideoPlayer(_controller),
            Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: VideoProgressIndicator(_controller, allowScrubbing: false),
            ),
            Center(
              child: playPauseButton(),
            ),
            Positioned(
              left: 80,
              bottom: 0,
              top: 0,
              child: Center(
                child: rewindButton(context),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 15,
              child: fullScreenButton(context),
            )
          ],
        ));
  }

  IconButton fullScreenButton(BuildContext context) {
    return IconButton(
      icon: const Icon(
        Icons.fullscreen,
        color: Colors.white,
        size: 30.0,
      ),
      onPressed: () {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FullScreenVideoView(
                controller: _controller,
                fullScreenButton: fullScreenButton(context),
                playPauseButton: playPauseButton(),
                rewindButton: rewindButton(context)),
          ),
        ).then((value) => SystemChrome.setPreferredOrientations([
              DeviceOrientation.portraitUp,
              DeviceOrientation.portraitDown,
            ]));
      },
    );
  }

  IconButton rewindButton(BuildContext context) {
    return IconButton(
      icon: const Opacity(
        opacity: 0.4,
        child: Icon(
          Icons.fast_rewind,
          color: Colors.white,
          size: 50.0,
        ),
      ),
      onPressed: () {
        final currentTime = DateTime.now();
        if (lastSnackBarTime == null ||
            currentTime.difference(lastSnackBarTime!).inSeconds > 3) {
          lastSnackBarTime = currentTime;
          CustomSnackBar.show(
            context,
            message: "Rewound 10 sec",
            type: SnackBarType.info,
            duration: const Duration(milliseconds: 1200),
          );
        }
        final newPosition =
            _controller.value.position - const Duration(seconds: 10);
        _controller.seekTo(newPosition);
      },
    );
  }

  IconButton playPauseButton() {
    return IconButton(
      icon: Opacity(
        opacity: 0.4,
        child: Icon(
          _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 100.0,
        ),
      ),
      onPressed: () {
        debugPrint("played amount ${_controller.value}");
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
    );
  }
}

class FullScreenVideoView extends StatefulWidget {
  const FullScreenVideoView({
    super.key,
    required this.controller,
    required this.fullScreenButton,
    required this.playPauseButton,
    required this.rewindButton,
  });

  final VideoPlayerController controller;
  final IconButton fullScreenButton;
  final IconButton rewindButton;
  final IconButton playPauseButton;

  @override
  State<FullScreenVideoView> createState() => _FullScreenVideoViewState();
}

class _FullScreenVideoViewState extends State<FullScreenVideoView> {
  late VideoPlayerController _controller;
  DateTime? lastSnackBarTime;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller;
  }

  bool _areControlsVisible = false;

  @override
  Widget build(BuildContext context) {
    // return Scaffold(
    //   body:
    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: Stack(
          children: [
            GestureDetector(
                onTap: () {
                  setState(() {
                    _areControlsVisible = true;
                  });

                  Timer(const Duration(seconds: 3), () {
                    setState(() {
                      _areControlsVisible = false;
                    });
                  });
                },
                child: VideoPlayer(_controller)),
            _areControlsVisible
                ? Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: VideoProgressIndicator(_controller,
                        allowScrubbing: false),
                  )
                : Container(),
            _areControlsVisible
                ? Center(child: widget.playPauseButton)
                : Container(),
            _areControlsVisible
                ? Positioned(
                    left: 80, bottom: 0, top: 0, child: widget.rewindButton)
                : Container(),
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton(
                icon: const Icon(
                  Icons.fullscreen,
                  color: Colors.white,
                  size: 30.0,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
      // ),
    );
  }
}
