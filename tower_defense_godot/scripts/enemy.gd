extends RefCounted

const Defs = preload("res://scripts/game_defs.gd")
const GameData = preload("res://scripts/game_data.gd")

var path: Array[Vector2i]
var index := 0
var pos: Vector2
var facing_dir := Vector2.RIGHT
var base_speed := 72.0
var hp := 72.0
var max_hp := 72.0
var reward := 8
var is_boss := false
var is_auditor := false
var type_id := Defs.ENEMY_BASIC
var name := "基礎敵人"
var body_color := Color("#ff9a5e")
var is_flying := false
var max_revives := 0
var revive_count := 0
var revive_hp_ratio := 0.5
var revive_speed_multiplier := 1.0
var revive_delay := 0.0
var revive_invulnerable_duration := 0.0
var revive_delay_timer := 0.0
var invulnerable_timer := 0.0
var slow_timer := 0.0
var slow_factor := 1.0
var hit_flash_timer := 0.0
var arrow_damage_taken_multiplier := 1.0


func _init(path_cells: Array[Vector2i], world_pos: Vector2, wave_level: int, boss: bool, enemy_type: String, hp_multiplier: float, speed_multiplier: float) -> void:
	path = path_cells.duplicate()
	pos = world_pos
	is_boss = boss
	type_id = enemy_type
	var base_data := GameData.enemy_base()
	var type_data := GameData.enemy(type_id)
	base_speed = (float(base_data.get("speed", 76.0)) + float(wave_level) * float(base_data.get("speed_per_wave", 1.8))) * speed_multiplier
	hp = (float(base_data.get("hp", 78.0)) + float(wave_level) * float(base_data.get("hp_per_wave", 32.0))) * hp_multiplier
	var reward_wave: int = min(wave_level, int(base_data.get("reward_soft_cap_wave", wave_level)))
	var late_wave: int = max(0, wave_level - reward_wave)
	var reward_per_wave := float(base_data.get("reward_per_wave", 1.1))
	var reward_late_scale := float(base_data.get("reward_late_scale", 1.0))
	reward = int(base_data.get("reward", 6)) + int(float(reward_wave) * reward_per_wave + float(late_wave) * reward_per_wave * reward_late_scale)
	if is_boss:
		type_data = GameData.boss()
	name = String(type_data.get("name", "基礎敵人"))
	if is_boss:
		var boss_names = type_data.get("names", [])
		if typeof(boss_names) == TYPE_ARRAY and not boss_names.is_empty():
			var boss_index: int = clampi(int(wave_level / 10) - 1, 0, boss_names.size() - 1)
			name = String(boss_names[boss_index])
	body_color = Color(String(type_data.get("color", "#ff9a5e")))
	is_auditor = bool(type_data.get("auditor", false))
	is_flying = bool(type_data.get("flying", false))
	arrow_damage_taken_multiplier = float(type_data.get("arrow_damage_taken", 1.0))
	max_revives = int(type_data.get("revives", 0))
	revive_hp_ratio = float(type_data.get("revive_hp_ratio", 0.5))
	revive_speed_multiplier = float(type_data.get("revive_speed_multiplier", 1.0))
	revive_delay = float(type_data.get("revive_delay", 0.0))
	revive_invulnerable_duration = float(type_data.get("revive_invulnerable_duration", 0.0))
	if is_boss and name == "蜘蛛女皇":
		var spider_data := GameData.enemy(Defs.ENEMY_REVIVER)
		max_revives = int(spider_data.get("revives", 1))
		revive_hp_ratio = float(spider_data.get("revive_hp_ratio", 0.5))
		revive_speed_multiplier = float(spider_data.get("revive_speed_multiplier", 1.5))
		revive_delay = float(spider_data.get("revive_delay", 3.0))
		revive_invulnerable_duration = 3.0
	base_speed *= float(type_data.get("speed_multiplier", 1.0))
	hp *= float(type_data.get("hp_multiplier", 1.0))
	if is_boss and wave_level >= 20:
		hp *= 2.0
	if is_boss:
		reward *= int(type_data.get("reward_multiplier", 1))
	else:
		reward += int(type_data.get("reward_bonus", 0))
	if wave_level > int(base_data.get("reward_late_total_scale_wave", wave_level + 1)):
		reward = max(1, int(round(float(reward) * float(base_data.get("reward_late_total_scale", 1.0)))))
	max_hp = hp


func can_revive() -> bool:
	return revive_count < max_revives and revive_delay_timer <= 0.0


func is_waiting_revive() -> bool:
	return revive_delay_timer > 0.0


func is_invulnerable() -> bool:
	return invulnerable_timer > 0.0


func is_targetable() -> bool:
	return hp > 0.0 and not is_waiting_revive() and not is_invulnerable()


func begin_revive_wait() -> void:
	revive_count += 1
	hp = 0.0
	revive_delay_timer = max(0.01, revive_delay)
	slow_timer = 0.0
	slow_factor = 1.0


func revive() -> void:
	hp = max(1.0, max_hp * revive_hp_ratio)
	base_speed *= revive_speed_multiplier
	invulnerable_timer = revive_invulnerable_duration
	slow_timer = 0.0
	slow_factor = 1.0
	apply_hit_flash()


func current_speed() -> float:
	if slow_timer > 0.0:
		return base_speed * slow_factor
	return base_speed


func apply_hit_flash() -> void:
	hit_flash_timer = 0.16


func apply_slow(factor: float, duration: float) -> void:
	if duration <= 0.0:
		return
	slow_factor = min(slow_factor, factor)
	slow_timer = max(slow_timer, duration)


func tick_status(delta: float) -> void:
	if revive_delay_timer > 0.0:
		revive_delay_timer = max(0.0, revive_delay_timer - delta)
		if revive_delay_timer <= 0.0:
			revive()
			return
	if invulnerable_timer > 0.0:
		invulnerable_timer = max(0.0, invulnerable_timer - delta)
	if hit_flash_timer > 0.0:
		hit_flash_timer = max(0.0, hit_flash_timer - delta)
	if slow_timer > 0.0:
		slow_timer -= delta
		if slow_timer <= 0.0:
			slow_timer = 0.0
			slow_factor = 1.0
