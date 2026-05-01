# Content Schema

All content ids must be lowercase snake_case.

Content must be stored as Godot custom Resources (`.tres`) using Resource classes from `scripts/defs/`.

## Shared rules

Every definition should have:

* `id: String`
* `display_name: String`
* `description: String`
* `tags: PackedStringArray`

Ids are stable API contracts. Do not rename ids casually.

## Player-facing text and localization

Technical ids remain lowercase snake_case and should not include slang spelling.

Every content definition that appears to the player should support Spanish/Sevillian visible text.

Preferred fields:

- `display_name_es`
- `description_es`
- `flavor_text_es`
- `short_ui_text_es`

Rules:

- ids are technical and stable
- display text can be vulgar/local
- gameplay-critical information must remain clear
- flavor can carry heavier slang
- do not hardcode final player-facing text inside UI scenes or gameplay scripts when it belongs in data

## EnemyDef

File:

* `scripts/defs/enemy_def.gd`

Fields:

* `id`
* `display_name`
* `description`
* `display_name_es`
* `description_es`
* `flavor_text_es`
* `scene_path`
* `tags`
* `base_hp`
* `base_speed`
* `base_armor`
* `leak_damage`
* `gold_reward`
* `abilities`
* `weakness_tags`
* `resistance_tags`
* `is_boss`
* `visual_color_key`

MVP enemy ids:

* `tactichandal_runner`
* `lagrima_negra`
* `resonante_bruiser`
* `clan_loot_summoner`
* `killo_bulevar_boss`

## DefenseDef

File:

* `scripts/defs/defense_def.gd`

Fields:

* `id`
* `display_name`
* `description`
* `display_name_es`
* `description_es`
* `flavor_text_es`
* `scene_path`
* `category`
* `element`
* `rarity`
* `base_cost`
* `base_damage`
* `base_fire_rate`
* `base_range`
* `targeting_mode`
* `effect_ids`
* `upgrade_1_description`
* `upgrade_2_description`
* `upgrade_1_description_es`
* `upgrade_2_description_es`
* `strong_against_tags`
* `weak_against_tags`
* `synergy_tags`
* `balance_risk`

Categories:

* `air`
* `ground`
* `wall`

Elements:

* `humo`
* `agua`
* `turbo`
* `oro`
* `pacto`
* `metal`

MVP defense ids:

* `ventilador_nube`
* `aspersor_azotea`
* `letrero_luminoso`
* `altavoz_resonante`
* `matojera_humo`
* `manguerazo`
* `cable_pelao`
* `reja_pinchos`

## ItemDef

File:

* `scripts/defs/item_def.gd`

Fields:

* `id`
* `display_name`
* `description`
* `display_name_es`
* `description_es`
* `flavor_text`
* `flavor_text_es`
* `rarity`
* `tags`
* `effect_hooks`
* `effect_values`
* `drawback_description`
* `balance_risk`

Rarities:

* `common`
* `rare`
* `epic`

MVP item ids:

* `botellin_congelado`
* `abanico_prestado`
* `ticket_bus_urbano`
* `silla_playa`
* `ventilador_viejo`
* `montadito_apretado`
* `bizum_pendiente`
* `mochila_reparto`
* `moneda_carro`
* `estampa_plastificada`

## CharacterDef

File:

* `scripts/defs/character_def.gd`

Fields:

* `id`
* `display_name`
* `description`
* `display_name_es`
* `description_es`
* `flavor_text_es`
* `start_gold`
* `core_hp`
* `free_rerolls`
* `active_ability_id`
* `passive_id`
* `tags`

MVP character id:

* `manue_el_encerrado`

## MapDef

File:

* `scripts/defs/map_def.gd`

Fields:

* `id`
* `display_name`
* `description`
* `scene_path`
* `ground_path_ids`
* `air_path_ids`
* `build_pad_groups`
* `gimmick_id`
* `music_id`

MVP map id:

* `pino_montano_bloques_bulevar`

## RoundDef

File:

* `scripts/defs/round_def.gd`

Fields:

* `id`
* `round_index`
* `display_name`
* `wave_steps`
* `base_gold_reward`
* `has_elite`
* `has_boss`
* `boss_enemy_id`
* `dominant_enemy_tags`
* `reward_table_id`

## WaveStepDef

File:

* `scripts/defs/wave_step_def.gd`

Fields:

* `enemy_id`
* `count`
* `spawn_interval`
* `start_delay`
* `path_id`
* `is_elite`

## RoomInteractionDef

File:

* `scripts/defs/room_interaction_def.gd`

Fields:

* `id`
* `display_name`
* `description`
* `display_name_es`
* `description_es`
* `success_text_es`
* `failure_text_es`
* `flavor_text_es`
* `cost_gold`
* `cost_room_charges`
* `max_uses_per_run`
* `max_uses_per_round`
* `benefit_tags`
* `risk_tags`
* `effect_values`

MVP ids:

* `encender_ventilador`
* `buscar_monedas_pantalon`
* `reiniciar_router`

## StatusEffectDef

File:

* `scripts/defs/status_effect_def.gd`

Fields:

* `id`
* `display_name`
* `description`
* `display_name_es`
* `description_es`
* `duration`
* `stacking_rule`
* `effect_values`
* `visual_key`

MVP effects:

* `slow`
* `wet`
* `mark`
* `armor_break`
* `silence_like`
