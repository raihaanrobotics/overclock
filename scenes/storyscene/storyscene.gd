extends Control

@onready var video_player: VideoStreamPlayer = $VideoStreamPlayer

# Path to your upcoming tutorial/gameplay scene (Update in Inspector as needed)
@export_file("*.tscn") var next_scene_path: String = "res://scenes/tutorial/tutorial.tscn"

func _ready() -> void:
	# Start invisible for a smooth fade-in after the portal zoom transition
	modulate.a = 0.0
	
	# Anchor VideoStreamPlayer to cover the full screen bounds
	video_player.anchor_right = 1.0
	video_player.anchor_bottom = 1.0
	video_player.expand = true
	
	# Connect signal to trigger when video playback completes
	if not video_player.finished.is_connected(_on_video_finished):
		video_player.finished.connect(_on_video_finished)
	
	# Fade in the scene smoothly
	var fade_in = create_tween()
	fade_in.tween_property(self, "modulate:a", 1.0, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# Start video playback
	video_player.play()

# Triggers when video ends naturally
func _on_video_finished() -> void:
	_transition_to_next_scene()

# Optional: Allows player to tap screen / press any key to skip cutscene
func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and not event.is_echo():
		if event is InputEventKey or event is InputEventMouseButton or event is InputEventScreenTouch:
			# Play transition sfx if needed (e.g., from audiomanager)
			_transition_to_next_scene()

func _transition_to_next_scene() -> void:
	# Disable input handling so transition can't trigger twice
	set_process_unhandled_input(false)
	
	# Stop the video immediately so the audio doesn't linger
	video_player.stop()
	
	# Smooth fade out before loading next scene
	var fade_out = create_tween()
	fade_out.tween_property(self, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fade_out.tween_callback(func():
		if next_scene_path != "":
			get_tree().change_scene_to_file(next_scene_path)
	)
