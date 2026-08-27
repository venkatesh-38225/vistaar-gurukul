import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gurukul/utils/widgets/custom_appbar.dart';
import 'package:gurukul/utils/widgets/lottie_widgets.dart';
import 'package:provider/provider.dart';

import '../../common/utils.dart';
import '../../model/training.dart';
import '../../provider/api_provider.dart';
import '../../provider/tab_provider.dart';
import '../../utils/widgets/topic_card_widget.dart';

class InProgressScreen extends StatefulWidget {
  const InProgressScreen({super.key});

  @override
  State<InProgressScreen> createState() => _InProgressScreenState();
}

class _InProgressScreenState extends State<InProgressScreen> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
        appBar: CustomAppBar(
          size: size,
          title: "Training",
          automaticallyImplyLeading: true,
        ),
        body: Container(
          // decoration: const BoxDecoration(
          //   color: Colors.white70,
          // ),
          height: size.height,
          width: size.width,
          padding: const EdgeInsets.all(20),
          child: FutureBuilder<Training>(
            future: Provider.of<UserProvider>(context, listen: false)
                .getTrainingData(isMandatory: "Y"),
            builder: (context, snapshot) {
              debugPrint("snapshot at ${DateTime.now()} == $snapshot");
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: LottieLoadingWidget(
                    size: 150,
                    message: "Loading trainings...",
                  ),
                );
              } else if (snapshot.hasError) {
                return Center(
                  child: Image.asset('assets/error.png'),
                );
              } else if (!snapshot.hasData ||
                  context
                          .read<UserProvider>()
                          .trainingStatusAndProgress['InProgress']
                          .length <
                      1) {
                return const Center(
                  child: NoTrainingWidget(
                    message:
                        "There are no training sessions in progress at the moment.",
                  ),
                );
              } else {
                // List<D> trainingList = snapshot.data!.d!;
                return SizedBox(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: context
                        .read<UserProvider>()
                        .trainingStatusAndProgress['InProgress']
                        .length,
                    itemBuilder: (context, index) {
                      D training = context
                          .read<UserProvider>()
                          .trainingStatusAndProgress['InProgress']
                          .toList()[index];
                      debugPrint("rainig = $training");

                      return GestureDetector(
                        onTap: () async {
                          if (training.geoLocation == 'N' ||
                              training.geoLocation == '') {
                            if (training.trainingType == 'T') {
                              var alertResult = await showOkCancelAlertDialog(
                                  context: context,
                                  title: "Are you ready to take the test?",
                                  message:
                                      "It’s time to put your knowledge to the test. Are you ready to take the test and see how much you’ve learned?");
                              if (alertResult == OkCancelResult.ok) {
                                if (context.mounted) {
                                  Provider.of<UserProvider>(context,
                                          listen: false)
                                      .resetUserSelect();
                                  context.read<TabProvider>().resetSelection();
                                  context.push('/training-test', extra: {
                                    'screenTitle': training.trainingName!,
                                    'heroTag': Key(training.id.toString()),
                                    'trainingID': training.id,
                                    'containsTest': training.trainingType,
                                    'cutOff': training.cutOffMarks,
                                    'testTimer': training.testTimer,
                                  });
                                }
                              }
                            } else {
                              context.push('/training', extra: {
                                'screenTitle': training.trainingName!,
                                'heroTag': Key(training.id.toString()),
                                'trainingID': training.id,
                                'containsTest': training.trainingType,
                                'cutOff': training.cutOffMarks,
                                'trainingDetails': training,
                              });
                            }
                          } else {
                            bool loaderShowing = true;
                            LottieLoadingDialog.show(context,
                                message: "Checking location...");

                            try {
                              if (context.mounted) {
                                var location = await Provider.of<UserProvider>(
                                        context,
                                        listen: false)
                                    .getLocation(context,
                                        trainingId: training.id!);

                                if (loaderShowing && context.mounted) {
                                  LottieLoadingDialog.dismiss(context);
                                  loaderShowing = false;
                                  if (location != null) {
                                    if (location['d'] == 'Y') {
                                      if (training.trainingType == 'T') {
                                        var alertResult = await showOkCancelAlertDialog(
                                            context: context,
                                            title:
                                                "Are you ready to take the test?",
                                            message:
                                                "It’s time to put your knowledge to the test. Are you ready to take the test and see how much you’ve learned?");
                                        if (alertResult == OkCancelResult.ok) {
                                          if (context.mounted) {
                                            Provider.of<UserProvider>(context,
                                                    listen: false)
                                                .resetUserSelect();
                                            context
                                                .read<TabProvider>()
                                                .resetSelection();
                                            context
                                                .push('/training-test', extra: {
                                              'screenTitle':
                                                  training.trainingName!,
                                              'heroTag':
                                                  Key(training.id.toString()),
                                              'trainingID': training.id,
                                              'containsTest':
                                                  training.trainingType,
                                              'cutOff': training.cutOffMarks,
                                              'testTimer': training.testTimer,
                                            });
                                          }
                                        }
                                      } else {
                                        context.push('/training', extra: {
                                          'screenTitle': training.trainingName!,
                                          'heroTag':
                                              Key(training.id.toString()),
                                          'trainingID': training.id,
                                          'containsTest': training.trainingType,
                                          'cutOff': training.cutOffMarks,
                                          'trainingDetails': training,
                                        });
                                      }
                                    } else {
                                      if (context.mounted) {
                                        showAlertDialog(
                                          button: true,
                                          context,
                                          content:
                                              'Your location is not matching in our branch location, Please try again later.',
                                          title: 'Notification',
                                        );
                                      }
                                    }
                                  } else {
                                    if (context.mounted) {
                                      showAlertDialog(
                                        button: true,
                                        context,
                                        content:
                                            'Unable to determine your current location. Please verify that Location Services are enabled on your device and permissions are granted.',
                                        title: 'Location Service Error',
                                      );
                                    }
                                  }
                                }
                              }
                            } catch (e) {
                              if (loaderShowing && context.mounted) {
                                LottieLoadingDialog.dismiss(context);
                                loaderShowing = false;
                              }
                              debugPrint("Error checking location: $e");
                            }
                          }
                        },
                        child: Builder(builder: (context) {
                          double progressVal = (double.tryParse(
                                      training.completedPercentage ?? "0") ??
                                  0) /
                              100.0;
                          if (progressVal > 1.0) progressVal = 1.0;
                          if (progressVal < 0.0) progressVal = 0.0;

                          return TopicCardWidget(
                            heroTag: Key(training.id.toString()),
                            height: size.height / 6,
                            width: size.width,
                            topicName: training.trainingName!,
                            accentColor: const Color(0xFF3B82F6),
                            subtitle:
                                "In Progress • ${(progressVal * 100).toStringAsFixed(0)}% completed",
                            progress: progressVal,
                          );
                        }),
                      );
                    },
                  ),
                );
              }
            },
          ),
        ));
  }

  void showAlertDialog(BuildContext context,
      {required String title, String? content, required bool button}) {
    AlertDialog alert = AlertDialog(
      title: Text(title),
      content: Text(content!),
      actions: [
        button
            ? TextButton(
                child: const Text("OK"),
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
              )
            : Container()
      ],
    );
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }
}
