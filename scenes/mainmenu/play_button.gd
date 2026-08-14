extends Button

# Path to your Story Scene (Update with your actual scene path)
@export_file("*.tscn") var story_scene_path: String = "res://scenes/storyscene/storyscene.tscn"

# Tweens for smooth transition
var hover_tween: Tween

func _ready() -> void:
	# Completely strip focus outline and box styling
	focus_mode = Control.FOCUS_NONE
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	
	# Set pivot to exact center so scaling happens from the middle
	pivot_offset = size / 2.0
	
	# Connect signals automatically
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	if not pressed.is_connected(_on_pressed):
		pressed.connect(_on_pressed)

func _on_mouse_entered() -> void:
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween().set_parallel(true)
	# Dim the button (darken modulating color)
	hover_tween.tween_property(self, "modulate", Color(0.8, 0.8, 0.8, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
	# Optional slight shrink effect for a tactile feel
	hover_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_SINE)

func _on_mouse_exited() -> void:
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween().set_parallel(true)
	# Reset back to normal brightness
	hover_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
	# Reset back to normal size
	hover_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)

func _on_pressed() -> void:
	# Ignore future mouse clicks without triggering the 'disabled' style box
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	release_focus()
	
	# Play click SFX
	audiomanager.play_button_click()
	
	# Find top-level Control node (Main Menu Root) to scale/zoom the whole screen
	var main_menu = get_tree().current_scene
	
	# Lock pivot to the exact center of the screen viewport
	main_menu.pivot_offset = get_viewport_rect().size / 2.0
	
	# Create transition tween
	var tween = create_tween()
	
	# Deep zoom into the center image (keeps 100% opacity so no blank background shows)
	tween.tween_property(main_menu, "scale", Vector2(12.0, 12.0), 0.55).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	
	# Once transition finishes, switch to the Story Scene
	tween.tween_callback(func():
		if story_scene_path != "":
			get_tree().change_scene_to_file(story_scene_path)
	)
