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
        ),
        const SizedBox(width: 16),
        socialButton(
          size,
          'assets/facebook-2.svg',
          'Facebook',
        ),
      ],
    );
  }

  /// Reusable Social Button
  Widget socialButton(Size size, String assetPath, String text) {
    return Container(
      alignment: Alignment.center,
      width: size.width / 2.8,
      height: size.height / 15,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(width: 1.0, color: const Color(0xFFEFEFEF)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(assetPath, width: 22, height: 22),
          const SizedBox(width: 12),
          Text(text, style: GoogleFonts.inter(fontSize: 14.0)),
        ],
      ),
    );
  }
}
