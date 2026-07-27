import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gurukul/constants/app_constants.dart';
import 'package:gurukul/provider/tab_provider.dart';
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:provider/provider.dart';

class PhotoViewer extends StatefulWidget {
  const PhotoViewer({super.key, required this.imageUrl});

  final String imageUrl;

  @override
  State<PhotoViewer> createState() => _PhotoViewerState();
}

class _PhotoViewerState extends State<PhotoViewer> {
  PageController photoPageController = PageController();

  @override
  void initState() {
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    //   DeviceOrientation.landscapeLeft,
    //   DeviceOrientation.landscapeRight,
    // ]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      int navigatePage =
          //  int.parse(widget.imageUrl);
          context.read<TabProvider>().getPhotos.indexWhere((element) {
        debugPrint(
            "${widget.imageUrl}  = ${element['image'] == widget.imageUrl}");

        return (element['image'] == widget.imageUrl);
      });

      debugPrint("navigate to image at $navigatePage");
      Future.delayed(const Duration(milliseconds: 500), () {
        goToPage = navigatePage;
      });
    });
    super.initState();
  }

  set goToPage(int page) {
    context.read<TabProvider>().setPhotoPage = page;
    photoPageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    // SystemChrome.setPreferredOrientations([
    //   DeviceOrientation.portraitUp,
    //   DeviceOrientation.portraitDown,
    // ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    // debugPrint(
    //     "photos is ${context.read<TabProvider>().getPhotos} and length ${context.read<TabProvider>().getPhotos.length} ");
    List photos = context.read<TabProvider>().getPhotos;
    return Scaffold(
      appBar: Platform.isIOS
          ? AppBar(
              backgroundColor: Colors.black,
              iconTheme: const IconThemeData(color: Colors.white),
            )
          : null,
      body: Hero(
        tag: imageHero,
        child: SizedBox(
            height: size.height / 0.8,
            child: PhotoViewGallery.builder(
              scrollPhysics: const BouncingScrollPhysics(),

              builder: (BuildContext context, int index) {
                debugPrint("photo index = $index");
                return PhotoViewGalleryPageOptions(
                  imageProvider: NetworkImage(
                      "$trainingContentAssetsUrl/${photos[index]['image']}"),
                  initialScale: PhotoViewComputedScale.contained * 0.8,
                  // heroAttributes: PhotoViewHeroAttributes(tag: index),
                );
              },
              itemCount: photos.length,
              loadingBuilder: (context, event) => Center(
                child: SizedBox(
                  width: 20.0,
                  height: 20.0,
                  child: CircularProgressIndicator(
                    value: event == null
                        ? 0
                        : event.cumulativeBytesLoaded /
                            event.expectedTotalBytes!,
                  ),
                ),
              ),
              // backgroundDecoration: widget.backgroundDecoration,
              pageController: photoPageController,
              onPageChanged: (onPageChanged) {
                context.read<TabProvider>().setPhotoPage =
                    photos[onPageChanged]['index'];
              },
            )),
      ),
    );
  }
}
