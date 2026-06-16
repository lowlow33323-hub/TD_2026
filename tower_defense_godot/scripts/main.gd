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
var hover_cell := Vector2i(-999, -999)
var hover_can_build := false
var spawn_flash_timer := 0.0
var wave_banner_timer := 0.0
var life_flash_timer := 0.0
var show_enemy_path := true
var floating_texts: Array[Dictionary] = []
var impact_waves: Array[Dictionary] = []
var music_enabled := true
var sfx_enabled := true
var music_volume := 1.0
var sfx_volume := 1.0

var cell_size := 24.0
var grid_origin := Vector2.ZERO
var grid_rect := Rect2()
var ui_scale := 1.0
var last_viewport_size := Vector2.ZERO

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
	add_child(ui_layer)
	_build_audio()
	_build_ui()
	_connect_ui()
	_load_meta_data()
	_reset_game_state()
	show_screen(Defs.SCREEN_MENU)
	set_process(true)


func _build_audio() -> void:
	cannon_audio.stream = make_tone(72.0, 0.26, 0.62, 3)
	arrow_audio.stream = make_tone(940.0, 0.09, 0.28, 4)
	ice_audio.stream = make_tone(610.0, 0.20, 0.34, 5)
	wave_audio.stream = make_tone(118.0, 0.42, 0.56, 6)
	error_audio.stream = make_tone(145.0, 0.16, 0.42, 1)
	build_audio.stream = make_tone(760.0, 0.48, 0.38, 7)
	remove_audio.stream = make_tone(260.0, 0.16, 0.34, 8)
	bgm_audio.stream = make_music_loop()
	for player in [cannon_audio, arrow_audio, ice_audio, wave_audio, error_audio, build_audio, remove_audio, bgm_audio]:
		player.max_polyphony = 6
		add_child(player)
	bgm_audio.finished.connect(func() -> void:
		bgm_audio.play()
	)
	_apply_audio_settings()
	bgm_audio.play()


func make_tone(frequency: float, duration: float, volume: float, style: int) -> AudioStreamWAV:
	var mix_rate := 44100
	var sample_count := int(duration * mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / float(mix_rate)
		var fade := 1.0 - clampf(t / duration, 0.0, 1.0)
		var sample := sin(TAU * frequency * t)
		if style == 1:
			sample = sin(TAU * frequency * t) * 0.75 + sin(TAU * frequency * 0.5 * t) * 0.35
		elif style == 2:
			sample = sin(TAU * frequency * t) * 0.6 + sin(TAU * frequency * 1.52 * t) * 0.35
		elif style == 3:
			sample = sin(TAU * frequency * t) * 0.85 + sin(TAU * frequency * 0.5 * t) * 0.55 + sin(TAU * frequency * 2.0 * t) * 0.18
			sample += randf_range(-0.16, 0.16) * fade
		elif style == 4:
			sample = sin(TAU * frequency * t) * 0.55 + sin(TAU * frequency * 1.98 * t) * 0.2
			if t > duration * 0.45:
				sample *= 0.35
		elif style == 5:
			sample = sin(TAU * frequency * t) * 0.45 + sin(TAU * (frequency * 1.34 + 90.0 * t) * t) * 0.38
			sample += sin(TAU * frequency * 2.01 * t) * 0.16
		elif style == 6:
			var beat := 1.0 if fmod(t, 0.18) < 0.055 else 0.22
			sample = (sin(TAU * frequency * t) * 0.9 + sin(TAU * frequency * 0.5 * t) * 0.45) * beat
			sample += randf_range(-0.12, 0.12) * beat
		elif style == 7:
			var strike_time := fmod(t, 0.16)
			var strike_fade := 1.0 - clampf(strike_time / 0.09, 0.0, 1.0)
			var strike_on := 1.0 if t < 0.42 and strike_time < 0.09 else 0.0
			sample = (sin(TAU * frequency * t) * 0.55 + sin(TAU * frequency * 1.62 * t) * 0.32) * strike_fade * strike_on
			sample += randf_range(-0.18, 0.18) * strike_fade * strike_on
		elif style == 8:
			sample = sin(TAU * (frequency - 80.0 * t) * t) * 0.55 + sin(TAU * frequency * 0.5 * t) * 0.18
		var value := int(clampf(sample * fade * volume, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream


func make_music_loop() -> AudioStreamWAV:
	var mix_rate := 44100
	var duration := 8.0
	var sample_count := int(duration * mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var notes: Array[float] = [196.0, 246.94, 293.66, 392.0, 349.23, 293.66, 246.94, 220.0]
	for i in range(sample_count):
		var t: float = float(i) / float(mix_rate)
		var beat_index: int = int(floor(t * 4.0)) % notes.size()
		var local_t: float = fmod(t, 0.25)
		var fade: float = min(1.0, local_t / 0.025) * min(1.0, (0.25 - local_t) / 0.045)
		var note: float = notes[beat_index]
		var kick_phase: float = fmod(t, 0.5)
		var kick: float = sin(TAU * (86.0 - 45.0 * kick_phase) * t) * max(0.0, 1.0 - kick_phase * 8.0)
		var hat: float = randf_range(-0.18, 0.18) if fmod(t, 0.125) < 0.025 else 0.0
		var sample: float = sin(TAU * note * t) * 0.20 + sin(TAU * note * 2.0 * t) * 0.08
		var bass: float = sin(TAU * 98.0 * t) * 0.12
		var value: int = int(clampf((sample * fade + bass + kick * 0.42 + hat) * 0.55, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream


func _apply_audio_settings() -> void:
	var sfx_db: float = -80.0 if not sfx_enabled or sfx_volume <= 0.0 else -9.0 + linear_to_db(sfx_volume)
	for player in [cannon_audio, arrow_audio, ice_audio, wave_audio, error_audio, build_audio, remove_audio]:
		player.volume_db = sfx_db
	bgm_audio.volume_db = -80.0 if not music_enabled or music_volume <= 0.0 else -18.5 + linear_to_db(music_volume)


func _build_ui() -> void:
	GameUI.build(self)


func _connect_ui() -> void:
	GameUI.connect_buttons(self)


func _process(delta: float) -> void:
	_update_layout()
	_update_hover_cell()
	if current_screen == Defs.SCREEN_GAME and lives > 0 and not game_won:
		var game_delta := delta * game_speed
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


func show_screen(screen: String) -> void:
	GameUI.show_screen(self, screen)


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
	current_path = find_path(blocked)
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
	current_path = find_path(blocked)


func _unhandled_input(event: InputEvent) -> void:
	if current_screen != Defs.SCREEN_GAME or lives <= 0 or game_won:
		return
	if event is InputEventMouseButton and event.pressed:
		var cell := world_to_cell(get_global_mouse_position())
		if not is_inside_grid(cell):
			selected_tower = null
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			try_build_or_select(cell)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
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
	show_message("敵人路徑顯示：%s。" % ("開啟" if show_enemy_path else "關閉"))


func toggle_auto_start() -> void:
	auto_start_enabled = not auto_start_enabled
	show_message("自動開始：%s。" % ("開啟" if auto_start_enabled else "關閉"))
	if auto_start_enabled and waiting_next_wave and not is_wave_active():
		start_wave()


func try_build_or_select(cell: Vector2i) -> void:
	var existing := tower_at(cell)
	if existing != null:
		selected_tower = existing
		show_message("已選取 %s。按 U 可升級。" % existing.name)
		return

	selected_tower = null
	if is_wave_active():
		reject_build("進攻波進行中，不能建造新塔。")
		return

	if not can_place_footprint(cell):
		reject_build("2x2 塔需要完整空地，且不能覆蓋入口或出口。")
		return

	var build_cost := tower_cost(selected_build_type)
	if gold < build_cost:
		reject_build("金幣不足，無法建造 %s。" % tower_name(selected_build_type))
		return
	if footprint_has_enemy(cell):
		reject_build("敵人正在建造範圍內，不能直接建塔。")
		return

	var test_blocked := blocked.duplicate()
	for footprint_cell in footprint_cells(cell):
		test_blocked[footprint_cell] = true
	var new_path := find_path(test_blocked)
	if new_path.is_empty():
		reject_build("不能完全阻擋敵人的路線。")
		return

	var tower := Tower.new(cell, selected_build_type)
	for footprint_cell in footprint_cells(cell):
		blocked[footprint_cell] = tower
	towers.append(tower)
	selected_tower = tower
	current_path = new_path
	gold -= build_cost
	build_audio.play()
	retarget_live_enemies()
	show_message("已建造 2x2 %s，敵人會重新尋路。" % tower.name)


func remove_tower(cell: Vector2i) -> void:
	var tower := tower_at(cell)
	if tower == null:
		selected_tower = null
		return
	for footprint_cell in footprint_cells(tower.cell):
		blocked.erase(footprint_cell)
	towers.erase(tower)
	if selected_tower == tower:
		selected_tower = null
	current_path = find_path(blocked)
	var refund := WaveManager.tower_refund(tower.cost, difficulty_id)
	gold += refund
	remove_audio.play()
	add_floating_text(tower_center(tower), "+%d" % refund, Color("#8ff0a4"))
	retarget_live_enemies()
	show_message("已拆除 %s。" % tower.name)


func upgrade_selected_tower() -> void:
	if selected_tower == null or not towers.has(selected_tower):
		show_message("請先選取一座塔。")
		return
	if selected_tower.level >= Defs.MAX_TOWER_LEVEL:
		show_message("%s 已經滿級。" % selected_tower.name)
		return
	var cost := selected_tower.upgrade_cost()
	if gold < cost:
		show_message("升級金幣不足，需要 $%d。" % cost)
		return
	gold -= cost
	selected_tower.upgrade()
	show_message("%s 已升到 %d 級。" % [selected_tower.name, selected_tower.level])


func upgrade_selected_tower_to_max() -> void:
	if selected_tower == null or not towers.has(selected_tower):
		show_message("請先選取一座塔。")
		return
	if selected_tower.level >= Defs.MAX_TOWER_LEVEL:
		show_message("%s 已經滿級。" % selected_tower.name)
		return
	var upgraded := 0
	while selected_tower.level < Defs.MAX_TOWER_LEVEL:
		var cost := selected_tower.upgrade_cost()
		if gold < cost:
			if upgraded > 0:
				show_message("%s 已升到 %d 級，金幣不足無法繼續。" % [selected_tower.name, selected_tower.level])
			else:
				show_message("升級金幣不足，需要 $%d。" % cost)
			return
		gold -= cost
		selected_tower.upgrade()
		upgraded += 1
	show_message("%s 已升到最高等。" % selected_tower.name)


func start_wave() -> void:
	WaveManager.start_wave(self)


func _update_spawn(delta: float) -> void:
	WaveManager.update_spawn(self, delta)


func spawn_enemy(is_boss: bool, enemy_type: String) -> void:
	var path := find_path(blocked)
	if path.is_empty():
		return
	current_path = path
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
	current_path = path
	var auditor := Enemy.new(path, cell_center(path[0]), Defs.FINAL_WAVE, false, Defs.ENEMY_AUDITOR, 1.0, 1.0)
	enemies.append(auditor)
	audit_active = true
	audit_damage_taken = 0.0
	audit_elapsed_time = 0.0
	show_message("攻擊量審查員出現，正在記錄承受傷害。")


func _update_hover_cell() -> void:
	if current_screen != Defs.SCREEN_GAME or is_wave_active() or lives <= 0 or game_won:
		hover_cell = Vector2i(-999, -999)
		hover_can_build = false
		return
	var mouse_cell := world_to_cell(get_global_mouse_position())
	if not is_inside_grid(mouse_cell):
		hover_cell = Vector2i(-999, -999)
		hover_can_build = false
		return
	hover_cell = mouse_cell
	hover_can_build = can_place_footprint(hover_cell) and not footprint_has_enemy(hover_cell)
	if hover_can_build:
		var test_blocked := blocked.duplicate()
		for footprint_cell in footprint_cells(hover_cell):
			test_blocked[footprint_cell] = true
		hover_can_build = not find_path(test_blocked).is_empty()


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
	for tower in towers:
		tower.cooldown = max(0.0, tower.cooldown - delta)
		if tower.cooldown > 0.0:
			continue
		var targets := enemies_for_tower(tower)
		if targets.is_empty():
			continue
		var aim_vector := targets[0].pos - tower_center(tower)
		if aim_vector.length_squared() > 0.001:
			tower.aim_dir = aim_vector.normalized()
		for target in targets:
			projectiles.append(Projectile.new(tower_center(tower), target, tower))
		tower.cooldown = tower.fire_rate
		play_tower_sound(tower.type_id)


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
	for i in range(projectiles.size() - 1, -1, -1):
		var projectile := projectiles[i]
		if not enemies.has(projectile.target):
			projectiles.remove_at(i)
			continue

		var direction := projectile.target.pos - projectile.pos
		var distance := direction.length()
		var step := projectile.speed * delta
		if distance <= step:
			_apply_projectile_hit(projectile)
			projectiles.remove_at(i)
		else:
			projectile.pos += direction.normalized() * step


func _apply_projectile_hit(projectile: Projectile) -> void:
	if not projectile.target.is_targetable():
		return
	if projectile.tower_type == Defs.TYPE_CANNON and projectile.splash_radius > 0.0:
		var center := projectile.target.pos
		for enemy in enemies:
			if not enemy.is_targetable() or enemy.is_flying:
				continue
			var dist := enemy.pos.distance_to(center)
			if dist <= projectile.splash_radius:
				var ratio := 1.0 - clampf(dist / projectile.splash_radius, 0.0, 0.45)
				var damage := adjusted_projectile_damage(projectile, enemy) * ratio
				apply_damage_to_enemy(enemy, damage)
				enemy.apply_hit_flash()
				add_impact_wave(enemy.pos, projectile.color, (enemy.pos - projectile.pos).normalized())
	else:
		apply_damage_to_enemy(projectile.target, adjusted_projectile_damage(projectile, projectile.target))
		projectile.target.apply_hit_flash()
		add_impact_wave(projectile.target.pos, projectile.color, (projectile.target.pos - projectile.pos).normalized())
		if projectile.tower_type == Defs.TYPE_ICE:
			projectile.target.apply_slow(projectile.slow_factor, projectile.slow_duration)


func apply_damage_to_enemy(enemy: Enemy, damage: float) -> void:
	if enemy.is_auditor:
		audit_damage_taken += damage
		enemy.hp = enemy.max_hp
	else:
		enemy.hp -= damage


func adjusted_projectile_damage(projectile: Projectile, enemy: Enemy) -> float:
	var damage := float(projectile.damage)
	if projectile.tower_type == Defs.TYPE_ARROW:
		damage *= enemy.arrow_damage_taken_multiplier
	return damage


func enemies_for_tower(tower: Tower) -> Array[Enemy]:
	var origin := tower_center(tower)
	var candidates: Array[Enemy] = []
	for enemy in enemies:
		if not enemy.is_targetable():
			continue
		if tower.type_id == Defs.TYPE_CANNON and enemy.is_flying:
			continue
		if origin.distance_to(enemy.pos) <= tower.range:
			candidates.append(enemy)
	candidates.sort_custom(func(a: Enemy, b: Enemy) -> bool:
		return a.index > b.index
	)

	var result: Array[Enemy] = []
	var count: int = min(tower.target_count, candidates.size())
	for i in range(count):
		result.append(candidates[i])
	return result


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
	var dialog := ConfirmationDialog.new()
	dialog.title = "回主選單"
	dialog.dialog_text = "確定要回主選單？目前波次進度若未存檔會遺失。"
	dialog.confirmed.connect(func() -> void:
		show_screen(Defs.SCREEN_MENU)
	)
	add_child(dialog)
	dialog.popup_centered()


func confirm_exit_game() -> void:
	var dialog := ConfirmationDialog.new()
	dialog.title = "退出遊戲"
	dialog.dialog_text = "確定要退出遊戲？"
	dialog.confirmed.connect(func() -> void:
		get_tree().quit()
	)
	add_child(dialog)
	dialog.popup_centered()


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
	GameUI.update(self)


func _draw() -> void:
	GameRenderer.render(self, {
		"current_screen": current_screen,
		"grid_rect": grid_rect,
		"grid_origin": grid_origin,
		"cell_size": cell_size,
		"blocked": blocked,
		"current_path": current_path,
		"show_enemy_path": show_enemy_path,
		"hover_cell": hover_cell,
		"hover_can_build": hover_can_build,
		"spawn_flash_timer": spawn_flash_timer,
		"wave_banner_timer": wave_banner_timer,
		"wave": wave,
		"is_boss_wave_active": wave > 0 and wave % 10 == 0 and (boss_to_spawn or not enemies.is_empty()),
		"towers": towers,
		"selected_tower": selected_tower,
		"enemies": enemies,
		"projectiles": projectiles,
		"floating_texts": floating_texts,
		"impact_waves": impact_waves,
		"lives": lives,
		"difficulty_name": difficulty_name()
	})
