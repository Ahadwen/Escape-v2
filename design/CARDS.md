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

5 card slots. Recipes are fixed per card; the safehouse offers a random few each visit. Set bonuses TBD.

## T1 — stats (2–6)

| Rank | ♥ Hearts | ♦ Diamonds | ♣ Clubs | ♠ Spades |
|---|---|---|---|---|
| 2 | +4 armour | +2 gold per pickup | +2 Will | +0.2 m/s |
| 3 | +4 elemental resist | −5 gold on recipes | +3 Will | +8 ability haste |
| 4 | +25 max HP | ⚠ *(replace)* | +4 Will | +0.3 m/s |
| 5 | +1 HP/s regen after 3 s without being hit | +4 gold interest at each safehouse | +5 Will | +12 ability haste |
| 6 | +35 max HP, +3 armour | +3 gold per pickup, −5 on recipes | +6 Will | +0.3 m/s, +6 ability haste |

## ♥ Hearts — survivability

| Card | Stats | Effect |
|---|---|---|
| 7♥ | +6 armour | **Crystal Skin:** each health crystal grants +6 armour until the end of the level. *(yours)* |
| 8♥ | +30 max HP | **Bracing:** taking a hit grants +15 armour for 2 s (8 s cooldown). *(draft)* |
| 9♥ | +30 max HP | **Vital Bloom:** health crystals heal 50 extra HP. *(draft)* |
| 10♥ | +6 armour, +6 resist | **Second Wind:** once per level, a lethal hit leaves you at 1 HP with 1.5 s invulnerability. *(draft)* |
| J♥ | +40 max HP | **Aegis:** block 3 hits; each health crystal refreshes one. *(yours)* |
| Q♥ | +40 max HP | **Blood Pact:** strong passive regen, paused for 3 s after taking damage — restores you in downtime or while dodging well. Every ability cast costs HP (spell costs don't pause the regen). *(yours)* |
| K♥ | +8 armour, +8 resist | **Bulwark:** a shield in an 80° cone in front of you blocks hits coming from that direction; enemy projectiles that hit it are destroyed. *(from V1)* |

## ♠ Spades — mobility and ability haste

| Card | Stats | Effect |
|---|---|---|
| 7♠ | +0.3 m/s | **Flight Response:** reaching low HP gives a big speed burst (long cooldown). *(yours)* |
| 8♠ | +10 ability haste | **Perfect Timing:** casting an ability within 0.3 s of its cooldown finishing makes its next cooldown 25% shorter. *(yours; bonus draft)* |
| 9♠ | +0.3 m/s | **Momentum:** after any movement ability, +1.5 m/s for 2 s. *(draft)* |
| 10♠ | +10 ability haste | **Free Cast:** once a minute, a non-ultimate ability doesn't trigger its cooldown. *(yours)* |
| J♠ | +0.4 m/s | **In the Thick of It:** +move speed and armour for each enemy within 4 m (cap 5). *(yours)* |
| Q♠ | +15 ability haste | **Phase:** after any ability, pass through enemies and their projectiles for 1 s. *(draft)* |
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
| 7♦ | +4 gold per pickup | ⚠ **Compound:** +8 gold interest at each safehouse. *(draft — overlaps 5♦)* |
| 8♦ | +4 gold per pickup | ⚠ *(replace)* |
| 9♦ | +4 armour | **Hoard:** +1 armour per 25 gold held (cap +20). *(draft)* |
| 10♦ | +4 gold per pickup | **Hazard Pay:** every minute survived pays gold, scaling with threat. *(draft)* |
| J♦ | −10 gold on recipes | **Patron:** the safehouse offers one extra recipe; your first reroll each visit is free. *(draft)* |
| Q♦ | −10 gold on recipes | **Forger:** once per safehouse visit, one of your cards may stand in as a wildcard ingredient for a recipe. *(yours)* |
| K♦ | — (grows) | **Absorb:** when you find a T1 card you may consume it instead of picking it up; its flat stats are permanently added to this card. *(yours)* |

## Aces — consumables ✅

Occupy a card slot and **stack up to 3** in it. PC keys 1–4 use ace stacks in slot order; gamepad D-pad cycles and Circle/B uses; touch has a compact ace widget (tap to cycle) with a Use button.

| Ace | Effect |
|---|---|
| A♥ | **Recover:** heal all damage taken in the last 1.5 s, as a heal over 6 s. *(yours)* |
| A♠ | **Slow Time:** every enemy and enemy projectile slows by 50% for 3 s. *(yours; numbers draft)* |
| A♣ | **Flurry:** for the next 5 s, your next 4 ability casts each have only a flat 0.2 s cooldown. *(yours)* |
| A♦ | **Upgrade:** used on the card pickup screen: reroll the offered card into one a rank higher. *(yours)* |

## Open questions

- ⚠ 4♦, 7♦, 8♦.
- Recipe rule details: ingredients per T2 / T3, suit requirements, gold prices, joker surcharge.
- Set bonus thresholds and effects.
- Do T2s drop from chests, and how rarely?
- K♦ Absorb: capped or uncapped? (Leaning uncapped since T1 stats are small and flat.)
