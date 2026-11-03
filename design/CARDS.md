# Cards — working draft

Status: **in discussion.** Agreed items are marked ✅; everything else is a draft to react to. Names are placeholders.

## Principles ✅

- **Nothing harms enemies or shortens their lifetime.** Cards help you escape: survive, move, control pursuit, scale your abilities, get richer. Never "fight by other means".
- **Flat values by default; % effects are special** (mostly T3), so stacking five cards stays readable and bounded.
- **Cards are named by rank and suit** (4♥, Q♣), so anyone can track them without learning names.
- **Internal cooldowns are good:** they create moments (an empowered cast every minute, a burst at low HP).
- **Generic first:** cards work for any character. Character-specific cards may come later as explicit swaps.

## Structure ✅

| Tier | Ranks | Count | Role | How you get them |
|---|---|---|---|---|
| T1 | 2–6 | 20 | Flat stats | Chests (common). Every pickup also gives gold. |
| T2 | 7–10 | 16 | Effects | Chests (rare), safehouse recipes |
| T3 | J, Q, K | 12 | Strong effects | Safehouse recipes only |
| Aces | A | 4 | Consumables (see below) | Chests |
| Jokers | — | — | Stand in for any one recipe ingredient (recipe costs more gold) | Chests (rare) |

- **5 card slots.** Picking up a card opens the inventory: swap, rearrange or discard.
- **Recipes** are fixed per card (learnable, like League's item tree). Draft rule: exact cards, where at least one ingredient must be of a given suit. The safehouse offers a random few recipes each visit, so holding components for one that may appear is the core decision.
- **Set bonuses** for several cards of one suit (thresholds TBD).

## Suits ✅

| Suit | Family |
|---|---|
| ♥ Hearts | Survivability |
| ♦ Diamonds | Wealth scaling |
| ♣ Clubs | Will (ability power) and control moments |
| ♠ Spades | Mobility, including cooldowns |

## T1 — flat stats (2–6)

Base values for scale: 400 HP, 8 m/s move speed, 10 Will.

| Rank | ♥ Hearts | ♦ Diamonds | ♣ Clubs | ♠ Spades |
|---|---|---|---|---|
| 2 | +4 armour | +2 gold per pickup | +2 Will | +0.2 m/s |
| 3 | +4 elemental resist | −5 gold on recipes | +3 Will | −0.4 s on all cooldowns |
| 4 | +25 max HP | +3 gold per pickup | +4 Will | +0.3 m/s |
| 5 | +1 HP/s regen when not hit for 3 s | +4 gold interest at each safehouse | +5 Will | −0.6 s on all cooldowns |
| 6 | +35 max HP, +3 armour | +3 gold per pickup, −5 on recipes | +6 Will | +0.3 m/s, −0.3 s cooldowns |

## T2 / T3 — Hearts ♥

| Card | Effect |
|---|---|
| 7♥ | **Crystal Skin:** each health crystal grants +6 armour until the end of the level. *(yours)* |
| 8♥ | *(draft)* **Bracing:** taking a hit grants +15 armour for 2 s (8 s cooldown). |
| 9♥ | *(draft)* **Vital Bloom:** health crystals heal 50 extra HP. |
| 10♥ | *(draft)* **Second Wind:** once per level, a lethal hit leaves you at 1 HP with 1.5 s invulnerability. |
| J♥ | **Aegis:** block 3 hits; each health crystal refreshes one. Recipe could use 7♥. *(yours)* |
| Q♥ | **Blood Pact:** strong passive HP regen, but every ability cast costs HP. *(yours)* |
| K♥ | *(draft)* **Last Stand:** dropping below 25% HP freezes every enemy on screen for 2 s (60 s cooldown). |

## T2 / T3 — Spades ♠

| Card | Effect |
|---|---|
| 7♠ | **Flight Response:** reaching low HP gives a big speed burst (long cooldown). Recipe needs a ♥. *(yours)* |
| 8♠ | **Reset:** every 45 s, your next non-ultimate cooldown resets the moment it's used. *(yours)* |
| 9♠ | *(draft)* **Momentum:** after any movement ability, +1.5 m/s for 2 s. |
| 10♠ | *(draft)* **Second Step:** your first ability slot holds a second charge. |
| J♠ | **In the Thick of It:** +move speed and armour for each enemy within 4 m (cap 5 enemies). *(yours)* |
| Q♠ | *(draft)* **Phase:** after any ability, pass through enemies and their projectiles for 1 s. |
| K♠ | *(draft)* **Slipstream:** moving without stopping for 2 s grants +20% move speed until you stop. |

## T2 / T3 — Clubs ♣

| Card | Effect |
|---|---|
| 7♣ | **Patience:** every 60 s, your next ability cast has double Will. *(yours)* |
| 8♣ | **Alchemy:** using an Ace grants +8 Will for 10 s. *(yours)* |
| 9♣ | **Desperation:** the lower your HP, the higher your Will (up to +12 near death). *(yours)* |
| 10♣ | **Dilation:** enemy projectiles within 5 m of you fly 40% slower, and ranged enemies near you take 30% longer to wind up. Melee is unaffected. *(yours)* |
| J♣ | **Oathbound:** your R (ultimate) is disabled, but you gain +60% Will. *(yours)* |
| Q♣ | **Lingering:** everything your abilities create lasts 30% longer — buffs, decoys, slows, stuns. |
| K♣ | **Crown** *(placeholder)*: +15 Will and +40% Will. The big "ability power" item. |

## T2 / T3 — Diamonds ♦ *(partly draft)*

| Card | Effect |
|---|---|
| 7♦ | **Compound:** +8 gold interest at each safehouse. |
| 8♦ | **Apothecary:** picking up an Ace grants double the stacks. *(yours)* |
| 9♦ | **Hoard:** +1 armour per 25 gold held (cap +20). |
| 10♦ | **Hazard Pay:** every minute survived pays gold, scaling with threat. |
| J♦ | **Midas:** +1 Will per 20 gold held. |
| Q♦ | **Patron:** the safehouse offers one extra recipe; your first reroll each visit is free. |
| K♦ | **Absorb:** when you find a T1 card you may consume it instead of picking it up; its flat stats are permanently added to this card. *(yours)* |

## Aces — consumables ✅ (effects draft)

- Occupy a card slot, **stack up to 3** in that slot.
- **Controls:** PC keys 1–4 use ace stacks in slot order. Gamepad: D-pad cycles the selected ace, Circle/B uses it. Touch: a compact ace widget near the ability sticks (tap to cycle) with a Use button.

| Ace | Effect |
|---|---|
| A♥ | **Recover:** heal all damage taken in the last 1.5 s, as a heal over 6 s. Big value after a big hit; worthless after chip damage. *(yours)* |
| A♠ | **Slow Time:** every enemy and enemy projectile slows by 50% for 3 s. *(yours; numbers draft)* |
| A♣ | **Flurry:** for the next 5 s, your next 4 ability casts each have only a flat 0.2 s cooldown. *(yours)* |
| A♦ | **Upgrade:** used on the card pickup screen: reroll the offered card into one a rank higher. *(yours)* |

## Open questions

- Recipe rule details: ingredients per T2 / T3, suit requirements, gold prices, joker surcharge.
- Set bonus thresholds and effects.
- Do T2s drop from chests, and how rarely?
