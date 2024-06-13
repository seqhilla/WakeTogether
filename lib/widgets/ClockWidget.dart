import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../utils/TimeUtils.dart';

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
              DateFormat('HH:mm').format(DateTime.now()),
              style: const TextStyle(fontSize: 64, fontWeight: FontWeight.bold),
            ),
            Text(
              TimeUtils.getDayMonth(DateTime.now()),
              style: const TextStyle(fontSize: 20),
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