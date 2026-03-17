import 'package:flutter/material.dart';
import '../widgets/primary_button.dart';
import '../app/routes.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              const Spacer(),

              Image.asset(
                'assets/logo/uv_sense_logo.png',
                height: 130,
              ),

              const SizedBox(height: 40),

              const Text(
                "This app tracks UV exposure and learns your personal sun tolerance.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const Spacer(),

              PrimaryButton(
                text: "Start Setup",
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.questionnaire);
                },
              ),

              const SizedBox(height: 30),

            ],
          ),
        ),
      ),
    );
  }
}