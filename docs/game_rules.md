# Game Rules

## Core loop

Room → build phase → wave → reward → room.

## Win condition

Defeat the boss in round 6 while core hp remains above 0.

## Lose condition

Core hp reaches 0.

## Core HP

The player starts with 20 core hp.

Enemies that reach the end of the path deal leak damage.

## Gold

Gold is used to buy, upgrade and sometimes activate systems.

Sources:

* starting gold
* kills
* elite kills
* round completion
* room interaction outcomes
* item effects

## Building

Defenses may only be built on compatible pads.

Pad categories:

* air
* ground
* wall

Defense categories:

* air
* ground
* wall

A defense can only be placed on a matching pad unless an item or future rule says otherwise.

## Selling

Sell value:

* rounds 1-2: 80%
* round 3 onwards: 70%

## Upgrades

Each defense supports upgrade levels.

Initial model:

* level 0: base
* level 1: first upgrade
* level 2: second upgrade

Upgrade cost formula:

```text
defense_upgrade_cost = base_cost * [1.0, 1.6, 2.2][level]
```

Damage formula:

```text
defense_damage = base_damage * (1 + 0.45 * level)
```

## Status effects

MVP status effects:

* slow
* wet
* mark
* armor_break
* silence_like

### slow

Reduces enemy speed for a duration.

### wet

Marks enemies as vulnerable to electrical or resonance effects.

### mark

Marked enemies can trigger bonus gold or bonus damage depending on source.

### armor_break

Reduces armor temporarily.

### silence_like

Temporarily reduces defense fire rate or disables special attack, depending on implementation.

## Rewards

After each normal round, offer 3 reward options.

The player chooses 1.

Rules:

* max 1 economy item per reward set
* rounds 1-2 should avoid high-impact epic rewards
* reward set may inject a stabilizer option if player lacks key counterplay

## Stabilizer logic

If next round has rushers and player lacks control, inject a control reward.

If next round has armored enemies and player lacks armor break, inject armor break.

If projected DPS is too low, inject raw damage.

## Room interactions

Room interactions happen between rounds.

They modify the next round, current economy or reward selection.

They must be useful but not mandatory.
