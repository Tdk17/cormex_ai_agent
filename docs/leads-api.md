# API de Leads — contrato de integração

Este documento é a especificação executável entre o front-end Flutter e o Cloud Code do Parse Server/Back4App para o Marco 2. O backend deve preservar os nomes, campos e envelopes abaixo para encaixar sem mudanças no aplicativo.

## 1. Transporte e autenticação

Todas as operações usam Cloud Functions:

```text
POST {PARSE_SERVER_URL}/functions/{functionName}
```

Headers enviados pelo `HttpManager`:

```http
Content-Type: application/json
X-Parse-Application-Id: <application-id>
X-Parse-REST-API-Key: <rest-api-key, quando configurada>
X-Parse-Session-Token: <token da sessão>
```

O Flutter nunca envia Master Key. O `workspaceId` identifica o tenant solicitado, mas não concede acesso. Cada função deve obter o usuário a partir da sessão, validar a membership no workspace e aplicar a role antes de consultar ou alterar qualquer lead.

## 2. Envelope obrigatório

O Parse envolve o retorno da Cloud Function em `result`. Dentro dele, o contrato da aplicação é:

```json
{
  "result": {
    "ok": true,
    "data": {},
    "meta": {
      "correlationId": "req_01J...",
      "nextCursor": null
    }
  }
}
```

Falhas de negócio devem manter o mesmo envelope:

```json
{
  "result": {
    "ok": false,
    "error": {
      "code": "VALIDATION_ERROR",
      "message": "Informe o nome do lead.",
      "correlationId": "req_01J...",
      "details": {
        "field": "name"
      }
    }
  }
}
```

`correlationId` deve ser gerado no início da função, incluído nos logs estruturados e devolvido tanto em sucesso quanto em erro.

## 3. DTO de Lead

```json
{
  "id": "lead_aB12Cd34",
  "workspaceId": "ws_Xy98Za76",
  "name": "Marina Souza",
  "phone": "+5511999999999",
  "email": "marina@empresa.com",
  "company": "Empresa Exemplo",
  "source": "whatsapp",
  "status": "qualified",
  "tags": ["inbound", "prioridade"],
  "ownerId": "user_kL45Mn67",
  "score": 78,
  "lastContactAt": "2026-08-24T16:30:00.000Z",
  "createdAt": "2026-08-20T12:00:00.000Z",
  "updatedAt": "2026-08-24T16:30:00.000Z"
}
```

Regras de serialização:

- `id`, `workspaceId`, `name`, `source`, `status`, `score`, `createdAt` e `updatedAt` são obrigatórios na resposta.
- `phone`, `email`, `company`, `ownerId` e `lastContactAt` podem ser `null`.
- `tags` deve ser sempre um array, mesmo vazio.
- Datas usam ISO 8601 em UTC.
- `score` é inteiro de 0 a 100.
- `status`: `new`, `contacted`, `qualified`, `proposal`, `won` ou `lost`.
- `source`: `manual`, `import`, `website`, `whatsapp`, `instagram`, `referral` ou `campaign`.

## 4. `v1-leads-list`

Lista leads do workspace com busca, filtros e paginação por cursor.

Request:

```json
{
  "workspaceId": "ws_Xy98Za76",
  "search": "marina",
  "status": "qualified",
  "source": "whatsapp",
  "tag": "prioridade",
  "cursor": "opaque_cursor_from_previous_page",
  "limit": 20
}
```

Todos os filtros são opcionais. `workspaceId` é obrigatório. `limit` deve aceitar de 1 a 100 e usar 20 como padrão. `search` procura, de forma case-insensitive, em nome, empresa, telefone, e-mail e tags.

Response:

```json
{
  "ok": true,
  "data": {
    "items": [
      {
        "id": "lead_aB12Cd34",
        "workspaceId": "ws_Xy98Za76",
        "name": "Marina Souza",
        "phone": "+5511999999999",
        "email": "marina@empresa.com",
        "company": "Empresa Exemplo",
        "source": "whatsapp",
        "status": "qualified",
        "tags": ["inbound", "prioridade"],
        "ownerId": null,
        "score": 78,
        "lastContactAt": null,
        "createdAt": "2026-08-20T12:00:00.000Z",
        "updatedAt": "2026-08-24T16:30:00.000Z"
      }
    ]
  },
  "meta": {
    "correlationId": "req_01J...",
    "nextCursor": "opaque_cursor_for_next_page"
  }
}
```

Ordenação estável recomendada: `updatedAt DESC, objectId DESC`. O cursor deve ser opaco e carregar os dois valores de ordenação. Na última página, `nextCursor` deve ser `null`.

## 5. `v1-leads-get`

Request:

```json
{
  "workspaceId": "ws_Xy98Za76",
  "leadId": "lead_aB12Cd34"
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "lead": {
      "id": "lead_aB12Cd34",
      "workspaceId": "ws_Xy98Za76",
      "name": "Marina Souza",
      "phone": "+5511999999999",
      "email": "marina@empresa.com",
      "company": "Empresa Exemplo",
      "source": "whatsapp",
      "status": "qualified",
      "tags": ["inbound"],
      "ownerId": null,
      "score": 78,
      "lastContactAt": null,
      "createdAt": "2026-08-20T12:00:00.000Z",
      "updatedAt": "2026-08-24T16:30:00.000Z"
    }
  },
  "meta": {
    "correlationId": "req_01J..."
  }
}
```

Responder `NOT_FOUND` se o lead não existir dentro do workspace autorizado. Nunca revelar que um ID existe em outro workspace.

## 6. `v1-leads-create`

Request:

```json
{
  "workspaceId": "ws_Xy98Za76",
  "lead": {
    "name": "Marina Souza",
    "phone": "+5511999999999",
    "email": "marina@empresa.com",
    "company": "Empresa Exemplo",
    "source": "manual",
    "status": "new",
    "tags": ["inbound"],
    "ownerId": null,
    "score": 40
  }
}
```

Validações mínimas:

- `name` obrigatório, após `trim`, com pelo menos dois caracteres;
- pelo menos `phone` ou `email` preenchido;
- e-mail válido quando presente;
- enums, score, owner e tags validados no servidor;
- aplicar limite do plano antes de criar;
- preencher `workspaceId`, `createdAt` e `updatedAt` exclusivamente no servidor.

Response: `data.lead` com o DTO completo, igual ao formato de `v1-leads-get`.

## 7. `v1-leads-update`

Request:

```json
{
  "workspaceId": "ws_Xy98Za76",
  "leadId": "lead_aB12Cd34",
  "changes": {
    "name": "Marina Souza",
    "phone": null,
    "email": "marina.nova@empresa.com",
    "company": "Empresa Exemplo",
    "source": "whatsapp",
    "status": "qualified",
    "tags": ["prioridade"],
    "ownerId": null,
    "score": 82
  }
}
```

O front envia o estado editável completo. Um campo nullable com valor `null` significa limpar o valor anterior. O backend não deve permitir mudança de `workspaceId`, `createdAt` ou identidade do objeto. Atualize `updatedAt` no servidor.

Response: `data.lead` com o DTO completo e atualizado.

## 8. `v1-leads-import`

O CSV é lido no dispositivo. O Flutter normaliza cabeçalhos em português/inglês, valida cada linha e envia somente as linhas válidas. O backend deve repetir as validações; validação no cliente não é controle de segurança.

Um arquivo de referência está disponível em [`docs/leads-import-template.csv`](leads-import-template.csv).

Request:

```json
{
  "workspaceId": "ws_Xy98Za76",
  "rows": [
    {
      "name": "Marina Souza",
      "phone": "+5511999999999",
      "email": "marina@empresa.com",
      "company": "Empresa Exemplo",
      "source": "import",
      "status": "new",
      "tags": ["inbound"],
      "ownerId": null,
      "score": 0
    }
  ]
}
```

Response:

```json
{
  "ok": true,
  "data": {
    "jobId": "import_01J...",
    "total": 1,
    "accepted": 1,
    "rejected": 0,
    "errors": []
  },
  "meta": {
    "correlationId": "req_01J..."
  }
}
```

Para lotes pequenos, a função pode concluir de forma síncrona. Se o backend tornar o processo assíncrono, mantenha estes campos e acrescente `status`; uma função de consulta do job deverá ser versionada antes de o front depender dela. Limite recomendado neste contrato: até 1.000 linhas ou 1 MB por chamada.

## 9. Códigos de erro usados pelo módulo

| Código | Quando usar |
| --- | --- |
| `UNAUTHENTICATED` | Sessão ausente, inválida ou expirada. |
| `FORBIDDEN` | Usuário autenticado sem membership/role para a operação. |
| `WORKSPACE_NOT_FOUND` | Workspace solicitado não existe ou não pode ser acessado. |
| `VALIDATION_ERROR` | Campo, filtro, cursor ou linha de importação inválida. |
| `NOT_FOUND` | Lead não encontrado dentro do escopo autorizado. |
| `CONFLICT` | Regra de duplicidade definida pelo produto. |
| `PLAN_LIMIT_REACHED` | Limite de leads/importação do plano atingido. |
| `RATE_LIMITED` | Frequência de chamadas excedida. |
| `INTERNAL_ERROR` | Falha inesperada, sempre com `correlationId`. |

## 10. Mapeamento no projeto Flutter

| Contrato | Implementação |
| --- | --- |
| Nomes das funções | `lib/Src/Core/http/endpoints.dart` |
| Transporte, headers e envelopes | `lib/Src/Core/http/http_manager.dart` |
| DTO | `lib/Src/Shared/models/lead_model.dart` |
| Parâmetros e payloads | `lib/Src/Features/leads/domain/` |
| Integração remota | `lib/Src/Features/leads/data/remote_leads_repository.dart` |
| Estado das telas | `lib/Src/Features/leads/presentation/controllers/` |

Para homologar, forneça as credenciais Parse no arquivo de ambiente e execute com `--dart-define-from-file`. Nenhuma tela precisa conhecer Parse ou Dio.

## 11. Checklist do backend

- [ ] Registrar `v1-leads-list`, `v1-leads-get`, `v1-leads-create`, `v1-leads-update` e `v1-leads-import` no Cloud Code.
- [ ] Validar `request.user` e membership em todas as funções.
- [ ] Filtrar toda query por workspace no servidor.
- [ ] Impedir leitura por enumeração de IDs entre tenants.
- [ ] Aplicar roles e limites do plano no servidor.
- [ ] Usar cursor opaco e ordenação estável na listagem.
- [ ] Sanitizar strings e validar enums, e-mail, score, tags e owner.
- [ ] Gerar e registrar `correlationId`.
- [ ] Nunca retornar segredos, Master Key ou credenciais de integrações.
- [ ] Criar testes de isolamento multi-tenant e de autorização antes de staging.
