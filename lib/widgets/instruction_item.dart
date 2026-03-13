import 'package:flutter/material.dart';

class InstructionItem extends StatelessWidget {
  final int stepNumber;
  final String instruction;

  const InstructionItem({super.key, required this.stepNumber, required this.instruction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
              radius: 12,
              backgroundColor: Colors.orange,
              child: Text('$stepNumber', style: const TextStyle(color: Colors.white, fontSize: 12))
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(instruction, style: const TextStyle(fontSize: 16, height: 1.4))),
        ],
      ),
    );
  }
}