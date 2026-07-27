import 'dart:convert';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:gurukul/model/complete_training_details.dart';
import 'package:gurukul/utils/widgets/custom_appbar.dart';
import 'package:gurukul/utils/widgets/loading_error_widgets.dart';
import 'package:gurukul/utils/widgets/topic_card_widget.dart';
import 'package:provider/provider.dart';

import '../../common/utils.dart';
import '../../provider/api_provider.dart';
import '../../provider/tab_provider.dart';

class CompletedScreen extends StatelessWidget {
  const CompletedScreen({super.key});

  String convertDateTime(String dateStr) {
    try {
      int timestamp = int.parse(dateStr.substring(6, 19));
      DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      return ("${date.day}-${date.month}-${date.year}, ${date.hour}:${date.minute}:${date.second}");
    } catch (e) {
      return ("${DateTime.now().day}-${DateTime.now().month}-${DateTime.now().year}, ${DateTime.now().hour}:${DateTime.now().minute}:${DateTime.now().second}");
    }
    // return date;
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: CustomAppBar(
        size: size,
        title: "Completed",
        automaticallyImplyLeading: true,

      ),
      body: Consumer<UserProvider>(
        builder: (context, value, child) {
          return FutureBuilder(
              future:
                  context.read<UserProvider>().setCompletedTrainingDetails(),
              // future:
              //     context.read<UserProvider>().setCompletedTrainingDetails(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingWidget();
                } else if (!snapshot.hasData ||
                    context
                            .read<UserProvider>()
                            .trainingStatusAndProgress['Completed']
                            .length <
                        1) {
                  return const Center(
                    child: NoTrainingWidget(
                      message:
                          "Currently, there are no finished training sessions",
                    ),
                  );
                } else if (snapshot.hasData) {
                  List<D> completeDetails = snapshot.data!.d!;
                  Provider.of<UserProvider>(context, listen: false)
                      .getTrainingData(isMandatory: "Y");
                  debugPrint(
                      "completed count = ${value.trainingStatusAndProgress['Completed'].length}");
                  return ListView.builder(
                      shrinkWrap: true,
                      itemCount:
                          value.trainingStatusAndProgress['Completed'].length,
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () async {
                            String typeOfTraining =
                                value.trainingStatusAndProgress['Completed']
                                    [index]['trainingType'];

                            int idOfTraining =
                                value.trainingStatusAndProgress['Completed']
                                    [index]['trainingId'];

                            String contentStatus = "";
                            String contentStartTime = "";
                            String contentEndTime = "";
                            String testStartTime = "";
                            String testEndTime = "";
                            int totalScore = -1;
                            String testDecision = "";
                            if (typeOfTraining.toLowerCase() == "c") {
                              for (var element in completeDetails) {
                                if (element.traingId == idOfTraining) {
                                  contentStatus = element.contentStatus ?? "";

                                  contentStartTime =
                                      element.contentStartDatetime ?? "";
                                  contentEndTime = element.contentEndDatetime ?? "";
                                }
                              }
                            }
                            if (typeOfTraining.toLowerCase() == "t") {
                              for (var element in completeDetails) {
                                if (element.traingId == idOfTraining) {
                                  contentStatus = element.bothStatus ?? "";

                                  totalScore = element.totalScore ?? -1;
                                  testDecision = element.testDecision ?? "";
                                  testStartTime = element.testStartDatetime ?? "";
                                  testEndTime = element.testEndDatetime ?? "";
                                  // contentStartTime =
                                  //     element.contentStartDatetime!;
                                  // contentEndTime = element.contentEndDatetime!;
                                }
                              }
                            } else if (typeOfTraining.toLowerCase() == "c+t") {
                              for (var element in completeDetails) {
                                if (element.traingId == idOfTraining) {
                                  contentStatus = element.bothStatus ?? "";

                                  totalScore = element.totalScore ?? -1;

                                  testDecision = element.testDecision ?? "";

                                  testStartTime = element.testStartDatetime ?? "";
                                  testEndTime = element.testEndDatetime ?? "";
                                  contentStartTime =
                                      element.contentStartDatetime ?? "";
                                  contentEndTime = element.contentEndDatetime ?? "";
                                  print("Contenst start: ${contentStartTime}");
                                  print("Contenst status: ${contentEndTime}");
                                }
                              }
                            }
 else {
                              for (var element in completeDetails) {
                                if (element.traingId == idOfTraining) {
                                  contentStatus = element.bothStatus ?? "";

                                  totalScore = element.totalScore ?? -1;
                                  contentStartTime =
                                      element.contentStartDatetime ?? "";
                                  contentEndTime = element.contentEndDatetime ?? "";
                                }
                              }
                            }

                            await showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Congratulations!',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold)),
                                  content: SingleChildScrollView(
                                    child: DataTable(
                                      border: TableBorder.all(width: 0),
                                      columns: const [
                                        DataColumn(
                                            label: Text('Content',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                        DataColumn(
                                            label: Text('Value',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                      ],
                                      rows: [
                                        DataRow(cells: [
                                          const DataCell(Text('Status',
                                              style: TextStyle(
                                                  fontWeight:
                                                      FontWeight.bold))),
                                          DataCell(Text(
                                            contentStatus,
                                          )),
                                        ]),
                                        // DataRow(cells: [
                                        //   const DataCell(Text('Percentage',
                                        //       style: TextStyle(
                                        //           fontWeight:
                                        //               FontWeight.bold))),
                                        //   DataCell(Text(contentPercentage)),
                                        // ]),
                                        if (totalScore > 0)
                                          DataRow(cells: [
                                            const DataCell(Text('Score',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                            DataCell(Text("$totalScore")),
                                          ]),

                                        if (testDecision.isNotEmpty)
                                          DataRow(cells: [
                                            const DataCell(Text('Result',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                            DataCell(Text(testDecision)),
                                          ]),
                                        if (contentStartTime.isNotEmpty)
                                          DataRow(cells: [
                                            const DataCell(Text(
                                                'Training Start Time',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                            DataCell(SizedBox(
                                              width: size.width / 4,
                                              child: Text(
                                                convertDateTime(
                                                    contentStartTime),
                                                maxLines: 2,
                                              ),
                                            )),
                                          ]),
                                        if (contentEndTime.isNotEmpty)
                                          DataRow(cells: [
                                            const DataCell(Text(
                                                'Training End Time',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                            DataCell(SizedBox(
                                                width: size.width / 4,
                                                child: Text(convertDateTime(
                                                    contentEndTime)))),
                                          ]),
                                        if (testStartTime.isNotEmpty)
                                          DataRow(cells: [
                                            const DataCell(Text(
                                                'Test Start Time',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                            DataCell(Text(convertDateTime(
                                                testStartTime))),
                                          ]),
                                        if (testEndTime.isNotEmpty)
                                          DataRow(cells: [
                                            const DataCell(Text('Test End Time',
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold))),
                                            DataCell(Text(
                                                convertDateTime(testEndTime))),
                                          ]),
                                      ],
                                    ),
                                  ),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text("Cancel"),
                                    ),
                                    // TextButton(
                                    //     child: const Text('Revisit'),
                                    //     onPressed: () async {
                                    //       if (value.trainingStatusAndProgress[
                                    //                   'Completed'][index]
                                    //               ['trainingType'] ==
                                    //           'T') {
                                    //         var alertResult =
                                    //             await showOkCancelAlertDialog(
                                    //                 context: context,
                                    //                 title:
                                    //                     "Are you ready to take the test?",
                                    //                 message:
                                    //                     "It’s time to put your knowledge to the test. Are you ready to take the test and see how much you’ve learned?");
                                    //         if (alertResult ==
                                    //             OkCancelResult.ok) {
                                    //           if (context.mounted) {
                                    //             Provider.of<UserProvider>(
                                    //                     context,
                                    //                     listen: false)
                                    //                 .resetUserSelect();
                                    //             context
                                    //                 .read<TabProvider>()
                                    //                 .resetSelection();
                                    //             context.push('/training-test',
                                    //                 extra: {
                                    //                   'screenTitle':
                                    //                       value.trainingStatusAndProgress[
                                    //                                   'Completed']
                                    //                               [index]
                                    //                           ['trainingName']!,
                                    //                   'heroTag': Key(value
                                    //                       .trainingStatusAndProgress[
                                    //                           'Completed']
                                    //                           [index]
                                    //                           ['trainingId']
                                    //                       .toString()),
                                    //                   'trainingID':
                                    //                       value.trainingStatusAndProgress[
                                    //                                   'Completed']
                                    //                               [index]
                                    //                           ['trainingId'],
                                    //                   'containsTest':
                                    //                       value.trainingStatusAndProgress[
                                    //                                   'Completed']
                                    //                               [index]
                                    //                           ['trainingType'],
                                    //                   'fromCompleted': true,
                                    //                   'cutOff':
                                    //                       value.trainingStatusAndProgress[
                                    //                               'Completed']
                                    //                           [index]['cutOff'],
                                    //                 });
                                    //           }
                                    //         }
                                    //       } else {
                                    //         context.push('/training', extra: {
                                    //           'screenTitle':
                                    //               value.trainingStatusAndProgress[
                                    //                       'Completed'][index]
                                    //                   ['trainingName']!,
                                    //           'heroTag': Key(value
                                    //               .trainingStatusAndProgress[
                                    //                   'Completed'][index]
                                    //                   ['trainingId']
                                    //               .toString()),
                                    //           'trainingID':
                                    //               value.trainingStatusAndProgress[
                                    //                       'Completed'][index]
                                    //                   ['trainingId'],
                                    //           'containsTest':
                                    //               value.trainingStatusAndProgress[
                                    //                       'Completed'][index]
                                    //                   ['trainingType'],
                                    //           'fromCompleted': true,
                                    //           'cutOff': value
                                    //                   .trainingStatusAndProgress[
                                    //               'Completed'][index]['cutOff'],
                                    //         });
                                    //       }
                                    //       Navigator.pop(context);
                                    //     }),
                                  ],
                                );
                              },
                            );
                          },
                          child: Builder(
                            builder: (context) {
                              final item = value.trainingStatusAndProgress['Completed'][index];
                              final idOfTraining = item['trainingId'];
                              final typeOfTraining = item['trainingType'] ?? '';
                              final trainingName = item['trainingName'] ?? '';

                              String? completionTime;
                              for (var element in completeDetails) {
                                if (element.traingId == idOfTraining) {
                                  completionTime = typeOfTraining.toLowerCase() == "t"
                                      ? element.testEndDatetime
                                      : element.contentEndDatetime;
                                  break;
                                }
                              }

                              String subtitleText = "Completed successfully";
                              if (completionTime != null && completionTime.isNotEmpty) {
                                subtitleText = "Completed on ${convertDateTime(completionTime)}";
                              }

                              return TopicCardWidget(
                                height: size.height / 6,
                                width: size.width,
                                topicName: trainingName,
                                heroTag: Key("completed_$idOfTraining"),
                                iconName: Icons.check_circle_rounded,
                                accentColor: const Color(0xFF10B981),
                                subtitle: subtitleText,
                              );
                            }
                          ),
                        );
                      });
                } else {
                  return const CustomErrorWidget();
                }
              });
        },
      ),
    );
  }
}
