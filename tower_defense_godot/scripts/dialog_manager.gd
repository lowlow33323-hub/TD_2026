extends RefCounted

const GameUI = preload("res://scripts/game_ui.gd")
const GameFont = preload("res://fonts/NotoSansTC-Regular.ttf")


static func popup_confirmation(owner, title: String, text: String, confirmed_action: Callable, ok_text: String = "確定", cancel_text: String = "取消") -> void:
	if owner.confirmation_dialog_open:
		return
	owner.confirmation_dialog_open = true
	var overlay := Control.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.0, 0.0, 0.0, 0.55)
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(430.0, 0.0)
	panel.add_theme_stylebox_override("panel", GameUI.make_panel_style(Color("#171b26"), Color("#6f819f")))
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	box.add_theme_constant_override("margin_left", 18)
	box.add_theme_constant_override("margin_right", 18)
	box.add_theme_constant_override("margin_top", 16)
	box.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(box)
	var title_label := Label.new()
	title_label.text = title
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_override("font", GameFont)
	title_label.add_theme_font_size_override("font_size", 22)
	title_label.add_theme_color_override("font_color", Color("#f7e8aa"))
	box.add_child(title_label)
	var body_label := Label.new()
	body_label.text = text
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body_label.add_theme_font_override("font", GameFont)
	body_label.add_theme_font_size_override("font_size", 17)
	body_label.add_theme_color_override("font_color", Color("#dde8ff"))
	box.add_child(body_label)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 12)
	box.add_child(buttons)
	var ok_button := Button.new()
	ok_button.text = ok_text
	ok_button.custom_minimum_size = Vector2(104.0, 38.0)
	ok_button.add_theme_font_override("font", GameFont)
	var cancel_button := Button.new()
	cancel_button.text = cancel_text
	cancel_button.custom_minimum_size = Vector2(104.0, 38.0)
	cancel_button.add_theme_font_override("font", GameFont)
	buttons.add_child(ok_button)
	buttons.add_child(cancel_button)
	var close_overlay := func() -> void:
		owner.confirmation_dialog_open = false
		overlay.queue_free()
	ok_button.pressed.connect(func() -> void:
		confirmed_action.call()
		close_overlay.call()
	)
	cancel_button.pressed.connect(close_overlay)
	owner.ui_layer.add_child(overlay)
