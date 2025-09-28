import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class AuthFooter extends StatelessWidget {
  final String text;
  final String actionText;
  final String route;

  const AuthFooter({
    super.key,
    required this.text,
    required this.actionText,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text.rich(
        TextSpan(
          style: GoogleFonts.inter(fontSize: 12.0, color: Colors.black),
          children: [
            TextSpan(text: text),
            TextSpan(
              text: actionText,
              style: const TextStyle(
                color: Color(0xFFFF7248),
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  try {
                    debugPrint('AuthFooter: Navigating to $route');
                    context.push(route);
                  } catch (e) {
                    debugPrint('AuthFooter navigation failed: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Navigation failed. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
            ),
          ],
        ),
      ),
    );
  }
}
