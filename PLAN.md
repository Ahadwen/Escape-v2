# Escape — Project Plan

## 1. Vision

A top-down isometric roguelike where **you cannot fight back**. Enemies can't be killed — only outmanoeuvred. You survive using movement, terrain, and four character abilities (mobility, defence, and crowd control) until each enemy's timer runs out and it despawns.

Each level is **infinite, procedurally generated terrain** that streams in around the player, and its **threat rises steadily over time**. Safehouses aren't marked: finding one is a discovery. Finding a safehouse poses the core question: *enter now and move on, or keep exploring for loot while the level gets more dangerous?*

**Run structure:** Nexus (pick character, meta upgrades) → Level 1 → Safehouse → Level 2 → … → Level 5 → win. Death returns you to the Nexus.

**Zones:** Every level is procedurally generated. Level 1 always uses the same neutral theme (stone paths and grass). Each run then drifts toward one randomly chosen **destination zone**, such as Inferno, Swamp or Graveyard. Levels 2–4 are progressively more zone-like, and level 5 is fully in the zone.

## 2. Core rules (decided)

| Topic | Rule |
|---|---|
| Combat | The player has no damage output. Abilities may affect enemies (slow, stun, root, knockback, blind, decoy/taunt, etc.) but never kill them. |
| Enemies | Each enemy spawns with its **own lifetime** and despawns when it expires (with a visible tell shortly before). |
| Threat | Driven by **time** in the level. Resets at the start of each level. |
| Difficulty curve | Each level starts at a higher baseline and ramps faster than the last, **but** the start of level N+1 is noticeably easier than the end of level N — lingering is always punished, moving on is a relief. |
| Safehouse | Entering a safehouse **ends the level**: enemies are gone, threat stops, the player can spend gold, then proceeds to the next level. You can't go back out. |
| Between levels | HP is fully restored. Items and gold carry over. |
| Death | Items and gold for the run are lost. Meta-progression (TBD) persists. |
| Zones | Every level is procedurally generated. Level 1 always uses the neutral theme. Levels 2–5 blend toward the run's destination zone, picked at random when the run starts, with increasing intensity: environment, hazards, zone-exclusive enemies, and zone variants of shared enemies. |
| Health crystals | Restore a % of max HP. |
| Chests | Contain items and/or gold. |

## 3. Player stats

- **HP** (max / current) — starts at 400
- **Move speed**
- **Will** — ability power; scales ability strength (duration, distance, slow %, shield size…)
- **Armour** — mitigates physical damage
- **Elemental resistance** — mitigates elemental damage
- **Character-specific resource pools** (mana, rage, …) — extendable; defined per character as data

## 4. Starting character — The Knight (working name)

A simple, readable introductory kit: one displacement ability, one buff, one aggro tool, and one escape button. **Cooldowns only — no resource.** Later characters get more complex kits and resource pools.

| Slot | Ability | Behaviour | Scaling |
|---|---|---|---|
| **Q** | **Blink** | Instant teleport in the aimed direction (`DIRECTION`), passing over walls. If the aimed spot is inside an obstacle, lands on whichever side is closer along the blink line. | Range scales a little with **Will**. The landing scales with **current HP**: above 50% HP, landing produces a shockwave (knockback + slow) whose radius and strength grow with HP. |
| **W** | **Rally** (move-speed steroid) | Timed self-buff adding a move-speed modifier. Will → speed amount; fixed duration (~3s). |
| **E** | **Decoy** | Places a decoy (`POINT`) with a high-priority `Targetable` that draws enemy aggro and absorbs hits until destroyed. | Decoy HP scales with **Will**. |
| **R** | **Unstoppable Charge** | Invulnerable while charging forward, gaining speed over time; steerable with a limited turn rate; ends on collision with terrain or an enemy (impact knocks enemies back), or after a max duration (~3s). No early recast. | None for now. |

All numbers above are placeholder defaults to get something playable; they live in `.tres` data and will be tuned in playtesting.

Systems this character proves out (good reason to build her first):

- `StatScaling` on two different stats (Will and HP) within one ability.
- Movement override (Q and R), status effects on enemies (Q shockwave), invulnerability as a status (R).
- A timed buff via stat modifiers (W).
- Spawning an ally entity with its own HP and aggro (E), which forces enemy AI to target `Targetable`s rather than the player.
- A sustained, steerable ability (R) that has to work on all three control schemes.

## 5. Controls

Three control schemes, all mapped to the same abstract action list. Abilities are owned by the character, not by the control scheme.

| | Move | Aim | Abilities 1–4 |
|---|---|---|---|
| **PC** (primary) | Right-click to move | Mouse cursor | Q / W / E / R |
| **Gamepad** | Left stick | Right stick | LT / RT / LB / RB (remappable) |
| **Mobile** | Left virtual stick | Drag on the ability stick | Four small ability sticks on the right (drag to aim, release to cast, tap to quick-cast, cancel zone) |

PC is the development and first-release target. Gamepad and touch are accounted for in the architecture from day one so they're not bolted on later.

## 6. Technical decisions

| Decision | Choice | Why |
|---|---|---|
| Engine | Godot 4.7, Jolt physics | Already set up in this repo |
| Language | GDScript with static typing (warnings as errors for untyped code) | Fast iteration, best editor integration |
| View | **3D** with an angled orthographic camera | Real lighting/shadows/VFX later; easy click-to-move raycasts; no depth-sorting headaches |
| Renderer | Forward+ on PC; Mobile renderer for phone exports | |
| Art (for now) | Geometric primitives (capsules, boxes, cylinders) with flat colour materials | Prettify once the game works |
| Pathfinding | NavigationServer3D; navmesh baked at runtime after level generation | Needed for click-to-move and enemy chasing |
| Testing | Small built-in headless runner (`tests/run_tests.gd`) for pure logic: stats, damage, threat curve, generation | No addon dependency; can move to GdUnit4 later if we need mocking or scene testing |

## 7. Architecture

Guiding rule: **each domain communicates through narrow interfaces — data Resources, signals, and intent objects — never by reaching into another domain's internals.** Gameplay data lives in `.tres` Resources so content is added as data, not code.

### 7.1 Input: device → actions → intents → controller

```
[Device]          [Actions (InputMap)]       [Intents]                 [Gameplay]
Mouse/KB   ─┐     move_to, move_axis,        MoveToPoint(pos)          PlayerController
Gamepad    ─┼──▶  aim_axis, ability_1..4, ─▶ MoveDirection(vec)    ─▶  moves the actor and
Touch UI   ─┘     cancel, interact           CastAbility(slot, aim)    asks AbilitySlot[n] to cast
```

- **InputMap actions** are the single list of inputs; device bindings hang off them (and are remappable).
- **Input schemes** (`PCInputScheme`, `GamepadInputScheme`, `TouchInputScheme`) translate actions into intents. Only schemes know about devices.
- **`InputRouter`** detects the last-used device, activates the matching scheme, and shows/hides touch UI.
- **Steering**: while a sustained ability is active (e.g. a steerable charge), the active scheme keeps emitting `AimUpdate(vec)` intents (cursor direction / right stick / held ability stick), and the ability reads them.
- **Targeting types** decouple abilities from devices. Each ability declares one of `SELF`, `DIRECTION`, `POINT` (with range), `NONE`; each scheme knows how to produce aim data for each type (cursor / right stick / stick drag) and how to draw the aim indicator.

### 7.2 Characters & abilities

- **`CharacterData`** (Resource): name, model, base stats, 4 `AbilityData`, list of resource pools.
- **`AbilityData`** (Resource): id, icon, targeting type, range, cooldown, cost (pool id + amount), tags, behaviour.
- **`AbilityBehaviour`**: the logic (dash, blink, decoy, slow field, shield, knockback…). Receives a `CastContext` (caster, aim, stat snapshot).
- **`AbilitySlot`** ×4 on the player: cooldowns, cost checks, cast requests. Filled from the chosen character at run start.
- **`StatScaling`** (Resource): maps a stat to an ability parameter through a `Curve` or linear coefficient, e.g. `dash_range = base + 0.5 × will`. Abilities declare their scalings as data, so tuning and item effects ("+30% Q range") never touch behaviour code.
- **Movement override**: dashes, charges and knockbacks ask the actor's movement component for a temporary `MovementOverride` (own velocity, collision response, end condition). Normal movement intents are ignored until it ends. Every displacement ability uses this, so there's one source of truth for "who is moving the actor right now".
- **Ability phases**: an ability can be instant, timed (buff), or sustained (runs until an end condition). The slot tracks the phase so the HUD and input schemes know when an ability is "in progress".

### 7.3 Stats, resources, damage, status effects

- **`StatId`**: extendable set (`max_hp`, `move_speed`, `will`, `armour`, `elemental_resist`, …).
- **`StatBlock`**: base values + `StatModifier`s (flat, % additive, % multiplicative, each tagged with a source). Final values cached; emits `stat_changed`. Items, buffs, and meta upgrades only ever add/remove modifiers.
- **`ResourcePool`**: generic current/max/regen. HP is a pool; mana and rage are pools. New resource types are data.
- **Damage pipeline**: enemy attack → `DamageEvent` (amount, `PHYSICAL`/`ELEMENTAL`, source) → `DamageResolver` (armour/resist mitigation, then item hooks) → HP pool. There is deliberately no player-to-enemy damage path.
- **`StatusEffect` system** (shared by player and enemies): slow, stun, root, knockback, blind, taunt, shield, haste… Applied via a `StatusEffectHost` component. Player abilities control enemies through this; enemies can use it on the player too.

### 7.4 Items

- **`ItemData`** (Resource): rarity, price, stat modifiers, tags (`generic`, `character:<id>`, `ability:<id>`), list of `ItemEffect`s.
- **`ItemEffect`**: small script subscribing to gameplay hooks (`on_damage_taken`, `on_ability_cast`, `on_pickup`, `on_level_start`, `on_status_applied`, …). Covers stat items, ability-specific modifiers, and unique passives.
- **`LootTable`**: weighted pools filtered by tags, so character-specific items only drop for that character.

### 7.5 Enemies & threat director

- **`EnemyData`** (Resource): stats, attack definition, behaviour, threat cost, lifetime range.
- **AI**: small state machine — wander → notice → chase → attack → lose interest — on nav agents. Responds to status effects (stunned, taunted, blinded).
- **Targets, not "the player"**: enemies pick targets from a `Targetable` component (with a priority and a faction), never by referencing the player directly. Decoys, and anything else that should draw aggro, simply carry a higher-priority `Targetable` and their own HP pool.
- **Lifetime**: per-enemy timer; telegraphs ~2s before despawning.
- **Archetypes** should create distinct evasion problems: charger (telegraphed dashes), spitter (ranged, dodgeable projectiles), stalker (slow, relentless, ignores lose-interest), area denier (leaves hazards), pack hunters (flank).
- **`ThreatDirector`** (per level): `threat = f(time, level)` from tunable `Curve` resources per level. Threat drives spawn budget, frequency, enemy mix, elite chance, and lifetime. The enemy mix comes from the level's zone-blended pool (see 7.6). Spawns off-screen, near but not on top of the player. Constraint enforced by a test: `threat(level N+1, t=0)` is clearly below `threat(level N, typical exit time)`.

### 7.6 Zones & theming

A zone is pure data, and the rest of the game reads it through a single **`LevelTheme`** computed for each level. No system hard-codes "fire" or "swamp".

- **`ZoneData`** (Resource):
  - **Environment:** palette, lighting/`Environment`, fog, ground and prop materials, and a chunk/prop set for the generator.
  - **Hazards:** environmental hazards, such as lava cracks, bog water that slows or fog that limits vision, each with a density.
  - **Exclusive enemies:** zone-only enemies, each with the intensity at which it starts appearing.
  - **Variants:** `EnemyVariant`s, which are modifiers applied to *shared* enemies (see below).
  - Optionally zone-biased loot. For example, elemental-resist items show up more often in Inferno.
- **`EnemyVariant`** (Resource): layered on top of a base `EnemyData`, so each enemy is defined once. A variant can:
  - add stat modifiers
  - change the damage type, for example physical to elemental
  - add an on-hit status, such as burn, slow or poison
  - add a behaviour, such as leaving a fire trail, reviving once when it despawns or emitting a poison cloud
  - change visuals, such as a material swap, tint or particle attachment

  Example: a base charger becomes a *burning charger* in Inferno (elemental damage, leaves fire on its dash path) or a *bog charger* in Swamp (slower, slows on hit).
- **Intensity:** each level has a zone intensity from 0 to 1. The default is L1 = 0, L2 = 0.25, L3 = 0.5, L4 = 0.75, L5 = 1, and it's tunable. A **`ThemeResolver`** takes the base zone, the destination zone and the intensity and produces the `LevelTheme`:
  - **Generator:** chunks and props are drawn from both zones, weighted by intensity.
  - **Hazard density** scales with intensity.
  - **Enemy pool:** shared enemies get the zone variant with a probability that scales with intensity, and exclusive enemies unlock at their threshold.
  - **Environment:** lighting, fog and colour grading blend from base to zone.
- **Level 1** uses the base zone (`neutral_grasslands`) at intensity 0 every run. That makes it a consistent on-ramp.
- **Destination zone** is picked at random from the run seed when the run starts and stored in `RunState`. It is **not announced**: the player discovers it as the levels shift. Picking it from the seed makes runs reproducible for debugging.

Elemental resistance becomes a strategic stat because of this. Once you know the run is heading into Inferno, you start valuing it.

### 7.7 World & level generation

- **Infinite, streamed terrain.** The world is a grid of chunks generated on demand around the player and freed behind them. Each chunk is generated deterministically from (run seed, level, chunk coordinate), so revisiting an area recreates it identically.
- **`ChunkGenerator`** takes the `LevelTheme` and a chunk coordinate and outputs a **`ChunkLayout`** data object (ground, obstacles, points of interest); a separate **`ChunkBuilder`** instantiates it. Generation is testable without rendering.
- **Navigation per chunk:** each chunk bakes its own navmesh from collision shapes (on a thread), and adjacent chunk navmeshes connect at their shared edges. Proven in M5.
- **Points of interest** are rolled per chunk: health crystals and chests with minimum spacing; safehouses are rare, with their chance rising with distance from the level start (and a guaranteed-eventually rule so a level can't go on forever without one).
- **Discovery, not markers.** Safehouses (and other POIs) aren't shown until the player has seen them — within a reveal radius or line of sight. Once discovered, an off-screen edge indicator points back to them, so the "leave now or push on" choice stays available.
- **Safehouse**: an enterable trigger zone. Entering ends the level and opens the shop screen, then advances to the next level.

### 7.8 Game flow & persistence

- **`GameFlow`** (autoload): Nexus → Level ↔ Safehouse → … → Results → Nexus.
- **`RunState`**: character, items, gold, level index, seed, destination zone. Created at run start, discarded on death or win. HP restored on level start.
- **`MetaProgress`**: persistent save in `user://` (contents TBD).
- **`EventBus`** (autoload): cross-domain events only (`player_died`, `level_completed`, `item_acquired`, `threat_tier_changed`). Local communication uses plain signals.
- Autoloads kept minimal: `GameFlow`, `EventBus`, `Settings`, later `Audio`.

### 7.9 Folder structure

```
res://
  core/         # event bus, game flow, save, settings, shared utilities
  input/        # actions, schemes, router, intents, touch UI widgets, aim indicators
  actors/       # player scene, shared components (movement, health, status host)
  stats/        # StatBlock, modifiers, pools, damage resolver
  status/       # status effect definitions and host
  abilities/    # AbilityData, behaviours, slots, targeting
  characters/   # CharacterData resources (+ character-specific abilities)
  items/        # ItemData, effects, loot tables
  enemies/      # EnemyData, AI states, archetypes
  director/     # ThreatDirector, spawner, threat curves
  zones/        # ZoneData, EnemyVariants, ThemeResolver; one subfolder per zone
  world/        # generator, builder, chunks, POIs (crystal, chest, safehouse)
  nexus/        # hub scene, character select, meta upgrades
  ui/           # HUD, shop, menus
  art/  audio/
  tests/
```

## 8. Milestones

The biggest risk is design, not tech: **is evasion-only fun?** So the core loop gets proven in a hand-built arena before procedural generation and content.

| # | Milestone | Done when |
|---|---|---|
| **M0** ✅ | Foundations | Folder layout, typed-GDScript settings, test framework, InputMap action list, export preset for PC |
| **M1** ✅ | Move & input | Greybox arena, ortho camera, player capsule moves via PC and gamepad schemes; touch scheme working via emulated touch; auto device switching |
| **M2** ✅ | Abilities | 4 slots, targeting types + aim indicators per scheme, cooldowns/costs, `StatScaling`, movement override; the Knight's Q (without shockwave), W and R |
| **M3** ✅ | Enemies & damage | StatBlock, pools, armour/resist, status effects, `Targetable` aggro, 2 archetypes that chase and attack, per-enemy lifetime + despawn tell, player death; Knight's Q shockwave and E decoy |
| **M4** | **Core loop prototype** | ThreatDirector + curve, health crystals, a hidden safehouse that's revealed on discovery and ends the level, discovered-POI edge indicators, HUD (HP, cooldowns, threat, time). Tuned against V1's proven feel |
| **M5** | Infinite terrain | Seeded chunk generation, streaming load/unload around the player, per-chunk navmesh baking and stitching, per-chunk POI rolls (crystals, safehouses), all driven by a `LevelTheme` (base zone only) |
| **M6** | Items & chests | Item data, modifiers, effect hooks, loot tables, gold, 10–15 items |
| **M7** | Run structure & zones | Safehouse shop, 5 levels with escalating curves, HP restore between levels, win/loss screens. Zone framework (ZoneData, EnemyVariant, ThemeResolver, intensity blending) with one greybox destination zone, using colour, a hazard and one variant to prove the blend |
| **M8** | Nexus & meta | Hub scene, character select, save system, meta-upgrade framework |
| **M9** | Art pass | Lighting, materials, VFX, readable telegraphs, UI style on one biome |
| **M10** | Content | 3+ characters, 6+ shared enemy archetypes, 3 destination zones (e.g. Inferno, Swamp, Graveyard), each with exclusives, variants and hazards, 40+ items |
| **M11** | Platforms & polish | Gamepad UI navigation, touch tuning, mobile renderer/perf, remapping, audio, juice |

## 9. Risks

- **Evasion isn't fun** → already proven in V1; the risk is losing V1's feel in the port, so M4 is tuned against it. Enemies must have readable, telegraphed attacks so dodging is skill, not luck.
- **Enemies feel unfair with no counterplay** → crowd-control abilities, despawn tells, and per-enemy lifetimes give the player tools and hope.
- **Navmesh on streamed terrain** → per-chunk threaded bakes with edge connections, and no hitches while chunks load; prove in M5. Enemies near unloaded chunks need a rule (despawn, or keep their chunk alive).
- **Touch/gamepad rot while developing on PC** → all three schemes go through the same intent layer and are exercised every milestone.
- **Mobile performance in 3D** → Mobile renderer, conservative lighting; test on a device before M11.

## 10. Open questions



- Meta-progression contents (Nexus unlocks).
- Number of characters at launch and their identities.
- Enemy damage types per archetype (physical vs elemental mix).
- Shop contents and pricing; can you reroll?
- Is there a final "boss" escape on level 5, or just a last safehouse?
