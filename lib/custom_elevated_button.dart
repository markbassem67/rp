import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Icon? icon;
  final double? textsize;

  const CustomElevatedButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.textsize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: icon,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, // Text color
        backgroundColor: Colors.blue, // Background color
        elevation: 2,
        fixedSize: const Size(330, 55),// Button elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Button shape
        ),
      ),
      onPressed: onPressed,
      label: Text(
        label,
        style: TextStyle(fontSize: textsize ?? 25),
      ),
    );
  }
}
