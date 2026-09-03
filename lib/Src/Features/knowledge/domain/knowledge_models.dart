import 'dart:typed_data';

class KnowledgeSourceModel {
  const KnowledgeSourceModel({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.createdAt,
    this.contentCount = 0,
    this.errorMessage,
    this.fileUrl,
  });

  final String id;
  final String name;
  final String type;
  final String status;
  final DateTime createdAt;
  final int contentCount;
  final String? errorMessage;
  final String? fileUrl;

  factory KnowledgeSourceModel.fromJson(Map<String, dynamic> json) {
    return KnowledgeSourceModel(
      id: (json['id'] ?? json['objectId'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? 'Fonte sem nome').toString(),
      type: (json['type'] ?? 'text').toString(),
      status: (json['status'] ?? 'processing').toString(),
      createdAt: _date(json['createdAt']) ?? DateTime.now(),
      contentCount:
          ((json['contentCount'] ?? json['chunksCount']) as num?)?.toInt() ?? 0,
      errorMessage: json['errorMessage']?.toString(),
      fileUrl: (json['fileUrl'] ?? json['url'])?.toString(),
    );
  }

  static DateTime? _date(dynamic value) {
    if (value is Map && value['iso'] != null) {
      return DateTime.tryParse(value['iso'].toString());
    }
    return DateTime.tryParse(value?.toString() ?? '');
  }
}

class KnowledgePageResult {
  const KnowledgePageResult({
    required this.items,
    this.nextCursor,
    this.correlationId,
  });

  final List<KnowledgeSourceModel> items;
  final String? nextCursor;
  final String? correlationId;
}

class KnowledgeSourceInput {
  const KnowledgeSourceInput({
    required this.type,
    required this.name,
    this.content,
    this.question,
    this.answer,
    this.fileUrl,
    this.fileName,
    this.mimeType,
  });

  final String type;
  final String name;
  final String? content;
  final String? question;
  final String? answer;
  final String? fileUrl;
  final String? fileName;
  final String? mimeType;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'type': type,
        'name': name.trim(),
        if (content?.trim().isNotEmpty == true) 'content': content!.trim(),
        if (question?.trim().isNotEmpty == true) 'question': question!.trim(),
        if (answer?.trim().isNotEmpty == true) 'answer': answer!.trim(),
        if (fileUrl?.trim().isNotEmpty == true) 'fileUrl': fileUrl!.trim(),
        if (fileName?.trim().isNotEmpty == true) 'fileName': fileName!.trim(),
        if (mimeType?.trim().isNotEmpty == true) 'mimeType': mimeType!.trim(),
      };
}

class KnowledgeFileInput {
  const KnowledgeFileInput({
    required this.name,
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String name;
  final String fileName;
  final String mimeType;
  final Uint8List bytes;
}
