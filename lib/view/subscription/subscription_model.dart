class SubscriptionModel {
  final String teamMembers;
  final String numberOfMessages;
  final String numberOfVoiceMessages;
  final String monthlyPrice;
  final String annuallyPrice;
  final String type;
  final String supportedPlatforms;
  final String details;
  SubscriptionModel({
    required this.details,
    required this.supportedPlatforms,
    required this.type,
    required this.annuallyPrice,
    required this.monthlyPrice,
    required this.numberOfMessages,
    required this.numberOfVoiceMessages,
    required this.teamMembers,
  });
}
