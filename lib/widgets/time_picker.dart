import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class TimeProvider extends ChangeNotifier {
  int _hour;
  int _minute;

  TimeProvider(TimeOfDay initialTime)
      : _hour = initialTime.hour,
        _minute = initialTime.minute;

  int get hour => _hour;

  int get minute => _minute;

  void setHour(int hour) {
    _hour = hour;
    notifyListeners();
  }

  void setMinute(int minute) {
    _minute = minute;
    notifyListeners();
  }

  TimeOfDay get time => TimeOfDay(hour: _hour, minute: _minute);
}

class CustomTimePicker extends StatelessWidget {
  final ValueChanged<TimeOfDay> onTimeChanged;

  const CustomTimePicker({Key? key, required this.onTimeChanged}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _TimePickerColumn(
          initialValue: Provider.of<TimeProvider>(context).hour,
          minValue: 0,
          maxValue: 23,
          onValueChanged: (value) {
            Provider.of<TimeProvider>(context, listen: false).setHour(value);
            onTimeChanged(Provider.of<TimeProvider>(context, listen: false).time);
          },
        ),
        const Text(':',
            style: TextStyle(
              fontSize: 45,
              fontWeight: FontWeight.bold,
            )),
        _TimePickerColumn(
          initialValue: Provider.of<TimeProvider>(context).minute,
          minValue: 0,
          maxValue: 59,
          onValueChanged: (value) {
            Provider.of<TimeProvider>(context, listen: false).setMinute(value);
            onTimeChanged(Provider.of<TimeProvider>(context, listen: false).time);
          },
        ),
      ],
    );
  }
}

class _TimePickerColumn extends StatelessWidget {
  final int initialValue;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onValueChanged;

  const _TimePickerColumn({
    required this.initialValue,
    required this.minValue,
    required this.maxValue,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final controller = FixedExtentScrollController(initialItem: initialValue - minValue);
    return SizedBox(
      width: 140,
      height: 200,
      child: ListWheelScrollView.useDelegate(
        controller: controller,
        physics: const FixedExtentScrollPhysics(),
        itemExtent: 75,
        diameterRatio: 5,
        onSelectedItemChanged: onValueChanged,
        childDelegate: ListWheelChildLoopingListDelegate(
          children: List<Widget>.generate(maxValue - minValue + 1, (index) {
            final value = minValue + index;
            return GestureDetector(
              onTap: () => controller.animateToItem(index, duration: const Duration(milliseconds: 250), curve: Curves.easeInOut),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  value.toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontSize: 40,
                    color: value == initialValue ? Colors.blue : Colors.black,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
