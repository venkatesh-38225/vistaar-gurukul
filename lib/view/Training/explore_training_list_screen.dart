import 'dart:developer';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gurukul/utils/widgets/custom_appbar.dart';
import 'package:provider/provider.dart';

import '../../model/training.dart';
import '../../provider/api_provider.dart';
import '../../provider/tab_provider.dart';
import '../../utils/widgets/topic_card_widget.dart';
import '../../utils/widgets/custom_snackbar.dart';

class ExploreTrainingListScreen extends StatefulWidget {
  const ExploreTrainingListScreen({
    super.key,
    required this.department,
  });

  final String department;

  @override
  State<ExploreTrainingListScreen> createState() =>
      _ExploreTrainingListScreenState();
}

class _ExploreTrainingListScreenState extends State<ExploreTrainingListScreen> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: CustomAppBar(

        size: size,
        title: widget.department,
        automaticallyImplyLeading: true,
      ),
      body: Container(
        // decoration: const BoxDecoration(
        //   color: Colors.white70,
        // ),
        height: size.height,
        width: size.width,
        padding: const EdgeInsets.all(20),
        child: StreamBuilder<Training>(
          stream: Provider.of<UserProvider>(context, listen: false)
              .getExploreTrainingByDeptStream(department: widget.department),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Image.asset('assets/loading.gif'),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Image.asset('assets/error.png'),
              );
            } else if (!snapshot.hasData || snapshot.data!.d!.isEmpty) {
              return Center(
                child: Text(
                  "Our knowledge factory is brewing. Stay tuned for some enlightening training content!",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            } else {
              List<D> trainingList = snapshot.data!.d!;
              return SizedBox(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: trainingList.length,
                  // itemExtent: size.height / 8,
                  itemBuilder: (context, index) {
                    D training = trainingList[index];
                    return GestureDetector(
                      onTap: () async {
                        // if (training.trainingType == 'T') {
                        log("TrainingId: ${training.id}, Department: ${widget.department}");
                        var alertResult = await showOkCancelAlertDialog(
                            context: context,
                            title: "Assign",
                            message: "Would you like to assign this course?");
                        if (alertResult == OkCancelResult.ok) {
                          Provider.of<UserProvider>(context, listen: false)
                              .resetUserSelect();
                          context.read<TabProvider>().resetSelection();
                          await context
                              .read<UserProvider>()
                              .assignTrainingToEmployee(
                                  trainingId: training.id.toString(),
                                  department: widget.department)
                              .then((value) {
                            if (value == 0) {
                              CustomSnackBar.show(
                                context,
                                message:
                                    "You have already been allocated to this training.",
                                type: SnackBarType.info,
                                actionLabel: "View in Others",
                                onAction: () => context.replace('/others'),
                              );
                            }
                            // } else if (value == 0) {
                            //   SnackBar snackBar = SnackBar(
                            //     content: const Text(
                            //         "This training has been allocated to you. Please verify it on the home screen's 'Others' tab. "),
                            //     duration: const Duration(seconds: 3),
                            //     action: SnackBarAction(
                            //         label: "Other's Tab",
                            //         onPressed: () =>
                            //             context.replace('/others')),
                            //   );
                            //   ScaffoldMessenger.of(context)
                            //       .showSnackBar(snackBar);
                            // }
                          });
                        }
                      },
                      child: TopicCardWidget(
                        heroTag: Key(training.id.toString()),
                        height: size.height / 6,
                        width: size.width,
                        topicName: training.trainingName!,
                        iconName: Icons.add,
                        accentColor: const Color(0xFF0077D6),
                        subtitle: "Available to assign • Tap to select",
                      ),
                    );
                  },
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
