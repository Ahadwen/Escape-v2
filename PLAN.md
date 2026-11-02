# Escape — Project Plan

## 1. Vision

A top-down isometric roguelike where **you cannot fight back**. Enemies can't be killed — only outmanoeuvred. You survive using movement, terrain, and four character abilities (mobility, defence, and crowd control) until each enemy's timer runs out and it despawns.

Each level is procedurally generated and its **threat rises steadily over time**. Finding a safehouse poses the core question: *enter now and move on, or keep exploring for loot while the level gets more dangerous?*

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

## 4. Controls

Three control schemes, all mapped to the same abstract action list. Abilities are owned by the character, not by the control scheme.

| | Move | Aim | Abilities 1–4 |
|---|---|---|---|
| **PC** (primary) | Right-click to move | Mouse cursor | Q / W / E / R |
| **Gamepad** | Left stick | Right stick | LT / RT / LB / RB (remappable) |
| **Mobile** | Left virtual stick | Drag on the ability stick | Four small ability sticks on the right (drag to aim, release to cast, tap to quick-cast, cancel zone) |

PC is the development and first-release target. Gamepad and touch are accounted for in the architecture from day one so they're not bolted on later.

## 5. Technical decisions

| Decision | Choice | Why |
|---|---|---|
| Engine | Godot 4.7, Jolt physics | Already set up in this repo |
| Language | GDScript with static typing (warnings as errors for untyped code) | Fast iteration, best editor integration |
| View | **3D** with an angled orthographic camera | Real lighting/shadows/VFX later; easy click-to-move raycasts; no depth-sorting headaches |
| Renderer | Forward+ on PC; Mobile renderer for phone exports | |
| Art (for now) | Geometric primitives (capsules, boxes, cylinders) with flat colour materials | Prettify once the game works |
| Pathfinding | NavigationServer3D; navmesh baked at runtime after level generation | Needed for click-to-move and enemy chasing |
| Testing | GdUnit4 (or GUT) for pure logic: stats, damage, threat curve, generation | |

## 6. Architecture

Guiding rule: **each domain communicates through narrow interfaces — data Resources, signals, and intent objects — never by reaching into another domain's internals.** Gameplay data lives in `.tres` Resources so content is added as data, not code.

### 6.1 Input: device → actions → intents → controller

```
[Device]          [Actions (InputMap)]       [Intents]                 [Gameplay]
Mouse/KB   ─┐     move_to, move_axis,        MoveToPoint(pos)          PlayerController
Gamepad    ─┼──▶  aim_axis, ability_1..4, ─▶ MoveDirection(vec)    ─▶  moves the actor and
Touch UI   ─┘     cancel, interact           CastAbility(slot, aim)    asks AbilitySlot[n] to cast
```

- **InputMap actions** are the single list of inputs; device bindings hang off them (and are remappable).
- **Input schemes** (`PCInputScheme`, `GamepadInputScheme`, `TouchInputScheme`) translate actions into intents. Only schemes know about devices.
- **`InputRouter`** detects the last-used device, activates the matching scheme, and shows/hides touch UI.
- **Targeting types** decouple abilities from devices. Each ability declares one of `SELF`, `DIRECTION`, `POINT` (with range), `NONE`; each scheme knows how to produce aim data for each type (cursor / right stick / stick drag) and how to draw the aim indicator.

### 6.2 Characters & abilities

- **`CharacterData`** (Resource): name, model, base stats, 4 `AbilityData`, list of resource pools.
- **`AbilityData`** (Resource): id, icon, targeting type, range, cooldown, cost (pool id + amount), tags, behaviour.
- **`AbilityBehaviour`**: the logic (dash, blink, decoy, slow field, shield, knockback…). Receives a `CastContext` (caster, aim, stat snapshot).
- **`AbilitySlot`** ×4 on the player: cooldowns, cost checks, cast requests. Filled from the chosen character at run start.

### 6.3 Stats, resources, damage, status effects

- **`StatId`**: extendable set (`max_hp`, `move_speed`, `will`, `armour`, `elemental_resist`, …).
- **`StatBlock`**: base values + `StatModifier`s (flat, % additive, % multiplicative, each tagged with a source). Final values cached; emits `stat_changed`. Items, buffs, and meta upgrades only ever add/remove modifiers.
- **`ResourcePool`**: generic current/max/regen. HP is a pool; mana and rage are pools. New resource types are data.
- **Damage pipeline**: enemy attack → `DamageEvent` (amount, `PHYSICAL`/`ELEMENTAL`, source) → `DamageResolver` (armour/resist mitigation, then item hooks) → HP pool. There is deliberately no player-to-enemy damage path.
- **`StatusEffect` system** (shared by player and enemies): slow, stun, root, knockback, blind, taunt, shield, haste… Applied via a `StatusEffectHost` component. Player abilities control enemies through this; enemies can use it on the player too.

### 6.4 Items

- **`ItemData`** (Resource): rarity, price, stat modifiers, tags (`generic`, `character:<id>`, `ability:<id>`), list of `ItemEffect`s.
- **`ItemEffect`**: small script subscribing to gameplay hooks (`on_damage_taken`, `on_ability_cast`, `on_pickup`, `on_level_start`, `on_status_applied`, …). Covers stat items, ability-specific modifiers, and unique passives.
- **`LootTable`**: weighted pools filtered by tags, so character-specific items only drop for that character.

### 6.5 Enemies & threat director

- **`EnemyData`** (Resource): stats, attack definition, behaviour, threat cost, lifetime range.
- **AI**: small state machine — wander → notice → chase → attack → lose interest — on nav agents. Responds to status effects (stunned, taunted, blinded).
- **Lifetime**: per-enemy timer; telegraphs ~2s before despawning.
- **Archetypes** should create distinct evasion problems: charger (telegraphed dashes), spitter (ranged, dodgeable projectiles), stalker (slow, relentless, ignores lose-interest), area denier (leaves hazards), pack hunters (flank).
- **`ThreatDirector`** (per level): `threat = f(time, level)` from tunable `Curve` resources per level. Threat drives spawn budget, frequency, enemy mix, elite chance, and lifetime. The enemy mix comes from the level's zone-blended pool (see 6.6). Spawns off-screen, near but not on top of the player. Constraint enforced by a test: `threat(level N+1, t=0)` is clearly below `threat(level N, typical exit time)`.

### 6.6 Zones & theming

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
- **Destination zone** is picked at random from the run seed when the run starts and stored in `RunState`. Picking it from the seed makes runs reproducible for debugging.

Elemental resistance becomes a strategic stat because of this. Once you know the run is heading into Inferno, you start valuing it.

### 6.7 World & level generation

- Seeded generator: layout graph → place modular chunks → bake navmesh → place points of interest.
- Takes the `LevelTheme` as input; outputs a **`LevelLayout`** data object; a separate **`LevelBuilder`** instantiates scenes. Generation is testable without rendering.
- POI rules: safehouses far from spawn (1–3 per level); crystals and chests spread with minimum spacing; every POI reachable.
- **Safehouse**: an enterable trigger zone. Entering ends the level and opens the shop screen, then advances to the next level.

### 6.8 Game flow & persistence

- **`GameFlow`** (autoload): Nexus → Level ↔ Safehouse → … → Results → Nexus.
- **`RunState`**: character, items, gold, level index, seed, destination zone. Created at run start, discarded on death or win. HP restored on level start.
- **`MetaProgress`**: persistent save in `user://` (contents TBD).
- **`EventBus`** (autoload): cross-domain events only (`player_died`, `level_completed`, `item_acquired`, `threat_tier_changed`). Local communication uses plain signals.
- Autoloads kept minimal: `GameFlow`, `EventBus`, `Settings`, later `Audio`.

### 6.9 Folder structure

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

## 7. Milestones

The biggest risk is design, not tech: **is evasion-only fun?** So the core loop gets proven in a hand-built arena before procedural generation and content.

| # | Milestone | Done when |
|---|---|---|
| **M0** | Foundations | Folder layout, typed-GDScript settings, test framework, InputMap action list, export preset for PC |
| **M1** | Move & input | Greybox arena, ortho camera, player capsule moves via PC and gamepad schemes; touch scheme working via emulated touch; auto device switching |
| **M2** | Abilities | 4 slots, targeting types + aim indicators per scheme, cooldowns/costs, one test character (e.g. dash, blink, slow field, shield) |
| **M3** | Enemies & damage | StatBlock, pools, armour/resist, status effects, 2 archetypes that chase and attack, per-enemy lifetime + despawn tell, player death |
| **M4** | **Core loop prototype** | ThreatDirector + curve, health crystals, a safehouse that ends the level, HUD (HP, cooldowns, threat). **Playtest checkpoint — iterate until it's fun** |
| **M5** | Procedural levels | Seeded generator, runtime navmesh, POI placement, reachability checks, all driven by a `LevelTheme` (base zone only) |
| **M6** | Items & chests | Item data, modifiers, effect hooks, loot tables, gold, 10–15 items |
| **M7** | Run structure & zones | Safehouse shop, 5 levels with escalating curves, HP restore between levels, win/loss screens. Zone framework (ZoneData, EnemyVariant, ThemeResolver, intensity blending) with one greybox destination zone, using colour, a hazard and one variant to prove the blend |
| **M8** | Nexus & meta | Hub scene, character select, save system, meta-upgrade framework |
| **M9** | Art pass | Lighting, materials, VFX, readable telegraphs, UI style on one biome |
| **M10** | Content | 3+ characters, 6+ shared enemy archetypes, 3 destination zones (e.g. Inferno, Swamp, Graveyard), each with exclusives, variants and hazards, 40+ items |
| **M11** | Platforms & polish | Gamepad UI navigation, touch tuning, mobile renderer/perf, remapping, audio, juice |

## 8. Risks

- **Evasion isn't fun** → M4 playtest gate; enemies must have readable, telegraphed attacks so dodging is skill, not luck.
- **Enemies feel unfair with no counterplay** → crowd-control abilities, despawn tells, and per-enemy lifetimes give the player tools and hope.
- **Navmesh on procedural maps** → pre-baked chunk navmeshes or threaded runtime bake; prove in M5.
- **Touch/gamepad rot while developing on PC** → all three schemes go through the same intent layer and are exercised every milestone.
- **Mobile performance in 3D** → Mobile renderer, conservative lighting; test on a device before M11.

## 9. Open questions


- Meta-progression contents (Nexus unlocks).
- Number of characters at launch and their identities.
- Enemy damage types per archetype (physical vs elemental mix).
- Shop contents and pricing; can you reroll?
- Is there a final "boss" escape on level 5, or just a last safehouse?
