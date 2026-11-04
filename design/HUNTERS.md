# Hunters — working draft

Status: **all nine hunters implemented** (first pass); numbers live in `enemies/data/hunters/*.tres` and the roster in `director/data/hunt.tres`.

## Principles

- **Few but strong.** A handful of hunters with real kits, not a swarm. Feels like being hunted through the jungle at low HP.
- **Finesse and fairness.** Every attack has a clear tell and can be dodged; cooldowns are the player's windows to escape.
- **A rotating cast.** Each hunter stays on the hunt for a while, then breaks off and another arrives.
- **Terrain matters.** Hunters always know where you are, but must path around walls, so terrain is how you make distance; cover blocks their shots.
- **Nothing can be killed** (core rule): hunters leave, they don't die.

## Pursuit rule — you can't outrun them forever

Running in a straight line must never be a strategy, but speed should still help.

1. **Hunters always know where you are.** No searching or losing you.
2. **Walls are how you make distance:** hunters path around obstacles, so going over or through somewhere they can't follow directly (blink, Ghostwalk) gains real ground.
3. **Line of sight matters for their ranged attacks:** the Trapper and Gunslinger need a clear shot, so cover protects you from them (the Artillerist's beam ignores walls).
4. **Hunters have their own speed, faster than your base,** and **never drop below your sustained speed + ~10%** (base + permanent card bonuses). Speed cards slow how fast you're closed down and help you keep the space your abilities make, but never let you outrun a hunter indefinitely.
5. **Temporary bursts aren't matched** (blink, parry boost, charge, A♠, Momentum…), so they open real distance.
6. **Every ability commits them:** wind-ups, recoveries and reloads slow or stop them. Dodge, then gain ground during the recovery.
7. **Their time on the hunt runs out:** you outlast hunters, you don't beat them.

## The hunt (director)

| Rule | Draft |
|---|---|
| On the field | 2 at the start of a level, rising to 4–5 at high threat |
| Time on the hunt | 30–60 s each, then a visible break-off and despawn |
| Rotation | When one leaves, another is drawn from the roster (weighted, no immediate repeats) |
| Threat | More hunters at once, nastier combinations, shorter cooldowns — not more bodies |
| Unlocks | Each hunter has a threat window it can appear in (the Shambler's closes early) |

## Roster

### Shambler — the fundamentals
Like Hades II's basic shambler. Walks at you and strikes. Teaches telegraphs and spacing, then **drops out of the spawn pool quickly** as threat rises.
- **Strike:** short wind-up, short-range cone in front of it.

### Brute — Sion / Sejuani
- **Charge:** long, telegraphed rush in a line; **stuns** on contact.
- **Slam:** when you're close, a telegraphed area slam that **knocks up / stuns** briefly.

### Spinner — the murder beyblade (reworked)
Larger and much faster than now, with real momentum.
- **Zoom:** accelerates hard in a straight line toward you, carries on well past, decelerates with momentum; **steers with a poor turning circle** while zooming (it can curve after you, but not turn sharply).
- **Re-aim:** after slowing, wobbles briefly, re-aims, and zooms again.
- **Contact:** damage + knockback.

### Harpooner — Blitzcrank
Nobody's favourite, but it raises the stakes.
- Ranged only, no melee. Doesn't tailgate you: holds 7–12 m while it can see you, backs off if you get close, and chases around walls to get a clear shot.
- **Hook:** wide, fast skillshot with a short wind-up and a line warning. If it hits, you're damaged, **pulled** to it (and toward whoever else is hunting you) and briefly stunned. Breaking line of sight is the counter.

### Assassin — Kha'Zix / Rengar / Evelynn
- **Vanish:** fades out (a faint shimmer) and closes in unseen.
- **Sequence:** reappears close and performs a **three-strike sequence**, each strike with its own short-range indicator (cones / lines in different directions), so you need three good dodges in a row.
- Then retreats and vanishes again.

### Trapper — a fast sniper
- **Reposition:** moves fast between spots where it has line of sight to you, at range.
- **Shot:** whenever it has line of sight: a brief aim line, then a fast shot.
- **Traps:** wherever the shot lands — on you or a wall — **three traps scatter** around the impact. Stepping on one **immobilises** you briefly. Traps are visible and expire.

### Artillerist — Xerath, with an escape
Keeps long range, and won't let you just run it down.
- **Beam:** a long, wide laser that **ignores walls**, with a clear charge-up line.
- **Barrage:** marks a **cluster of circles** on the floor around you; they detonate in sequence — find the safe spots between them while dealing with everything else.
- **Displace:** if you get too close, it **interrupts what it's doing and teleports** to a set distance away (cooldown).

### Gunslinger — Jhin / Graves
- **Runs alongside:** matches your pace at medium range, off to one side.
- **Salvo:** five shots in rhythm; the **fifth is stronger** (bigger, faster, its own tell).
- **Reload:** a visible pause after the salvo — your window.

### Broodmother — Elise / Zyra
- Slow; keeps her distance.
- **Swarm:** a telegraphed burst of short-lived mites that rush you, on a long cooldown — the swarm is a moment, not the background.
- **Web:** short-range skillshot that **slows** you so the swarm can catch up.

## Crowd control on the player

Several hunters can stun, root, pull or slow you. Durations stay short (0.5–1.2 s) so it's punishing but readable, and it gives the Knight's parry, blink and charge more reason to exist.

## Open questions

- Field size and time-on-hunt numbers.
- CC durations — and whether the parry should be able to break or block CC.
- Zone variants for each hunter (Inferno versions).
- Fate of the current roster: Chaser → Shambler? Charger → Brute? Gunner / Laser / Artillery / Brood → folded into the new kits?
