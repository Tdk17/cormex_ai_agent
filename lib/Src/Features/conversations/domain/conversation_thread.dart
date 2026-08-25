import 'package:agente_vendas_saas/Src/Shared/models/conversation_models.dart';
import 'package:agente_vendas_saas/Src/Shared/models/lead_model.dart';

class ConversationThread {
  const ConversationThread({
    required this.conversation,
    required this.messages,
    required this.lead,
    this.context = const ConversationSalesContext(),
    this.owners = const <ConversationOwnerModel>[],
    this.suggestedReply,
    this.nextMessagesCursor,
    this.correlationId,
  });

  final ConversationModel conversation;
  final List<MessageModel> messages;
  final LeadModel lead;
  final ConversationSalesContext context;
  final List<ConversationOwnerModel> owners;
  final String? suggestedReply;
  final String? nextMessagesCursor;
  final String? correlationId;

  bool get hasOlderMessages =>
      nextMessagesCursor != null && nextMessagesCursor!.isNotEmpty;
}

class ConversationSalesContext {
  const ConversationSalesContext({
    this.product,
    this.cartSummary,
    this.notes,
    this.historySummary,
  });

  final String? product;
  final String? cartSummary;
  final String? notes;
  final String? historySummary;

  factory ConversationSalesContext.fromJson(Map<String, dynamic> json) {
    return ConversationSalesContext(
      product: json['product']?.toString(),
      cartSummary: json['cartSummary']?.toString(),
      notes: json['notes']?.toString(),
      historySummary: json['historySummary']?.toString(),
    );
  }
}

class SendMessageResult {
  const SendMessageResult({
    required this.message,
    required this.conversation,
  });

  final MessageModel message;
  final ConversationModel conversation;
}
