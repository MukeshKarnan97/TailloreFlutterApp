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

class ForgotPassword extends StatelessWidget {
  const ForgotPassword({Key? key}) : super(key: key);

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
                const SizedBox(height: 100),

                // Logo + Title
                Center(child: LogoWidget(height_: size.height / 8, width_:size.height / 8)),
                const SizedBox(height: 60),
                // Center(child: richText(24)),
                const Center(child: AuthTitle(first: "FORGOT", second: "PASSWORD", fontSize: 24)),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Let’s reset your password',
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: const Color(0xFF969AA8),
                    ),
                  ),
                ),
                const SizedBox(height: 40),

                // Email
                // buildLabel('Email'),
                const InputLabel(text: 'Email'),
                const SizedBox(height: 8),
                // emailTextField(size),
                CustomTextField(size: size, hint: 'Enter your email', keyboardType: TextInputType.emailAddress,),
                const SizedBox(height: 16),
                AuthButton(
                  text: "Reset",
                  onTap: () => GoRouter.of(context).push("/auth/otp",
                            extra: {
                              'firstTitle': 'VERIFICATION',
                              'secondTitle': 'OTP',
                              'emailText': 'Code sent to test@gmail.com',
                              'onVerified': () => GoRouter.of(context).push('/home'),
                            },),
                ),
                const SizedBox(height: 24),

                // Footer
                // buildFooter(context),
                const AuthFooter(
                  text: "Already have an account? ",
                  actionText: "Sign In here",
                  route: "/sign-in",
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
