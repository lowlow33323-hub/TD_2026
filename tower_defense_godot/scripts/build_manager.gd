extends RefCounted

const Defs = preload("res://scripts/game_defs.gd")
const Tower = preload("res://scripts/tower.gd")
const WaveManager = preload("res://scripts/wave_manager.gd")


static func validate_build(owner, cell: Vector2i) -> Dictionary:
	if owner.is_wave_active():
		return {"ok": false, "message": "進攻波進行中，不能建造新塔。"}

	if not owner.can_place_footprint(cell):
		return {"ok": false, "message": "2x2 塔需要完整空地，且不能覆蓋入口或出口。"}

	var build_cost: int = owner.tower_cost(owner.selected_build_type)
	if owner.gold < build_cost:
		return {"ok": false, "message": "金幣不足，無法建造 %s。" % owner.tower_name(owner.selected_build_type)}
	if owner.footprint_has_enemy(cell):
		return {"ok": false, "message": "敵人正在建造範圍內，不能直接建塔。"}

	var test_blocked: Dictionary = owner.blocked.duplicate()
	for footprint_cell in owner.footprint_cells(cell):
		test_blocked[footprint_cell] = true
	var new_path: Array[Vector2i] = owner.find_path(test_blocked)
	if new_path.is_empty():
		return {"ok": false, "message": "不能完全阻擋敵人的路線。"}

	return {"ok": true, "path": new_path}


static func try_build_or_select(owner, cell: Vector2i) -> void:
	var existing = owner.tower_at(cell)
	if existing != null:
		owner.selected_tower = existing
		owner.show_message("已選取 %s。按 U 可升級。" % existing.name)
		return

	owner.selected_tower = null
	var build_check := validate_build(owner, cell)
	if not bool(build_check["ok"]):
		owner.reject_build(String(build_check["message"]))
		return

	var build_cost: int = owner.tower_cost(owner.selected_build_type)
	var tower := Tower.new(cell, owner.selected_build_type)
	for footprint_cell in owner.footprint_cells(cell):
		owner.blocked[footprint_cell] = tower
	owner.towers.append(tower)
	owner.selected_tower = tower
	owner.set_current_path(build_check["path"])
	owner.gold -= build_cost
	owner.build_audio.play()
	owner.retarget_live_enemies()
	owner.show_message("已建造 2x2 %s，敵人會重新尋路。" % tower.name)


static func remove_tower(owner, cell: Vector2i) -> void:
	var tower = owner.tower_at(cell)
	if tower == null:
		owner.selected_tower = null
		return
	for footprint_cell in owner.footprint_cells(tower.cell):
		owner.blocked.erase(footprint_cell)
	owner.towers.erase(tower)
	if owner.selected_tower == tower:
		owner.selected_tower = null
	owner.set_current_path(owner.find_path(owner.blocked))
	var refund := WaveManager.tower_refund(tower.cost, owner.difficulty_id)
	owner.gold += refund
	owner.remove_audio.play()
	owner.add_floating_text(owner.tower_center(tower), "+%d" % refund, Color("#8ff0a4"))
	owner.retarget_live_enemies()
	owner.show_message("已拆除 %s。" % tower.name)


static func upgrade_selected_tower(owner) -> void:
	if owner.selected_tower == null or not owner.towers.has(owner.selected_tower):
		owner.show_message("請先選取一座塔。")
		return
	if owner.selected_tower.level >= Defs.MAX_TOWER_LEVEL:
		owner.show_message("%s 已經滿級。" % owner.selected_tower.name)
		return
	var cost: int = owner.selected_tower.upgrade_cost()
	if owner.gold < cost:
		owner.show_message("升級金幣不足，需要 $%d。" % cost)
		return
	owner.gold -= cost
	owner.selected_tower.upgrade()
	owner.mark_static_layer_dirty()
	owner.show_message("%s 已升到 %d 級。" % [owner.selected_tower.name, owner.selected_tower.level])


static func upgrade_selected_tower_to_max(owner) -> void:
	if owner.selected_tower == null or not owner.towers.has(owner.selected_tower):
		owner.show_message("請先選取一座塔。")
		return
	if owner.selected_tower.level >= Defs.MAX_TOWER_LEVEL:
		owner.show_message("%s 已經滿級。" % owner.selected_tower.name)
		return
	var upgraded := 0
	while owner.selected_tower.level < Defs.MAX_TOWER_LEVEL:
		var cost: int = owner.selected_tower.upgrade_cost()
		if owner.gold < cost:
			if upgraded > 0:
				owner.show_message("%s 已升到 %d 級，金幣不足無法繼續。" % [owner.selected_tower.name, owner.selected_tower.level])
			else:
				owner.show_message("升級金幣不足，需要 $%d。" % cost)
			return
		owner.gold -= cost
		owner.selected_tower.upgrade()
		owner.mark_static_layer_dirty()
		upgraded += 1
	owner.show_message("%s 已升到最高等。" % owner.selected_tower.name)
