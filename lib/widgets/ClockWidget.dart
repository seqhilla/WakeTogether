import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ClockWidget extends StatelessWidget {
  final String alarmText;

  const ClockWidget({required Key key, required this.alarmText}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Stream.periodic(const Duration(seconds: 1)),
      builder: (context, snapshot) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              DateFormat('hh:mm').format(DateTime.now()),
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('yyyy-MM-dd').format(DateTime.now()),
              style: const TextStyle(fontSize: 20), //TODO Pzt, 10 Haz tarzı yap
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16),
              child: Text(
                alarmText,
                style: const TextStyle(fontSize: 20),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        );
      },
    );
  }
}