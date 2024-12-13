import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<T?>? push<T>(Widget child) => navigatorKey.currentState
    ?.push<T>(MaterialPageRoute(builder: (_) => child));

void replace(Widget child) => navigatorKey.currentState
    ?.pushReplacement(MaterialPageRoute(builder: (_) => child));

void pop<T>({T? data}) => navigatorKey.currentState?.pop(data);

void popToDashboard() =>
    navigatorKey.currentState?.popUntil((route) => route.isFirst);

// void downloadBytes(String name, Uint8List bytes) async {
//   final anchor = AnchorElement(
//       href: 'data:application/octet-stream;base64,${base64Encode(bytes)}')
//     ..target = 'blank';
//   anchor.download = name;
//   anchor.click();
// }

Widget temp() {
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                color: Colors.red,
                child: const Icon(Icons.message),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                color: Colors.red,
                child: const Icon(Icons.multitrack_audio),
              ),
            ),
          ),
        ],
      ),
      Expanded(
        child: GestureDetector(
          onTap: () {},
          child: Container(
            color: Colors.red,
            child: const Icon(Icons.notification_add),
          ),
        ),
      ),
    ],
  );
}
