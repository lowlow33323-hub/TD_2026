# Path Bender Tower Defense - Project Notes

## Origin Context

This Godot project was migrated from a previous Windows 10 Codex session.

Original user goal:

- Build a tower defense game in Godot.
- Enemies move horizontally from left to right.
- The player can freely build towers to increase or bend the enemy path.
- Tower placement must never completely block all routes from entrance to exit.

Migrated Codex history is stored outside the Godot project at:

```text
/Users/qqq/Documents/Godot Game/_old_codex_windows/sessions/
```

The main development session is:

```text
2026/06/08/rollout-2026-06-08T19-27-45-019ea6fd-1aec-7161-8382-9301ed099833.jsonl
```

## Current Project

Project folder:

```text
/Users/qqq/Documents/Godot Game/tower_defense_godot
```

Main files:

- `project.godot`: Godot project entry.
- `scenes/main.tscn`: main launch scene.
- `scripts/main.gd`: all current gameplay, UI, drawing, pathfinding, enemies, towers, projectiles, audio, and wave logic.
- `README.md`: player-facing controls and feature summary.

Current game version constant:

```gdscript
const GAME_VERSION := "Beta 0.2.0"
```

## Implemented Gameplay

- Grid-based side-to-side tower defense.
- Entrance is `START := Vector2i(0, 10)`.
- Exit is `GOAL := Vector2i(GRID_W - 1, 10)`.
- Grid size is `30 x 20`.
- Towers occupy a `2 x 2` footprint and alter the enemy path.
- Before building, the code simulates the new blocked cell and runs pathfinding.
- If no path remains, the build is rejected with the message `不能完全阻擋敵人的路線。`
- Enemies retarget when towers are built or removed.
- Building is disabled while a wave is active.
- Towers can be selected, upgraded, and sold.
- Game speed can be changed with UI buttons: `1x`, `2x`, `3x`, `4x`.
- The game now starts from a main menu with Rules, Ranking, Start Game, and Difficulty pages.
- In-game UI includes Save, Main Menu, and Exit controls.
- Layout is recalculated from the viewport size for desktop and narrow/mobile displays.

## Tower Types

### Cannon Tower

- High damage.
- Slow fire rate.
- Splash damage.
- Good against grouped or high-health enemies.

### Arrow Tower

- Fast fire rate.
- Long range.
- Later upgrades can target multiple enemies.
- Good general-purpose tower.

### Ice Tower

- Deals lower damage.
- Applies slow.
- Good for path-control strategies and supporting other towers.

Tower levels currently max at:

```gdscript
const MAX_TOWER_LEVEL := 5
```

## Enemy Types

### Basic Enemy

- Standard health and speed.

### Tank Enemy

- Higher health.
- Slower movement.
- Higher reward.

### Fast Enemy

- Faster movement.
- Lower health.
- Higher reward than basic enemies.

### Boss

- Every 10th wave is a Boss wave.
- Boss waves spawn only one large Boss.
- Boss has much higher health, slower speed, higher reward.
- Defeated Bosses are timed.
- Best 5 Boss clear times are shown in the HUD leaderboard.

## Important Code Areas

- Build validation: `try_build_or_select`
- Wave start: `start_wave`
- Enemy spawning: `_update_spawn`, `spawn_enemy`, `enemy_type_for_spawn`
- Enemy movement: `_update_enemies`
- Tower targeting: `_update_towers`, `enemies_for_tower`
- Projectile hit effects: `_apply_projectile_hit`
- Boss leaderboard: `record_boss_kill`, `leaderboard_text`, `boss_rank_summary`
- Pathfinding: `find_path`, `find_path_from`
- UI update: `_update_ui`
- Drawing: `_draw`, `draw_grid`, `draw_path`, `draw_towers`, `draw_enemies`, `draw_projectiles`

## Design Direction

The core fantasy is not just killing enemies, but shaping the route. Future changes should preserve this:

- Let players create longer paths.
- Always prevent complete path blocking.
- Keep route readability high.
- Make tower choices meaningfully different.
- Make wave pacing and enemy variety increasingly strategic.

## Likely Next Improvements

- Add persistent save data for Boss leaderboard.
- Split `main.gd` into smaller scripts once feature growth makes the single file hard to manage.
- Add tower preview before placement, including blocked/allowed placement feedback.
- Show projected path change before confirming tower placement.
- Add pause button.
- Add restart button after game over.
- Add more map layouts or random obstacle presets.
- Add clearer visual warning when a placement would block all paths.
- Add exported balance constants or resource files for easier tuning.
