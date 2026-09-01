class AgentTestRequest {
  const AgentTestRequest({
    required this.message,
    required this.lead,
    required this.context,
    required this.history,
    required this.clientRequestId,
  });

  final String message;
  final Map<String, dynamic> lead;
  final Map<String, dynamic> context;
  final List<Map<String, String>> history;
  final String clientRequestId;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'message': message.trim(),
        'lead': lead,
        'context': context,
        'history': history,
        'clientRequestId': clientRequestId,
      };
}
