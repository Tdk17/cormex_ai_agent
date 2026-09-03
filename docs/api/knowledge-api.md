# API — Base de Conhecimento

Tela: `/knowledge`

Os nomes abaixo são preservados sem prefixo `v1` porque esse é o contrato atual do Cloud Code. Não renomear somente no Flutter.

## `knowledge.list`

Request:

```json
{
  "workspaceId": "ws_01J...",
  "search": "preço",
  "type": "faq",
  "status": "ready",
  "cursor": null,
  "limit": 30
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "items": [
      {
        "id": "source_01J...",
        "name": "Perguntas de preço",
        "type": "faq",
        "status": "ready",
        "contentCount": 4,
        "createdAt": "2026-09-03T14:00:00.000Z"
      }
    ]
  },
  "meta": { "nextCursor": null, "correlationId": "req_01J..." }
}
```

## `knowledge.create`

Texto:

```json
{
  "workspaceId": "ws_01J...",
  "source": {
    "type": "text",
    "name": "Política comercial",
    "content": "Conteúdo autorizado..."
  },
  "clientRequestId": "knowledge_1725192000000"
}
```

FAQ usa `type=faq`, `question` e `answer`. Arquivo usa `type=file`, `fileUrl`, `fileName` e `mimeType`; o Flutter envia o binário primeiro para Parse Files e nunca envia Base64 à Cloud Function.

Response: `{ "ok": true, "data": { "source": {} } }`. A nova fonte normalmente começa em `processing`.

O worker deve extrair texto, dividir em trechos, gerar embeddings quando aplicável e mudar o status para `ready`. Em falha, usar `failed` e preencher `errorMessage` sem expor segredo ou stack trace. Todos os vetores/trechos pertencem ao mesmo `workspaceId`.

## `knowledge.delete`

```json
{
  "workspaceId": "ws_01J...",
  "sourceId": "source_01J..."
}
```

Excluir também trechos e embeddings vinculados. Se a fonte estiver bloqueada por um processamento não cancelável, responder `CONFLICT` de forma acionável.

## Limites e segurança

- tipos do front: `text`, `faq`, `file`;
- arquivos: PDF, DOCX, TXT ou MD, até 15 MB;
- status: `processing`, `ready`, `failed`;
- busca vetorial e resposta da IA devem sempre filtrar por `workspaceId`;
- conteúdo de um workspace nunca pode compor resposta de outro.
