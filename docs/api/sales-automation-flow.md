# Fluxo automático — Google Ads até a venda

Este fluxo conecta aquisição, Lead, Conversa, Agente, Conhecimento, Follow-ups, Pipeline e Dashboard. O Flutter configura e acompanha; webhooks, workers e entrega de mensagens pertencem ao backend.

1. O usuário publica a campanha após conectar o Google Ads.
2. O provedor entrega um lead ou conversão ao callback seguro do backend.
3. O backend valida assinatura, deduplica o evento e resolve `workspaceId + campaignId`.
4. Cria/atualiza o Lead com `source=campaign` e identificação externa.
5. Se `automation.onlyRegisterLead=false`, cria a Conversation em `agentMode=auto`.
6. O agente carrega configuração, produto/oferta e apenas fontes `ready` do mesmo workspace.
7. Envia abordagem, coleta dados e executa perguntas de qualificação.
8. Cria/atualiza a oportunidade e movimenta o Pipeline conforme eventos confirmados.
9. Follow-ups retomam o atendimento enquanto não houver resposta, conversão, perda ou handoff.
10. Ao converter, registra `won`, interrompe automações pendentes e atualiza métricas atribuídas.

## Guardas obrigatórios

- nunca confiar em `workspaceId` vindo diretamente do provedor; resolver por credencial/campanha persistida;
- índice único para o ID externo de lead/evento e para cada tentativa de mensagem;
- conferir `agentMode=auto` imediatamente antes de gerar e entregar;
- suspender IA quando cliente pedir humano, houver tema sensível, baixa confiança, disputa, cobrança ou regra de handoff;
- não prometer preço, desconto, estoque ou condição fora do conhecimento autorizado;
- não realizar cobrança, aumentar orçamento ou publicar nova campanha sem autorização explícita;
- registrar auditoria e `correlationId` em toda transição.
