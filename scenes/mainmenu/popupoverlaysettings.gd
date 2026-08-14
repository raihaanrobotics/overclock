extends PanelContainer

@export var dim_bg: ColorRect

# Audio Sliders
@onready var master_slider: HSlider = %MasterSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SFXSlider

# Graphics Toggles
@onready var fullscreen_toggle: CheckButton = %FullscreenToggle
@onready var vsync_toggle: CheckButton = %VSyncToggle

# Control Remap Button Example
@onready var key_btn: Button = %KeyBtn

# Remap state tracker
var remapping_action: String = ""

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	scale = Vector2(0.9, 0.9)
	pivot_offset = size / 2.0
	
	# Connect audio slider signals automatically
	if master_slider and not master_slider.value_changed.is_connected(_on_master_slider_value_changed):
		master_slider.value_changed.connect(_on_master_slider_value_changed)
	if music_slider and not music_slider.value_changed.is_connected(_on_music_slider_value_changed):
		music_slider.value_changed.connect(_on_music_slider_value_changed)
	if sfx_slider and not sfx_slider.value_changed.is_connected(_on_sfx_slider_value_changed):
		sfx_slider.value_changed.connect(_on_sfx_slider_value_changed)

	_initialize_settings_ui()

# --- INITIALIZATION ---
func _initialize_settings_ui() -> void:
	# Audio Sliders with safe bus index checks
	var master_idx = AudioServer.get_bus_index("Master")
	if master_slider and master_idx != -1:
		master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_idx))
		
	var music_idx = AudioServer.get_bus_index("Music")
	if music_slider and music_idx != -1:
		music_slider.value = db_to_linear(AudioServer.get_bus_volume_db(music_idx))
		
	var sfx_idx = AudioServer.get_bus_index("SFX")
	if sfx_slider and sfx_idx != -1:
		sfx_slider.value = db_to_linear(AudioServer.get_bus_volume_db(sfx_idx))
	
	# Graphics Toggles
	if fullscreen_toggle:
		var is_fullscreen = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen_toggle.button_pressed = is_fullscreen
		_apply_toggle_style(fullscreen_toggle, is_fullscreen)
		
	if vsync_toggle:
		var is_vsync = (DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_ENABLED)
		vsync_toggle.button_pressed = is_vsync
		_apply_toggle_style(vsync_toggle, is_vsync)
	
	# Controls
	if key_btn:
		_update_keybind_display("move_forward", key_btn)

# --- TOGGLE STYLING HELPER ---
func _apply_toggle_style(toggle: CheckButton, is_on: bool) -> void:
	# Reset entire node modulate back to standard White so text isn't tinted
	toggle.modulate = Color.WHITE
	
	# Lock label text colors to ALWAYS stay White across all interaction states
	toggle.add_theme_color_override("font_color", Color.WHITE)
	toggle.add_theme_color_override("font_pressed_color", Color.WHITE)
	toggle.add_theme_color_override("font_hover_color", Color.WHITE)
	toggle.add_theme_color_override("font_hover_pressed_color", Color.WHITE)
	toggle.add_theme_color_override("font_focus_color", Color.WHITE)

	# Toggle switch icon color: Cyan (#00E5FF) when ON, White (#FFFFFF) when OFF
	var cyan = Color(0.0, 0.9, 1.0, 1.0)
	var white = Color(1.0, 1.0, 1.0, 1.0)
	var active_color = cyan if is_on else white

	toggle.add_theme_color_override("icon_normal_color", active_color)
	toggle.add_theme_color_override("icon_pressed_color", active_color)
	toggle.add_theme_color_override("icon_hover_color", active_color)
	toggle.add_theme_color_override("icon_hover_pressed_color", active_color)
	toggle.add_theme_color_override("icon_focus_color", active_color)

# --- ANIMATIONS ---
func open_overlay() -> void:
	pivot_offset = size / 2.0
	visible = true
	
	if dim_bg:
		dim_bg.visible = true
		create_tween().tween_property(dim_bg, "modulate:a", 1.0, 0.2)

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 1.0, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func close_overlay() -> void:
	if dim_bg:
		create_tween().tween_property(dim_bg, "modulate:a", 0.0, 0.2)

	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "modulate:a", 0.0, 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tween.tween_property(self, "scale", Vector2(0.9, 0.9), 0.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	
	tween.chain().tween_callback(func(): 
		visible = false
		if dim_bg: dim_bg.visible = false
	)

# --- AUDIO HANDLERS ---
func _on_master_slider_value_changed(value: float) -> void:
	var idx = AudioServer.get_bus_index("Master")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value))

func _on_music_slider_value_changed(value: float) -> void:
	var idx = AudioServer.get_bus_index("Music")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value))

func _on_sfx_slider_value_changed(value: float) -> void:
	var idx = AudioServer.get_bus_index("SFX")
	if idx != -1:
		AudioServer.set_bus_volume_db(idx, linear_to_db(value))

# --- GRAPHICS HANDLERS (With Audio Feedback) ---
func _on_fullscreen_toggle_toggled(toggled_on: bool) -> void:
	audiomanager.play_toggle()
	if toggled_on:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	if fullscreen_toggle:
		_apply_toggle_style(fullscreen_toggle, toggled_on)

func _on_vsync_toggle_toggled(toggled_on: bool) -> void:
	audiomanager.play_toggle()
	if toggled_on:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if vsync_toggle:
		_apply_toggle_style(vsync_toggle, toggled_on)

func _on_close_btn_pressed() -> void:
	audiomanager.play_button_click()
	close_overlay()

# --- CONTROL REMAPPING HANDLERS ---
func _on_key_btn_pressed() -> void:
	remapping_action = "move_forward"
	if key_btn:
		key_btn.text = "Press any key..."

func _unhandled_input(event: InputEvent) -> void:
	if remapping_action != "" and event is InputEventKey and event.is_pressed():
		# Remove old keybind and assign new one
		InputMap.action_erase_events(remapping_action)
		InputMap.action_add_event(remapping_action, event)
		
		# Update UI button text
		if key_btn:
			_update_keybind_display(remapping_action, key_btn)
		remapping_action = ""

func _update_keybind_display(action_name: String, button: Button) -> void:
	if not button:
		return
	var events = InputMap.action_get_events(action_name)
	if events.size() > 0:
		button.text = events[0].as_text().replace(" (Physical)", "")
	else:
		button.text = "None"
