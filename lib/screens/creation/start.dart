import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:Satsails/screens/shared/custom_button.dart';
import 'package:Satsails/translations/translations.dart';
import './components/logo.dart';

class Start extends ConsumerWidget {
  const Start({super.key});

  Shader createGradientShader(Rect bounds) {
    return const LinearGradient(
      colors: [Colors.redAccent, Colors.orangeAccent],
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
    ).createShader(bounds);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SizedBox(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.2, vertical: screenHeight * 0.15),
            child: Column(
              children: [
                const Logo(),
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Satsails',
                        style: TextStyle(
                          foreground: Paint()
                            ..shader = createGradientShader(
                              Rect.fromLTWH(0.0, 0.0, screenWidth * 0.6, screenHeight * 0.1),
                            ),
                          fontSize: screenWidth * 0.15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                          'Become sovereign and freely opt out of the system.'.i18n(ref),
                        style: TextStyle(
                          fontSize: screenWidth * 0.04,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: screenHeight * 0.1),
                Column(
                  children: [
                    CustomButton(
                      text: 'Create wallet'.i18n(ref),
                      onPressed: () {
                        Navigator.pushNamed(context, '/set_pin');
                      },
                    ),
                    CustomButton(
                      text: 'Recover wallet'.i18n(ref),
                      onPressed: () {
                        Navigator.pushNamed(context, '/recover_wallet');
                      },
                      primaryColor: Colors.black,
                      secondaryColor: Colors.black
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
