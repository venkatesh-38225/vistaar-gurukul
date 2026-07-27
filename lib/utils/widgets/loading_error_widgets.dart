import 'package:flutter/material.dart';

class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            'assets/book-loading.gif',
            width: 100,
            height: 100,
          ),
          const SizedBox(height: 12),
          const Text("Loading....."),
        ],
      ),
    );
  }
}
