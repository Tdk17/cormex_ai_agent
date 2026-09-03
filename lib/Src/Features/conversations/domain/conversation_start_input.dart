class ConversationStartInput {
  const ConversationStartInput({
    required this.channel,
    required this.mode,
    this.leadId,
    this.contactName,
    this.phone,
    this.email,
    this.initialMessage,
  });

  final String channel;
  final String mode;
  final String? leadId;
  final String? contactName;
  final String? phone;
  final String? email;
  final String? initialMessage;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'channel': channel,
        'mode': mode,
        if (leadId?.trim().isNotEmpty == true) 'leadId': leadId!.trim(),
        if (contactName?.trim().isNotEmpty == true)
          'contactName': contactName!.trim(),
        if (phone?.trim().isNotEmpty == true) 'phone': phone!.trim(),
        if (email?.trim().isNotEmpty == true) 'email': email!.trim(),
        if (initialMessage?.trim().isNotEmpty == true)
          'initialMessage': initialMessage!.trim(),
      };

  String get idempotencyKey => <String?>[
        leadId,
        contactName,
        phone,
        email,
        channel,
        mode,
        initialMessage,
      ].map((String? value) => value?.trim().toLowerCase() ?? '').join('|');
}
