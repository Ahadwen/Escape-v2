# Cards — working draft

Status: **in discussion.** *(yours)* = your idea, *(draft)* = mine, ⚠ = flagged. Names are placeholders.

## Principles ✅

- **Nothing harms enemies or shortens their lifetime.** Cards help you escape: survive, move, control pursuit, scale your abilities, get richer.
- **Flat values by default; % effects are special** (mostly T3).
- **Every card has stats** (League-style): T1 is stats only; T2 and T3 have stats *and* an effect, unless decided otherwise case by case.
- **Cards are named by rank and suit** (4♥, Q♣).
- **Internal cooldowns are good**: they create moments.
- **Generic first:** cards work for any character.

## Stat rules ✅

| Stat | How it works |
|---|---|
| Armour | Physical damage × 100 / (100 + armour). 30 armour = −23%, 60 = −37.5%, 100 = −50%: each point is worth less than the last. |
| Elemental resist | Same curve, for elemental damage. |
| Ability haste | Cooldowns × 100 / (100 + haste). 20 haste = −17%, 50 = −33%, 100 = −50%. Never reaches instant casting. |
| Move speed | Flat m/s (base 8). |
| Will | Flat (base 10). Scales what abilities do. |

## Structure ✅

| Tier | Ranks | Count | Role | How you get them |
|---|---|---|---|---|
| T1 | 2–6 | 20 | Stats | Chests (common). Every pickup also gives gold. |
| T2 | 7–10 | 16 | Stats + effect | Chests (rare), safehouse recipes |
| T3 | J, Q, K | 12 | Stats + strong effect | Safehouse recipes only |
| Aces | A | 4 | Consumables, stack in one slot | Chests |
| Jokers | — | — | Wildcard recipe ingredient (recipe costs more gold) | Chests (rare) |

**Deck (V1 format, no set bonuses):** 13 slots, one per rank (A, 2 ... K), each holding only a card of that rank (any suit), plus a **3-slot backpack** for spares (any card, jokers included). Only cards in rank slots are active; the Ace slot's Ace is the one you use. One of each card: chests and the trader never give you a card you already hold (Aces stack). Picking up a card **pauses the game** and opens the deck (equip, swap, rearrange, discard).

**Recipes:** T2 = two T1s of its suit + one T1 of a partner suit, plus gold. T3 = two T2s + one T1 (suits case by case), plus more gold. You must hold the components (or a wildcard: a joker at +50% gold each, or the Q♦ Forger wildcard).

**Safehouse lobby:** a small walkable scene between levels with a **shop** (lists every recipe you can complete right now, plus greyed-out near misses one card short; no rerolls), a **trader** (a few offers to swap one of your cards for one of the same or one-higher rank, never T3; reroll for gold), and the **exit door** to the next level.

**Chests drop Ace to 10** (T2s rarer than T1s); J/Q/K come from recipes only. **No set bonuses for now.**

**Gold:** every amount lives in one economy data file, expressed against a base unit, so the economy can be designed and scaled as a whole later.

## T1 — stats (2–6)

| Rank | ♥ Hearts | ♦ Diamonds | ♣ Clubs | ♠ Spades |
|---|---|---|---|---|
| 2 | +4 armour | +2 gold per pickup | +2 Will | +0.2 m/s |
| 3 | +4 elemental resist | −5 gold on recipes | +3 Will | +8 ability haste |
| 4 | +25 max HP | +10 gold at the start of each level | +4 Will | +0.3 m/s |
| 5 | +1 HP/s regen after 3 s without being hit | +4 gold per health crystal | +5 Will | +12 ability haste |
| 6 | +35 max HP, +3 armour | +3 gold per pickup, −5 on recipes | +6 Will | +0.3 m/s, +6 ability haste |

## ♥ Hearts — survivability

| Card | Stats | Effect |
|---|---|---|
| 7♥ | +6 armour | **Crystal Skin:** each health crystal grants +6 armour until the end of the level. *(yours)* |
| 8♥ | +30 max HP | **Bracing:** taking a hit grants +15 armour for 2 s (8 s cooldown). |
| 9♥ | +30 max HP | **Vital Bloom:** health crystals heal 50 extra HP. |
| 10♥ | +6 armour, +6 resist | **Second Wind:** once per level, a lethal hit leaves you at 1 HP with 1.5 s invulnerability. |
| J♥ | +40 max HP | **Aegis:** block 3 hits; each health crystal refreshes one. *(yours)* |
| Q♥ | +40 max HP | **Blood Pact:** strong passive regen, paused for 3 s after taking damage — restores you in downtime or while dodging well. Every ability cast costs HP (spell costs don't pause the regen). *(yours)* |
| K♥ | +8 armour, +8 resist | **Bulwark:** a shield in an 80° cone in front of you blocks hits coming from that direction; enemy projectiles that hit it are destroyed. *(from V1)* |

## ♠ Spades — mobility and ability haste

| Card | Stats | Effect |
|---|---|---|
| 7♠ | +0.3 m/s | **Flight Response:** reaching low HP gives a big speed burst (long cooldown). *(yours)* |
| 8♠ | +10 ability haste | **Perfect Timing:** casting an ability within 0.3 s of its cooldown finishing gives a short speed burst (doesn't count for K♠ Ghostwalk). *(yours)* |
| 9♠ | +0.3 m/s | **Momentum:** after any movement ability, +1.5 m/s for 2 s. |
| 10♠ | +10 ability haste | **Free Cast:** once a minute, a non-ultimate ability doesn't trigger its cooldown. *(yours)* |
| J♠ | +0.4 m/s | **In the Thick of It:** +move speed and armour for each enemy within 4 m (cap 5). *(yours)* |
| Q♠ | +15 ability haste | **Phase:** when an ability's active part ends (e.g. after the Knight's parry window), pass through enemies and their projectiles for 1 s. |
| K♠ | +0.4 m/s, +10 haste | **Ghostwalk:** while any active speed boost is running (from abilities or Aces), you pass through walls. When it ends inside an obstacle, you dash to the nearest walkable spot. *(yours)* |

## ♣ Clubs — Will and control moments

| Card | Stats | Effect |
|---|---|---|
| 7♣ | +5 Will | **Patience:** every 60 s, your next ability cast has double Will. *(yours)* |
| 8♣ | +5 Will | **Alchemy:** using an Ace grants +8 Will for 10 s. *(yours)* |
| 9♣ | +5 Will | **Desperation:** the lower your HP, the higher your Will (up to +12 near death). *(yours)* |
| 10♣ | +6 Will | **Dilation:** within 5 m, enemy projectiles fly 40% slower and ranged wind-ups take 30% longer. Melee unaffected. *(yours)* |
| J♣ | +8 Will | **Oathbound:** your R (ultimate) is disabled, but you gain +60% Will. *(yours)* |
| Q♣ | +8 Will | **Lingering:** everything your abilities create lasts 30% longer — buffs, decoys, slows, stuns. |
| K♣ | +15 Will | **Crown** *(placeholder)*: +40% Will. |

## ♦ Diamonds — wealth scaling

| Card | Stats | Effect |
|---|---|---|
| 7♦ | +4 gold per pickup | **Compound:** +8 gold interest at each safehouse. |
| 8♦ | +4 gold per pickup | **Apothecary:** picking up an Ace grants double the stacks. *(yours)* |
| 9♦ | +4 armour | **Hoard:** +1 armour per 25 gold held (cap +20). |
| 10♦ | +4 gold per pickup | **Hazard Pay:** every minute survived pays gold, scaling with threat. |
| J♦ | −10 gold on recipes, +5 gold per pickup | **Patron:** the safehouse trader offers one extra trade, and your first trader reroll each visit is free. |
| Q♦ | −10 gold on recipes | **Forger:** once per safehouse visit, one of your cards may stand in as a wildcard ingredient for a recipe. *(yours)* |
| K♦ | — (grows) | **Absorb:** when you find a T1 card you may consume it instead of picking it up; its flat stats are permanently added to this card. *(yours)* |

## Aces — consumables ✅

Occupy a card slot and **stack without limit** in it. PC keys 1–4 use ace stacks in slot order; gamepad D-pad cycles and Circle/B uses; touch has a compact ace widget (tap to cycle) with a Use button.

| Ace | Effect |
|---|---|
| A♥ | **Recover:** heal all damage taken in the last 1.5 s, as a heal over 6 s. *(yours)* |
| A♠ | **Slow Time:** every enemy and enemy projectile slows by 30% for 3 s. *(yours)* |
| A♣ | **Flurry:** for the next 5 s, your next 4 ability casts each have only a flat 0.2 s cooldown. *(yours)* |
| A♦ | **Upgrade:** used on the card pickup screen: reroll the offered card into one a rank higher. *(yours)* |

## Recipes

Recipes name **tiers and suits**, any rank within the tier (T1 = 2–6, T2 = 7–10). A **T2** is two T1s of its own suit plus one T1 of a partner suit chosen by theme (each suit's four T2s use the four partners, its own included). A **T3** is two T2s plus one T1, suits chosen card by card (Kings: a T2 and a T1 of their own suit plus a guest T2). Jokers and the Q♦ Forger wildcard can stand in for any ingredient. Prices at the current economy; jokers +50% each.

| Card | Recipe | Price |
|---|---|---|
| 7♥ | 2× T1 ♥ + 1× T1 ♦ | 40 g |
| 8♥ | 3× T1 ♥ | 40 g |
| 9♥ | 2× T1 ♥ + 1× T1 ♣ | 40 g |
| 10♥ | 2× T1 ♥ + 1× T1 ♠ | 40 g |
| 7♦ | 3× T1 ♦ | 40 g |
| 8♦ | 2× T1 ♦ + 1× T1 ♣ | 40 g |
| 9♦ | 2× T1 ♦ + 1× T1 ♥ | 40 g |
| 10♦ | 2× T1 ♦ + 1× T1 ♠ | 40 g |
| 7♣ | 3× T1 ♣ | 40 g |
| 8♣ | 2× T1 ♣ + 1× T1 ♦ | 40 g |
| 9♣ | 2× T1 ♣ + 1× T1 ♥ | 40 g |
| 10♣ | 2× T1 ♣ + 1× T1 ♠ | 40 g |
| 7♠ | 2× T1 ♠ + 1× T1 ♥ | 40 g |
| 8♠ | 2× T1 ♠ + 1× T1 ♣ | 40 g |
| 9♠ | 3× T1 ♠ | 40 g |
| 10♠ | 2× T1 ♠ + 1× T1 ♦ | 40 g |
| J♥ | 2× T2 ♥ + 1× T1 ♣ | 100 g |
| Q♥ | 1× T2 ♥ + 1× T2 ♠ + 1× T1 ♥ | 100 g |
| K♥ | 1× T2 ♥ + 1× T2 ♣ + 1× T1 ♥ | 100 g |
| J♦ | 2× T2 ♦ + 1× T1 ♣ | 100 g |
| Q♦ | 1× T2 ♦ + 1× T2 ♣ + 1× T1 ♦ | 100 g |
| K♦ | 1× T2 ♦ + 1× T2 ♠ + 1× T1 ♦ | 100 g |
| J♣ | 2× T2 ♣ + 1× T1 ♠ | 100 g |
| Q♣ | 1× T2 ♣ + 1× T2 ♠ + 1× T1 ♣ | 100 g |
| K♣ | 1× T2 ♣ + 1× T2 ♥ + 1× T1 ♣ | 100 g |
| J♠ | 2× T2 ♠ + 1× T1 ♥ | 100 g |
| Q♠ | 2× T2 ♠ + 1× T1 ♣ | 100 g |
| K♠ | 1× T2 ♠ + 1× T2 ♣ + 1× T1 ♠ | 100 g |

## Open questions

- The gold economy as a whole (sources, sinks, prices, scaling).
- Set bonuses — later.
- Character-specific cards — later.
