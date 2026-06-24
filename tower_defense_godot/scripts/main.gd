extends Node2D

const Defs = preload("res://scripts/game_defs.gd")
const Tower = preload("res://scripts/tower.gd")
const Enemy = preload("res://scripts/enemy.gd")
const Projectile = preload("res://scripts/projectile.gd")
const Pathfinder = preload("res://scripts/pathfinder.gd")
const GameRenderer = preload("res://scripts/game_renderer.gd")
const GameUI = preload("res://scripts/game_ui.gd")
const GameData = preload("res://scripts/game_data.gd")
const WaveManager = preload("res://scripts/wave_manager.gd")
const SaveManager = preload("res://scripts/save_manager.gd")
const CombatManager = preload("res://scripts/combat_manager.gd")
const BuildManager = preload("res://scripts/build_manager.gd")
const AudioManager = preload("res://scripts/audio_manager.gd")
const DialogManager = preload("res://scripts/dialog_manager.gd")
const StaticBoardLayer = preload("res://scripts/static_board_layer.gd")
const GameFont = preload("res://fonts/NotoSansTC-Regular.ttf")

const INVALID_CELL := Vector2i(-999, -999)
const MAX_IMPACT_WAVES_NORMAL := 28
const MAX_IMPACT_WAVES_BUSY := 14
const BUSY_VISUAL_LOAD := 130
const BUILD_DURATION_CANNON := 0.3
const BUILD_DURATION_ARROW := 0.2
const BUILD_DURATION_ICE := 0.5

var blocked: Dictionary = {}
var towers: Array[Tower] = []
var enemies: Array[Enemy] = []
var projectiles: Array[Projectile] = []
var current_path: Array[Vector2i] = []
var selected_tower: Tower = null
var selected_build_type := Defs.TYPE_CANNON
var current_screen := Defs.SCREEN_MENU
var difficulty_id := Defs.DIFFICULTY_NORMAL
var game_speed := 1.0

var gold := 150
var lives := 12
var wave := 0
var enemies_to_spawn := 0
var enemies_spawned_this_wave := 0
var boss_to_spawn := false
var spawn_timer := 0.0
var next_wave_wait := 1.0
var waiting_next_wave := false
var auto_start_enabled := false
var boss_fight_active := false
var boss_fight_time := 0.0
var game_won := false
var audit_active := false
var audit_damage_taken := 0.0
var audit_elapsed_time := 0.0
var boss_leaderboard: Array[Dictionary] = []
var message := "按 1/2/3 或點選按鈕選塔。左鍵建造或選取，U 升級，右鍵拆除。"
var message_time := 4.0
var saved_game_data: Dictionary = {}
var has_saved_game := false
var hover_cell := INVALID_CELL
var hover_can_build := false
var spawn_flash_timer := 0.0
var wave_banner_timer := 0.0
var life_flash_timer := 0.0
var show_enemy_path := true
var floating_texts: Array[Dictionary] = []
var impact_waves: Array[Dictionary] = []
var impact_wave_skip_counter := 0
var music_enabled := true
var sfx_enabled := true
var music_volume := 1.0
var sfx_volume := 1.0
var confirmation_dialog_open := false
var touch_build_mode := false
var touch_pending_build_cell := INVALID_CELL
var touch_pending_can_build := false
var touch_mouse_suppress_until_msec := 0
var touch_input_seen := false
var build_confirm_enabled := true
var build_in_progress := false
var build_in_progress_cell := INVALID_CELL
var build_in_progress_type := Defs.TYPE_CANNON
var build_progress_time := 0.0

var cell_size := 24.0
var grid_origin := Vector2.ZERO
var grid_rect := Rect2()
var ui_scale := 1.0
var last_viewport_size := Vector2.ZERO
var static_layer_signature := ""
var ui_update_signature := ""
var last_hover_path_cell := INVALID_CELL
var last_hover_path_result := false

@onready var static_board_layer: Node2D = StaticBoardLayer.new()
@onready var ui_layer: CanvasLayer = CanvasLayer.new()
@onready var menu_panel: PanelContainer = PanelContainer.new()
@onready var rules_panel: PanelContainer = PanelContainer.new()
@onready var ranking_panel: PanelContainer = PanelContainer.new()
@onready var difficulty_panel: PanelContainer = PanelContainer.new()
@onready var game_panel: PanelContainer = PanelContainer.new()
@onready var game_over_panel: PanelContainer = PanelContainer.new()
@onready var tower_buttons_box: VBoxContainer = VBoxContainer.new()
@onready var speed_buttons_box: HBoxContainer = HBoxContainer.new()
@onready var game_actions_box: HBoxContainer = HBoxContainer.new()
@onready var game_options_box: VBoxContainer = VBoxContainer.new()
@onready var stats_label: Label = Label.new()
@onready var hint_label: Label = Label.new()
@onready var tower_label: Label = Label.new()
@onready var leaderboard_label: Label = Label.new()
@onready var game_difficulty_label: Label = Label.new()
@onready var menu_title: Label = Label.new()
@onready var menu_version_label: Label = Label.new()
@onready var rules_label: Label = Label.new()
@onready var ranking_label: Label = Label.new()
@onready var difficulty_label: Label = Label.new()
@onready var game_over_title_label: Label = Label.new()
@onready var game_over_detail_label: Label = Label.new()
@onready var start_button: Button = Button.new()
@onready var rules_button: Button = Button.new()
@onready var ranking_button: Button = Button.new()
@onready var difficulty_button: Button = Button.new()
@onready var load_button: Button = Button.new()
@onready var back_from_rules_button: Button = Button.new()
@onready var back_from_ranking_button: Button = Button.new()
@onready var back_from_difficulty_button: Button = Button.new()
@onready var easy_button: Button = Button.new()
@onready var normal_button: Button = Button.new()
@onready var hard_button: Button = Button.new()
@onready var cannon_button: Button = Button.new()
@onready var arrow_button: Button = Button.new()
@onready var ice_button: Button = Button.new()
@onready var wave_button: Button = Button.new()
@onready var wave_countdown_label: Label = Label.new()
@onready var speed_1_button: Button = Button.new()
@onready var speed_2_button: Button = Button.new()
@onready var speed_3_button: Button = Button.new()
@onready var speed_4_button: Button = Button.new()
@onready var speed_5_button: Button = Button.new()
@onready var save_button: Button = Button.new()
@onready var main_menu_button: Button = Button.new()
@onready var exit_button: Button = Button.new()
@onready var game_over_menu_button: Button = Button.new()
@onready var game_over_ranking_button: Button = Button.new()
@onready var path_toggle: CheckBox = CheckBox.new()
@onready var auto_start_toggle: CheckBox = CheckBox.new()
@onready var build_confirm_toggle: CheckBox = CheckBox.new()
@onready var music_toggle: CheckBox = CheckBox.new()
@onready var sfx_toggle: CheckBox = CheckBox.new()
@onready var music_volume_slider: HSlider = HSlider.new()
@onready var sfx_volume_slider: HSlider = HSlider.new()
@onready var cannon_audio: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var arrow_audio: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var ice_audio: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var wave_audio: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var error_audio: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var build_audio: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var remove_audio: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var bgm_audio: AudioStreamPlayer = AudioStreamPlayer.new()


func _ready() -> void:
	static_board_layer.owner_node = self
	static_board_layer.z_index = -10
	add_child(static_board_layer)
	add_child(ui_layer)
	_build_audio()
	_build_ui()
	_connect_ui()
	_load_meta_data()
	_reset_game_state()
	show_screen(Defs.SCREEN_MENU)
	set_process(true)


func _build_audio() -> void:
	AudioManager.build(self)


func _apply_audio_settings() -> void:
	AudioManager.apply_settings(self)

func _build_ui() -> void:
	GameUI.build(self)


func _connect_ui() -> void:
	GameUI.connect_buttons(self)


func _process(delta: float) -> void:
	_update_layout()
	update_static_layer_if_needed()
	_update_hover_cell()
	if current_screen == Defs.SCREEN_GAME and lives > 0 and not game_won and not confirmation_dialog_open:
		var game_delta := delta * game_speed
		_update_pending_build(delta)
		if boss_fight_active:
			boss_fight_time += game_delta
		if audit_active:
			audit_elapsed_time += game_delta
		_update_spawn(game_delta)
		_update_enemies(game_delta)
		_update_towers(game_delta)
		_update_projectiles(game_delta)

	if message_time > 0.0:
		message_time -= delta
	if spawn_flash_timer > 0.0:
		spawn_flash_timer = max(0.0, spawn_flash_timer - delta)
	if wave_banner_timer > 0.0:
		wave_banner_timer = max(0.0, wave_banner_timer - delta)
	if life_flash_timer > 0.0:
		life_flash_timer = max(0.0, life_flash_timer - delta)
	_update_floating_texts(delta)

	_update_ui()
	queue_redraw()


func _update_layout() -> void:
	GameUI.update_layout(self)
	update_static_layer_if_needed()


func show_screen(screen: String) -> void:
	if screen != Defs.SCREEN_GAME:
		cancel_pending_build()
	GameUI.show_screen(self, screen)
	mark_static_layer_dirty()


func start_new_game() -> void:
	_reset_game_state()
	show_screen(Defs.SCREEN_GAME)
	show_message("新遊戲開始：%s。" % difficulty_name())


func load_saved_game() -> void:
	if not has_saved_game:
		show_message("目前沒有可讀取的存檔。")
		return
	_reset_game_state()
	difficulty_id = String(saved_game_data.get("difficulty", difficulty_id))
	gold = int(saved_game_data.get("gold", starting_gold()))
	lives = int(saved_game_data.get("lives", starting_lives()))
	wave = int(saved_game_data.get("wave", 0))
	var loaded_towers = saved_game_data.get("towers", [])
	if typeof(loaded_towers) == TYPE_ARRAY:
		for entry in loaded_towers:
			if typeof(entry) != TYPE_DICTIONARY:
				continue
			var tower_cell := Vector2i(int(entry.get("x", 0)), int(entry.get("y", 0)))
			if not can_place_footprint(tower_cell):
				continue
			var tower := Tower.new(tower_cell, String(entry.get("type", Defs.TYPE_CANNON)), int(entry.get("level", 1)))
			for footprint_cell in footprint_cells(tower.cell):
				blocked[footprint_cell] = tower
			towers.append(tower)
	set_current_path(find_path(blocked))
	show_screen(Defs.SCREEN_GAME)
	show_message("已讀取存檔。")


func _reset_game_state() -> void:
	blocked.clear()
	towers.clear()
	enemies.clear()
	projectiles.clear()
	selected_tower = null
	selected_build_type = Defs.TYPE_CANNON
	game_speed = 1.0
	show_enemy_path = true
	floating_texts.clear()
	impact_waves.clear()
	gold = starting_gold()
	lives = starting_lives()
	wave = 0
	enemies_to_spawn = 0
	enemies_spawned_this_wave = 0
	boss_to_spawn = false
	spawn_timer = 0.0
	next_wave_wait = 1.0
	waiting_next_wave = false
	boss_fight_active = false
	boss_fight_time = 0.0
	game_won = false
	audit_active = false
	audit_damage_taken = 0.0
	audit_elapsed_time = 0.0
	spawn_flash_timer = 0.0
	wave_banner_timer = 0.0
	life_flash_timer = 0.0
	cancel_pending_build()
	set_current_path(find_path(blocked))


func _unhandled_input(event: InputEvent) -> void:
	if current_screen != Defs.SCREEN_GAME or lives <= 0 or game_won:
		return
	if event is InputEventScreenTouch and event.pressed:
		touch_input_seen = true
		touch_mouse_suppress_until_msec = Time.get_ticks_msec() + 350
		var touch_cell := world_to_cell(event_position_to_world(event.position))
		if build_confirm_enabled:
			handle_touch_primary_action(touch_cell)
		else:
			if not is_inside_grid(touch_cell):
				selected_tower = null
				clear_touch_build_preview()
				get_viewport().set_input_as_handled()
				return
			touch_build_mode = false
			clear_touch_build_preview()
			try_build_or_select(touch_cell)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseButton and event.pressed:
		if Time.get_ticks_msec() < touch_mouse_suppress_until_msec:
			get_viewport().set_input_as_handled()
			return
		var cell := world_to_cell(get_global_mouse_position())
		if touch_input_seen and event.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			return
		if not is_inside_grid(cell):
			selected_tower = null
			clear_touch_build_preview()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if build_confirm_enabled:
				handle_touch_primary_action(cell)
			else:
				touch_build_mode = false
				clear_touch_build_preview()
				try_build_or_select(cell)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			touch_build_mode = false
			clear_touch_build_preview()
			remove_tower(cell)
	elif event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1:
				select_build_type(Defs.TYPE_CANNON)
			KEY_2:
				select_build_type(Defs.TYPE_ARROW)
			KEY_3:
				select_build_type(Defs.TYPE_ICE)
			KEY_N:
				start_wave()
			KEY_U:
				upgrade_selected_tower()
			KEY_I:
				upgrade_selected_tower_to_max()
			KEY_D:
				step_game_speed(1)
			KEY_S:
				step_game_speed(-1)
			KEY_R:
				toggle_enemy_path()
			KEY_A:
				toggle_auto_start()
			KEY_B:
				set_build_confirm_enabled(not build_confirm_enabled)
			KEY_ESCAPE:
				show_screen(Defs.SCREEN_MENU)


func set_difficulty(id: String) -> void:
	difficulty_id = id
	_save_meta_data()
	show_message("難度已調整為：%s。" % difficulty_name())
	_update_ui()


func difficulty_name() -> String:
	return WaveManager.difficulty_name(difficulty_id)


func starting_gold() -> int:
	return WaveManager.starting_gold(difficulty_id)


func starting_lives() -> int:
	return WaveManager.starting_lives(difficulty_id)


func enemy_hp_multiplier() -> float:
	return WaveManager.enemy_hp_multiplier(difficulty_id)


func enemy_speed_multiplier() -> float:
	return WaveManager.enemy_speed_multiplier(difficulty_id)


func select_build_type(type_id: String) -> void:
	selected_build_type = type_id
	cancel_pending_build()
	show_message("已選擇建造：%s。" % tower_name(type_id))


func set_game_speed(speed: float) -> void:
	game_speed = speed
	show_message("遊戲速度調整為 %.0f 倍。" % game_speed)


func step_game_speed(direction: int) -> void:
	var speeds: Array[float] = [1.0, 2.0, 4.0, 16.0]
	var index := 0
	for i in range(speeds.size()):
		if is_equal_approx(game_speed, speeds[i]):
			index = i
			break
	if direction > 0:
		index = min(index + 1, speeds.size() - 1)
	else:
		index = max(index - 1, 0)
	set_game_speed(speeds[index])


func toggle_enemy_path() -> void:
	show_enemy_path = not show_enemy_path
	mark_static_layer_dirty()
	show_message("敵人路徑顯示：%s。" % ("開啟" if show_enemy_path else "關閉"))


func toggle_auto_start() -> void:
	auto_start_enabled = not auto_start_enabled
	show_message("自動開始：%s。" % ("開啟" if auto_start_enabled else "關閉"))
	if auto_start_enabled and waiting_next_wave and not is_wave_active():
		start_wave()


func set_build_confirm_enabled(enabled: bool) -> void:
	build_confirm_enabled = enabled
	if not build_confirm_enabled:
		cancel_pending_build()
	show_message("建造二次確認：%s。" % ("開啟" if build_confirm_enabled else "關閉"))
	_update_ui()


func try_build_or_select(cell: Vector2i) -> void:
	BuildManager.try_build_or_select(self, cell)


func handle_touch_primary_action(cell: Vector2i) -> void:
	if build_in_progress:
		show_message("正在建造中，請稍候。")
		return
	touch_build_mode = true
	if not is_inside_grid(cell):
		selected_tower = null
		clear_touch_build_preview()
		return

	var existing := tower_at(cell)
	if existing != null:
		selected_tower = existing
		clear_touch_build_preview()
		show_message("已選取 %s。按 U 可升級。" % existing.name)
		return

	if pending_build_contains_cell(cell) and touch_pending_can_build:
		start_pending_build(touch_pending_build_cell)
		return

	var build_check := BuildManager.validate_build(self, cell)
	touch_pending_build_cell = cell
	touch_pending_can_build = bool(build_check["ok"])
	hover_cell = cell
	hover_can_build = touch_pending_can_build
	last_hover_path_cell = INVALID_CELL
	if touch_pending_can_build:
		selected_tower = null
		show_message("再次點擊此位置建造%s。" % tower_name(selected_build_type))
	else:
		reject_build(String(build_check["message"]))
	queue_redraw()


func start_pending_build(cell: Vector2i) -> void:
	var build_check := BuildManager.validate_build(self, cell)
	if not bool(build_check["ok"]):
		reject_build(String(build_check["message"]))
		clear_touch_build_preview()
		return
	build_in_progress = true
	build_in_progress_cell = cell
	build_in_progress_type = selected_build_type
	build_progress_time = 0.0
	touch_pending_build_cell = cell
	touch_pending_can_build = true
	hover_cell = cell
	hover_can_build = true
	show_message("正在建造%s..." % tower_name(build_in_progress_type))


func pending_build_contains_cell(cell: Vector2i) -> bool:
	if touch_pending_build_cell == INVALID_CELL:
		return false
	return footprint_cells(touch_pending_build_cell).has(cell)


func build_duration_for_type(type_id: String) -> float:
	match type_id:
		Defs.TYPE_ARROW:
			return BUILD_DURATION_ARROW
		Defs.TYPE_CANNON:
			return BUILD_DURATION_CANNON
		Defs.TYPE_ICE:
			return BUILD_DURATION_ICE
	return BUILD_DURATION_CANNON


func _update_pending_build(delta: float) -> void:
	if not build_in_progress:
		return
	if current_screen != Defs.SCREEN_GAME or is_wave_active() or lives <= 0 or game_won:
		cancel_pending_build()
		return
	build_progress_time += delta
	if build_progress_time < build_duration_for_type(build_in_progress_type):
		return
	var cell := build_in_progress_cell
	var type_id := build_in_progress_type
	cancel_pending_build()
	selected_build_type = type_id
	try_build_or_select(cell)


func cancel_pending_build() -> void:
	build_in_progress = false
	build_in_progress_cell = INVALID_CELL
	build_in_progress_type = selected_build_type
	build_progress_time = 0.0
	touch_build_mode = false
	clear_touch_build_preview()


func clear_touch_build_preview() -> void:
	touch_pending_build_cell = INVALID_CELL
	touch_pending_can_build = false
	if touch_build_mode:
		hover_cell = INVALID_CELL
		hover_can_build = false
		last_hover_path_cell = INVALID_CELL


func remove_tower(cell: Vector2i) -> void:
	cancel_pending_build()
	BuildManager.remove_tower(self, cell)


func upgrade_selected_tower() -> void:
	BuildManager.upgrade_selected_tower(self)


func upgrade_selected_tower_to_max() -> void:
	BuildManager.upgrade_selected_tower_to_max(self)


func start_wave() -> void:
	cancel_pending_build()
	WaveManager.start_wave(self)


func _update_spawn(delta: float) -> void:
	WaveManager.update_spawn(self, delta)


func spawn_enemy(is_boss: bool, enemy_type: String) -> void:
	var path := find_path(blocked)
	if path.is_empty():
		return
	set_current_path(path)
	var start_pos := cell_center(path[0])
	var enemy := Enemy.new(path, start_pos, wave, is_boss, enemy_type, enemy_hp_multiplier(), enemy_speed_multiplier())
	if enemy.is_flying:
		enemy.path = [Defs.START, Defs.GOAL]
		enemy.index = 0
	enemies.append(enemy)
	if is_boss:
		boss_fight_active = true
		boss_fight_time = 0.0


func start_damage_audit() -> void:
	if audit_active or game_won:
		return
	var path := find_path(blocked)
	if path.is_empty():
		path = [Defs.START, Defs.GOAL]
	set_current_path(path)
	var auditor := Enemy.new(path, cell_center(path[0]), Defs.FINAL_WAVE, false, Defs.ENEMY_AUDITOR, 1.0, 1.0)
	enemies.append(auditor)
	audit_active = true
	audit_damage_taken = 0.0
	audit_elapsed_time = 0.0
	show_message("攻擊量審查員出現，正在記錄承受傷害。")


func _update_hover_cell() -> void:
	if current_screen != Defs.SCREEN_GAME or is_wave_active() or lives <= 0 or game_won:
		hover_cell = INVALID_CELL
		hover_can_build = false
		last_hover_path_cell = INVALID_CELL
		clear_touch_build_preview()
		return
	if touch_build_mode:
		hover_cell = touch_pending_build_cell
		hover_can_build = touch_pending_build_cell != INVALID_CELL and touch_pending_can_build
		return
	var mouse_cell := world_to_cell(get_global_mouse_position())
	if not is_inside_grid(mouse_cell):
		hover_cell = INVALID_CELL
		hover_can_build = false
		last_hover_path_cell = INVALID_CELL
		return
	hover_cell = mouse_cell
	if hover_cell == last_hover_path_cell:
		hover_can_build = last_hover_path_result and not footprint_has_enemy(hover_cell)
		return
	last_hover_path_cell = hover_cell
	hover_can_build = bool(BuildManager.validate_build(self, hover_cell)["ok"])
	last_hover_path_result = hover_can_build


func enemy_type_for_spawn(spawn_index: int) -> String:
	return WaveManager.enemy_type_for_spawn(wave, spawn_index)


func _update_enemies(delta: float) -> void:
	for i in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[i]
		enemy.tick_status(delta)
		if enemy.is_waiting_revive():
			continue
		if _handle_defeated_enemy(enemy, i):
			continue
		if enemy.index >= enemy.path.size() - 1:
			if enemy.is_auditor:
				finish_damage_audit()
				enemies.remove_at(i)
				continue
			lose_life(3 if enemy.is_boss else 1)
			if enemy.is_boss:
				boss_fight_active = false
				show_message("Boss 抵達出口，這次沒有列入排行榜。")
			enemies.remove_at(i)
			continue

		var target := cell_center(enemy.path[enemy.index + 1])
		var direction := target - enemy.pos
		var distance := direction.length()
		var step := enemy.current_speed() * delta
		if distance > 0.001:
			enemy.facing_dir = direction.normalized()
		if distance <= step:
			enemy.pos = target
			enemy.index += 1
		else:
			enemy.pos += direction.normalized() * step

		_handle_defeated_enemy(enemy, i)


func _handle_defeated_enemy(enemy: Enemy, enemy_index: int) -> bool:
	if enemy.hp > 0.0:
		return false
	if enemy.is_auditor:
		enemy.hp = max(enemy.max_hp, 1.0)
		return true
	if enemy.can_revive():
		enemy.begin_revive_wait()
		add_floating_text(enemy.pos, "墓碑", Color("#d8d0bf"))
		return true
	if enemy.is_boss:
		record_boss_kill(wave, boss_fight_time)
	var reward := WaveManager.reward_for_enemy(enemy.reward, difficulty_id)
	gold += reward
	add_floating_text(enemy.pos, "+%d" % reward, Color("#ffe48a"))
	enemies.remove_at(enemy_index)
	return true


func _update_towers(delta: float) -> void:
	CombatManager.update_towers(self, delta)


func play_tower_sound(type_id: String) -> void:
	match type_id:
		Defs.TYPE_CANNON:
			cannon_audio.play()
		Defs.TYPE_ARROW:
			arrow_audio.play()
		Defs.TYPE_ICE:
			ice_audio.play()


func lose_life(amount: int) -> void:
	lives -= amount
	life_flash_timer = 0.65


func record_boss_kill(boss_wave: int, clear_time: float) -> void:
	boss_fight_active = false
	show_message("Boss 擊倒！")


func finish_damage_audit() -> void:
	audit_active = false
	game_won = true
	boss_leaderboard.append({
		"damage": int(round(audit_damage_taken)),
		"time": audit_elapsed_time,
		"difficulty": difficulty_name()
	})
	boss_leaderboard.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a.get("damage", 0)) > int(b.get("damage", 0))
	)
	while boss_leaderboard.size() > 5:
		boss_leaderboard.pop_back()
	_save_meta_data()
	show_message("審查完成：承受 %d 傷害，用時 %.1f 秒。" % [int(round(audit_damage_taken)), audit_elapsed_time])


func leaderboard_text() -> String:
	if audit_active:
		return "攻擊量審查：%d 傷害 / %.1f 秒 | 排行榜：%s" % [int(round(audit_damage_taken)), audit_elapsed_time, boss_rank_summary()]
	return "攻擊量排行榜：%s" % boss_rank_summary()


func boss_rank_summary() -> String:
	if boss_leaderboard.is_empty():
		return "尚無紀錄"
	var parts := PackedStringArray()
	for i in range(boss_leaderboard.size()):
		var entry: Dictionary = boss_leaderboard[i]
		var diff := String(entry.get("difficulty", "普通"))
		parts.append("%d. %s %d 傷害 %.1f秒" % [i + 1, diff, int(entry.get("damage", 0)), float(entry.get("time", 0.0))])
	return " | ".join(parts)


func _update_projectiles(delta: float) -> void:
	CombatManager.update_projectiles(self, delta)


func visual_load() -> int:
	return enemies.size() + projectiles.size() + impact_waves.size()


func tower_at(cell: Vector2i) -> Tower:
	for tower in towers:
		if footprint_cells(tower.cell).has(cell):
			return tower
	return null


func can_place_footprint(cell: Vector2i) -> bool:
	for footprint_cell in footprint_cells(cell):
		if not is_inside_grid(footprint_cell):
			return false
		if footprint_cell == Defs.START or footprint_cell == Defs.GOAL:
			return false
		if blocked.has(footprint_cell):
			return false
	return true


func footprint_cells(cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	for y in range(Defs.TOWER_SIZE):
		for x in range(Defs.TOWER_SIZE):
			cells.append(cell + Vector2i(x, y))
	return cells


func footprint_has_enemy(cell: Vector2i) -> bool:
	for footprint_cell in footprint_cells(cell):
		for enemy in enemies:
			if world_to_cell(enemy.pos) == footprint_cell:
				return true
	return false


func is_wave_active() -> bool:
	return enemies_to_spawn > 0 or boss_to_spawn or not enemies.is_empty()


func retarget_live_enemies() -> void:
	for enemy in enemies:
		var from_cell := world_to_cell(enemy.pos)
		var fresh_path := find_path_from(from_cell, blocked)
		if not fresh_path.is_empty():
			enemy.path = fresh_path
			enemy.index = 0


func find_path(block_map: Dictionary) -> Array[Vector2i]:
	return Pathfinder.find_path(block_map)


func find_path_from(start_cell: Vector2i, block_map: Dictionary) -> Array[Vector2i]:
	return Pathfinder.find_path_from(start_cell, block_map)


func tower_cost(type_id: String) -> int:
	return GameData.tower_cost(type_id)


func tower_name(type_id: String) -> String:
	return GameData.tower_name(type_id)


func is_inside_grid(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < Defs.GRID_W and cell.y >= 0 and cell.y < Defs.GRID_H


func world_to_cell(pos: Vector2) -> Vector2i:
	var local := pos - grid_origin
	return Vector2i(floori(local.x / cell_size), floori(local.y / cell_size))


func event_position_to_world(pos: Vector2) -> Vector2:
	return get_canvas_transform().affine_inverse() * pos


func cell_center(cell: Vector2i) -> Vector2:
	return grid_origin + Vector2(cell.x * cell_size + cell_size * 0.5, cell.y * cell_size + cell_size * 0.5)


func tower_center(tower: Tower) -> Vector2:
	return cell_center(tower.cell) + Vector2(cell_size * 0.5, cell_size * 0.5)


func show_message(text: String) -> void:
	message = text
	message_time = 2.2


func add_floating_text(pos: Vector2, text: String, color: Color) -> void:
	floating_texts.append({
		"pos": pos,
		"text": text,
		"color": color,
		"time": 0.9
	})


func add_impact_wave(pos: Vector2, color: Color, direction: Vector2) -> void:
	var load := visual_load()
	var max_impacts := MAX_IMPACT_WAVES_BUSY if load >= BUSY_VISUAL_LOAD else MAX_IMPACT_WAVES_NORMAL
	if impact_waves.size() >= max_impacts:
		return
	if load >= BUSY_VISUAL_LOAD:
		impact_wave_skip_counter += 1
		if impact_wave_skip_counter % 3 != 0:
			return
	if direction.length_squared() <= 0.001:
		direction = Vector2.RIGHT
	impact_waves.append({
		"pos": pos,
		"color": color,
		"dir": direction.normalized(),
		"time": 0.32,
		"duration": 0.32
	})


func _update_floating_texts(delta: float) -> void:
	for i in range(floating_texts.size() - 1, -1, -1):
		floating_texts[i]["time"] = float(floating_texts[i]["time"]) - delta
		floating_texts[i]["pos"] = Vector2(floating_texts[i]["pos"]) + Vector2(0, -28.0 * delta)
		if float(floating_texts[i]["time"]) <= 0.0:
			floating_texts.remove_at(i)
	for i in range(impact_waves.size() - 1, -1, -1):
		impact_waves[i]["time"] = float(impact_waves[i]["time"]) - delta
		if float(impact_waves[i]["time"]) <= 0.0:
			impact_waves.remove_at(i)


func confirm_return_to_menu() -> void:
	popup_confirmation("回主選單", "確定要回主選單？目前波次進度若未存檔會遺失。", func() -> void:
		show_screen(Defs.SCREEN_MENU)
	)


func confirm_exit_game() -> void:
	popup_confirmation("退出遊戲", "確定要退出遊戲？", func() -> void:
		get_tree().quit()
	)


func popup_confirmation(title: String, text: String, confirmed_action: Callable) -> void:
	DialogManager.popup_confirmation(self, title, text, confirmed_action)


func reject_build(text: String) -> void:
	show_message(text)
	error_audio.play()


func save_game() -> void:
	if is_wave_active():
		show_message("敵人出現時不能存檔，請在波與波之間存檔。")
		error_audio.play()
		return
	var data := SaveManager.build_save_data(self)
	if not SaveManager.save_game_data(data):
		show_message("存檔失敗。")
		return
	saved_game_data = data
	has_saved_game = true
	_save_meta_data()
	show_message("已存檔。")


func _load_meta_data() -> void:
	SaveManager.apply_loaded_data(self)


func _read_json_file(path: String) -> Dictionary:
	return SaveManager.read_json_file(path)


func _save_meta_data() -> void:
	SaveManager.save_meta_data(difficulty_id, boss_leaderboard)


func _update_ui() -> void:
	var signature := build_ui_update_signature()
	if signature == ui_update_signature:
		return
	ui_update_signature = signature
	GameUI.update(self)


func mark_static_layer_dirty() -> void:
	static_layer_signature = ""
	last_hover_path_cell = INVALID_CELL
	if is_instance_valid(static_board_layer):
		static_board_layer.queue_redraw()


func update_static_layer_if_needed() -> void:
	if not is_instance_valid(static_board_layer):
		return
	var signature := build_static_layer_signature()
	if signature == static_layer_signature:
		return
	static_layer_signature = signature
	static_board_layer.queue_redraw()


func build_ui_update_signature() -> String:
	var selected_id := "none"
	var selected_level := 0
	var selected_cost := 0
	if selected_tower != null and towers.has(selected_tower):
		selected_id = "%d,%d,%s" % [selected_tower.cell.x, selected_tower.cell.y, selected_tower.type_id]
		selected_level = selected_tower.level
		selected_cost = selected_tower.upgrade_cost() if selected_tower.level < Defs.MAX_TOWER_LEVEL else 0
	var countdown := ceili(next_wave_wait) if waiting_next_wave and not auto_start_enabled else -1
	var flash_step := ceili(life_flash_timer * 10.0)
	var message_visible := message if message_time > 0.0 else ""
	return "%s|%d|%d|%d|%.0f|%s|%s|%d|%d|%s|%s|%s|%s|%s|%s|%s|%.2f|%.2f|%d|%s|%s|%d|%.1f|%s|%d" % [
		current_screen,
		gold,
		lives,
		wave,
		game_speed,
		difficulty_id,
		selected_build_type,
		enemies_to_spawn,
		enemies.size(),
		str(boss_to_spawn),
		str(waiting_next_wave),
		str(auto_start_enabled),
		str(build_confirm_enabled),
		str(show_enemy_path),
		str(music_enabled),
		str(sfx_enabled),
		music_volume,
		sfx_volume,
		countdown,
		selected_id,
		message_visible,
		flash_step,
		audit_damage_taken,
		str(game_won),
		selected_level + selected_cost
	]


func build_static_layer_signature() -> String:
	var viewport_size := get_viewport_rect().size
	var blocked_cells: Array = blocked.keys()
	blocked_cells.sort()
	var path_cells: Array = []
	for cell in current_path:
		path_cells.append("%d,%d" % [cell.x, cell.y])
	return "%s|%s|%.1f,%.1f|%.2f|%.1f,%.1f,%.1f,%.1f|%s|%s|%s|%s" % [
		current_screen,
		str(viewport_size),
		grid_origin.x,
		grid_origin.y,
		cell_size,
		grid_rect.position.x,
		grid_rect.position.y,
		grid_rect.size.x,
		grid_rect.size.y,
		str(blocked_cells),
		"|".join(path_cells),
		str(show_enemy_path),
		str(wave > 0 and wave % 10 == 0 and (boss_to_spawn or not enemies.is_empty()))
	]


func set_current_path(path: Array) -> void:
	if path_signature(path) == path_signature(current_path):
		current_path = path
		return
	current_path = path
	mark_static_layer_dirty()


func path_signature(path: Array) -> String:
	var parts: Array = []
	for cell in path:
		parts.append("%d,%d" % [cell.x, cell.y])
	return "|".join(parts)


func render_state() -> Dictionary:
	return {
		"current_screen": current_screen,
		"grid_rect": grid_rect,
		"grid_origin": grid_origin,
		"cell_size": cell_size,
		"blocked": blocked,
		"current_path": current_path,
		"show_enemy_path": show_enemy_path,
		"hover_cell": hover_cell,
		"hover_can_build": hover_can_build,
		"preview_tower_type": build_in_progress_type if build_in_progress else selected_build_type,
		"build_confirm_enabled": build_confirm_enabled,
		"build_in_progress": build_in_progress,
		"build_progress": clampf(build_progress_time / build_duration_for_type(build_in_progress_type), 0.0, 1.0) if build_in_progress else 0.0,
		"spawn_flash_timer": spawn_flash_timer,
		"wave_banner_timer": wave_banner_timer,
		"wave": wave,
		"game_speed": game_speed,
		"is_boss_wave_active": wave > 0 and wave % 10 == 0 and (boss_to_spawn or not enemies.is_empty()),
		"towers": towers,
		"selected_tower": selected_tower,
		"enemies": enemies,
		"projectiles": projectiles,
		"visual_load": visual_load(),
		"floating_texts": floating_texts,
		"impact_waves": impact_waves,
		"lives": lives,
		"difficulty_name": difficulty_name(),
		"font": GameFont
	}


func _draw_static_layer(canvas: Node2D) -> void:
	GameRenderer.render_static(canvas, render_state())


func _draw() -> void:
	GameRenderer.render_dynamic(self, render_state())
