# API — Uploads de arquivos

O Flutter usa o endpoint nativo do Parse Files para imagens de campanha e arquivos da Base de Conhecimento.

## `POST /files/{fileName}`

### Headers

```http
Content-Type: image/png
X-Parse-Application-Id: {applicationId}
X-Parse-REST-API-Key: {restApiKey, quando configurada}
X-Parse-Session-Token: {sessionToken}
```

O body contém os bytes brutos do arquivo. Não usar JSON, multipart ou Base64.

### Response nativa do Parse

```json
{
  "name": "tfss-...-campaign-ws_123-produto.png",
  "url": "https://files.example.com/tfss-...-produto.png"
}
```

O campo `url` é obrigatório para o fluxo atual.

## Usos atuais

### Imagem de campanha

- nome lógico enviado: `campaign-{workspaceId}-{fileName}`;
- tipos aceitos pelo front: JPEG, PNG e WebP;
- tamanho máximo do front: 8 MB;
- a URL retornada entra em `campaign.mediaUrls`;
- a publicação deve validar que a URL pertence a um host de arquivos permitido.

### Base de Conhecimento

- nome lógico enviado: `knowledge-{workspaceId}-{fileName}`;
- tipos aceitos: PDF, DOCX, TXT e MD;
- tamanho máximo do front: 15 MB;
- depois do upload, o Flutter chama `knowledge.create` com `fileUrl`, `fileName` e `mimeType`;
- o arquivo só se torna utilizável pela IA após o worker concluir e a fonte ficar `ready`.

## Segurança obrigatória

- exigir sessão válida;
- validar magic bytes, extensão, MIME e tamanho novamente no backend/storage;
- sanitizar o nome; o cliente já limita a 120 caracteres, mas o servidor não deve confiar nisso;
- impedir execução ou interpretação de conteúdo ativo;
- não aceitar SVG/HTML para criativo sem sanitização específica;
- manter relação entre arquivo, usuário e workspace em classe protegida;
- limitar quantidade e volume conforme o plano;
- varrer malware quando o ambiente oferecer esse serviço;
- usar URL assinada/privada quando o provedor permitir;
- remover arquivo órfão quando a criação da entidade falhar definitivamente.

## Erros

| Situação | Código |
| --- | --- |
| Sessão ausente | `UNAUTHENTICATED` |
| Tipo inválido | `VALIDATION_ERROR` |
| Arquivo grande | `PLAN_LIMIT_REACHED` ou `VALIDATION_ERROR` |
| Limite de armazenamento | `PLAN_LIMIT_REACHED` |
| Falha do storage | `FILE_UPLOAD_ERROR` |

Quando Parse Files devolver seu erro nativo, a camada de API deve normalizá-lo antes de exibi-lo ao usuário.
