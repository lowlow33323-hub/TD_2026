# Codex Notes for This Godot Project

## Project Scope

This is a Godot 4 tower defense prototype named `Path Bender Tower Defense`.

The central rule is:

- Players may place 2x2 towers freely to change and lengthen the enemy route.
- Placement must never fully block the path from the left entrance to the right exit.

Keep this path-bending mechanic as the main design pillar when changing gameplay.

## Current Structure

- `project.godot` opens the project.
- `scenes/main.tscn` loads a single `Node2D` with `scripts/main.gd`.
- `scripts/main.gd` currently contains the full prototype: screen flow, responsive UI, gameplay state, drawing, audio, pathfinding, enemy logic, tower logic, projectiles, Boss timing, save metadata, and leaderboard.
- `README.md` is player-facing.
- `PROJECT_NOTES.md` contains migrated context from the previous Windows Codex session.

## Development Conventions

- Use Godot 4 style GDScript.
- Keep changes small and playable.
- Prefer preserving the current simple single-scene architecture until a feature clearly benefits from splitting files.
- When adding new gameplay, keep UI text in Traditional Chinese to match the existing project.
- Do not remove the path-validity check when changing build logic.
- If modifying tower placement, always verify that `find_path` still prevents complete blocking.
- Tower placement uses a 2x2 footprint. Any new build logic must update all footprint cells in `blocked`.
- Avoid committing `.godot/` editor cache files unless the user specifically wants local editor state tracked.

## Key Gameplay Hooks

- Build or select tower: `try_build_or_select`
- Remove tower: `remove_tower`
- Upgrade tower: `upgrade_selected_tower`
- Pathfinding: `find_path`, `find_path_from`
- Wave start and spawn: `start_wave`, `_update_spawn`, `spawn_enemy`
- Enemy selection for towers: `enemies_for_tower`
- Projectile effects: `_apply_projectile_hit`
- HUD state: `_update_ui`

## Verification

After gameplay edits, check at minimum:

- Project opens through `project.godot`.
- Main scene is still `res://scenes/main.tscn`.
- Building a tower on a valid cell succeeds.
- Building a tower that blocks all routes is rejected.
- Starting a wave spawns enemies.
- Enemies can reach the exit if not killed.
- Towers fire and damage enemies.
- Boss wave behavior still occurs every 10 waves.
