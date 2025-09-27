import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class InputLabel extends StatelessWidget {
  final String text;

  const InputLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14.0,
        color: Colors.black,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
