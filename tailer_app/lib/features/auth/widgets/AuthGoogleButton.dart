import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SignUpGoogleFacebookButton extends StatelessWidget {
  final Size size;

  const SignUpGoogleFacebookButton({Key? key, required this.size}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        socialButton(
          size,
          'assets/google-2.svg',
          'Google',
          borderColor: const Color(0xFFDB4437), // Google red
          textColor: const Color(0xFF374151),
        ),
        const SizedBox(width: 16),
        socialButton(
          size,
          'assets/facebook-2.svg',
          'Facebook',
          borderColor: const Color(0xFF4267B2), // Facebook blue
          textColor: const Color(0xFF374151),
        ),
      ],
    );
  }

  /// Reusable Social Button
  Widget socialButton(
    Size size, 
    String assetPath, 
    String text, {
    Color borderColor = const Color(0xFFD1D5DB),
    Color textColor = const Color(0xFF374151),
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Add social login functionality here
          debugPrint('$text button tapped');
        },
        borderRadius: BorderRadius.circular(12.0),
        splashColor: borderColor.withOpacity(0.1),
        highlightColor: borderColor.withOpacity(0.05),
        child: Container(
          alignment: Alignment.center,
          width: size.width / 2.8,
          height: size.height / 15,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              width: 1.5, 
              color: const Color(0xFFD1D5DB), // More visible gray border
            ),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SvgPicture.asset(assetPath, width: 24, height: 24),
              const SizedBox(width: 10),
              Text(
                text, 
                style: GoogleFonts.inter(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w600, // Make text more prominent
                  color: const Color(0xFF374151), // Darker text color
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
