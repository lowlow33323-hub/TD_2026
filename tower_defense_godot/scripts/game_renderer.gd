extends RefCounted

const Defs = preload("res://scripts/game_defs.gd")

const MAX_VISIBLE_PROJECTILES := 150
const BUSY_VISUAL_LOAD := 130


static func render(canvas: Node2D, state: Dictionary) -> void:
	var viewport_size := canvas.get_viewport_rect().size
	canvas.draw_rect(Rect2(Vector2.ZERO, viewport_size), Color("#10131b"))
	draw_background_details(canvas, viewport_size)
	if state["current_screen"] == Defs.SCREEN_GAME:
		draw_grid(canvas, state)
		if bool(state.get("show_enemy_path", true)):
			draw_path(canvas, state)
		draw_spawn_flash(canvas, state)
		draw_build_preview(canvas, state)
		draw_towers(canvas, state)
		draw_enemies(canvas, state)
		draw_projectiles(canvas, state)
		draw_impact_waves(canvas, state)
		draw_floating_texts(canvas, state)
		draw_wave_banner(canvas, state, viewport_size)
		if int(state["lives"]) <= 0:
			draw_game_over(canvas, viewport_size, state.get("font", ThemeDB.fallback_font))
	else:
		draw_menu_background(canvas, viewport_size)


static func draw_background_details(canvas: Node2D, viewport_size: Vector2) -> void:
	for y in range(0, int(viewport_size.y) + 48, 48):
		canvas.draw_line(Vector2(0, y), Vector2(viewport_size.x, y), Color(1, 1, 1, 0.025), 1.0)
	for x in range(0, int(viewport_size.x) + 48, 48):
		canvas.draw_line(Vector2(x, 0), Vector2(x, viewport_size.y), Color(1, 1, 1, 0.018), 1.0)


static func draw_menu_background(canvas: Node2D, viewport_size: Vector2) -> void:
	var path_y := viewport_size.y * 0.62
	canvas.draw_line(Vector2(viewport_size.x * 0.08, path_y), Vector2(viewport_size.x * 0.92, path_y), Color("#f6df7b"), 10.0)
	for i in range(7):
		var x := viewport_size.x * (0.16 + float(i) * 0.11)
		canvas.draw_circle(Vector2(x, path_y), 10.0, Color("#fff3a6"))
		canvas.draw_circle(Vector2(x + 22.0, path_y - 36.0), 18.0, Color("#6ec6ff"))


static func draw_grid(canvas: Node2D, state: Dictionary) -> void:
	var grid_rect: Rect2 = state["grid_rect"]
	var cell_size: float = state["cell_size"]
	var blocked: Dictionary = state["blocked"]
	var is_boss_wave: bool = bool(state.get("is_boss_wave_active", false))
	var base_color := Color("#1a0b10") if is_boss_wave else Color("#0b0f17")
	var border_color := Color("#9f3c42") if is_boss_wave else Color("#6f819f")
	canvas.draw_rect(grid_rect.grow(8.0), base_color)
	canvas.draw_rect(grid_rect.grow(4.0), border_color, false, max(2.0, cell_size * 0.12))
	for y in range(Defs.GRID_H):
		for x in range(Defs.GRID_W):
			var cell := Vector2i(x, y)
			var rect := cell_rect(state, cell)
			var color := Color("#34202a") if is_boss_wave else Color("#202536")
			if cell == Defs.START:
				color = Color("#275a3d")
			elif cell == Defs.GOAL:
				color = Color("#57313a")
			elif blocked.has(cell):
				color = Color("#111623")
			canvas.draw_rect(rect, color)
			if not blocked.has(cell):
				canvas.draw_rect(rect, Color("#3b4259"), false, max(1.0, cell_size * 0.025))
	canvas.draw_rect(cell_rect(state, Defs.START).grow(2.0), Color("#74e39a"), false, max(2.0, cell_size * 0.08))
	canvas.draw_rect(cell_rect(state, Defs.GOAL).grow(2.0), Color("#ff8da1"), false, max(2.0, cell_size * 0.08))


static func draw_spawn_flash(canvas: Node2D, state: Dictionary) -> void:
	var spawn_flash_timer: float = state["spawn_flash_timer"]
	if spawn_flash_timer <= 0.0:
		return
	var cell_size: float = state["cell_size"]
	var ratio := clampf(spawn_flash_timer / 1.2, 0.0, 1.0)
	var center := cell_center(state, Defs.START)
	canvas.draw_circle(center, cell_size * (1.0 + (1.0 - ratio) * 2.0), Color(0.45, 1.0, 0.58, 0.20 * ratio))
	canvas.draw_arc(center, cell_size * (0.7 + (1.0 - ratio) * 1.8), 0.0, TAU, 48, Color(0.75, 1.0, 0.55, 0.8 * ratio), max(2.0, cell_size * 0.08))


static func draw_wave_banner(canvas: Node2D, state: Dictionary, viewport_size: Vector2) -> void:
	var timer: float = state.get("wave_banner_timer", 0.0)
	if timer <= 0.0:
		return
	var ratio: float = clampf(timer / 1.8, 0.0, 1.0)
	var alpha: float = min(1.0, ratio * 1.4)
	var font_size := 54
	var text := "第 %d 波" % int(state.get("wave", 0))
	var font: Font = state.get("font", ThemeDB.fallback_font)
	var grid_rect: Rect2 = state["grid_rect"]
	var center: Vector2 = grid_rect.get_center()
	var text_size: Vector2 = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	canvas.draw_string(font, center - Vector2(text_size.x * 0.5, 0.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color(1.0, 0.91, 0.45, alpha))


static func draw_build_preview(canvas: Node2D, state: Dictionary) -> void:
	var hover_cell: Vector2i = state["hover_cell"]
	if hover_cell.x < -100:
		return
	var cell_size: float = state["cell_size"]
	var grid_origin: Vector2 = state["grid_origin"]
	var rect := Rect2(grid_origin + Vector2(hover_cell.x * cell_size, hover_cell.y * cell_size), Vector2(cell_size * Defs.TOWER_SIZE, cell_size * Defs.TOWER_SIZE))
	var color := Color(0.35, 0.75, 1.0, 0.32) if bool(state["hover_can_build"]) else Color(1.0, 0.25, 0.25, 0.32)
	canvas.draw_rect(rect, color)
	canvas.draw_rect(rect, color.lightened(0.35), false, max(2.0, cell_size * 0.08))


static func draw_path(canvas: Node2D, state: Dictionary) -> void:
	var current_path: Array = state["current_path"]
	var cell_size: float = state["cell_size"]
	if current_path.size() < 2:
		return
	var path_width: float = cell_size
	var path_color := Color(0.50, 0.46, 0.28, 0.46)
	var points := PackedVector2Array()
	for cell in current_path:
		points.append(cell_center(state, cell))
	canvas.draw_polyline(points, path_color, path_width, true)


static func draw_towers(canvas: Node2D, state: Dictionary) -> void:
	var towers: Array = state["towers"]
	var selected_tower = state["selected_tower"]
	var cell_size: float = state["cell_size"]
	var grid_origin: Vector2 = state["grid_origin"]
	for tower in towers:
		var rect := Rect2(grid_origin + Vector2(tower.cell.x * cell_size, tower.cell.y * cell_size), Vector2(cell_size * Defs.TOWER_SIZE, cell_size * Defs.TOWER_SIZE))
		var center := tower_center(state, tower)
		if tower == selected_tower:
			canvas.draw_circle(center, tower.range, Color(tower.color.r, tower.color.g, tower.color.b, 0.13))
			canvas.draw_arc(center, tower.range, 0.0, TAU, 96, tower.color, 2.0)
			canvas.draw_rect(rect.grow(2.0), tower.color, false, 3.0)
		match tower.type_id:
			Defs.TYPE_CANNON:
				draw_cannon_tower(canvas, center, tower, cell_size)
			Defs.TYPE_ARROW:
				draw_arrow_tower(canvas, center, tower, cell_size)
			Defs.TYPE_ICE:
				draw_ice_tower(canvas, center, tower, cell_size)
		draw_tower_level_marker(canvas, center, tower.level, cell_size)


static func draw_tower_level_marker(canvas: Node2D, center: Vector2, level: int, cell_size: float) -> void:
	if level <= 1:
		return
	if level >= 5:
		draw_star(canvas, center + Vector2(cell_size * 0.55, cell_size * 0.55), cell_size * 0.28, Color("#ff9f1c"))
		return
	var count := level - 1
	var spacing := cell_size * 0.22
	var start := center + Vector2(-spacing * float(count - 1) * 0.5, cell_size * 0.72)
	for i in range(count):
		canvas.draw_circle(start + Vector2(spacing * i, 0), max(2.0, cell_size * 0.085), Color("#ff4458"))


static func draw_star(canvas: Node2D, center: Vector2, radius: float, color: Color) -> void:
	var points := PackedVector2Array()
	for i in range(5):
		var angle := -PI * 0.5 + float(i) * TAU / 5.0
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	canvas.draw_colored_polygon(points, color)


static func draw_cannon_tower(canvas: Node2D, center: Vector2, tower, cell_size: float) -> void:
	var r := cell_size * 0.72
	var dir: Vector2 = tower.aim_dir.normalized()
	if dir.length_squared() <= 0.001:
		dir = Vector2.RIGHT
	canvas.draw_circle(center + Vector2(0, r * 0.12), r, Color("#6b4a2f"))
	canvas.draw_circle(center, r * 0.82, tower.color)
	canvas.draw_circle(center, r * 0.46, Color("#2b2621"))
	canvas.draw_line(center + dir * r * 0.15, center + dir * r * 1.22, Color("#ffe2af"), max(4.0, r * 0.36))
	canvas.draw_line(center + dir * r * 0.15, center + dir * r * 1.22, Color("#3a2b22"), max(2.0, r * 0.14))
	canvas.draw_arc(center, r * 1.02, PI * 0.1, PI * 1.9, 24, Color("#ffd99d"), 2.0)


static func draw_arrow_tower(canvas: Node2D, center: Vector2, tower, cell_size: float) -> void:
	var r := cell_size * 0.82
	var dir: Vector2 = tower.aim_dir.normalized()
	if dir.length_squared() <= 0.001:
		dir = Vector2.RIGHT
	var normal := dir.orthogonal()
	var points := PackedVector2Array([
		center + Vector2(0, -r),
		center + Vector2(r * 0.86, r * 0.55),
		center + Vector2(0, r),
		center + Vector2(-r * 0.86, r * 0.55)
	])
	canvas.draw_colored_polygon(points, Color("#31543a"))
	canvas.draw_polyline(points, Color("#bff2b7"), 3.0, true)
	canvas.draw_line(center - normal * r * 0.55, center + normal * r * 0.55, Color("#efffe6"), max(2.0, r * 0.12))
	canvas.draw_line(center - dir * r * 0.2, center + dir * r * 0.9, tower.color, max(3.0, r * 0.22))
	canvas.draw_circle(center, r * 0.32, Color("#16291b"))


static func draw_ice_tower(canvas: Node2D, center: Vector2, tower, cell_size: float) -> void:
	var r := cell_size * 0.78
	canvas.draw_circle(center, r, Color("#23415a"))
	canvas.draw_circle(center, r * 0.75, tower.color)
	var crystal := PackedVector2Array([
		center + Vector2(0, -r * 1.05),
		center + Vector2(r * 0.58, -r * 0.2),
		center + Vector2(r * 0.38, r * 0.76),
		center + Vector2(-r * 0.38, r * 0.76),
		center + Vector2(-r * 0.58, -r * 0.2)
	])
	canvas.draw_colored_polygon(crystal, Color("#d8fbff"))
	canvas.draw_polyline(crystal, Color("#6cc8ff"), 2.0, true)
	canvas.draw_line(center + Vector2(0, -r * 0.86), center + Vector2(0, r * 0.66), Color("#88e7ff"), 2.0)
	canvas.draw_line(center + Vector2(-r * 0.48, -r * 0.14), center + Vector2(r * 0.48, -r * 0.14), Color("#88e7ff"), 2.0)


static func draw_enemies(canvas: Node2D, state: Dictionary) -> void:
	var enemies: Array = state["enemies"]
	var cell_size: float = state["cell_size"]
	for enemy in enemies:
		var visual_scale := enemy_visual_scale(enemy)
		var radius := (cell_size * 0.72 if enemy.is_boss else cell_size * 0.32) * visual_scale
		var color := enemy_color(enemy)
		if enemy.is_waiting_revive():
			draw_tombstone(canvas, enemy.pos, cell_size)
			continue
		if enemy.is_auditor:
			canvas.draw_arc(enemy.pos, radius * 1.95, 0.0, TAU, 40, Color("#fff1a8"), max(3.0, cell_size * 0.1))
		if enemy.is_flying:
			canvas.draw_arc(enemy.pos, radius * 1.75, 0.0, TAU, 30, Color("#e7f1ff"), max(2.0, cell_size * 0.08))
		if enemy.is_invulnerable():
			canvas.draw_arc(enemy.pos, radius * 1.55, 0.0, TAU, 32, Color("#f7e8aa"), max(2.0, cell_size * 0.08))
		draw_enemy_body(canvas, enemy, radius, color)
		var hp_ratio := clampf(enemy.hp / enemy.max_hp, 0.0, 1.0)
		var bar_width := cell_size * 1.8 if enemy.is_boss else cell_size * 0.85
		bar_width *= visual_scale
		var bar_pos: Vector2 = enemy.pos + Vector2(-bar_width * 0.5, -radius - cell_size * 0.28)
		canvas.draw_rect(Rect2(bar_pos, Vector2(bar_width, max(4.0, cell_size * 0.12))), Color("#201219"))
		canvas.draw_rect(Rect2(bar_pos, Vector2(bar_width * hp_ratio, max(4.0, cell_size * 0.12))), Color("#72e06a"))


static func enemy_visual_scale(enemy) -> float:
	if enemy.is_boss:
		return 2.0
	if enemy.type_id == Defs.ENEMY_BASIC or enemy.type_id == Defs.ENEMY_AUDITOR:
		return 1.0
	return 2.0


static func draw_tombstone(canvas: Node2D, pos: Vector2, cell_size: float) -> void:
	var w := cell_size * 0.55
	var h := cell_size * 0.72
	var top := pos + Vector2(-w * 0.5, -h * 0.5)
	var rect := Rect2(top + Vector2(0, h * 0.22), Vector2(w, h * 0.78))
	canvas.draw_rect(rect, Color("#918a80"))
	canvas.draw_circle(top + Vector2(w * 0.5, h * 0.24), w * 0.5, Color("#aaa298"))
	canvas.draw_line(pos + Vector2(-w * 0.22, -h * 0.05), pos + Vector2(w * 0.22, -h * 0.05), Color("#4d4741"), max(1.5, cell_size * 0.06))
	canvas.draw_line(pos + Vector2(0, -h * 0.24), pos + Vector2(0, h * 0.18), Color("#4d4741"), max(1.5, cell_size * 0.06))


static func enemy_color(enemy) -> Color:
	var color: Color = enemy.body_color
	if enemy.hit_flash_timer > 0.0:
		color = Color("#ff4040")
	if enemy.slow_timer > 0.0:
		color = Color("#66cfff")
	return color


static func draw_enemy_body(canvas: Node2D, enemy, radius: float, color: Color) -> void:
	var pos: Vector2 = enemy.pos
	var angle: float = enemy.facing_dir.angle() + PI
	canvas.draw_set_transform(pos, angle, Vector2.ONE)
	if enemy.is_boss:
		draw_boss_enemy(canvas, enemy.name, radius, color)
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		return
	match enemy.type_id:
		Defs.ENEMY_BASIC:
			draw_ant_enemy(canvas, Vector2.ZERO, radius, color)
		Defs.ENEMY_FAST:
			draw_roach_enemy(canvas, Vector2.ZERO, radius, color)
		Defs.ENEMY_TANK:
			draw_beetle_enemy(canvas, Vector2.ZERO, radius, color)
		Defs.ENEMY_REVIVER:
			draw_spider_enemy(canvas, Vector2.ZERO, radius, color)
		Defs.ENEMY_FLYING:
			draw_locust_enemy(canvas, Vector2.ZERO, radius, color)
		Defs.ENEMY_AUDITOR:
			draw_generic_enemy(canvas, Vector2.ZERO, radius, color, false)
		_:
			draw_generic_enemy(canvas, Vector2.ZERO, radius, color, false)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func draw_generic_enemy(canvas: Node2D, pos: Vector2, radius: float, color: Color, is_boss: bool) -> void:
	canvas.draw_circle(pos, radius, color)
	canvas.draw_circle(pos + Vector2(0, radius * 0.12), radius * 0.72, color.darkened(0.25))
	canvas.draw_circle(pos + Vector2(-radius * 0.35, -radius * 0.25), radius * 0.17, Color("#fff6df"))
	canvas.draw_circle(pos + Vector2(radius * 0.35, -radius * 0.25), radius * 0.17, Color("#fff6df"))
	canvas.draw_circle(pos + Vector2(-radius * 0.35, -radius * 0.25), radius * 0.07, Color("#1a1014"))
	canvas.draw_circle(pos + Vector2(radius * 0.35, -radius * 0.25), radius * 0.07, Color("#1a1014"))
	canvas.draw_line(pos + Vector2(-radius * 0.35, radius * 0.28), pos + Vector2(radius * 0.35, radius * 0.28), Color("#241216"), max(2.0, radius * 0.12))
	if is_boss:
		canvas.draw_arc(pos, radius + 4.0, PI * 0.08, PI * 1.92, 36, Color("#ffd36b"), 3.0)
		canvas.draw_string(ThemeDB.fallback_font, pos + Vector2(-6, 8), "B", HORIZONTAL_ALIGNMENT_LEFT, -1, max(16, int(radius * 0.5)), Color.WHITE)


static func draw_boss_enemy(canvas: Node2D, boss_name: String, radius: float, color: Color) -> void:
	match boss_name:
		"蟻后":
			draw_ant_enemy(canvas, Vector2.ZERO, radius, color)
			draw_boss_crown(canvas, Vector2(-radius * 0.42, -radius * 0.58), radius)
		"聖甲蟲":
			draw_beetle_enemy(canvas, Vector2.ZERO, radius, color)
			canvas.draw_arc(Vector2.ZERO, radius * 1.08, PI * 0.12, PI * 1.88, 36, Color("#ffd36b"), max(2.0, radius * 0.08))
		"蟑螂將軍":
			draw_roach_enemy(canvas, Vector2.ZERO, radius, color)
			canvas.draw_line(Vector2(-radius * 0.2, -radius * 0.62), Vector2(radius * 0.55, -radius * 0.62), Color("#ffd36b"), max(2.0, radius * 0.1))
		"蜘蛛女皇":
			draw_spider_enemy(canvas, Vector2.ZERO, radius, color)
			draw_boss_crown(canvas, Vector2(-radius * 0.36, -radius * 0.62), radius)
		"昆蟲魔王":
			draw_generic_enemy(canvas, Vector2.ZERO, radius, color, true)
			canvas.draw_line(Vector2(-radius * 0.75, -radius * 0.5), Vector2(-radius * 1.28, -radius * 0.95), Color("#ffd36b"), max(2.0, radius * 0.08))
			canvas.draw_line(Vector2(-radius * 0.75, radius * 0.5), Vector2(-radius * 1.28, radius * 0.95), Color("#ffd36b"), max(2.0, radius * 0.08))
		_:
			draw_generic_enemy(canvas, Vector2.ZERO, radius, color, true)


static func draw_boss_crown(canvas: Node2D, pos: Vector2, radius: float) -> void:
	var points := PackedVector2Array([
		pos + Vector2(-radius * 0.28, radius * 0.16),
		pos + Vector2(-radius * 0.16, -radius * 0.16),
		pos + Vector2(0, radius * 0.04),
		pos + Vector2(radius * 0.16, -radius * 0.16),
		pos + Vector2(radius * 0.28, radius * 0.16)
	])
	canvas.draw_colored_polygon(points, Color("#ffd36b"))
	canvas.draw_polyline(points, Color("#8b5d16"), max(1.5, radius * 0.04), false)


static func draw_ant_enemy(canvas: Node2D, pos: Vector2, radius: float, color: Color) -> void:
	for offset in [-0.55, 0.0, 0.55]:
		canvas.draw_circle(pos + Vector2(radius * offset, 0), radius * 0.42, color)
	for side in [-1, 1]:
		for offset in [-0.45, 0.0, 0.45]:
			canvas.draw_line(pos + Vector2(radius * offset, radius * 0.1), pos + Vector2(radius * offset, radius * side * 0.95), color.darkened(0.35), max(1.5, radius * 0.12))
	canvas.draw_line(pos + Vector2(-radius * 0.65, -radius * 0.22), pos + Vector2(-radius * 1.05, -radius * 0.55), color.darkened(0.25), 2.0)
	canvas.draw_line(pos + Vector2(-radius * 0.65, radius * 0.22), pos + Vector2(-radius * 1.05, radius * 0.55), color.darkened(0.25), 2.0)


static func draw_roach_enemy(canvas: Node2D, pos: Vector2, radius: float, color: Color) -> void:
	var body := Rect2(pos - Vector2(radius * 0.75, radius * 0.36), Vector2(radius * 1.5, radius * 0.72))
	canvas.draw_rect(body, color)
	canvas.draw_circle(pos + Vector2(-radius * 0.72, 0), radius * 0.36, color.darkened(0.15))
	canvas.draw_line(pos + Vector2(-radius * 0.55, 0), pos + Vector2(radius * 0.68, 0), color.darkened(0.45), max(1.5, radius * 0.08))
	for side in [-1, 1]:
		canvas.draw_line(pos + Vector2(-radius * 0.2, side * radius * 0.25), pos + Vector2(-radius * 0.65, side * radius * 0.85), color.darkened(0.35), 2.0)
		canvas.draw_line(pos + Vector2(radius * 0.25, side * radius * 0.25), pos + Vector2(radius * 0.72, side * radius * 0.8), color.darkened(0.35), 2.0)


static func draw_beetle_enemy(canvas: Node2D, pos: Vector2, radius: float, color: Color) -> void:
	canvas.draw_circle(pos, radius * 0.82, color)
	canvas.draw_circle(pos + Vector2(-radius * 0.45, 0), radius * 0.46, color.darkened(0.18))
	canvas.draw_line(pos + Vector2(-radius * 0.78, -radius * 0.12), pos + Vector2(-radius * 1.35, -radius * 0.5), color.darkened(0.4), max(2.0, radius * 0.14))
	canvas.draw_line(pos + Vector2(-radius * 0.78, radius * 0.12), pos + Vector2(-radius * 1.35, radius * 0.5), color.darkened(0.4), max(2.0, radius * 0.14))
	canvas.draw_line(pos + Vector2(0, -radius * 0.72), pos + Vector2(0, radius * 0.72), color.darkened(0.35), max(1.5, radius * 0.08))


static func draw_spider_enemy(canvas: Node2D, pos: Vector2, radius: float, color: Color) -> void:
	canvas.draw_circle(pos + Vector2(radius * 0.22, 0), radius * 0.58, color)
	canvas.draw_circle(pos + Vector2(-radius * 0.38, 0), radius * 0.38, color.darkened(0.1))
	for side in [-1, 1]:
		for offset in [-0.45, -0.15, 0.15, 0.45]:
			canvas.draw_line(pos + Vector2(radius * offset, side * radius * 0.2), pos + Vector2(radius * (offset + 0.25), side * radius * 1.08), color.darkened(0.35), max(1.5, radius * 0.1))


static func draw_locust_enemy(canvas: Node2D, pos: Vector2, radius: float, color: Color) -> void:
	canvas.draw_circle(pos, radius * 0.48, color)
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-radius * 0.2, -radius * 0.1),
		pos + Vector2(radius * 1.15, -radius * 0.75),
		pos + Vector2(radius * 0.35, -radius * 0.02)
	]), Color(0.85, 0.95, 1.0, 0.55))
	canvas.draw_colored_polygon(PackedVector2Array([
		pos + Vector2(-radius * 0.2, radius * 0.1),
		pos + Vector2(radius * 1.15, radius * 0.75),
		pos + Vector2(radius * 0.35, radius * 0.02)
	]), Color(0.85, 0.95, 1.0, 0.55))
	canvas.draw_line(pos + Vector2(-radius * 0.35, 0), pos + Vector2(-radius * 1.05, -radius * 0.35), color.darkened(0.35), 2.0)
	canvas.draw_line(pos + Vector2(-radius * 0.35, 0), pos + Vector2(-radius * 1.05, radius * 0.35), color.darkened(0.35), 2.0)


static func draw_projectiles(canvas: Node2D, state: Dictionary) -> void:
	var projectiles: Array = state["projectiles"]
	var cell_size: float = state["cell_size"]
	var stride: int = max(1, int(ceil(float(projectiles.size()) / float(MAX_VISIBLE_PROJECTILES))))
	for i in range(0, projectiles.size(), stride):
		var projectile = projectiles[i]
		match projectile.tower_type:
			Defs.TYPE_CANNON:
				canvas.draw_circle(projectile.pos, max(3.0, cell_size * 0.16), Color("#ffcf70"))
			Defs.TYPE_ARROW:
				var direction: Vector2 = (projectile.target.pos - projectile.pos).normalized()
				if direction.length_squared() <= 0.001:
					direction = Vector2.RIGHT
				var tail: Vector2 = projectile.pos - direction * max(8.0, cell_size * 0.28)
				var head: Vector2 = projectile.pos + direction * max(8.0, cell_size * 0.28)
				canvas.draw_line(tail, head, Color("#efffe6"), max(2.0, cell_size * 0.08))
			Defs.TYPE_ICE:
				canvas.draw_circle(projectile.pos, max(3.0, cell_size * 0.14), Color("#bff8ff"))


static func draw_floating_texts(canvas: Node2D, state: Dictionary) -> void:
	var floating_texts: Array = state.get("floating_texts", [])
	var cell_size: float = state["cell_size"]
	var font: Font = state.get("font", ThemeDB.fallback_font)
	for entry in floating_texts:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var pos: Vector2 = entry.get("pos", Vector2.ZERO)
		var text := String(entry.get("text", ""))
		var color: Color = entry.get("color", Color.WHITE)
		var ratio := clampf(float(entry.get("time", 0.0)) / 0.9, 0.0, 1.0)
		color.a = ratio
		canvas.draw_string(font, pos + Vector2(-cell_size * 0.35, -cell_size * 0.25), text, HORIZONTAL_ALIGNMENT_LEFT, -1, max(12, int(cell_size * 0.62)), color)


static func draw_impact_waves(canvas: Node2D, state: Dictionary) -> void:
	var impact_waves: Array = state.get("impact_waves", [])
	var cell_size: float = state["cell_size"]
	var is_busy := int(state.get("visual_load", 0)) >= BUSY_VISUAL_LOAD
	var point_count := 8 if is_busy else 14
	for entry in impact_waves:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var pos: Vector2 = entry.get("pos", Vector2.ZERO)
		var color: Color = entry.get("color", Color.WHITE)
		var direction: Vector2 = entry.get("dir", Vector2.RIGHT)
		if direction.length_squared() <= 0.001:
			direction = Vector2.RIGHT
		var time: float = float(entry.get("time", 0.0))
		var duration: float = max(0.01, float(entry.get("duration", 0.32)))
		var progress: float = 1.0 - clampf(time / duration, 0.0, 1.0)
		color.a = 0.7 * (1.0 - progress)
		var center_angle: float = (direction * -1.0).angle()
		var arc_half: float = PI / 3.0
		canvas.draw_arc(pos, cell_size * (0.25 + progress * 0.75), center_angle - arc_half, center_angle + arc_half, point_count, color, max(2.0, cell_size * 0.09))


static func draw_game_over(canvas: Node2D, viewport_size: Vector2, font: Font = null) -> void:
	if font == null:
		font = ThemeDB.fallback_font
	canvas.draw_rect(Rect2(Vector2.ZERO, viewport_size), Color(0, 0, 0, 0.55))
	canvas.draw_string(font, viewport_size * 0.5 + Vector2(-100, 0), "遊戲結束", HORIZONTAL_ALIGNMENT_LEFT, -1, 38, Color.WHITE)


static func cell_rect(state: Dictionary, cell: Vector2i) -> Rect2:
	var grid_origin: Vector2 = state["grid_origin"]
	var cell_size: float = state["cell_size"]
	return Rect2(grid_origin + Vector2(cell.x * cell_size, cell.y * cell_size), Vector2(cell_size, cell_size))


static func cell_center(state: Dictionary, cell: Vector2i) -> Vector2:
	var grid_origin: Vector2 = state["grid_origin"]
	var cell_size: float = state["cell_size"]
	return grid_origin + Vector2(cell.x * cell_size + cell_size * 0.5, cell.y * cell_size + cell_size * 0.5)


static func tower_center(state: Dictionary, tower) -> Vector2:
	var cell_size: float = state["cell_size"]
	return cell_center(state, tower.cell) + Vector2(cell_size * 0.5, cell_size * 0.5)
