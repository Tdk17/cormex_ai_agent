import 'package:agente_vendas_saas/Src/Shared/models/conversation_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('converte DTO aninhado da conversa e datas do Parse', () {
    final conversation = ConversationModel.fromJson(<String, dynamic>{
      'objectId': 'conversation_1',
      'workspaceId': 'workspace_1',
      'lead': <String, dynamic>{
        'objectId': 'lead_1',
        'name': 'Marina Souza',
      },
      'channel': 'whatsapp',
      'status': 'waiting_customer',
      'agentMode': 'assist',
      'assignedUser': <String, dynamic>{
        'objectId': 'user_1',
        'name': 'Pedro Henrique',
      },
      'lastMessage': <String, dynamic>{
        'content': 'Vou analisar a proposta.',
        'sentAt': <String, dynamic>{
          '__type': 'Date',
          'iso': '2026-08-24T21:30:00.000Z',
        },
      },
      'unreadCount': 3,
      'updatedAt': '2026-08-24T21:30:00.000Z',
    });

    expect(conversation.id, 'conversation_1');
    expect(conversation.leadId, 'lead_1');
    expect(conversation.leadName, 'Marina Souza');
    expect(conversation.assignedUserId, 'user_1');
    expect(conversation.lastMessagePreview, 'Vou analisar a proposta.');
    expect(conversation.lastMessageAt?.isUtc, isTrue);
    expect(conversation.unreadCount, 3);
  });

  test('classifica remetente e direção da mensagem', () {
    final message = MessageModel.fromJson(<String, dynamic>{
      'id': 'message_1',
      'conversationId': 'conversation_1',
      'direction': 'outbound',
      'senderType': 'ai',
      'type': 'text',
      'content': 'Olá! Como posso ajudar?',
      'status': 'delivered',
      'sentAt': '2026-08-24T21:35:00.000Z',
    });

    expect(message.isOutbound, isTrue);
    expect(message.isAi, isTrue);
    expect(message.isHuman, isFalse);
    expect(message.isSystem, isFalse);
  });

  test('copyWith atualiza modo e remove atribuição explicitamente', () {
    final original = ConversationModel.fromJson(<String, dynamic>{
      'id': 'conversation_1',
      'workspaceId': 'workspace_1',
      'leadId': 'lead_1',
      'leadName': 'Marina',
      'agentMode': 'human',
      'assignedUserId': 'user_1',
      'assignedUserName': 'Pedro',
      'updatedAt': '2026-08-24T21:35:00.000Z',
    });

    final updated = original.copyWith(
      agentMode: 'auto',
      clearAssignment: true,
      unreadCount: 0,
    );

    expect(updated.agentMode, 'auto');
    expect(updated.assignedUserId, isNull);
    expect(updated.assignedUserName, isNull);
    expect(updated.unreadCount, 0);
  });
}
