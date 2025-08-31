## Visão geral do projeto

- **Propósito**: Protótipo de RPG narrativo tático baseado no Daggerheart SRD (dupla rolagem d12: Esperança vs Medo), em Godot 4.4.1 com GDScript.
- **Camadas do jogo**: Mundo de fantasia (exploração e combate tático) e vida real (diálogo/relacionamentos). A UI se inspira em The Sims GBA e Knights of Pen & Paper.
- **Arquitetura**: Sistemas modulares e data‑driven. Regras, falas e estatísticas vêm de CSV em `data/`. UI desacoplada da lógica (ex.: `ChatLog` apenas renderiza mensagens). Logs detalhados em `logs/godot.log`.

---

## Estrutura de pastas (o que cada coisa faz)

- `addons/SimpleFormatOnSave`:
  - Plugin de formatação ao salvar (organiza espaços/linhas) para manter o código consistente.

- `data/`:
  - `database_voices.csv`: Banco de falas/narrações. Linhas indexadas por `speaker | listener | situation | variant`, com `style` e `text`.
  - `database_players.csv` e `database_monsters.csv`: Estatísticas de personagens e monstros (HP, thresholds, arma, etc.).
  - Arquivos `.translation`: gerados a partir dos CSVs, para suporte a localização/ferramentas.

- `docs/`:
  - Documentos de design e referência (Daggerheart SRD e GDD).
  - Este resumo.

- `scenes/`:
  - `CombatScene.tscn`: Cena principal do protótipo de combate.

- `scripts/`:
  - Scripts GDScript principais que implementam dados, rolagens, narração, UI e lógica de combate/turnos.

- Arquivos de projeto:
  - `project.godot`, `icon.svg(.import)`: Configurações/metadados do projeto Godot.

---

## Cena principal: `scenes/CombatScene.tscn`

Árvore de nós relevante (resumo):

- `CombatScene` (`Node2D`) – `scripts/combat_scene.gd`
- `DiceRoller` (`Node`) – rolagens de dados
- `Narrator` (`Node`) – narração via CSV
- `TurnManager` (`Node`) – sinais de início/fim de turnos
- `CombatManager` (`Node`) – cálculo de dano e categorias (minor/major/severe)
- `MasterAI` (`Node`) – turno do Mestre
- `UI` (`CanvasLayer`)
  - `ActionButtonsPanel` – botão “Tentar Ação”
  - `ChatScroll/ChatLog` – feed de mensagens
  - `PlayerStatusPanel` – cards dos heróis (seleção do ator)
  - `EnemyStatusPanel` – cards dos inimigos (seleção do alvo)
  - `MasterStatusBox` – exibe o Medo do Mestre
  - `PlayerParty` – container de instâncias dos jogadores
  - `EnemyParty` – container de instâncias dos monstros

---

## Fluxo de combate atual

1. Inicialização
   - `PlayerParty` instancia 2 `PlayerCharacter` (template atual: `default_hero`).
   - `EnemyParty` instancia 2 `MonsterCharacter` (`jagged_knife_bandit`).
   - Logs detalhados são emitidos para `logs/godot.log` em todos os sistemas.

2. Seleção por mouse (single select)
   - `PlayerStatusPanel`: clique em um card seleciona o herói que irá agir (apenas 1 selecionado por vez; highlight verde).
   - `EnemyStatusPanel`: clique em um card seleciona o alvo do ataque (apenas 1 selecionado por vez; highlight amarelo).
   - Os painéis emitem `player_selected(player)` e `enemy_selected(enemy)`. O `CombatScene` registra o ator (`current_actor`) e o alvo (`current_target`).
   - Se um nó for derrotado/liberado, o card é removido, o mapeamento e a seleção são limpos com segurança.

3. Turno do jogador
   - Clique em “Tentar Ação”:
     - `DiceRoller.roll_duality(0)` emite Esperança vs Medo; o `Narrator` compõe mensagens.
     - Checagem de acerto: `total` vs `target.data.difficulty`.
     - Se acertar: `CombatManager.resolve_attack(actor, target, "2d8")` rola dano e categoriza com base nos thresholds do alvo (`major`, `severe`).
     - Se resultado for `hope`, o ator ganha 1 Hope.
     - Fim de turno: encerra em `fear` ou `miss`. Em `hope`/`crit` com acerto, o jogador pode agir novamente.

4. Turno do Mestre
   - `MasterAI` escolhe o primeiro monstro vivo de `EnemyParty` e o primeiro jogador vivo de `PlayerParty`.
   - To‑hit: `1d20 + attack_bonus` vs evasion do jogador; se acertar, chama `CombatManager.resolve_attack(monster, player, weapon_roll)` (do monstro).
   - Ao terminar, emite `turn_finished` e o `TurnManager` inicia o próximo turno do jogador.

5. Derrota e remoção
   - `PlayerCharacter` e `MonsterCharacter` emitem `defeated`, fazem `hide()` e `queue_free()` quando `HP <= 0`.
   - Painéis removem cards e limpam seleções ao receber `defeated`.
   - Unidades derrotadas não podem agir nem ser alvos.

---

## Scripts principais (resumo)

- `scripts/combat_scene.gd`
  - Orquestra turnos, integra seleção (ator/alvo), conecta sinais e valida ações.

- `scripts/turn_manager.gd`
  - Sinais: `player_turn_started`, `master_turn_started`, `turn_ended`. Controla a troca de turnos.

- `scripts/combat_manager.gd`
  - `resolve_attack(attacker, target, damage_roll_string)`: rola dano, classifica (`minor/major/severe`) pelos thresholds do alvo e aplica `apply_hp_loss`.

- `scripts/master_ai.gd`
  - Executa o turno do Mestre: escolhe primeiro monstro vivo e ataca o primeiro jogador vivo. Atualiza `Medo` quando necessário.

- `scripts/ui_player_status_panel.gd`
  - Renderiza cards de heróis. Single‑select com highlight; emite `player_selected(player)`. Remove card e limpa seleção em `defeated`.

- `scripts/ui_enemy_status_panel.gd`
  - Renderiza cards de inimigos. Single‑select com highlight; emite `enemy_selected(enemy)`. Remove card e limpa seleção em `defeated`.

- `scripts/player_party.gd` / `scripts/enemy_party.gd`
  - Responsáveis por instanciar 2 jogadores e 2 monstros no início. Helpers para obter o primeiro vivo.

- `scripts/player_character.gd` / `scripts/monster_character.gd`
  - Estado e sinais (`hp_changed`, `defeated`). Ao morrer: `hide()` + `queue_free()`.

- `scripts/dice_roller.gd`
  - `roll_duality`, `roll_d20_value`, `roll_string` com breakdown.

- `scripts/chat_log.gd` / `scripts/narrator.gd`
  - Mensagens e narração data‑driven a partir de `DatabaseVoices`.

- `scripts/database_players.gd` / `scripts/database_monsters.gd`
  - Carregam CSV em memória e expõem getters.

---

## Como executar rapidamente

1. Abrir o projeto no Godot 4.4.1.
2. Rodar a cena `scenes/CombatScene.tscn`.
3. Selecionar um herói (card verde) e um alvo (card amarelo), clicar em “Tentar Ação” e acompanhar o fluxo no `ChatLog` e em `logs/godot.log`.

---

## Dicas de evolução (próximos passos)

- Separar ações em botões: “Atacar” (to‑hit + dano por arma) vs “Tentar Ação” (interações gerais).
- Tornar armas/rolagens totalmente data‑driven por personagem (arma/ataque do jogador a partir do CSV de players).
- UI/feedback: efeitos visuais no `EffectsLayer`, ícones de status, tooltips ricos.
- Estados especiais e condições (stun, bleed, proteção), iniciativa e economia de ações.
- Persistência de campanha e camadas de vida real impactando domínios/rolagens.


