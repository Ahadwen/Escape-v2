# Escape

A top-down isometric roguelike where you can't fight back, only escape. Built with Godot 4.7.

See [PLAN.md](PLAN.md) for the design and architecture.

## Project layout

Code is organised by domain (see PLAN.md §7.9): `core/`, `input/`, `actors/`, `stats/`, `status/`, `abilities/`, `characters/`, `items/`, `enemies/`, `director/`, `zones/`, `world/`, `nexus/`, `ui/`, plus `art/`, `audio/` and `tests/`.

## Conventions

- **Static typing everywhere.** Untyped declarations are errors (Project Settings → Debug → GDScript); unsafe access and casts are warnings.
- **Input goes through `InputActions`.** Never use action-name string literals; use the constants in `input/input_actions.gd`. Bindings live in Project Settings → Input Map.
- **Format and lint** with [gdtoolkit](https://github.com/Scony/godot-gdscript-toolkit):

  ```bash
  pip install "gdtoolkit==4.5.0"
  ```

  ```bash
  gdformat . && gdlint .
  ```

## Tests

Tests are plain GDScript, with no addon needed. Put them in `tests/` as `test_*.gd`, extend `res://tests/framework/test_case.gd`, and name each test method `test_*`.

Run all tests headless:

```bash
godot --headless --path . -s res://tests/run_tests.gd
```

Run only files whose path contains some text:

```bash
godot --headless --path . -s res://tests/run_tests.gd -- unit/input
```

The exit code is non-zero if any test fails. CI runs lint and the tests on every push.

## Input bindings

| Action | PC | Gamepad |
|---|---|---|
| `move_to` | Right click | – |
| `confirm` | Left click | – |
| `stop` | S | – |
| `move_*` | – | Left stick |
| `aim_*` | – | Right stick |
| `ability_1`–`ability_4` | Q / W / E / R (physical keys) | LB / RB / LT / RT |
| `interact` | F | A / Cross |
| `pause` | Esc | Start |

Touch controls are on-screen widgets that feed the same actions and intents (milestone M1).
