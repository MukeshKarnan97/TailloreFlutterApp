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

class SignUp extends StatelessWidget {
  const SignUp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset: true, // 👈 allows scroll with keyboard
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
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const SizedBox(height: 30),

                // Logo
                Center(child: LogoWidget(height_: size.height / 8, width_:size.height / 8)),
                const SizedBox(height: 16),

                // Title
                const Center(child: AuthTitle(first: "SIGN", second: "UP", fontSize: 24)),
                const SizedBox(height: 8),

                Center(
                  child: Text(
                    'Let’s Register to continue exploring',
                    style: GoogleFonts.inter(
                      fontSize: 14.0,
                      color: const Color(0xFF969AA8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),

                // Google & Facebook
                // signUpGoogleFacebookButton(size),
                SignUpGoogleFacebookButton(size: size),
                const SizedBox(height: 20),

                // Username
                // buildLabel('Username'),
                const InputLabel(text: 'Username'),
                const SizedBox(height: 8),
                // inputTextField(size, hint: 'Enter your username'),
                CustomTextField(size: size, hint: 'Enter your username'),
                const SizedBox(height: 8),

                // Email
                // buildLabel('Email'),
                const InputLabel(text: 'Email'),
                const SizedBox(height: 8),
                // emailTextField(size, hint: 'Enter your email'),
                CustomTextField(size: size, hint: 'Enter your email', keyboardType: TextInputType.emailAddress,),
                const SizedBox(height: 8),

                // Password
                // buildLabel('Password'),
                const InputLabel(text: 'Password'),
                const SizedBox(height: 8),
                // passwordTextField(size, hint: 'Enter your password'),
                CustomTextField(size: size, hint: 'Enter your password', obscureText: true),
                const SizedBox(height: 24),

                // Sign Up button
                // signUpButton(size),
                AuthButton(
                  text: "Sign In",
                  onTap: () => debugPrint("Sign In tapped"),
                ),
                const SizedBox(height: 20),

                // Footer
                // buildFooter(context),
                const AuthFooter(
                  text: "Already have an account? ",
                  actionText: "Sign In here",
                  route: "/sign-in",
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }


}
