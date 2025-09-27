import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthTitle extends StatelessWidget {
  final String first;
  final String second;
  final double fontSize;

  const AuthTitle({
    super.key,
    required this.first,
    required this.second,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: GoogleFonts.inter(
          fontSize: fontSize,
          color: const Color(0xFF21899C),
          letterSpacing: 2.0,
        ),
        children: [
          TextSpan(
            text: first,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          TextSpan(
            text: " $second",
            style: const TextStyle(
              color: Color(0xFFFE9879),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
