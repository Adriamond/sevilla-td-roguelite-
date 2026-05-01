# Balance Notes

This document is the source of truth for initial MVP tuning.

## Initial player values

```text
core_hp = 20
start_gold = 140
reward_options = 3
room_charges = 2
sell_value_rounds_1_2 = 0.8
sell_value_after_round_2 = 0.7
round_reward_gold = 45 + 15 * round_index
```

## Scaling formulas

```text
enemy_hp = base_hp * (1 + 0.18 * (round - 1))
enemy_speed = base_speed * (1 + 0.03 * max(0, round - 3))
elite_hp = hp * 2.2
boss_hp = hp * 9.0
defense_upgrade_cost = base_cost * [1.0, 1.6, 2.2][level]
defense_damage = base_damage * (1 + 0.45 * level)
```

## Enemy base stats

| Enemy               |   HP | Speed | Armor | Leak | Role     |
| ------------------- | ---: | ----: | ----: | ---: | -------- |
| tactichandal_runner |   70 |  1.45 |     0 |    1 | rusher   |
| lagrima_negra       |   95 |  0.95 |     0 |    1 | debuffer |
| resonante_bruiser   |  180 |  0.75 |     2 |    2 | tank     |
| clan_loot_summoner  |   85 |  1.05 |     0 |    1 | summoner |
| killo_bulevar_boss  | 1400 |  0.85 |     2 |    5 | boss     |

## Run targets

* MVP run length: 15-18 minutes
* boss time-to-kill with reasonable build: 60-90 seconds
* player should not lose before round 3 due to a single bad early reward
* economy should not allow full map lockdown by round 4

## Reward rules

* Offer 3 rewards after normal rounds.
* Maximum 1 economy item per reward set.
* No high-impact epic items during rounds 1-2 unless explicitly tuned.
* Inject stabilizer option when needed.

## Suspicious balance signals

| Metric                     | Suspicious value                     |
| -------------------------- | ------------------------------------ |
| Item pick rate             | >45% in same context                 |
| Item win rate              | >60% when offered                    |
| One defense damage share   | >45% of total damage in winning runs |
| Unspent gold after round 4 | >120 average                         |
| Leaks in rounds 1-2        | >3 average                           |
| Boss kill time             | <35 seconds in average build         |
| Reward reroll usage        | near 0%                              |
| Room interaction usage     | <15%                                 |

## Testing batches

Manual testing should include:

1. 10 neutral runs
2. 10 greedy economy runs
3. 10 bad early reward runs
4. 5 no-selling runs
5. 5 no-room-interaction runs
6. 5 control-heavy runs
7. 5 damage-heavy runs
