import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';



class CustomTextField extends StatefulWidget {
  final Size size;
  final String hint;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final Color? borderColor;
  final ValueChanged<String>? onChanged;

  const CustomTextField({
    Key? key,
    required this.size,
    required this.hint,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.borderColor,
    this.onChanged,
  }) : super(key: key);

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.obscureText;
  }

  void _toggleVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: widget.size.height / 14,
      child: TextField(
        controller: widget.controller,
        obscureText: _obscureText,
        keyboardType: widget.keyboardType,
        style: GoogleFonts.inter(
          fontSize: 16.0,
          color: const Color(0xFF151624),
        ),
        cursorColor: const Color(0xFF151624),
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: GoogleFonts.inter(
            fontSize: 14.0,
            color: const Color(0xFFABB3BB),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: widget.borderColor ?? const Color(0xFFABB3BB),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: widget.borderColor ?? const Color(0xFFABB3BB),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: widget.borderColor ?? Theme.of(context).primaryColor,
              width: 2.0,
            ),
          ),
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: _toggleVisibility,
                )
              : null,
        ),
      ),
    );
  }
}
