import 'package:flutter/material.dart';

/// Shows a network image for http(s) URLs and a bundled asset otherwise,
/// so the same widgets work for uploaded photos and built-in artwork.
class NetOrAssetImage extends StatelessWidget {
  const NetOrAssetImage(this.src, {super.key, this.width, this.height, this.fit, this.alignment = Alignment.center, this.errorBuilder});
  final String src;
  final double? width, height;
  final BoxFit? fit;
  final Alignment alignment;
  final ImageErrorWidgetBuilder? errorBuilder;

  @override
  Widget build(BuildContext context) {
    if (src.startsWith('http') || src.startsWith('data:')) {
      return Image.network(src, width: width, height: height, fit: fit, alignment: alignment, errorBuilder: errorBuilder);
    }
    return Image.asset(src, width: width, height: height, fit: fit, alignment: alignment, errorBuilder: errorBuilder);
  }
}
