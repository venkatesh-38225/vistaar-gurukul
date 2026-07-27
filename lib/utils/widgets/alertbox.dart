import 'package:flutter/material.dart';

class AnimatedDialogExample extends StatefulWidget {
  const AnimatedDialogExample({super.key});

  @override
  _AnimatedDialogExampleState createState() => _AnimatedDialogExampleState();
}

class _AnimatedDialogExampleState extends State<AnimatedDialogExample>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Offset _tapPosition;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTap(BuildContext context, TapDownDetails details) {
    setState(() {
      _tapPosition = details.globalPosition;
    });
    _animationController.forward(from: 0.0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (details) => _onTap(context, details),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Animated Dialog Example'),
        ),
        body: const Center(
          child: Text('Tap on an empty area to trigger the dialog.'),
        ),
        floatingActionButton: _buildAnimatedDialog(),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildAnimatedDialog() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        final animationValue = _animationController.value;
        final dialogOpacity = Curves.easeInOut.transform(animationValue);
        final dialogScale =
            Tween<double>(begin: 0.0, end: 1.0).transform(animationValue);
        const dialogSize = 200.0; // Adjust this size as per your requirement

        return Positioned(
          top: _tapPosition.dy -
              (dialogSize / 2) +
              (dialogSize / 2) * dialogScale,
          left: _tapPosition.dx -
              (dialogSize / 2) +
              (dialogSize / 2) * dialogScale,
          child: Opacity(
            opacity: dialogOpacity,
            child: Transform.scale(
              scale: dialogScale,
              child: Container(
                width: dialogSize,
                height: dialogSize,
                color: Colors.blue,
                child: const Center(
                  child: Text('Your Dialog Content'),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
