// import 'package:flutter/material.dart';

// import 'dart:io';

// import 'package:pdf/widgets.dart' as pw;
// import 'dart:ui' as ui;
// import 'dart:html' as html;

// Future<void> showPdf() async {
//   final pdf = pw.Document();

//   pdf.addPage(
//     pw.Page(
//       build: (pw.Context context) => pw.Center(
//         child: pw.Text('Hello World!'),
//       ),
//     ),
//   );

//   final file = File('example.pdf');
//   await file.writeAsBytes(await pdf.save());
// }

// class WebPdfScreen extends StatelessWidget {
//   WebPdfScreen({
//     super.key,
//     this.pdfUrl,
//     required this.width,
//     required this.height,
//   }) {
//     // ignore: undefined_prefixed_name
//     ui.platformViewRegistry.registerViewFactory('iframe', (int viewId) {
//       var iframe = html.IFrameElement();
//       iframe.src = pdfUrl;
//       return iframe;
//     });
//   }

//   final String? pdfUrl;
//   final double width;
//   final double height;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//         decoration: BoxDecoration(border: Border.all(color: Colors.blueAccent)),
//         width: width,
//         height: height,
//         child: const HtmlElementView(viewType: 'iframe'));
//   }
// }
