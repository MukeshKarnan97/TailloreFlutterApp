import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';
import 'package:tailer_app/features/auth/widgets/AuthButton.dart';
import 'package:tailer_app/features/auth/widgets/AuthCustomTextField.dart';
import 'package:tailer_app/features/auth/widgets/AuthFooter.dart';
import 'package:tailer_app/features/auth/widgets/AuthGoogleButton.dart';
import 'package:tailer_app/features/auth/widgets/AuthInputLabel.dart';
import 'package:tailer_app/features/auth/widgets/AuthTitle.dart';
import 'package:tailer_app/features/auth/widgets/Authlogo.dart';

class SignIn extends StatelessWidget {
  const SignIn({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true, // 👈 important for keyboard
      body: SafeArea(
        child: Container(
          width: size.width,
          height: size.height,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.fromRGBO(33, 137, 156, 0.15),
                Colors.white,
                Colors.white,
                Colors.white,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 40),

                // Logo + Title
                Center(child: LogoWidget(height_: size.height / 8, width_:size.height / 8)),
                const SizedBox(height: 16),
                // Center(child: richText(24)),
                const Center(child: AuthTitle(first: "SIGN", second: "IN", fontSize: 24)),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Let’s login to continue exploring',
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: const Color(0xFF969AA8),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Google + Facebook
                // signInGoogleFacebookButton(size),
                SignUpGoogleFacebookButton(size: size),
                const SizedBox(height: 24),

                // Email
                // buildLabel('Email'),
                const InputLabel(text: 'Email'),
                const SizedBox(height: 8),
                // emailTextField(size),
                CustomTextField(size: size, hint: 'Enter your email', keyboardType: TextInputType.emailAddress,),
                const SizedBox(height: 16),

                // Password
                // buildLabel('Password'),
                const InputLabel(text: 'Password'),
                const SizedBox(height: 8),
                // passwordTextField(size),
                CustomTextField(size: size, hint: 'Enter your password', obscureText: true),
                const SizedBox(height: 16),

                // Keep signed in + Forgot
                keepSignedForgetSection(),
                const SizedBox(height: 24),

                // Sign In button
                // signInButton(size),
                // Sign In button
                AuthButton(
                  text: "Sign In",
                  onTap: () => debugPrint("Sign In tapped"),
                ),
                const SizedBox(height: 24),

                // Footer
                // buildFooter(context),
                const AuthFooter(
                  text: "Don’t have an account? ",
                  actionText: "Sign Up here",
                  route: "/sign-up",
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Keep signed in + forgot password
  Widget keepSignedForgetSection() {
    return Row(
      children: <Widget>[
        Container(
          width: 20.0,
          height: 20.0,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4.0),
            border: Border.all(width: 1, color: const Color(0xFFD0D0D0)),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Keep me signed in',
          style: GoogleFonts.inter(
            fontSize: 12.0,
            color: const Color(0xFFABB3BB),
          ),
        ),
        const Spacer(),
        Text(
          'Forgot password?',
          style: GoogleFonts.inter(
            fontSize: 12.0,
            color: const Color(0xFFF56B3F),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

}
