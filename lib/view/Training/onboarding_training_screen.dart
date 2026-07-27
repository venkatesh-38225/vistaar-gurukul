import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
// import 'package:gurukul/utils/colors.dart';
// import 'package:gurukul/utils/widgets/custom_appbar.dart';
import 'package:gurukul/utils/widgets/lottie_widgets.dart';
import 'package:provider/provider.dart';

import '../../model/training.dart';
import '../../provider/api_provider.dart';
import '../../provider/tab_provider.dart';
import '../../utils/widgets/topic_card_widget.dart';

class OnBoardingTrainingScreen extends StatefulWidget {
  const OnBoardingTrainingScreen({super.key});

  @override
  State<OnBoardingTrainingScreen> createState() =>
      _OnBoardingTrainingScreenState();
}

class _OnBoardingTrainingScreenState extends State<OnBoardingTrainingScreen> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      // appBar: CustomAppBar(size: size, title: "Training"),
      body: Container(
        decoration: const BoxDecoration(
            // color: ColorConstraints.cardColor(context),
            ),
        height: size.height,
        width: size.width,
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<Training>(
          future: Provider.of<UserProvider>(context, listen: false)
              .getTrainingData(isMandatory: "N"),
          builder: (context, snapshot) {
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
                snapshot.data?.d == null ||
                snapshot.data!.d!.isEmpty) {
              return const Center(
                child: LottieEmptyWidget(
                  message: "No training available",
                  subtitle: "New onboarding courses will appear here soon.",
                ),
              );
            } else {
              // List<D> trainingList = snapshot.data!.d!;
              return SizedBox(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: snapshot.data!.d!.length,
                  // itemExtent: size.height / 8,
                  itemBuilder: (context, index) {
                    D training = snapshot.data!.d![index];
                    debugPrint("rainig = $training");
                    return GestureDetector(
                      onTap: () async {
                        if (training.trainingType == 'T') {
                          var alertResult = await showOkCancelAlertDialog(
                              context: context,
                              title: "Are you ready to take the test?",
                              message:
                                  "It’s time to put your knowledge to the test. Are you ready to take the test and see how much you’ve learned?");
                          if (alertResult == OkCancelResult.ok) {
                            if (context.mounted) {
                              Provider.of<UserProvider>(context, listen: false)
                                  .resetUserSelect();
                              context.read<TabProvider>().resetSelection();
                              context.push('/training-test', extra: {
                                'screenTitle': training.trainingName!,
                                'heroTag': Key(training.id.toString()),
                                'trainingID': training.id,
                                'containsTest': training.trainingType,
                              });
                            }
                          }
                        } else {
                          context.push('/training', extra: {
                            'screenTitle': training.trainingName!,
                            'heroTag': Key(training.id.toString()),
                            'trainingID': training.id,
                            'containsTest': training.trainingType,
                            'trainingDetails': training,
                          });
                        }
                      },
                      child: TopicCardWidget(
                        heroTag: Key(training.id.toString()),
                        height: size.height / 6,
                        width: size.width,
                        topicName: training.trainingName!,
                        accentColor: const Color(0xFF00529B),
                        subtitle: "Onboarding course • Tap to begin",
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
