extends RefCounted

const Defs = preload("res://scripts/game_defs.gd")

const SAVE_PATH := "user://path_bender_save.json"
const META_PATH := "user://path_bender_meta.json"


static func build_save_data(owner) -> Dictionary:
	var tower_data: Array[Dictionary] = []
	for tower in owner.towers:
		tower_data.append({
			"x": tower.cell.x,
			"y": tower.cell.y,
			"type": tower.type_id,
			"level": tower.level
		})
	return {
		"difficulty": owner.difficulty_id,
		"gold": owner.gold,
		"lives": owner.lives,
		"wave": owner.wave,
		"towers": tower_data,
		"leaderboard": owner.boss_leaderboard
	}


static func save_game_data(data: Dictionary) -> bool:
	return write_json(SAVE_PATH, data)


static func load_save_data() -> Dictionary:
	return read_json_file(SAVE_PATH)


static func save_meta_data(difficulty_id: String, leaderboard: Array[Dictionary]) -> void:
	write_json(META_PATH, {
		"difficulty": difficulty_id,
		"leaderboard": leaderboard
	})


static func load_meta_data() -> Dictionary:
	return read_json_file(META_PATH)


static func apply_loaded_data(owner) -> void:
	var meta := load_meta_data()
	if not meta.is_empty():
		owner.difficulty_id = String(meta.get("difficulty", Defs.DIFFICULTY_NORMAL))
		_apply_leaderboard(owner, meta.get("leaderboard", []))

	var save_data := load_save_data()
	if save_data.is_empty():
		return
	owner.saved_game_data = save_data
	owner.has_saved_game = true
	owner.difficulty_id = String(save_data.get("difficulty", owner.difficulty_id))
	_apply_leaderboard(owner, save_data.get("leaderboard", []))


static func read_json_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


static func write_json(path: String, data: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	return true


static func _apply_leaderboard(owner, leaderboard) -> void:
	if typeof(leaderboard) != TYPE_ARRAY:
		return
	owner.boss_leaderboard.clear()
	for entry in leaderboard:
		if typeof(entry) == TYPE_DICTIONARY and entry.has("damage"):
			owner.boss_leaderboard.append(entry)
