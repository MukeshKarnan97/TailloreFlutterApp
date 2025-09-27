import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:tailer_app/features/auth/widgets/AuthButton.dart';
import 'package:tailer_app/features/auth/widgets/AuthLogo.dart';
import 'package:tailer_app/features/auth/widgets/AuthTitle.dart';

class VerificationScreen extends StatefulWidget {

  final String firstTitle;
  final String secondTitle;
  final String emailText;
  final VoidCallback onVerified;
  // const VerificationScreen({super.key});

  const VerificationScreen({
    super.key,
    required this.firstTitle,
    required this.secondTitle,
    required this.emailText,
    required this.onVerified,
  });


  @override
  _VerificationScreenState createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: LogoWithTitle(
        firstTitle: widget.firstTitle,
        secondTitle: widget.secondTitle,
        subText: "Email Verification code has been sent",
        children: [
          Text(
            widget.emailText,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: MediaQuery.of(context).size.height * 0.04),
          OtpForm(onVerified: widget.onVerified),
        ],
      ),
    );
  }
}

class OtpForm extends StatefulWidget {
  final VoidCallback onVerified;
  const OtpForm({super.key, required this.onVerified});

  @override
  _OtpFormState createState() => _OtpFormState();
}

class _OtpFormState extends State<OtpForm> {
  final _formKey = GlobalKey<FormState>();

  late FocusNode _pin1Node;
  late FocusNode _pin2Node;
  late FocusNode _pin3Node;
  late FocusNode _pin4Node;

  @override
  void initState() {
    super.initState();
    _pin1Node = FocusNode();
    _pin2Node = FocusNode();
    _pin3Node = FocusNode();
    _pin4Node = FocusNode();
  }

  @override
  void dispose() {
    _pin1Node.dispose();
    _pin2Node.dispose();
    _pin3Node.dispose();
    _pin4Node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OtpTextFormField(
                  focusNode: _pin1Node,
                  autofocus: true,
                  onChanged: (value) {
                    if (value.length == 1) _pin2Node.requestFocus();
                  },
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: OtpTextFormField(
                  focusNode: _pin2Node,
                  onChanged: (value) {
                    if (value.length == 1) _pin3Node.requestFocus();
                  },
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: OtpTextFormField(
                  focusNode: _pin3Node,
                  onChanged: (value) {
                    if (value.length == 1) _pin4Node.requestFocus();
                  },
                ),
              ),
              const SizedBox(width: 16.0),
              Expanded(
                child: OtpTextFormField(
                  focusNode: _pin4Node,
                  onChanged: (value) {
                    if (value.length == 1) _pin4Node.unfocus();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 40.0),
          AuthButton(
            text: "Next",
            onTap: () {
              // Validate OTP if needed
              widget.onVerified(); // ✅ trigger callback
            },
          ),
        ],
      ),
    );
  }
}

class OtpTextFormField extends StatelessWidget {
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  const OtpTextFormField({
    Key? key,
    this.focusNode,
    this.onChanged,
    this.autofocus = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      autofocus: autofocus,
      focusNode: focusNode,
      onChanged: onChanged,
      obscureText: true,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      style: Theme.of(context).textTheme.headlineSmall,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(1),
      ],
      decoration: const InputDecoration(
        filled: false,
        border: UnderlineInputBorder(),
        hintText: "0",
      ),
    );
  }
}

class LogoWithTitle extends StatelessWidget {
  final String firstTitle, secondTitle, subText;
  final List<Widget> children;

  const LogoWithTitle({
    Key? key,
    required this.firstTitle,
    required this.secondTitle,
    this.subText = '',
    required this.children,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return SafeArea(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Gradient container up to subText
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(33, 137, 156, 0.15),
                    Colors.white,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  // Logo
                  LogoWidget(height_: size.height / 8, width_: size.height / 8),
                  const SizedBox(height: 24),

                  // Title
                  AuthTitle(first: firstTitle, second: secondTitle, fontSize: 24),
                  const SizedBox(height: 16),

                  // Subtext
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      subText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        height: 1.5,
                        color: Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .color!
                            .withOpacity(0.64),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // OTP fields and other children
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20),
              child: Column(children: children),
            ),
          ],
        ),
      ),
    );
  }
}
