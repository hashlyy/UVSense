import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../core/constants.dart';
import 'routes.dart';
import '../screens/onboarding_screen.dart';
import '../screens/fitzpatrick_questionnaire_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/feedback_screen.dart';
import '../screens/explanation_screen.dart';

class UVApp extends StatelessWidget {
  const UVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      initialRoute: AppRoutes.onboarding,
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case AppRoutes.onboarding:
            return MaterialPageRoute(builder: (_) => const StartScreen());
          
          case AppRoutes.questionnaire:
            return MaterialPageRoute(builder: (_) => const FitzpatrickQuestionnaireScreen());
          
          case AppRoutes.dashboard:
            // Expecting int argument for initial threshold (optional, service manages real state)
            final args = settings.arguments;
            int threshold = AppConstants.defaultThreshold;
            if (args is int) {
              threshold = args;
            } else if (args is double) {
              threshold = args.toInt();
            }
            
            return MaterialPageRoute(
              builder: (_) => DashboardScreen(
                initialThreshold: threshold,
              ),
            );
          
          case AppRoutes.feedback:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => FeedbackScreen(
                cumulativeExposure: (args['cumulative'] as num).toDouble(),
                currentThreshold: (args['threshold'] as num).toDouble(),
                currentUV: (args['currentUV'] as num).toDouble(),
              ),
            );
          
          case AppRoutes.explanation:
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => ExplanationScreen(
                cumulativeExposure: (args['cumulative'] as num).toDouble(),
                currentUV: (args['currentUV'] as num).toDouble(),
                threshold: (args['threshold'] as num).toDouble(),
                previousThreshold: (args['previousThreshold'] as num).toDouble(),
                feedback: args['feedback'] as String,
              ),
            );
            
          default:
            return MaterialPageRoute(builder: (_) => const StartScreen());
        }
      },
    );
  }
}
