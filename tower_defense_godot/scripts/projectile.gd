extends RefCounted

const Enemy = preload("res://scripts/enemy.gd")
const Tower = preload("res://scripts/tower.gd")

var pos: Vector2
var target: Enemy
var tower_type: String
var damage: int
var splash_radius: float
var slow_factor: float
var slow_duration: float
var color: Color
var speed := 460.0


func _init(start_pos: Vector2, target_enemy: Enemy, source: Tower) -> void:
	pos = start_pos
	target = target_enemy
	tower_type = source.type_id
	damage = source.damage
	splash_radius = source.splash_radius
	slow_factor = source.slow_factor
	slow_duration = source.slow_duration
	color = source.color
