class SalesAgentModel {
  const SalesAgentModel({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.objective,
    required this.persona,
    required this.tone,
    required this.mode,
    required this.productOffer,
    required this.initialMessage,
    required this.isActive,
    required this.rules,
    required this.qualificationQuestions,
    required this.schedule,
    required this.policies,
    required this.version,
    this.updatedAt,
  });

  final String id;
  final String workspaceId;
  final String name;
  final String objective;
  final String persona;
  final String tone;
  final String mode;
  final String productOffer;
  final String initialMessage;
  final bool isActive;
  final List<String> rules;
  final List<String> qualificationQuestions;
  final AgentScheduleModel schedule;
  final AgentPoliciesModel policies;
  final int version;
  final DateTime? updatedAt;

  factory SalesAgentModel.fromJson(Map<String, dynamic> json) {
    final legacyInstructions = json['instructions']?.toString() ?? '';

    return SalesAgentModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      workspaceId: json['workspaceId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      objective: _firstNonEmpty(<dynamic>[
        json['objective'],
        _legacySection(legacyInstructions, 'OBJECTIVE'),
      ]),
      persona: _firstNonEmpty(<dynamic>[
        json['persona'],
        _legacySection(legacyInstructions, 'PERSONA'),
      ]),
      tone: json['tone']?.toString() ?? 'consultive',
      mode: json['mode']?.toString() ?? 'assist',
      productOffer: _firstNonEmpty(<dynamic>[
        json['productOffer'],
        _legacySection(legacyInstructions, 'PRODUCT_OFFER'),
      ]),
      initialMessage: _firstNonEmpty(<dynamic>[
        json['initialMessage'],
        json['greeting'],
      ]),
      isActive: _bool(
        json.containsKey('isActive') ? json['isActive'] : json['active'],
      ),
      rules: _firstStringList(
        json['rules'],
        _legacyListSection(legacyInstructions, 'RULES'),
      ),
      qualificationQuestions: _firstStringList(
        json['qualificationQuestions'],
        _legacyListSection(legacyInstructions, 'QUALIFICATION_QUESTIONS'),
      ),
      schedule: AgentScheduleModel.fromJson(_map(json['schedule'])),
      policies: AgentPoliciesModel.fromJson(_map(json['policies'])),
      version: (json['version'] as num?)?.toInt() ?? 0,
      updatedAt: _date(json['updatedAt']),
    );
  }

  static Map<String, dynamic> _map(dynamic value) {
    return value is Map
        ? Map<String, dynamic>.from(value)
        : const <String, dynamic>{};
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((dynamic item) => item.toString().trim())
        .where((String item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<String> _firstStringList(dynamic primary, List<String> fallback) {
    final parsed = _stringList(primary);
    return parsed.isNotEmpty ? parsed : fallback;
  }

  static String _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return '';
  }

  static bool _bool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1';
  }

  static String _legacySection(String raw, String section) {
    if (raw.trim().isEmpty) return '';
    final marker = '[$section]';
    final start = raw.indexOf(marker);
    if (start < 0) return '';

    final contentStart = start + marker.length;
    final tail = raw.substring(contentStart).trimLeft();
    final nextSection = RegExp(r'\n\[[A-Z_]+\]').firstMatch(tail);
    final value = nextSection == null
        ? tail
        : tail.substring(0, nextSection.start);
    return value.trim();
  }

  static List<String> _legacyListSection(String raw, String section) {
    final content = _legacySection(raw, section);
    if (content.isEmpty) return const <String>[];
    return content
        .split('\n')
        .map((String line) => line.trim())
        .where((String line) => line.isNotEmpty)
        .map((String line) => line.startsWith('- ') ? line.substring(2).trim() : line)
        .where((String line) => line.isNotEmpty)
        .toList(growable: false);
  }

  static DateTime? _date(dynamic value) {
    if (value is Map && value['iso'] != null) {
      return DateTime.tryParse(value['iso'].toString());
    }
    return DateTime.tryParse(value?.toString() ?? '');
  }
}

class AgentScheduleModel {
  const AgentScheduleModel({
    required this.enabled,
    required this.timezone,
    required this.daysOfWeek,
    required this.startTime,
    required this.endTime,
  });

  final bool enabled;
  final String timezone;
  final List<int> daysOfWeek;
  final String startTime;
  final String endTime;

  factory AgentScheduleModel.fromJson(Map<String, dynamic> json) {
    final rawDays = json['daysOfWeek'];
    return AgentScheduleModel(
      enabled: json['enabled'] == true,
      timezone: json['timezone']?.toString() ?? 'America/Sao_Paulo',
      daysOfWeek: _days(rawDays),
      startTime: json['startTime']?.toString() ?? '08:00',
      endTime: json['endTime']?.toString() ?? '18:00',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'enabled': enabled,
        'timezone': timezone,
        'daysOfWeek': daysOfWeek,
        'startTime': startTime,
        'endTime': endTime,
      };

  static List<int> _days(dynamic value) {
    if (value is! List) return const <int>[1, 2, 3, 4, 5];
    final days = value
        .whereType<num>()
        .map((num item) => item.toInt())
        .where((int item) => item >= 1 && item <= 7)
        .toSet()
        .toList(growable: false);
    days.sort();
    return days;
  }
}

class AgentPoliciesModel {
  const AgentPoliciesModel({
    required this.maxResponseCharacters,
    required this.maxAttemptsBeforeHandoff,
    required this.askForName,
    required this.askForPhone,
    required this.allowPricePresentation,
    required this.allowFollowUp,
    required this.followUpDelayMinutes,
    required this.handoffOnRequest,
  });

  final int maxResponseCharacters;
  final int maxAttemptsBeforeHandoff;
  final bool askForName;
  final bool askForPhone;
  final bool allowPricePresentation;
  final bool allowFollowUp;
  final int followUpDelayMinutes;
  final bool handoffOnRequest;

  factory AgentPoliciesModel.fromJson(Map<String, dynamic> json) {
    return AgentPoliciesModel(
      maxResponseCharacters:
          (json['maxResponseCharacters'] as num?)?.toInt() ?? 700,
      maxAttemptsBeforeHandoff:
          (json['maxAttemptsBeforeHandoff'] as num?)?.toInt() ?? 3,
      askForName: json['askForName'] != false,
      askForPhone: json['askForPhone'] != false,
      allowPricePresentation: json['allowPricePresentation'] != false,
      allowFollowUp: json['allowFollowUp'] != false,
      followUpDelayMinutes:
          (json['followUpDelayMinutes'] as num?)?.toInt() ?? 1440,
      handoffOnRequest: json['handoffOnRequest'] != false,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'maxResponseCharacters': maxResponseCharacters,
        'maxAttemptsBeforeHandoff': maxAttemptsBeforeHandoff,
        'askForName': askForName,
        'askForPhone': askForPhone,
        'allowPricePresentation': allowPricePresentation,
        'allowFollowUp': allowFollowUp,
        'followUpDelayMinutes': followUpDelayMinutes,
        'handoffOnRequest': handoffOnRequest,
      };
}

class AgentTestReplyModel {
  const AgentTestReplyModel({
    required this.content,
    required this.rulesUsed,
    required this.warnings,
    required this.shouldHandoff,
    this.productConsulted,
    this.suggestedAction,
  });

  final String content;
  final String? productConsulted;
  final List<String> rulesUsed;
  final String? suggestedAction;
  final List<String> warnings;
  final bool shouldHandoff;

  factory AgentTestReplyModel.fromJson(Map<String, dynamic> json) {
    return AgentTestReplyModel(
      content: json['content']?.toString() ?? '',
      productConsulted: json['productConsulted']?.toString(),
      rulesUsed: _stringList(json['rulesUsed']),
      suggestedAction: json['suggestedAction']?.toString(),
      warnings: _stringList(json['warnings']),
      shouldHandoff: json['shouldHandoff'] == true,
    );
  }

  static List<String> _stringList(dynamic value) {
    if (value is! List) return const <String>[];
    return value
        .map((dynamic item) => item.toString())
        .toList(growable: false);
  }
}

class KnowledgeSourceModel {
  const KnowledgeSourceModel({
    required this.id,
    required this.agentId,
    required this.type,
    required this.title,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String agentId;
  final String type;
  final String title;
  final String status;
  final DateTime createdAt;

  factory KnowledgeSourceModel.fromJson(Map<String, dynamic> json) {
    return KnowledgeSourceModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      agentId: json['agentId']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      title: json['title']?.toString() ?? 'Fonte sem título',
      status: json['status']?.toString() ?? 'processing',
      createdAt: SalesAgentModel._date(json['createdAt']) ?? DateTime.now(),
    );
  }
}
