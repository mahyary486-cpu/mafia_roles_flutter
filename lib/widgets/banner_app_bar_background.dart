import 'package:flutter/material.dart';

/// The "Mafia Rulebook" banner image, used as the background behind
/// every main screen's AppBar so the whole app shares one visual
/// identity at the top - not a new/different image, the same banner
/// everywhere, just darkened enough that title text stays readable.
class BannerAppBarBackground extends StatelessWidget {
  const BannerAppBarBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/app_logo.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
        ),
      ),
    );
  }
}
