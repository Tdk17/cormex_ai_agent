class ConversationModes {
  const ConversationModes._();

  static const String auto = 'auto';
  static const String assist = 'assist';
  static const String human = 'human';

  static const List<String> values = <String>[auto, assist, human];
}

class ConversationStatuses {
  const ConversationStatuses._();

  static const String open = 'open';
  static const String waitingCustomer = 'waiting_customer';
  static const String closed = 'closed';

  static const List<String> values = <String>[
    open,
    waitingCustomer,
    closed,
  ];
}

class ConversationChannels {
  const ConversationChannels._();

  static const String whatsapp = 'whatsapp';
  static const String instagram = 'instagram';
  static const String webchat = 'webchat';
  static const String email = 'email';

  static const List<String> values = <String>[
    whatsapp,
    instagram,
    webchat,
    email,
  ];
}
