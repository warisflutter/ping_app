class SubscriptionModel {
  final String teamMembers;
  final String numberOfMessages;
  final String numberOfVoiceMessages;
  final String monthlyPrice;
  final String annuallyPrice;
  SubscriptionModel({
    required this.annuallyPrice,
    required this.monthlyPrice,
    required this.numberOfMessages,
    required this.numberOfVoiceMessages,
    required this.teamMembers,
  });
}
