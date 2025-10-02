import 'package:flutter/material.dart';
import 'package:rekindle/models/assessment.dart';

class AnswerOptionWidget extends StatelessWidget {
  final AnswerOption option;
  final int index;
  final int? selectedOptionIndex;
  final bool hasAnswered;
  final ValueChanged<int?> onSelected;

  const AnswerOptionWidget({
    super.key,
    required this.option,
    required this.index,
    required this.selectedOptionIndex,
    required this.hasAnswered,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final bool isSelected = selectedOptionIndex == index;
    Color? tileColor;
    Color borderColor = colorScheme.outline;

    if (hasAnswered) {
      if (option.isCorrect) {
        tileColor = Colors.green.withAlpha(25);
        borderColor = Colors.green;
      } else if (isSelected) {
        tileColor = colorScheme.error.withAlpha(25);
        borderColor = colorScheme.error;
      }
    } else if (isSelected) {
      tileColor = colorScheme.primary.withAlpha(25);
      borderColor = colorScheme.primary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: RadioListTile<int>(
        value: index,
        groupValue: selectedOptionIndex,
        onChanged: hasAnswered ? null : onSelected,
        activeColor: colorScheme.primary,
        title: Text(option.optionText, style: textTheme.bodyLarge),
        secondary: Container(
          width: 24, height: 24, alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.outline),
          ),
          child: Text(
            String.fromCharCode('A'.codeUnitAt(0) + index),
            style: textTheme.bodySmall,
          ),
        ),
        controlAffinity: ListTileControlAffinity.trailing,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: borderColor,
            width: isSelected || (hasAnswered && option.isCorrect) ? 2.0 : 1.0,
          ),
        ),
        tileColor: tileColor,
      ),
    );
  }
}