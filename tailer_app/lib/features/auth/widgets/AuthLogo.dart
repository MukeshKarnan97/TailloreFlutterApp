// logo_widget.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class LogoWidget extends StatelessWidget {
  final double height_;
  final double width_;

  // Constructor
  const LogoWidget({
    Key? key,
    required this.height_,
    required this.width_,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      'assets/logo2.svg',
      height: height_,
      width: width_,
    );
  }
}
