import 'package:flutter/material.dart';

class ErrorDialog extends StatelessWidget {
  final String error;

  const ErrorDialog({Key? key, required this.error}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Error'),
      content: Text('Failed to generate questions: $error'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
