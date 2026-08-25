import 'package:agente_vendas_saas/Src/Shared/models/conversation_models.dart';

class ConversationPage {
  const ConversationPage({
    required this.items,
    this.owners = const <ConversationOwnerModel>[],
    this.nextCursor,
    this.correlationId,
  });

  final List<ConversationModel> items;
  final List<ConversationOwnerModel> owners;
  final String? nextCursor;
  final String? correlationId;

  bool get hasMore => nextCursor != null && nextCursor!.isNotEmpty;
}
