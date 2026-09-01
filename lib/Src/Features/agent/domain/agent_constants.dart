class AgentModes {
  const AgentModes._();

  static const String auto = 'auto';
  static const String assist = 'assist';
  static const String human = 'human';

  static const List<String> values = <String>[auto, assist, human];
}

class AgentTones {
  const AgentTones._();

  static const String consultive = 'consultive';
  static const String friendly = 'friendly';
  static const String direct = 'direct';
  static const String formal = 'formal';
  static const String persuasive = 'persuasive';

  static const List<String> values = <String>[
    consultive,
    friendly,
    direct,
    formal,
    persuasive,
  ];
}
