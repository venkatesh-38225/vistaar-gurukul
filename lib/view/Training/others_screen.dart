import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gurukul/provider/api_provider.dart';
import 'package:gurukul/utils/widgets/custom_appbar.dart';
import 'package:gurukul/utils/widgets/topic_card_widget.dart';
import 'package:provider/provider.dart';

import '../../model/training.dart';
import '../../provider/tab_provider.dart';
import '../../utils/widgets/loading_error_widgets.dart';

class OthersScreen extends StatefulWidget {
  const OthersScreen({super.key});

  @override
  State<OthersScreen> createState() => _OthersScreenState();
}

class _OthersScreenState extends State<OthersScreen> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: CustomAppBar(

        size: size,
        title: "Others",
        automaticallyImplyLeading: true,
      ),
      body: SizedBox(
        height: size.height,
        child: FutureBuilder<Training>(
            future: Provider.of<UserProvider>(context, listen: false)
                .getOtherTrainingData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: LoadingWidget(),
                );
              } else {
                if(snapshot.data != null){
                List<D> otherTrainingList = snapshot.data!.d!;
                return ListView.builder(
                    shrinkWrap: true,
                    itemCount: otherTrainingList.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () async {
                          if (otherTrainingList[index].trainingType == 'T') {
                            var alertResult = await showOkCancelAlertDialog(
                                context: context,
                                title: "Are you ready to take the test?",
                                message:
                                    "It’s time to put your knowledge to the test. Are you ready to take the test and see how much you’ve learned?");
                            if (alertResult == OkCancelResult.ok) {
                              Provider.of<UserProvider>(context, listen: false)
                                  .resetUserSelect();
                              context.read<TabProvider>().resetSelection();
                              if (context.mounted) {
                                context.push('/training-test', extra: {
                                  'screenTitle':
                                      otherTrainingList[index].trainingName!,
                                  'heroTag': Key(
                                      otherTrainingList[index].id.toString()),
                                  'trainingID': otherTrainingList[index].id,
                                  'containsTest':
                                      otherTrainingList[index].trainingType,
                                  'cutOff':
                                      otherTrainingList[index].cutOffMarks,
                                });
                              }
                            }
                          } else {
                            context.push('/training', extra: {
                              'screenTitle':
                                  otherTrainingList[index].trainingName!,
                              'heroTag':
                                  Key(otherTrainingList[index].id.toString()),
                              'trainingID': otherTrainingList[index].id,
                              'containsTest':
                                  otherTrainingList[index].trainingType,
                              'cutOff': otherTrainingList[index].cutOffMarks,
                            });
                          }
                        },
                        child: TopicCardWidget(
                          height: size.height / 6,
                          width: size.width,
                          topicName: otherTrainingList[index].trainingName!,
                          heroTag: Key("other_${otherTrainingList[index].id}"),
                          accentColor: const Color(0xFF8B5CF6),
                          subtitle: "Extra module • Tap to view",
                        ),
                      );
                    });}else{
                  return const Center(
                    child: Text(
                      'No Task'
                    ),
                  );
                }
              }
            }),
      ),
    );
  }
}
