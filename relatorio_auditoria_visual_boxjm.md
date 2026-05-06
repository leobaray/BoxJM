# Relatório de Auditoria Visual Flutter – BOX JM

## 1. Sumário Executivo

**Veredito geral:** O app tem uma UI dark bem-acabada, com design system consistente, paleta coesa e atenção a detalhes visuais (gradientes, sombras, bordas arredondadas, AnimatedContainers). Não há problemas visuais **críticos** que "quebrem" a UI em condições normais de uso.

Dito isso, há um conjunto real de problemas que afetam usuários em edge cases concretos — principalmente acessibilidade, `withOpacity` deprecated, e `textScaleFactor` ignorado.

| Severidade | Quantidade | O que significa |
|---|---|---|
| **Real** | 3 | Causa erro/deprecation visível ou quebra de funcionalidade |
| **Médio** | 5 | Afeta usuários reais em cenários específicos (acessibilidade, tela pequena) |
| **Leve/Melhoria** | 9 | Polish, nice-to-have, melhoria de manutenção |
| **Total** | **17** | |

### Os 3 Problemas Reais

1. **`withOpacity` deprecated** — `flutter analyze` retorna 37 infos de `deprecated_member_use`. Em Flutter 3.29+, `Color.withOpacity()` gera warning. Isso quebra lint CI limpo e será removido em versões futuras.
2. **`onPopInvoked` deprecated** — `PopScope.onPopInvoked` está deprecated desde v3.22. Deve ser `onPopInvokedWithResult`.
3. **`GestureDetector` sem feedback visual no preço editável** — O preço em `_ServiceRow` usa `GestureDetector` ao invés de `InkWell`. Sem ripple, sem highlight. O usuário não tem como saber que é tocável.

---

## 2. Metodologia de Inspeção

| Ferramenta | Resultado |
|---|---|
| Leitura de todos 33 arquivos `.dart` | Completa |
| `flutter analyze` | 76 issues (37 `withOpacity` deprecated, 1 `onPopInvoked` deprecated, restantes são info-level em testes) |
| `grep -rn "fontSize:" lib/` | ~90 ocorrências — hardcoded |
| `grep -rn "withOpacity" lib/` | 37 ocorrências no código de UI |
| `grep -rn "Semantics" lib/presentation/` | 0 ocorrências |
| `grep -rn "Theme.of(context)" lib/presentation/` | 0 ocorrências — TextTheme nunca usada |
| `grep -rn "Hero" lib/presentation/` | 0 ocorrências |
| `grep -rn "MediaQuery" lib/presentation/` | 2 (viewInsets e size.height no bottom sheet) |

---

## 3. Detalhamento de Problemas

---

### [REAL] R-01 — `Color.withOpacity()` deprecated (37 ocorrências no código de UI)

- **Localização:** `app_colors.dart:67,73`, `app_theme.dart:129`, `budget_detail_page.dart:834,845,887,894,897`, `home_page.dart:405,421,424,521,594,606,695,698`, `main_shell.dart:110,115,170,222`, `new_budget_page.dart:574,728,945,952,955`, `services_page.dart:106,149`, `brand_header.dart:108,113`, `budget_card.dart:48,61`, `connectivity_banner.dart:25,28`, `gradient_button.dart:34,35,43`, `service_editor_sheet.dart:210,266,289`, `service_item_tile.dart:46`, `status_badge.dart:42,44`, `vehicle_type_selector.dart:67`
- **Categoria:** Cor / Deprecation
- **Descrição:** `flutter analyze` retorna 37 `deprecated_member_use` para `withOpacity`. O Flutter 3.29+ recomenda `Color.withValues(alpha: ...)`. Essa API será removida em versão futura.
- **Evidência do `flutter analyze`:**
```
info - 'withOpacity' is deprecated and shouldn't be used. Use .withValues() to avoid precision loss
```
- **Ferramenta de Debug:** `flutter analyze`

---

### [REAL] R-02 — `PopScope.onPopInvoked` deprecated

- **Localização:** `lib/presentation/pages/new_budget_page.dart:342`
- **Categoria:** API Deprecated
- **Descrição:** `onPopInvoked` está deprecated desde Flutter v3.22. Deve ser substituído por `onPopInvokedWithResult`.
- **Evidência do `flutter analyze`:**
```
info - 'onPopInvoked' is deprecated and shouldn't be used. Use onPopInvokedWithResult instead.
```
- **Ferramenta de Debug:** `flutter analyze`

---

### [REAL] R-03 — `GestureDetector` no preço editável sem feedback visual

- **Localização:** `lib/presentation/pages/new_budget_page.dart:786`
- **Categoria:** Interação / Estado de UI
- **Descrição:** O preço em `_ServiceRow` usa `GestureDetector(onTap: onEditPrice)` — sem ripple, sem highlight, sem cursor pointer. Há um micro-label "editar" em fontSize 10, cor `textMuted` (#71717A), que é praticamente invisível. O preço parece um texto estático. É o único elemento interativo do app que não usa `InkWell`/`Material`.
- **Ferramenta de Debug:** Tocar no preço e observar que não há feedback visual
- **Trecho:**
```dart
// new_budget_page.dart:786
GestureDetector(
  onTap: selected ? onEditPrice : null,
  child: Column(
```

---

### [MÉDIO] M-01 — Zero Semantics — app completamente inacessível a leitores de tela

- **Localização:** Todos os 16 arquivos em `lib/presentation/`
- **Categoria:** Acessibilidade
- **Descrição:** Nenhuma ocorrência de `Semantics`, `semanticLabel`, `excludeSemantics` ou `MergeSemantics`. CustomPaints (logo, silhuetas de veículo) são invisíveis. Botões de +/− são lidos sem contexto. TalkBack/VoiceOver não consegue descrever o app. Não é um bug visual para usuários videntes, mas é uma falha de acessibilidade real.

---

### [MÉDIO] M-02 — `textScaleFactor` ignorado em toda a UI

- **Localização:** Todos os widgets de apresentação — ~90 `fontSize:` hardcoded
- **Categoria:** Tipografia / Acessibilidade
- **Descrição:** Nenhum widget usa `Theme.of(context).textTheme`. Os estilos são todos inline. Quando o usuário aumenta o tamanho da fonte nas configurações do sistema (Settings > Display > Font size), absolutamente nada mrega no app. Em `textScaleFactor` 1.5+, vários_widgets com tamanho fixo vão overflow:
  - Nav bar (height: 70) — label "Orçamentos" pode overflow
  - StatusFilterRow (height: 50) — chips podem overflow verticalmente
  - VehicleTypeSelector cards (width: 104) — "Caminhonete" pode overflow
- **Ferramenta de Debug:** Ativar textScaleFactor 1.5 nas configurações do dispositivo

---

### [MÉDIO] M-03 — Hit targets abaixo de 48dp em controles de quantidade

- **Localização:** `new_budget_page.dart:923` (30×30 `_QtyBtn`), `budget_detail_page.dart:974` (34×34 editar total), `service_item_tile.dart:168` (32×32 `_IconBtn`)
- **Categoria:** Acessibilidade
- **Descrição:** Botões de +/− e editar com área de toque de 30-34dp. Em dedos grandes, esses botões são difíceis de acertar. Os botões de header (42×42) e add (44×44) estão perto do mínimo e são aceitáveis.

---

### [MÉDIO] M-04 — `_StatBox` valor monetário truncado com `TextOverflow.ellipsis`

- **Localização:** `lib/presentation/pages/home_page.dart:457-468`
- **Categoria:** Layout
- **Descrição:** O valor monetário (ex: "R$ 150.000,00") na stat box usa `fontSize: 18, maxLines: 1, overflow: TextOverflow.ellipsis`. Em telas estreitas com valores altos, o valor será truncado para "R$ 150.000...". O usuário não verá o valor completo. Esse é o único caso em que dados importantes podem ser efetivamente perdidos na UI.
- **Trecho:**
```dart
// home_page.dart:457
Text(
  value,
  maxLines: 1,
  overflow: TextOverflow.ellipsis,
  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, ...),
),
```

---

### [MÉDIO] M-05 — Padding inferior hardcoded para navbar (110-120px)

- **Localização:** `home_page.dart:229` (110), `new_budget_page.dart:370` (120), `services_page.dart:54` (110)
- **Categoria:** Responsividade
- **Descrição:** O espaço abaixo da lista para não ser coberto pela navbar flutuante é hardcoded. Não consulta `MediaQuery.of(context).padding.bottom`. Em dispositivos com safe area diferente (iPhone com home bar, tablets), o último item pode ficar parcialmente oculto ou haver espaço morto excessivo.

---

### [LEVE] L-01 — `_TotalsCard` duplicado em dois arquivos

- **Localização:** `new_budget_page.dart:933-1020` e `budget_detail_page.dart:872-996`
- **Categoria:** Manutenibilidade
- **Descrição:** Dois `_TotalsCard` quase idênticos. Se forem divergidos no futuro, causará inconsistência visual.

---

### [LEVE] L-02 — `ServiceItemTile` é widget morto

- **Localização:** `lib/presentation/widgets/service_item_tile.dart`
- **Categoria:** Manutenibilidade
- **Descrição:** O widget `ServiceItemTile` nunca é instanciado como construtor. Só `ServiceItemTile.iconFor()` é chamado. O widget completo (117 linhas) é código não utilizado.

---

### [LEVE] L-03 — TextTheme definida mas nunca usada na camada de apresentação

- **Localização:** `app_theme.dart:11-13` define `GoogleFonts.interTextTheme`, mas 0 widgets usam `Theme.of(context).textTheme`
- **Categoria:** Manutenibilidade
- **Descrição:** A TextTheme existe no tema mas é papel morto. 90+ TextStyle inline. Manutenção de estilo requer edição em dezenas de locais.

---

### [LEVE] L-04 — Valor total com 3 tamanhos diferentes entre telas

- **Localização:** `budget_card.dart:170` (fontSize 21), `budget_detail_page.dart:958` (28), `new_budget_page.dart:987` (30)
- **Categoria:** Consistência
- **Descrição:** O mesmo dado (valor monetário total) tem 3 tamanhos de fonte diferentes dependendo da tela. A variação é intencional (hierarquia), mas a diferença de 28→30 entre detail e new budget é arbitrária.

---

### [LEVE] L-05 — Expansão de categorias sem animação suave

- **Localização:** `services_page.dart:213`, `new_budget_page.dart:663`
- **Categoria:** Animação
- **Descrição:** O `AnimatedContainer` anima borda/cor, mas o conteúdo é adicionado/removido instantaneamente via `if (expanded)`. Não há `AnimatedSize`. O salto visual é perceptível mas não dramaticamente problemático.

---

### [LEVE] L-06 — Checkbox custom sem animação de check

- **Localização:** `new_budget_page.dart:754`
- **Categoria:** Animação
- **Descrição:** O ícone de check aparece/desaparece instantaneamente. `AnimatedContainer` anima cor/borda, mas o `Icon` é condicional. Falta de polish, não bug.

---

### [LEVE] L-07 — `Color(0xFFFFA0A0)` hardcoded dentro de CustomPaint

- **Localização:** `lib/presentation/widgets/brand_header.dart:166`
- **Categoria:** Cor
- **Descrição:** Cor hardcoded `Color(0xFFFFA0A0)` no painter do logo, fora do sistema AppColors. Menor das menores — é um detalhe interno de um CustomPaint.

---

### [MELHORIA] X-01 — Adicionar Hero transition BudgetCard → Detail

- **Categoria:** Animação
- **Descrição:** Continuidade visual entre card e detalhe. Nice-to-have.

---

### [MELHORIA] X-02 — Skeleton/shimmer loading

- **Categoria:** Estado de UI
- **Descrição:** `CircularProgressIndicator` funciona, mas skeleton dá percepção de velocidade.

---

### [MELHORIA] X-03 — Tema claro

- **Categoria:** Cor
- **Descrição:** App é dark-only. Intencional para estética automotiva, mas impede uso em luz solar direta.

---

## 4. Checklist de Verificação

| Item | Status |
|---|---|
| Zero erros/warnings de layout no `flutter analyze` | ✅ Nenhum |
| 37 deprecation warnings (`withOpacity`) | ⚠️ Real |
| 1 deprecation warning (`onPopInvoked`) | ⚠️ Real |
| Overflow visível em condições normais | ✅ Nenhum encontrado |
| Cores centralizadas em AppColors | ✅ Exceto 1 caso em CustomPaint |
| Design system consistente | ✅ Excelente |
| Animações de microinteração | ✅ AnimatedContainer, AnimatedRotation |
| Acessibilidade semântica | ❌ Zero |
| textScaleFactor respeitado | ❌ Zero |
| Hit targets > 48dp | ⚠️ Controles de qty: 30-34dp |
| Dados importantes truncados | ⚠️ StatBox com ellipsis em valores altos |

---

## 5. Anexos

### A. Saída completa do `flutter analyze` (resumo)

```
76 issues found. (ran in 4.3s)

Breakdown:
- 37 × withOpacity deprecated (lib/code)
- 1 × onPopInvoked deprecated (new_budget_page.dart)
- 2 × use_build_context_synchronously (new_budget_page.dart)
- 1 × no_leading_underscores_for_local_identifiers (providers.dart)
- 35 × test-related infos (prefer_const, relative_lib_imports, unused_imports)
```

### B. Flags de Debug Recomendadas

```dart
debugPaintSizeEnabled = true;       // Ver hit targets
debugRepaintRainbowEnabled = true;  // Ver repaints
```

- Widget Inspector para hit targets e constraints
- TextScaleFactor 1.5 em emulador para testar overflow

---

*Relatório gerado em 2026-04-17.*
*33 arquivos Dart inspecionados. flutter analyse executado com sucesso.*