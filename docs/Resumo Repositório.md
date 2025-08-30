## Visão geral do projeto

- **Propósito**: Protótipo de RPG narrativo tático baseado no Daggerheart SRD (dupla rolagem d12: Esperança vs Medo), em Godot 4.4.1 com GDScript.
- **Camadas do jogo**: Mundo de fantasia (exploração e combate tático) e vida real (diálogo/relacionamentos). A UI se inspira em The Sims GBA e Knights of Pen & Paper.
- **Arquitetura**: Sistemas modulares e data-driven. Regras de fala/narração vêm de CSV em `data/`. UI desacoplada da lógica (ex.: `ChatLog` apenas renderiza mensagens).

---

## Estrutura de pastas (o que cada coisa faz)

- `addons/SimpleFormatOnSave`:
  - **Plugin de formatação ao salvar** (organiza espaços/linhas) para manter o código consistente.

- `backup/tutorial_jrpg_16bit`:
  - **Material de referência/backup** (cena, imagens e personagens) que não participa do fluxo atual do jogo.

- `data/`:
  - `database_voices.csv`: Banco de falas/narrações. Linhas são indexadas por quatro chaves: `speaker | listener | situation | variant`, com `style` e `text`.
  - Arquivos `.translation`: recursos de tradução do Godot gerados a partir do CSV (suporte a localização/ferramentas), não usados diretamente no código atual.

- `docs/`:
  - `Daggerheart System Reference Document.pdf`: Referência oficial do sistema Daggerheart.
  - `Game Design Document.pdf`: Documento de design do jogo.
  - `RESUMO_DO_REPOSITORIO.md`: Este resumo para consulta rápida semanal.

- `scenes/`:
  - `CombatScene.tscn`: Cena principal atual do protótipo. Instancia UI de chat, rolagens de dado e narrador.

- `scripts/`:
  - Scripts GDScript principais que implementam dados, rolagens, narração e UI do chat.

- Arquivos de projeto:
  - `project.godot`, `icon.svg(.import)`: Configurações/metadados do projeto Godot.

---

## Cena principal: `scenes/CombatScene.tscn`

Nodos relevantes da cena:

- `CombatScene` (`Node2D`): Nó raiz com script `scripts/combat_scene.gd`.
- `UI/ChatLog` (`VBoxContainer`): Painel de mensagens na tela, script `scripts/chat_log.gd`.
- `DiceRoller` (`Node`): Lógica de rolagem, script `scripts/dice_roller.gd`.
- `Narrator` (`Node`): Monta falas com base no CSV e envia ao `ChatLog`, script `scripts/narrator.gd`.

Fluxo atual (simplificado):

1. A cena inicia e adiciona mensagens de exemplo ao `ChatLog`.
2. O `Narrator` consulta `DatabaseVoices` para obter frases contextualizadas e as renderiza no `ChatLog`.
3. O `DiceRoller` está pronto para emitir sinais de rolagem (conexões estão comentadas no momento).

---

## Scripts principais (o que fazem)

- `scripts/dice_roller.gd` (Node)
  - Sinais: `duality_rolled(hope_roll, fear_roll, total, result_type)` e `d20_rolled(value)`.
  - `roll_duality(modifier=0)`: Rola 2d12 (Esperança vs Medo), classifica o resultado em `"hope" | "fear" | "crit"` e emite o sinal com `total = hope + modifier`.
  - `roll_d20(modifier=0)`: Rola 1d20 com modificador e emite o valor.

- `scripts/database_voices.gd` (Node)
  - Carrega `data/database_voices.csv` em um dicionário `voices` indexado por `speaker|listener|situation|variant`.
  - `get_line(speaker, listener, situation, variant, values={})`: Busca com fallback nas seguintes chaves, nesta ordem:
    1) `speaker|listener|situation|variant`
    2) `speaker|all|situation|variant`
    3) `speaker|all|situation|generic`
    4) `system|all|situation|generic`
  - Faz substituição de tokens no texto: cada `{token}` é trocado pelos valores em `values`.
  - Retorna dicionário `{ speaker, style, text }`. Se não encontrar, retorna mensagem de erro padronizada.

- `scripts/narrator.gd` (Node)
  - Acessa `UI/ChatLog` e o singleton `DatabaseVoices` para montar mensagens.
  - `narrate_roll(speaker, listener, result_type, variant, values)`: Constrói `situation = "roll " + result_type` e envia ao `ChatLog`.
  - `narrate_custom(speaker, listener, situation, variant, values)`: Envia mensagem arbitrária contextualizada ao `ChatLog`.

- `scripts/chat_log.gd` (VBoxContainer)
  - Mantém um array `messages` e emite `message_added(message_data)` quando renderiza.
  - `add_entry(speaker, text, style)`: Cria um `RichTextLabel` e formata o texto por `style`:
    - `talk`: `"[speaker] texto"`
    - `narration`: `"#speaker# texto"`
    - `effect`: `"!speaker! texto"`
    - padrão: `"speaker: texto"`

- `scripts/combat_scene.gd` (Node2D)
  - Prepara referências a `DiceRoller`, `ChatLog` e `Narrator`.
  - No `_ready()`, adiciona entradas de exemplo e demonstra `narrator.narrate_roll(...)`.
  - Conexões de sinais do `DiceRoller` estão comentadas (ativar quando o fluxo de rolagem estiver integrado à UI/eventos).

---

## Dados e narração (`data/database_voices.csv`)

- Colunas esperadas (6): `speaker, listener, situation, variant, style, text`.
- Chaves de busca: combinação de `speaker|listener|situation|variant`.
- Fallbacks permitem generalizar por `listener = all` e `variant = generic`, além de uma linha de `system` por `situation`.
- Substituição de tokens: use `{token}` no `text` e passe `values = { token: valor }`.

Exemplo mínimo de linha no CSV:

```csv
speaker,listener,situation,variant,style,text
Aurora,all,roll hope,generic,talk,Eu senti coragem: {hope} contra {fear}!
```

---

## Como executar rapidamente

1. Abrir o projeto no Godot 4.4.1.
2. Rodar a cena `scenes/CombatScene.tscn` (ou defini-la como cena principal no `project.godot`).
3. Ver o painel de chat à direita exibindo mensagens e testes de narração.

---

## Dicas de evolução (quando retomar na próxima semana)

- Conectar sinais do `DiceRoller` e acionar `Narrator` automaticamente ao rolar.
- Mover frases de exemplo para o CSV e remover strings hardcoded.
- Definir enums/constantes para `result_type` e `style` para evitar typos.
- Separar UI de combate da de exploração, mantendo `ChatLog` reutilizável.
- Expandir `database_voices.csv` com situações: `turn start`, `turn end`, `ability use`, `fail`, etc.

---

## Mapa mental rápido

- **Rolagem**: `DiceRoller` → emite sinais.
- **Narração**: `Narrator` → consulta `DatabaseVoices` → envia para `ChatLog`.
- **UI**: `ChatLog` → renderiza mensagens conforme `style`.


