extends RefCounted

const Defs = preload("res://scripts/game_defs.gd")

const TOWERS_PATH := "res://data/towers.json"
const ENEMIES_PATH := "res://data/enemies.json"

static var _towers: Dictionary = {}
static var _enemies: Dictionary = {}


static func tower(type_id: String) -> Dictionary:
	_load_towers()
	return Dictionary(_towers.get(type_id, _towers.get(Defs.TYPE_CANNON, {})))


static func enemy(type_id: String) -> Dictionary:
	_load_enemies()
	return Dictionary(_enemies.get(type_id, _enemies.get(Defs.ENEMY_BASIC, {})))


static func enemy_base() -> Dictionary:
	_load_enemies()
	return Dictionary(_enemies.get("base", {}))


static func boss() -> Dictionary:
	_load_enemies()
	return Dictionary(_enemies.get("boss", {}))


static func tower_name(type_id: String) -> String:
	var data := tower(type_id)
	return String(data.get("name", "未知塔"))


static func tower_cost(type_id: String) -> int:
	var data := tower(type_id)
	return int(data.get("cost", 30))


static func _load_towers() -> void:
	if not _towers.is_empty():
		return
	_towers = _read_json(TOWERS_PATH)


static func _load_enemies() -> void:
	if not _enemies.is_empty():
		return
	_enemies = _read_json(ENEMIES_PATH)


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("資料檔不存在：%s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("資料檔無法讀取：%s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("資料檔格式錯誤：%s" % path)
		return {}
	return parsed
