class FollowUpRuleInput {
  const FollowUpRuleInput({
    required this.name,
    required this.delayMinutes,
    required this.condition,
    required this.active,
    required this.channel,
    required this.message,
    required this.maxAttempts,
    required this.stopOnReply,
    required this.stopOnLost,
    this.expectedVersion,
  });

  final String name;
  final int delayMinutes;
  final String condition;
  final bool active;
  final String channel;
  final String message;
  final int maxAttempts;
  final bool stopOnReply;
  final bool stopOnLost;
  final int? expectedVersion;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'name': name.trim(),
        'delayMinutes': delayMinutes,
        'condition': condition,
        'active': active,
        'channel': channel,
        'message': message.trim(),
        'maxAttempts': maxAttempts,
        'stopOnReply': stopOnReply,
        'stopOnLost': stopOnLost,
        if (expectedVersion != null) 'expectedVersion': expectedVersion,
      };
}
