import 'package:flutter/material.dart';

/// The filled dot marking where the journey starts.
class HeroOriginNode extends StatelessWidget {
  const HeroOriginNode({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(56),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// The pin marking where the journey ends.
class HeroDestinationNode extends StatelessWidget {
  const HeroDestinationNode({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(56),
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.place_rounded, size: 12, color: Colors.white),
    );
  }
}
