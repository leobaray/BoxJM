# Features Pendentes — BOX JM (novo)

---

## Alta Prioridade

### 1. Busca de orçamentos na Home
A tela inicial mostra uma lista flat sem nenhuma forma de buscar. Falta:
- Campo de busca em tempo real filtrando por nome do cliente ou marca/modelo do veículo
- Botão de limpar busca quando há texto no campo
- Contador de resultados ("X de Y orçamentos") quando há filtro ativo

### 2. Filtro por status na Home
Não é possível filtrar orçamentos por status. Falta:
- Chips/pills horizontais scrolláveis: Todos, Rascunho, Enviado, Aprovado, Concluído
- Destaque visual no filtro ativo (cor primária) vs inativo (cor cinza)
- Mensagem contextual quando o filtro retorna vazio + botão para limpar filtros

### 3. Ordenação de orçamentos na Home
A lista sempre vem na ordem do repositório (created_at desc). Falta:
- Opções de ordenação: Mais recente, Maior valor, Status
- Botão de alternância cíclica ou dropdown para selecionar
- Ordenação padrão: mais recente primeiro

### 4. Serviços agrupados por categoria no formulário de novo orçamento
Na `NewBudgetPage` os serviços são renderizados como lista flat (`for (final s in services)`). Falta:
- Agrupar por categoria (Exterior, Interior, Proteção, Detailing) com headers de seção
- Seções colapsáveis (expandir/recolher por categoria)
- Contador de serviços selecionados por categoria no header
- Ícone visual por categoria no header

### 5. Edição de preço base por serviço no formulário de orçamento
Ao criar ou editar um orçamento, o preço de cada serviço é fixo (vem do catálogo). O `BudgetItem.basePrice` sempre recebe `svc.basePrice` direto. Falta:
- Input inline de preço em cada serviço selecionado
- Permitir customizar o valor cobrado naquele orçamento específico sem alterar o catálogo
- O preço editado deve ser salvo no `BudgetItem.basePrice` e NÃO propagar de volta ao catálogo
- Formatação em R$ com vírgula decimal enquanto digita

### 6. `createdAt` do tipo `DateTime` quebra na serialização JSON local
`Budget.fromJson` faz `DateTime.parse(json['createdAt'] as String)` — funciona se for ISO 8601, mas `Budget.toJson` usa `createdAt.toIso8601String()`. O `fromSupabase` também parseia ISO. O problema: quando o orçamento é criado offline com `DateTime.now()`, o `toIso8601String()` gera string, o `fromJson` parseia de volta. Isso funciona, MAS o `toSupabaseInsert()` NÃO envia `created_at` (key ausente no map). Falta:
- Garantir que `toSupabaseInsert()` inclua `'created_at': createdAt.toIso8601String()` para o Supabase registrar a data correta
- Ou remover `createdAt` do JSON local e usar apenas string ISO, validando round-trip consistente

---

## Média Prioridade

### 7. Agrupamento temporal na lista de orçamentos
A lista da Home é flat, sem separação visual por período. Falta:
- Agrupar orçamentos em seções: Hoje, Ontem, Esta semana, Mais antigos
- Headers de seção com o label temporal
- Considerar `SliverList` ou `CustomScrollView` com `SliverList` por seção para performance

### 8. Serviços padrão não podem ser editados nem excluídos no catálogo
No `ServicesPage`, clicar em qualquer serviço (inclusive os 11 padrão) abre o editor que permite alterar nome, preço e até excluir. Os serviços padrão vêm hardcoded em `catalog.dart`. Se o usuário editar um serviço padrão via bottom sheet, o `CatalogRepositoryImpl.save()` faz upsert no Supabase. Funciona pelo merge, mas:
- Não há distinção visual entre serviço padrão e customizado na listagem
- Não há proteção contra exclusão de serviços padrão — se excluir, some até o próximo sync, e o fallback é `_merge` que inclui defaults novamente, criando comportamento confuso
- Falta: indicar visualmente quais são padrão vs customizados; bloquear exclusão de padrão (ou pelo menos alertar); talvez um campo `isDefault` no `ServiceItem`

### 9. Serviço padrão com preço alterado não persiste localmente de forma confiável
O merge do `CatalogRepositoryImpl` faz `custom.firstWhere((c) => c.id == def.id, orElse: () => def)`. Se o usuário altera o preço de um serviço padrão, isso vai pro Supabase como upsert na tabela `custom_services`. Mas se no offline o cache local (`getCustomServices`) não tem aquele ID, o merge retorna o preço original do catálogo. Falta:
- Ao salvar preço de serviço padrão, garantir que o upsert também atualize o cache local ANTES de tentar o remoto (já faz isso na linha `await _local.saveCustomServices(next)`, mas o `idx` only encontra por ID exato — services padrão nunca estão no cache `customServices` local, então sempre cai no `[...cached, service]`, adicionando duplicata potencial se o merge não filtrar)

### 10. Validação de telefone
O campo de telefone aceita qualquer texto, sem máscara nem validação. Falta:
- Máscara de input para telefone brasileiro: `(XX) XXXXX-XXXX` ou `(XX) XXXX-XXXX`
- Validação de formato mínimo (pelo menos 10 dígitos)
- `TextInputFormatter` com máscara no `TextField`

### 11. Indicador de status offline / conectividade
O app tem infraestrutura de sync e conectividade (`connectivityProvider`, `SyncService`), mas NENHUMA indicação visual para o usuário. O usuário pode estar offline, criar orçamentos, e não saber que estão pendentes de sync. Falta:
- Indicador visual na UI (banner, badge no header, ou ícone na bottom nav) mostrando offline
- Indicador de quantas operações estão na fila de sync pendente
- Feedback visual quando sync é concluído com sucesso

### 12. Fila de sync pode crescer infinitamente sem feedback
A `SyncOp` queue é persistida em SharedPreferences como JSON. Em uso prolongado offline, pode acumular muitas operações. Falta:
- Limite de tamanho da fila (alertar usuário se passar de X operações pendentes)
- Retry com backoff exponencial (atualmente `processQueue` para na primeira falha e não tenta mais até reconectar)
- Timestamp de criação em cada `SyncOp` para ordenar por prioridade ou descartar operações muito antigas

### 13. `NewBudgetPage` não preserva estado ao trocar de tab
`MainShell` usa `IndexedStack`, que preserva estado das 3 páginas. MAS a `NewBudgetPage` usa `ConsumerStatefulWidget` com `_selected`, `_client`, `_brand`, etc. Se o usuário começa a preencher, troca pra tab de Orçamentos, e volta, o estado deve estar preservado. Isso funciona com `IndexedStack`. Porém: se o usuário navega para detalhe do orçamento (`/budget/:id`) e depois volta, o `MainShell` é reconstruído (rota diferente no GoRouter), e o formulário perde tudo. Falta:
- Preservar formulário parcial em algum lugar (provider, cache local, ou state restaurável)
- Ou pelo menos alertar "Dados não salvos serão perdidos" antes de navegar

### 14. Confirmar antes de sair do formulário com dados preenchidos
Se o usuário preencheu nome, veículo ou selecionou serviços e aperta voltar (ou navega pra outro lugar), perde tudo sem aviso. Falta:
- `PopScope` (ou `WillPopScope` obsoleto) no `NewBudgetPage` para interceptar back
- Dialog "Descartar alterações?" quando há dados preenchidos
- Verificar se `_selected.isNotEmpty || _client.text.isNotEmpty || ...`

### 15. Erro silencioso no `BudgetRepositoryImpl.update`
Na linha 58: `final saved = await _remote.update(id, updates);` — se o remoto falha, o `_local.addSyncOp` enqueue a operação. MAS o `budgetCreate` offline salva o orçamento COM `id` gerado localmente (`generateId()` UUID). Quando o sync roda e manda esse budget pro Supabase, se o Supabase gerou um ID diferente no INSERT, o cache local ainda tem o ID local, mas o sync `budgetCreate` manda o budget com ID local. O Supabase aceita INSERT com ID explícito? Depende da config da tabela. Se não aceitar, o sync falha silenciosamente e o orçamento fica órfão local. Falta:
- Verificar se tabela `budgets` no Supabase permite INSERT com `id` fornecido pelo cliente
- Se não, mapear ID local → ID remoto após sync
- Log de erros de sync ao invés de swallow silencioso

---

## Prioridade Menor

### 16. Tela de rota não encontrada (404)
GoRouter não tem `errorBuilder`. Navegar pra rota inexistente provavelmente mostra tela em branco ou crash. Falta:
- `GoRouter.errorBuilder` ou `errorBuilder` com tela amigável
- Mensagem + branding BOX JM + botão "Voltar ao início"

### 17. `connectivityProvider` nunca é observado em telas além da Home
O `connectivityProvider` é dado `ref.watch` só na `HomePage`. Se o usuário está na `ServicesPage` ou `NewBudgetPage` e reconecta, o sync NÃO dispara automaticamente porque ninguém está observando o stream. Falta:
- Observar `connectivityProvider` num nível mais alto (no `MainShell` ou via `ref.listen` global)
- Ou mover pra um `ProviderObserver` / `ref.listen` que não depende de widget estar montado

### 18. Cache de catálogo não é carregado instantaneamente como o de budgets
`BudgetListController.build()` mostra cache local instantaneamente (`final cached = ref.read(localStorageProvider).getBudgets()`). `CatalogListController.build()` NÃO faz isso — vai direto no `catalogRepositoryProvider.getAll()` que tenta remoto primeiro. Em offline, cai no `catch` e retorna merge do cache, mas sem o "show cache first" pattern. Falta:
- Carregar cache local de custom_services instantaneamente e fazer merge antes de tentar remoto
- Mesmo pattern do `BudgetListController`: `if (cached.isNotEmpty) state = AsyncData(cached);`

### 19. `Budget.toSupabaseInsert()` não envia `created_at`
O método monta o map sem o campo `created_at`. Se o orçamento foi criado offline com `DateTime.now()`, ao sincronizar depois, o Supabase vai gerar `created_at` automaticamente (se tiver default `now()`), mas a data será a do INSERT, não a data real de criação. Falta:
- Incluir `'created_at': createdAt.toIso8601String()` no `toSupabaseInsert()`

### 20. `SyncOp.budgetUpdate` no `sync_service._execute` pode falhar
O `_execute` para `budgetUpdate` faz:
```dart
final id = op.payload['id'] as String;
final updates = BudgetUpdate.fromJson(Map<String, dynamic>.from(op.payload['updates'] as Map));
```
Mas `BudgetUpdate.toJson()` serializa `vehicleType` como string (`vehicleType!.name`) e `items` como lista de maps. O `BudgetUpdate.fromJson()` espera `json['vehicleType']` como String e `json['items']` como List. Funciona. MAS: se o orçamento foi criado offline e ainda não foi sincronizado, um `budgetUpdate` na fila vai tentar `UPDATE` num ID que não existe no Supabase. Falta:
- Garantir que a fila processa `budgetCreate` antes de `budgetUpdate` para o mesmo orçamento
- Ou: se o update falhar e o orçamento nao existe no remoto, tentar INSERT em vez de UPDATE (upsert pattern)

### 21. Orçamentos duplicados ao criar offline e depois sincronizar
`BudgetRepositoryImpl.create` gera ID local, salva no cache, e se o remoto falha, enqueue. Quando sync roda, manda o mesmo budget pro Supabase. Se o INSERT funciona, o sync NÃO atualiza o cache local com o resultado do Supabase (o `processQueue` só chama `_budgetRemote.create()` e `removeSyncOp`). O cache local continua com o orçamento "local". Se depois um `fetchAndCache` roda, ele traz TODOS orçamentos do Supabase, incluindo o recém-sincronizado. O `saveBudgets` sobrescreve o cache inteiro, então funciona. MAS: se o INSERT no Supabase falhar (ID duplicado ou outro erro), a `SyncOp` fica na fila para sempre e o `processQueue` para na primeira falha, bloqueando TODAS as operações subsequentes. Falta:
- Tratamento de erro por operação individual (skip e log ao invés de break)
- Retry individual com backoff
- Limite de tentativas por SyncOp

### 22. SharedPreferences como storage local tem limitações
O app salva lista inteira de orçamentos como JSON string num único key do SharedPreferences. Isso funciona pra poucos orçamentos, mas:
- SharedPreferences não é feito pra dados grandes — JSON de orçamentos com `items` aninhados cresce rápido
- Não há indexação — toda leitura desserializa a lista inteira
- Para dezenas/centenas de orçamentos, pode ficar lento
Falta:
- Considerar migrar para Hive, Isar, ou SQLite (via `sqflite`/`drift`) para storage local escalável
- Ou pelo menos paginar e não desserializar tudo de uma vez

### 23. `NewBudgetPage` carrega dados do orçamento para edição de forma frágil
Na linha 168: `final b = budgets.where((x) => x.id == widget.editingBudgetId).firstOrNull;` — busca pelo ID na lista em memória. Se o provider está em loading ou error, `valueOrNull ?? const []` retorna vazio e `b` é null, então `_hydrateFromBudget` nunca roda e o formulário fica vazio em modo edição. Falta:
- Mostrar loading enquanto busca o orçamento para edição
- Fallback: buscar o orçamento direto no repository por ID ao invés de filtrar a lista inteira
- Ou: rota param com passagem de dados via `extra` do GoRouter

### 24. Não há `updatedAt` no modelo `Budget`
O orçamento só tem `createdAt`. Edição de total, status, dados do cliente — nenhum registro de quando foi modificado. Falta:
- Campo `updatedAt: DateTime?` no `Budget`
- Atualizar `updatedAt` em toda mutation
- Mapear pro Supabase (`updated_at`)
- Útil para: ordenação por última modificação, resolver conflitos de sync, auditoria

### 25. Compartilhamento de orçamento não inclui label do tipo de veículo
A mensagem de share mostra `Veículo: ${budget.vehicleBrand} ${budget.vehicleModel}` mas não diz se é SUV, Caminhonete, etc. O multiplicador aparece nos cálculos mas o tipo de veículo não. Falta:
- Incluir o tipo de veículo (label amigável) no texto do compartilhamento
- Ex: `Veículo: Ford EcoSport (SUV) - Multiplicador: x1.7`

### 26. `BudgetDetailPage` mostra `vehicleType.name` em inglês
Na linha 298: `'Tipo: ${budget.vehicleType.name}'` — como `VehicleType` é enum, `.name` retorna a string do enum ("small", "medium", "large", "suv", "truck"), não o label em português. Falta:
- `VehicleType` precisa de um `label` getter (tipo `BudgetStatus.label`)
- "Pequeno", "Médio", "Grande", "SUV", "Caminhonete"

### 27. Nenhum teste real
O arquivo `test/widget_test.dart` existe mas provavelmente é o boilerplate padrão. Falta:
- Testes unitários: `BudgetCalc`, `Currency`, `Budget.fromJson`/`toJson`, `BudgetUpdate.apply`
- Testes de repository: `BudgetRepositoryImpl` (com mock do remote + local)
- Testes de widget: render das páginas, interação dos widgets
- Testes de integração: fluxo criar orçamento, editar, excluir

### 28. Nenhum logging estruturado
Todos os `catch (_)` engolem erros silenciosamente. No `sync_service`, `budget_repository_impl`, etc. Falta:
- `logger` ou `debugPrint` com contexto (tipo da operação, ID, erro)
- Pelo menos em debug mode, logar erros ao invés de swallow
- Em produção, considerar crashlytics (`firebase_crashlytics` ou Sentry)

### 29. Sem proteção de dados sensíveis no `.env`
O `.env` com `SUPABASE_ANON_KEY` está incluído no bundle do app via `pubspec.yaml` (assets). A chave é "anon" e provavelmente tem RLS no Supabase, mas: 
- Não há `.env.example` pra documentar as variáveis necessárias
- Se por acaso tiver service_role key vazando, é crítico
Falta:
- `.env.example` com valores placeholder
- Verificar que o `.env` está no `.gitignore`

### 30. MainShell não sincroniza tab com URL
Se o usuário navega pra `/services` ou `/new` via deep link, o `MainShell(initialTab: X)` funciona. Mas se está na tab 0 e toca num orçamento (navega pra `/budget/:id`), ao voltar com `pop()`, volta pra rota `/` que cria `MainShell(initialTab: 0)`. Se estava na tab de serviços antes, perde. E se navegar pra `/services` direto, o `initialTab: 1` funciona, mas o back do sistema não sabe qual tab estava ativa. Falta:
- Sincronizar tab ativa com a URL atual no GoRouter (stateful shell route)
- Ou usar `StatefulShellRoute` do go_router pra preservar estado de navegação

### 31. ServiceItem do catálogo não tem `createdAt` nem `updatedAt`
Serviços customizados não têm timestamp de criação. O Supabase `custom_services` tem `created_at`, mas a entidade `ServiceItem` não carrega. Falta:
- Campo `createdAt` no `ServiceItem` para ordenar por mais recentes
- `fromSupabase` já pode mapear `created_at`

### 32. Categoria vazia aparece no catálogo
Se não há serviços em "Detailing" (por exemplo), a `ServicesPage` itera `ServiceCategory.values.where(grouped.containsKey)`, que ignora categorias vazias. Ok, isso funciona. Mas se o usuário exclui todos os custom e os defaults incluem pelo menos 1 por categoria, nunca fica vazio. Se no futuro adicionar categoria sem serviços, funciona. Nada crítico aqui, só nota.

### 33. Orçamento sem serviços pode ter total editado
Na `BudgetDetailPage._editTotal`, a linha 111: `if (budget.items.isEmpty) return;` — protege contra edit sem serviços. Boa. Mas o `BudgetRepositoryImpl.create` não impede criar orçamento com items vazio (a validação tá no UI nível `NewBudgetPage`). Se alguém chamar o controller diretamente com items vazio, o orçamento é criado com subtotal 0. Falta:
- Validação no domain/repository level (não só no UI)
- `items.isNotEmpty` como invariant do `Budget`

### 34. Não há forma de duplicar orçamento
Se o cliente volta pra fazer mesmo serviço, precisa recriar do zero. Falta:
- Botão "Duplicar" na detail page
- Cria novo orçamento com mesmos dados, novo ID, status draft

### 35. Nenhum sistema de autenticação
O app conecta ao Supabase com anon key. Qualquer pessoa com a key pode ler/escrever tudo. Falta:
- Autenticação (pelo menos login simples com email/senha via Supabase Auth)
- RLS policies no Supabase que restrinja acesso ao dono dos dados
- Logout, session management

### 36. Sem deep link / share link
O `share_plus` compartilha texto formatado. Mas não gera link que abre o app num orçamento específico. Falta:
- Deep link configurado no Flutter/Supabase
- Link compartilhável tipo `boxjm://budget/abc123` ou URL universal
- O receptor do link abre direto na detail page do orçamento

### 37. Sem impressão / PDF
Para oficinas que imprimem orçamento para o cliente. Falta:
- Gerar PDF do orçamento
- Ou pelo menos print-friendly layout
- Pacotes: `pdf`, `printing`

### 38. Sem foto do veículo
Orçamentos de estética automotiva se beneficiariam de foto antes/depois. Falta:
- Captura de foto da placa ou do veículo
- Upload pro Supabase Storage
- Exibição na detail page e no compartilhamento

### 39. Notificações locais
Para lembrar de orçamentos enviados que não foram respondidos. Falta:
- Lembrete: "Orçamento enviado há X dias sem resposta"
- Notificação local (`flutter_local_notifications`)
- Configurável pelo usuário

### 40. Histórico de alterações de status
Não há log de quando o status mudou. Falta:
- `StatusLog` com status anterior, novo, timestamp
- Linha do tempo na detail page
- Útil para: "Enviado em 10/04, Aprovado em 12/04"

### 41. Formatação de moeda inconsistente no input
O `TextField` de preço no `service_editor_sheet` usa `keyboardType: numberWithOptions(decimal: true)`, mas não formata em tempo real. O usuário digita "50" e vê "50" ao invés de "R$ 50,00". Na `BudgetDetailPage._editTotal` também. Falta:
- `TextInputFormatter` de moeda BR que formata enquanto digita
- Consistência entre todos os campos de preço

### 42. `IndexedStack` carrega todas as 3 tabs de uma vez
`MainShell` usa `IndexedStack(index: _index, children: _pages)` — as 3 páginas são construídas no primeiro render. Isso significa que `NewBudgetPage` e `ServicesPage` disparam seus providers/fetches mesmo se o usuário nunca navegar pra elas. Falta:
- Considerar lazy loading — só construir a tab quando for acessada pela primeira vez
- Ou usar `AutomaticKeepAliveClientMixin` com `PageView` se preferir

### 43. Nenhum accessibility (acessibilidade)
- Sem `Semantic` labels nos ícones e botões
- Sem suporte a `TalkBack`/`VoiceOver`
- Contraste pode ser insuficiente em alguns textos cinza sobre fundo escuro
- Sem suporte a font scaling (tamanhos fixos)