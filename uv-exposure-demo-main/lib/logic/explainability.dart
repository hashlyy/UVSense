
/// Handles the Explainability (XAI) feature providing text-based reasons.
class ExplainabilityLogic {
  
  static String generateDailyReport(double cumulativeUV, int threshold, int feedbackIndex) {
    String exposureText = "";
    
    if (cumulativeUV > threshold) {
      exposureText = "Your accumulated UV exposure (${cumulativeUV.toStringAsFixed(1)}) exceeded your safety threshold ($threshold).";
    } else {
      exposureText = "You stayed within your safety threshold ($threshold) today.";
    }

    String feedbackText = "";
    switch (feedbackIndex) {
      case 0:
        feedbackText = "Since you reported no discomfort, we have slightly increased your limit.";
        break;
      case 1:
        feedbackText = "Because you reported mild discomfort, we lowered your limit to be safer.";
        break;
      case 2:
      case 3:
        feedbackText = "Due to significant discomfort, we have drastically reduced your UV allowance.";
        break;
    }

    return "$exposureText\n\n$feedbackText";
  }
}
