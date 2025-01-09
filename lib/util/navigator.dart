import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<T?>? push<T>(Widget child) => navigatorKey.currentState
    ?.push<T>(MaterialPageRoute(builder: (_) => child));

void replace(Widget child) => navigatorKey.currentState
    ?.pushReplacement(MaterialPageRoute(builder: (_) => child));
void replaceAll(Widget child) => navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => child),
      (route) => false,
    );

void pop<T>({T? data}) => navigatorKey.currentState?.pop(data);
bool canPop() => navigatorKey.currentState?.canPop() ?? false;
void popToDashboard() =>
    navigatorKey.currentState?.popUntil((route) => route.isFirst);
void safePop<T>({T? data}) {
  if (canPop()) {
    pop<T>(data: data);
  }
}
/// Pops all routes until the first one in the stack.
void popToRoot() => navigatorKey.currentState?.popUntil((route) => route.isFirst);

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
