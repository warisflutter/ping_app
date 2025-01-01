import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ping_app/view/settings/repo/activity_report_generator.dart';

class ActivityReportProgress extends StatefulWidget {
  final String teamLeadId;

  const ActivityReportProgress({super.key, required this.teamLeadId});

  @override
  State<ActivityReportProgress> createState() => _ActivityReportProgressState();
}

class _ActivityReportProgressState extends State<ActivityReportProgress> {
  final ActivityReportGenerator _generator = ActivityReportGenerator();
  List<String> updates = [];

  @override
  void initState() {
    super.initState();
    _startReportGeneration();
  }

  void _startReportGeneration() {
    _generator.updates.listen((update) {
      setState(() {
        updates.add(update);
      });
    });

    _generator.generateAndShareActivityReport(widget.teamLeadId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('t_activityReportProgress'.tr()),
      ),
      body: ListView.builder(
        itemCount: updates.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: const Icon(Icons.newspaper),
            title: Text(updates[index]),
          );
        },
      ),
    );
  }
}
