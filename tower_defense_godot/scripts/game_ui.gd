extends RefCounted

const Defs = preload("res://scripts/game_defs.gd")
const GameData = preload("res://scripts/game_data.gd")
const GameFont = preload("res://fonts/NotoSansTC-Regular.ttf")


static func build(owner) -> void:
	_build_menu_panel(owner)
	_build_rules_panel(owner)
	_build_ranking_panel(owner)
	_build_difficulty_panel(owner)
	_build_game_panel(owner)
	_apply_font_tree(owner.ui_layer)


static func _apply_font_tree(node: Node) -> void:
	if node is Control:
		(node as Control).add_theme_font_override("font", GameFont)
	for child in node.get_children():
		_apply_font_tree(child)


static func connect_buttons(owner) -> void:
	owner.start_button.pressed.connect(owner.start_new_game)
	owner.load_button.pressed.connect(owner.load_saved_game)
	owner.rules_button.pressed.connect(func() -> void: owner.show_screen(Defs.SCREEN_RULES))
	owner.ranking_button.pressed.connect(func() -> void: owner.show_screen(Defs.SCREEN_RANKING))
	owner.difficulty_button.pressed.connect(func() -> void: owner.show_screen(Defs.SCREEN_DIFFICULTY))
	owner.back_from_rules_button.pressed.connect(func() -> void: owner.show_screen(Defs.SCREEN_MENU))
	owner.back_from_ranking_button.pressed.connect(func() -> void: owner.show_screen(Defs.SCREEN_MENU))
	owner.back_from_difficulty_button.pressed.connect(func() -> void: owner.show_screen(Defs.SCREEN_MENU))
	owner.easy_button.pressed.connect(func() -> void: owner.set_difficulty(Defs.DIFFICULTY_EASY))
	owner.normal_button.pressed.connect(func() -> void: owner.set_difficulty(Defs.DIFFICULTY_NORMAL))
	owner.hard_button.pressed.connect(func() -> void: owner.set_difficulty(Defs.DIFFICULTY_HARD))
	owner.wave_button.pressed.connect(owner.start_wave)
	owner.cannon_button.pressed.connect(func() -> void: owner.select_build_type(Defs.TYPE_CANNON))
	owner.arrow_button.pressed.connect(func() -> void: owner.select_build_type(Defs.TYPE_ARROW))
	owner.ice_button.pressed.connect(func() -> void: owner.select_build_type(Defs.TYPE_ICE))
	owner.speed_1_button.pressed.connect(func() -> void: owner.set_game_speed(1.0))
	owner.speed_2_button.pressed.connect(func() -> void: owner.set_game_speed(2.0))
	owner.speed_3_button.pressed.connect(func() -> void: owner.set_game_speed(4.0))
	owner.speed_4_button.pressed.connect(func() -> void: owner.set_game_speed(8.0))
	owner.speed_5_button.pressed.connect(func() -> void: owner.set_game_speed(16.0))
	owner.save_button.pressed.connect(owner.save_game)
	owner.main_menu_button.pressed.connect(owner.confirm_return_to_menu)
	owner.exit_button.pressed.connect(owner.confirm_exit_game)
	owner.game_over_menu_button.pressed.connect(func() -> void: owner.show_screen(Defs.SCREEN_MENU))
	owner.game_over_ranking_button.pressed.connect(func() -> void: owner.show_screen(Defs.SCREEN_RANKING))
	owner.path_toggle.toggled.connect(func(pressed: bool) -> void:
		owner.show_enemy_path = pressed
		owner.mark_static_layer_dirty()
		owner.queue_redraw()
	)
	owner.auto_start_toggle.toggled.connect(func(pressed: bool) -> void:
		owner.auto_start_enabled = pressed
		if pressed and owner.waiting_next_wave and not owner.is_wave_active():
			owner.start_wave()
		owner._update_ui()
	)
	owner.build_confirm_toggle.toggled.connect(owner.set_build_confirm_enabled)
	owner.music_toggle.toggled.connect(func(pressed: bool) -> void:
		owner.music_enabled = pressed
		owner._apply_audio_settings()
		owner._update_ui()
	)
	owner.sfx_toggle.toggled.connect(func(pressed: bool) -> void:
		owner.sfx_enabled = pressed
		owner._apply_audio_settings()
		owner._update_ui()
	)
	owner.music_volume_slider.value_changed.connect(func(value: float) -> void:
		owner.music_volume = value
		owner._apply_audio_settings()
	)
	owner.sfx_volume_slider.value_changed.connect(func(value: float) -> void:
		owner.sfx_volume = value
		owner._apply_audio_settings()
	)
	owner.tower_upgrade_float_button.pressed.connect(owner.upgrade_selected_tower)
	owner.tower_delete_float_button.pressed.connect(owner.confirm_remove_selected_tower)


static func update_layout(owner) -> void:
	var size: Vector2 = owner.get_viewport_rect().size
	if size == owner.last_viewport_size and is_equal_approx(owner.board_zoom, owner.last_layout_zoom):
		return
	owner.last_viewport_size = size
	owner.last_layout_zoom = owner.board_zoom
	owner.ui_scale = clampf(min(size.x / 1280.0, size.y / 720.0), 0.72, 1.25)

	var is_narrow: bool = size.x < 760.0
	var is_mobile_landscape: bool = size.x > size.y and size.y < 640.0
	var margin: float = 14.0 * owner.ui_scale
	var side_w: float = 0.0 if is_narrow else min(240.0 * owner.ui_scale, size.x * 0.22)
	var info_w: float = min((780.0 if is_mobile_landscape else 720.0) * owner.ui_scale, size.x - margin * 2.0 - side_w)
	var info_h: float = 30.0 * owner.ui_scale
	var top_h: float = 258.0 * owner.ui_scale if is_narrow else 58.0 * owner.ui_scale
	var available_w: float = max(1.0, size.x - margin * 2.0 - side_w - margin)
	var available_h: float = max(1.0, size.y - top_h - margin * 2.0)
	owner.cell_size = floorf(min(available_w / float(Defs.GRID_W), available_h / float(Defs.GRID_H)) * owner.board_zoom)
	owner.cell_size = max(owner.cell_size, 8.0)
	var battle_w: float = owner.cell_size * Defs.GRID_W
	var battle_h: float = owner.cell_size * Defs.GRID_H
	if is_narrow:
		owner.grid_origin = Vector2((size.x - battle_w) * 0.5, top_h)
	else:
		var battle_area_w: float = size.x - side_w - margin * 3.0
		owner.grid_origin = Vector2(margin + max(0.0, (battle_area_w - battle_w) * 0.5), top_h)
	owner.grid_rect = Rect2(owner.grid_origin, Vector2(owner.cell_size * Defs.GRID_W, owner.cell_size * Defs.GRID_H))

	var menu_w: float = min(460.0 * owner.ui_scale, size.x - margin * 2.0)
	for panel in [owner.menu_panel, owner.rules_panel, owner.ranking_panel, owner.difficulty_panel]:
		panel.position = Vector2((size.x - menu_w) * 0.5, max(margin, size.y * 0.14))
		panel.custom_minimum_size = Vector2(menu_w, 0)
	owner.menu_version_label.position = Vector2(size.x - margin - 150.0 * owner.ui_scale, size.y - margin - 28.0 * owner.ui_scale)
	owner.menu_version_label.custom_minimum_size = Vector2(150.0 * owner.ui_scale, 24.0 * owner.ui_scale)
	var game_over_w: float = min(360.0 * owner.ui_scale, size.x - margin * 2.0)
	owner.game_over_panel.custom_minimum_size = Vector2(game_over_w, 0)
	owner.game_over_panel.position = Vector2((size.x - game_over_w) * 0.5, max(margin, size.y * 0.38))

	if is_narrow:
		owner.game_panel.position = Vector2(margin, margin)
		owner.game_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		owner.game_panel.custom_minimum_size = Vector2(size.x - margin * 2.0, 32.0 * owner.ui_scale)
		owner.game_panel.size = Vector2(size.x - margin * 2.0, 32.0 * owner.ui_scale)
		owner.tower_label.position = Vector2(margin, margin + 24.0 * owner.ui_scale)
		owner.tower_label.custom_minimum_size = Vector2(size.x - margin * 2.0, 22.0 * owner.ui_scale)
		owner.tower_buttons_box.position = Vector2(margin, 104.0 * owner.ui_scale)
		owner.wave_button.position = Vector2(margin, 152.0 * owner.ui_scale)
		owner.wave_countdown_label.position = owner.wave_button.position + Vector2(112.0 * owner.ui_scale, 9.0 * owner.ui_scale)
		owner.speed_buttons_box.position = Vector2(margin + 122.0 * owner.ui_scale, 152.0 * owner.ui_scale)
		owner.game_actions_box.position = Vector2(margin, 202.0 * owner.ui_scale)
		owner.game_options_box.position = Vector2(margin, 250.0 * owner.ui_scale)
	else:
		owner.game_panel.position = Vector2(margin, margin)
		owner.game_panel.set_anchors_preset(Control.PRESET_TOP_LEFT)
		owner.game_panel.custom_minimum_size = Vector2(info_w, info_h)
		owner.game_panel.size = Vector2(info_w, info_h)
		var tower_info_w: float = min(520.0 * owner.ui_scale, size.x - side_w - margin * 3.0)
		owner.tower_label.position = Vector2(size.x - side_w - margin - tower_info_w, margin + 24.0 * owner.ui_scale)
		owner.tower_label.custom_minimum_size = Vector2(tower_info_w, 22.0 * owner.ui_scale)
		var side_x: float = size.x - side_w + margin - 40.0 * owner.ui_scale
		owner.tower_buttons_box.position = Vector2(side_x, margin)
		owner.tower_buttons_box.position.y += 100.0 * owner.ui_scale
		owner.wave_button.position = Vector2(side_x, margin + 250.0 * owner.ui_scale)
		owner.wave_countdown_label.position = owner.wave_button.position + Vector2(112.0 * owner.ui_scale, 9.0 * owner.ui_scale)
		owner.speed_buttons_box.position = Vector2(side_x, margin + 302.0 * owner.ui_scale)
		owner.game_actions_box.position = Vector2(side_x, margin + 360.0 * owner.ui_scale)
		owner.game_options_box.position = Vector2(side_x, margin + 418.0 * owner.ui_scale)

	for button in [owner.cannon_button, owner.arrow_button, owner.ice_button]:
		button.custom_minimum_size = Vector2(96.0 * owner.ui_scale, 38.0 * owner.ui_scale)
	owner.wave_button.custom_minimum_size = Vector2(104.0 * owner.ui_scale, 40.0 * owner.ui_scale)
	owner.wave_countdown_label.custom_minimum_size = Vector2(60.0 * owner.ui_scale, 24.0 * owner.ui_scale)
	for button in [owner.speed_1_button, owner.speed_2_button, owner.speed_3_button, owner.speed_4_button, owner.speed_5_button]:
		button.custom_minimum_size = Vector2(42.0 * owner.ui_scale, 40.0 * owner.ui_scale)
	for button in [owner.save_button, owner.main_menu_button, owner.exit_button]:
		button.custom_minimum_size = Vector2(66.0 * owner.ui_scale, 40.0 * owner.ui_scale)
	owner.path_toggle.custom_minimum_size = Vector2(160.0 * owner.ui_scale, 30.0 * owner.ui_scale)
	for slider in [owner.music_volume_slider, owner.sfx_volume_slider]:
		slider.custom_minimum_size = Vector2(92.0 * owner.ui_scale, 24.0 * owner.ui_scale)
	if is_mobile_landscape:
		owner.stats_label.add_theme_font_size_override("font_size", 12)
		owner.tower_label.add_theme_font_size_override("font_size", 9)
		owner.leaderboard_label.visible = false
	else:
		owner.stats_label.add_theme_font_size_override("font_size", 18)
		owner.tower_label.add_theme_font_size_override("font_size", 11)
		owner.leaderboard_label.visible = true
	owner.tower_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner.tower_label.clip_text = true
	owner.hint_label.visible = false
	owner.leaderboard_label.visible = false
	update_selected_tower_actions(owner)


static func show_screen(owner, screen: String) -> void:
	owner.current_screen = screen
	owner.last_viewport_size = Vector2.ZERO
	update_layout(owner)
	owner.menu_panel.visible = screen == Defs.SCREEN_MENU
	owner.rules_panel.visible = screen == Defs.SCREEN_RULES
	owner.ranking_panel.visible = screen == Defs.SCREEN_RANKING
	owner.difficulty_panel.visible = screen == Defs.SCREEN_DIFFICULTY
	owner.menu_version_label.visible = screen == Defs.SCREEN_MENU
	var game_visible := screen == Defs.SCREEN_GAME
	owner.game_panel.visible = game_visible
	owner.tower_buttons_box.visible = game_visible
	owner.speed_buttons_box.visible = game_visible
	owner.game_actions_box.visible = game_visible
	owner.wave_button.visible = game_visible
	owner.wave_countdown_label.visible = game_visible
	owner.game_options_box.visible = game_visible
	owner.tower_upgrade_float_button.visible = false
	owner.tower_delete_float_button.visible = false
	owner.game_over_panel.visible = game_visible and (owner.lives <= 0 or owner.game_won)
	update(owner)
	owner.queue_redraw()


static func update(owner) -> void:
	if owner.life_flash_timer > 0.0:
		owner.stats_label.add_theme_color_override("font_color", Color("#ff8c96"))
	else:
		owner.stats_label.add_theme_color_override("font_color", Color("#f7e8aa"))
	var boss_text := ""
	if owner.wave > 0 and owner.wave % 10 == 0 and (owner.boss_to_spawn or not owner.enemies.is_empty()):
		boss_text = "    Boss"
	if owner.audit_active:
		boss_text = "    審查 %d" % int(round(owner.audit_damage_taken))
	owner.stats_label.text = "%s    金幣 %d    生命 %d    波數 %d%s    速度 %.0fx" % [Defs.GAME_VERSION, owner.gold, owner.lives, owner.wave, boss_text, owner.game_speed]
	owner.menu_version_label.text = Defs.GAME_VERSION
	if owner.lives <= 0:
		owner.hint_label.text = "遊戲結束。可回主選單重新開始。"
		owner.game_over_title_label.text = "遊戲結束"
		owner.game_over_detail_label.text = "難度：%s\n已抵達第 %d 波。" % [owner.difficulty_name(), owner.wave]
	elif owner.game_won:
		owner.hint_label.text = "已通過第 %d 關，遊戲勝利。" % Defs.FINAL_WAVE
		owner.game_over_title_label.text = "遊戲獲勝"
		owner.game_over_detail_label.text = "難度：%s\n攻擊量審查：%d 傷害 / %.1f 秒。" % [owner.difficulty_name(), int(round(owner.audit_damage_taken)), owner.audit_elapsed_time]
	elif owner.message_time > 0.0:
		owner.hint_label.text = owner.message
	else:
		owner.hint_label.text = "建造區 %dx%d，塔佔 2x2。第 %d 關為最後一關，敵人可斜線移動。" % [Defs.GRID_W, Defs.GRID_H, Defs.FINAL_WAVE]

	var build_name: String = owner.tower_name(owner.selected_build_type)
	var build_cost: int = owner.tower_cost(owner.selected_build_type)
	if owner.selected_tower != null and owner.towers.has(owner.selected_tower):
		var attack_speed: float = 1.0 / owner.selected_tower.fire_rate
		var upgrade_text := "MAX"
		if owner.selected_tower.level < Defs.MAX_TOWER_LEVEL:
			upgrade_text = "$%d" % owner.selected_tower.upgrade_cost()
		owner.tower_label.text = "建造：%s $%d | 選取：%s Lv %d | 射程 %.0f | 攻速 %.1f/秒 | 傷害 %d | 目標 %d | 升級 %s" % [
			build_name,
			build_cost,
			owner.selected_tower.name,
			owner.selected_tower.level,
			owner.selected_tower.range,
			attack_speed,
			owner.selected_tower.damage,
			owner.selected_tower.target_count,
			upgrade_text
		]
	else:
		owner.tower_label.text = "建造：%s $%d | 尚未選取塔。" % [build_name, build_cost]

	owner.leaderboard_label.text = owner.leaderboard_text()
	owner.game_difficulty_label.text = "難度：%s" % owner.difficulty_name()
	owner.ranking_label.text = "攻擊量排行榜\n\n%s" % owner.boss_rank_summary()
	owner.difficulty_label.text = "難度調整\n\n目前難度：%s\n\n簡單：更多金幣與生命，敵人較弱。\n普通：標準規則。\n困難：金幣與生命較少，敵人更強，但擊殺金幣略高。" % owner.difficulty_name()
	owner.load_button.disabled = not owner.has_saved_game

	owner.cannon_button.text = "1 %s $%d" % [GameData.tower_name(Defs.TYPE_CANNON), GameData.tower_cost(Defs.TYPE_CANNON)]
	owner.arrow_button.text = "2 %s $%d" % [GameData.tower_name(Defs.TYPE_ARROW), GameData.tower_cost(Defs.TYPE_ARROW)]
	owner.ice_button.text = "3 %s $%d" % [GameData.tower_name(Defs.TYPE_ICE), GameData.tower_cost(Defs.TYPE_ICE)]
	owner.cannon_button.disabled = owner.selected_build_type == Defs.TYPE_CANNON
	owner.arrow_button.disabled = owner.selected_build_type == Defs.TYPE_ARROW
	owner.ice_button.disabled = owner.selected_build_type == Defs.TYPE_ICE
	owner.speed_1_button.text = "1x"
	owner.speed_2_button.text = "2x"
	owner.speed_3_button.text = "4x"
	owner.speed_4_button.text = "8x"
	owner.speed_5_button.text = "16x"
	if owner.waiting_next_wave and not owner.auto_start_enabled:
		owner.wave_countdown_label.text = "%ds" % ceili(owner.next_wave_wait)
	elif owner.auto_start_enabled:
		owner.wave_countdown_label.text = "自動"
	else:
		owner.wave_countdown_label.text = ""
	owner.path_toggle.text = "顯示敵人路徑"
	owner.path_toggle.button_pressed = owner.show_enemy_path
	owner.auto_start_toggle.text = "自動開始"
	owner.auto_start_toggle.button_pressed = owner.auto_start_enabled
	owner.build_confirm_toggle.text = "建造二次確認 B"
	owner.build_confirm_toggle.button_pressed = owner.build_confirm_enabled
	owner.music_toggle.text = "音樂"
	owner.music_toggle.button_pressed = owner.music_enabled
	owner.sfx_toggle.text = "音效"
	owner.sfx_toggle.button_pressed = owner.sfx_enabled
	owner.music_volume_slider.value = owner.music_volume
	owner.sfx_volume_slider.value = owner.sfx_volume
	if owner.lives <= 0 or owner.game_won:
		for button in [
			owner.cannon_button,
			owner.arrow_button,
			owner.ice_button,
			owner.wave_button,
			owner.speed_1_button,
			owner.speed_2_button,
			owner.speed_3_button,
			owner.speed_4_button,
			owner.speed_5_button,
			owner.save_button,
			owner.main_menu_button,
			owner.exit_button,
			owner.path_toggle,
			owner.auto_start_toggle,
			owner.build_confirm_toggle,
			owner.music_toggle,
			owner.sfx_toggle
		]:
			button.disabled = true
		owner.music_volume_slider.editable = false
		owner.sfx_volume_slider.editable = false
	else:
		owner.speed_1_button.disabled = is_equal_approx(owner.game_speed, 1.0)
		owner.speed_2_button.disabled = is_equal_approx(owner.game_speed, 2.0)
		owner.speed_3_button.disabled = is_equal_approx(owner.game_speed, 4.0)
		owner.speed_4_button.disabled = is_equal_approx(owner.game_speed, 8.0)
		owner.speed_5_button.disabled = is_equal_approx(owner.game_speed, 16.0)
		owner.save_button.disabled = owner.is_wave_active()
		owner.wave_button.disabled = owner.is_wave_active()
		owner.main_menu_button.disabled = false
		owner.exit_button.disabled = false
		owner.path_toggle.disabled = false
		owner.auto_start_toggle.disabled = false
		owner.build_confirm_toggle.disabled = false
		owner.music_toggle.disabled = false
		owner.sfx_toggle.disabled = false
		owner.music_volume_slider.editable = true
		owner.sfx_volume_slider.editable = true
	owner.game_over_ranking_button.visible = owner.game_won
	owner.game_over_panel.visible = owner.current_screen == Defs.SCREEN_GAME and (owner.lives <= 0 or owner.game_won)
	update_selected_tower_actions(owner)


static func update_selected_tower_actions(owner) -> void:
	var visible: bool = owner.current_screen == Defs.SCREEN_GAME and owner.selected_tower != null and owner.towers.has(owner.selected_tower) and owner.lives > 0 and not owner.game_won
	owner.tower_upgrade_float_button.visible = visible
	owner.tower_delete_float_button.visible = visible
	if not visible:
		return
	var center: Vector2 = owner.tower_center(owner.selected_tower)
	var offset: float = max(26.0, owner.cell_size * 1.35)
	var button_size: Vector2 = Vector2(58.0 * owner.ui_scale, 32.0 * owner.ui_scale)
	var y_shift: float = 20.0 * owner.ui_scale
	owner.tower_upgrade_float_button.custom_minimum_size = button_size
	owner.tower_delete_float_button.custom_minimum_size = button_size
	owner.tower_upgrade_float_button.text = "升級"
	owner.tower_delete_float_button.text = "刪除"
	owner.tower_upgrade_float_button.disabled = owner.selected_tower.level >= Defs.MAX_TOWER_LEVEL or owner.gold < owner.selected_tower.upgrade_cost()
	owner.tower_delete_float_button.disabled = false
	owner.tower_upgrade_float_button.position = center + Vector2(-button_size.x - 6.0, -offset - button_size.y * 0.5 + y_shift)
	owner.tower_delete_float_button.position = center + Vector2(6.0, -offset - button_size.y * 0.5 + y_shift)


static func _build_menu_panel(owner) -> void:
	owner.menu_panel.add_theme_stylebox_override("panel", make_panel_style(Color("#171b26"), Color("#44506a")))
	owner.ui_layer.add_child(owner.menu_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	owner.menu_panel.add_child(box)

	owner.menu_title.text = "Path Bender Tower Defense"
	owner.menu_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owner.menu_title.add_theme_font_size_override("font_size", 30)
	owner.menu_title.add_theme_color_override("font_color", Color("#f7e8aa"))
	box.add_child(owner.menu_title)
	owner.ui_layer.add_child(owner.menu_version_label)
	owner.menu_version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	owner.menu_version_label.add_theme_font_size_override("font_size", 14)
	owner.menu_version_label.add_theme_color_override("font_color", Color("#91a6ca"))
	owner.menu_version_label.visible = false

	for button in [owner.start_button, owner.load_button, owner.rules_button, owner.ranking_button, owner.difficulty_button]:
		button.custom_minimum_size = Vector2(260, 48)
		button.add_theme_font_size_override("font_size", 18)
		button.add_theme_stylebox_override("normal", make_panel_style(Color("#243149"), Color("#61708f")))
		button.add_theme_stylebox_override("hover", make_panel_style(Color("#2f405d"), Color("#91a6ca")))
		box.add_child(button)

	owner.start_button.text = "開始遊戲"
	owner.load_button.text = "繼續遊戲"
	owner.rules_button.text = "操作規則"
	owner.ranking_button.text = "排行榜"
	owner.difficulty_button.text = "難度調整"


static func _build_rules_panel(owner) -> void:
	owner.rules_panel.add_theme_stylebox_override("panel", make_panel_style(Color("#171b26"), Color("#44506a")))
	owner.ui_layer.add_child(owner.rules_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	owner.rules_panel.add_child(box)
	owner.rules_label.text = "操作規則\n\n1/2/3 或按鈕選塔。\n左鍵/觸控：預設第一次點空地顯示半透明塔預覽，第二次點同一格開始建造。\n建造需要 0.5 秒，上方會顯示進度條。\n右側可取消「建造二次確認」，改回點一下直接建造。\nB：切換建造二次確認。\n右鍵：拆除塔。\nU：升級選取塔。\n下一波：開始敵人進攻。\n\n塔現在佔地 2x2。建造前會重新計算路徑，若入口到出口被完全堵死，系統會拒絕建造。\n\n進攻波進行中不能建造新塔，可以調整速度、存檔或回主選單。"
	owner.rules_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner.rules_label.add_theme_font_size_override("font_size", 18)
	owner.rules_label.add_theme_color_override("font_color", Color("#dde8ff"))
	box.add_child(owner.rules_label)
	owner.back_from_rules_button.text = "回主選單"
	owner.back_from_rules_button.custom_minimum_size = Vector2(220, 48)
	box.add_child(owner.back_from_rules_button)


static func _build_ranking_panel(owner) -> void:
	owner.ranking_panel.add_theme_stylebox_override("panel", make_panel_style(Color("#171b26"), Color("#44506a")))
	owner.ui_layer.add_child(owner.ranking_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	owner.ranking_panel.add_child(box)
	owner.ranking_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner.ranking_label.add_theme_font_size_override("font_size", 18)
	owner.ranking_label.add_theme_color_override("font_color", Color("#ffdca0"))
	box.add_child(owner.ranking_label)
	owner.back_from_ranking_button.text = "回主選單"
	owner.back_from_ranking_button.custom_minimum_size = Vector2(220, 48)
	box.add_child(owner.back_from_ranking_button)


static func _build_difficulty_panel(owner) -> void:
	owner.difficulty_panel.add_theme_stylebox_override("panel", make_panel_style(Color("#171b26"), Color("#44506a")))
	owner.ui_layer.add_child(owner.difficulty_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	owner.difficulty_panel.add_child(box)
	owner.difficulty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	owner.difficulty_label.add_theme_font_size_override("font_size", 18)
	owner.difficulty_label.add_theme_color_override("font_color", Color("#dde8ff"))
	box.add_child(owner.difficulty_label)
	for button in [owner.easy_button, owner.normal_button, owner.hard_button]:
		button.custom_minimum_size = Vector2(260, 48)
		button.add_theme_font_size_override("font_size", 18)
		box.add_child(button)
	owner.easy_button.text = "簡單"
	owner.normal_button.text = "普通"
	owner.hard_button.text = "困難"
	owner.back_from_difficulty_button.text = "回主選單"
	owner.back_from_difficulty_button.custom_minimum_size = Vector2(220, 48)
	box.add_child(owner.back_from_difficulty_button)


static func _build_game_panel(owner) -> void:
	var transparent_style := StyleBoxEmpty.new()
	owner.game_panel.add_theme_stylebox_override("panel", transparent_style)
	owner.ui_layer.add_child(owner.game_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	owner.game_panel.add_child(box)
	owner.game_panel.clip_contents = true

	owner.stats_label.add_theme_font_size_override("font_size", 11)
	box.add_child(owner.stats_label)
	owner.stats_label.add_theme_font_size_override("font_size", 18)
	owner.stats_label.add_theme_color_override("font_color", Color("#f7e8aa"))
	owner.hint_label.add_theme_color_override("font_color", Color("#dde8ff"))
	owner.tower_label.add_theme_color_override("font_color", Color("#cbe7ff"))
	owner.leaderboard_label.add_theme_color_override("font_color", Color("#ffdca0"))
	owner.ui_layer.add_child(owner.tower_label)

	owner.ui_layer.add_child(owner.tower_buttons_box)
	owner.tower_buttons_box.add_theme_constant_override("separation", 8)
	for button in [owner.cannon_button, owner.arrow_button, owner.ice_button]:
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_stylebox_override("normal", make_panel_style(Color("#202737"), Color("#46516a")))
		button.add_theme_stylebox_override("hover", make_panel_style(Color("#2a344a"), Color("#6a7896")))
		button.add_theme_stylebox_override("disabled", make_panel_style(Color("#3a4f64"), Color("#a7d7ff")))
		owner.tower_buttons_box.add_child(button)

	owner.wave_button.text = "下一波 N"
	owner.wave_button.add_theme_font_size_override("font_size", 16)
	owner.wave_button.add_theme_stylebox_override("normal", make_panel_style(Color("#3e2f19"), Color("#d6aa4a")))
	owner.wave_button.add_theme_stylebox_override("hover", make_panel_style(Color("#543f1f"), Color("#ffd36b")))
	owner.wave_button.add_theme_stylebox_override("disabled", make_panel_style(Color("#2a2b31"), Color("#565b68")))
	owner.ui_layer.add_child(owner.wave_button)
	owner.wave_countdown_label.add_theme_font_size_override("font_size", 16)
	owner.wave_countdown_label.add_theme_color_override("font_color", Color("#ffdca0"))
	owner.ui_layer.add_child(owner.wave_countdown_label)

	owner.ui_layer.add_child(owner.speed_buttons_box)
	owner.speed_buttons_box.add_theme_constant_override("separation", 6)
	for button in [owner.speed_1_button, owner.speed_2_button, owner.speed_3_button, owner.speed_4_button, owner.speed_5_button]:
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_stylebox_override("normal", make_panel_style(Color("#202737"), Color("#46516a")))
		button.add_theme_stylebox_override("hover", make_panel_style(Color("#2a344a"), Color("#6a7896")))
		button.add_theme_stylebox_override("disabled", make_panel_style(Color("#3a4f64"), Color("#a7d7ff")))
		owner.speed_buttons_box.add_child(button)

	owner.ui_layer.add_child(owner.game_actions_box)
	owner.game_actions_box.add_theme_constant_override("separation", 6)
	for button in [owner.save_button, owner.main_menu_button, owner.exit_button]:
		button.add_theme_font_size_override("font_size", 15)
		button.add_theme_stylebox_override("normal", make_panel_style(Color("#26303d"), Color("#657184")))
		button.add_theme_stylebox_override("hover", make_panel_style(Color("#334153"), Color("#9bacbf")))
		owner.game_actions_box.add_child(button)
	owner.save_button.text = "存檔"
	owner.main_menu_button.text = "回主選單"
	owner.exit_button.text = "退出"

	owner.ui_layer.add_child(owner.game_options_box)
	owner.game_options_box.add_theme_constant_override("separation", 6)
	owner.game_difficulty_label.add_theme_font_size_override("font_size", 15)
	owner.game_difficulty_label.add_theme_color_override("font_color", Color("#f7e8aa"))
	owner.game_options_box.add_child(owner.game_difficulty_label)
	owner.path_toggle.text = "顯示敵人路徑"
	owner.path_toggle.button_pressed = true
	owner.path_toggle.add_theme_font_size_override("font_size", 15)
	owner.path_toggle.add_theme_color_override("font_color", Color("#dde8ff"))
	owner.game_options_box.add_child(owner.path_toggle)
	owner.auto_start_toggle.text = "自動開始"
	owner.auto_start_toggle.add_theme_font_size_override("font_size", 15)
	owner.auto_start_toggle.add_theme_color_override("font_color", Color("#dde8ff"))
	owner.game_options_box.add_child(owner.auto_start_toggle)
	owner.build_confirm_toggle.text = "建造二次確認 B"
	owner.build_confirm_toggle.button_pressed = true
	owner.build_confirm_toggle.add_theme_font_size_override("font_size", 15)
	owner.build_confirm_toggle.add_theme_color_override("font_color", Color("#dde8ff"))
	owner.game_options_box.add_child(owner.build_confirm_toggle)
	var music_row := HBoxContainer.new()
	music_row.add_theme_constant_override("separation", 8)
	owner.music_toggle.text = "音樂"
	owner.music_toggle.button_pressed = true
	owner.music_toggle.add_theme_font_size_override("font_size", 15)
	owner.music_toggle.add_theme_color_override("font_color", Color("#dde8ff"))
	owner.music_volume_slider.min_value = 0.0
	owner.music_volume_slider.max_value = 1.5
	owner.music_volume_slider.step = 0.01
	owner.music_volume_slider.value = 1.0
	music_row.add_child(owner.music_toggle)
	music_row.add_child(owner.music_volume_slider)
	owner.game_options_box.add_child(music_row)
	var sfx_row := HBoxContainer.new()
	sfx_row.add_theme_constant_override("separation", 8)
	owner.sfx_toggle.text = "音效"
	owner.sfx_toggle.button_pressed = true
	owner.sfx_toggle.add_theme_font_size_override("font_size", 15)
	owner.sfx_toggle.add_theme_color_override("font_color", Color("#dde8ff"))
	owner.sfx_volume_slider.min_value = 0.0
	owner.sfx_volume_slider.max_value = 1.5
	owner.sfx_volume_slider.step = 0.01
	owner.sfx_volume_slider.value = 1.0
	sfx_row.add_child(owner.sfx_toggle)
	sfx_row.add_child(owner.sfx_volume_slider)
	owner.game_options_box.add_child(sfx_row)

	for button in [owner.tower_upgrade_float_button, owner.tower_delete_float_button]:
		button.add_theme_font_size_override("font_size", 14)
		button.add_theme_stylebox_override("normal", make_panel_style(Color("#26303d"), Color("#ffd36b")))
		button.add_theme_stylebox_override("hover", make_panel_style(Color("#3a4556"), Color("#ffe8a3")))
		button.add_theme_stylebox_override("disabled", make_panel_style(Color("#222631"), Color("#5d6472")))
		owner.ui_layer.add_child(button)
		button.visible = false

	owner.game_over_panel.add_theme_stylebox_override("panel", make_panel_style(Color("#171b26"), Color("#ff8da1")))
	owner.ui_layer.add_child(owner.game_over_panel)
	var over_box := VBoxContainer.new()
	over_box.add_theme_constant_override("separation", 10)
	owner.game_over_panel.add_child(over_box)
	owner.game_over_title_label.text = "遊戲結束"
	owner.game_over_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owner.game_over_title_label.add_theme_font_size_override("font_size", 26)
	owner.game_over_title_label.add_theme_color_override("font_color", Color("#ffccd4"))
	over_box.add_child(owner.game_over_title_label)
	owner.game_over_detail_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	owner.game_over_detail_label.add_theme_font_size_override("font_size", 16)
	owner.game_over_detail_label.add_theme_color_override("font_color", Color("#dde8ff"))
	over_box.add_child(owner.game_over_detail_label)
	owner.game_over_menu_button.text = "回主選單"
	owner.game_over_menu_button.custom_minimum_size = Vector2(180, 44)
	owner.game_over_menu_button.add_theme_font_size_override("font_size", 16)
	owner.game_over_menu_button.add_theme_stylebox_override("normal", make_panel_style(Color("#243149"), Color("#61708f")))
	owner.game_over_menu_button.add_theme_stylebox_override("hover", make_panel_style(Color("#2f405d"), Color("#91a6ca")))
	over_box.add_child(owner.game_over_menu_button)
	owner.game_over_ranking_button.text = "排行榜"
	owner.game_over_ranking_button.custom_minimum_size = Vector2(180, 44)
	owner.game_over_ranking_button.add_theme_font_size_override("font_size", 16)
	owner.game_over_ranking_button.add_theme_stylebox_override("normal", make_panel_style(Color("#3e2f19"), Color("#d6aa4a")))
	owner.game_over_ranking_button.add_theme_stylebox_override("hover", make_panel_style(Color("#543f1f"), Color("#ffd36b")))
	over_box.add_child(owner.game_over_ranking_button)
	owner.game_over_panel.visible = false


static func make_panel_style(fill: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style
