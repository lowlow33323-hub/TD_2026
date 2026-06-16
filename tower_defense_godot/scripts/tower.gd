extends RefCounted

const Defs = preload("res://scripts/game_defs.gd")
const GameData = preload("res://scripts/game_data.gd")

var cell: Vector2i
var type_id: String
var name: String
var cooldown := 0.0
var level := 1
var cost := 25
var range := 140.0
var fire_rate := 0.6
var damage := 20
var target_count := 1
var splash_radius := 0.0
var slow_factor := 1.0
var slow_duration := 0.0
var color := Color.WHITE
var aim_dir := Vector2.RIGHT


func _init(cell_pos: Vector2i, tower_type: String, tower_level := 1) -> void:
	cell = cell_pos
	type_id = tower_type
	level = tower_level
	_apply_stats()


func upgrade_cost() -> int:
	if level >= Defs.MAX_TOWER_LEVEL:
		return 0
	return cost + 25 + level * 30


func upgrade() -> void:
	if level >= Defs.MAX_TOWER_LEVEL:
		return
	level += 1
	_apply_stats()


func _apply_stats() -> void:
	var data := GameData.tower(type_id)
	var level_step := float(level - 1)
	name = String(data.get("name", "未知塔"))
	cost = int(data.get("cost", 30))
	range = float(data.get("range", 140.0)) + level_step * float(data.get("range_per_level", 0.0))
	fire_rate = max(float(data.get("min_fire_rate", 0.1)), float(data.get("fire_rate", 0.6)) + level_step * float(data.get("fire_rate_per_level", 0.0)))
	damage = int(data.get("damage", 20)) + int(level - 1) * int(data.get("damage_per_level", 0))
	target_count = int(data.get("target_count", 1))
	for bonus_level in data.get("target_count_bonus_levels", []):
		if level >= int(bonus_level):
			target_count += 1
	splash_radius = float(data.get("splash_radius", 0.0)) + level_step * float(data.get("splash_radius_per_level", 0.0))
	slow_factor = max(float(data.get("min_slow_factor", 0.0)), float(data.get("slow_factor", 1.0)) + level_step * float(data.get("slow_factor_per_level", 0.0)))
	slow_duration = float(data.get("slow_duration", 0.0)) + level_step * float(data.get("slow_duration_per_level", 0.0))
	color = Color(String(data.get("color", "#ffffff")))
