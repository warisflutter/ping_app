import 'package:flutter/material.dart';

class DashBoardProvider extends ChangeNotifier {
  int currentIndex = 0;

  onTap(int value) {
    currentIndex = value;
    notifyListeners();
  }

  List<Map<String, dynamic>> pages = [
    {
      'title': "t_team",
      'icon': const Icon(
        Icons.group,
        size: 10,
      ),
    },
    {
      'title': "t_notifications",
      'icon': const Icon(
        Icons.notifications,
        size: 10,
      ),
    },
    {
      'title': "t_settings",
      'icon': const Icon(
        Icons.settings,
        size: 10,
      ),
    },
  ];
}
