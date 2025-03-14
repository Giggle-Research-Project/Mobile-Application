import 'package:flutter/material.dart';

class TeacherAndTimerWidget extends StatefulWidget {
  final String selectedTeacher;
  final String avatar;
  final int timeRemaining;

  const TeacherAndTimerWidget({
    Key? key,
    required this.selectedTeacher,
    required this.avatar,
    required this.timeRemaining,
  }) : super(key: key);

  @override
  _TeacherAndTimerWidgetState createState() => _TeacherAndTimerWidgetState();
}

class _TeacherAndTimerWidgetState extends State<TeacherAndTimerWidget> {
  late int _timeRemaining;

  @override
  void initState() {
    super.initState();
    _timeRemaining = widget.timeRemaining;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Teacher avatar and name
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: AssetImage(widget.avatar),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                widget.selectedTeacher,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          // Timer Display
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, size: 20),
                const SizedBox(width: 8),
                Text(
                  '${_timeRemaining ~/ 60}:${(_timeRemaining % 60).toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
