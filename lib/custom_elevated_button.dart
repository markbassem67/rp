import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Icon? icon;
  final double? textsize;
  final double width;
  final double height;

  const CustomElevatedButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.textsize,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: icon,
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, // Text color
        backgroundColor: const Color.fromRGBO(0, 91, 196, 1), // Background color
        elevation: 0,
        fixedSize:  Size(width, height),// Button elevation
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Button shape
        ),
      ),
      onPressed: onPressed,
      label: Flexible(
        child: Text(overflow: TextOverflow.visible,
          softWrap: false,
          label,
          //style: TextStyle(fontSize: textsize ?? 25),
        ),
      ),
    );
  }
}
