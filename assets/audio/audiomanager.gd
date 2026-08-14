extends Node

# Audio Players
var bgm_player: AudioStreamPlayer = AudioStreamPlayer.new()
var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()

# Preload Audio Streams
var menu_music: AudioStream = preload("res://assets/audio/Dystopian.ogg")
var tutorial_music: AudioStream = preload("res://assets/audio/The Protagonist.ogg")

var button_click_sfx: AudioStream = preload("res://assets/audio/click.wav")  # Set to preload("res://assets/audio/click.wav") when added
var toggle_sfx: AudioStream = preload("res://assets/audio/gun_fire.wav")        # Set to preload("res://assets/audio/toggle.wav") when added
var gun_fire_sfx: AudioStream = null      # Set to preload("res://assets/audio/gun_fire.wav") when added
var laser_beam_sfx: AudioStream = null    # Set to preload("res://assets/audio/laser_beam.wav") when added
var enemy_destroy_sfx: AudioStream = null # Set to preload("res://assets/audio/enemy_destroy.wav") when added

func _ready() -> void:
	# Set Audio Bus assignments
	bgm_player.bus = &"Music"
	sfx_player.bus = &"SFX"
	
	add_child(bgm_player)
	add_child(sfx_player)
	
	# Start Main Menu BGM
	play_music(menu_music)

func play_music(stream: AudioStream) -> void:
	if stream == null:
		return
	if bgm_player.stream == stream and bgm_player.playing:
		return
	bgm_player.stream = stream
	bgm_player.play()

func stop_music() -> void:
	if bgm_player.playing:
		bgm_player.stop()

func play_sfx(stream: AudioStream) -> void:
	if stream:
		sfx_player.stream = stream
		sfx_player.play()

func play_button_click() -> void:
	stop_music() # Stop main menu music completely on click
	play_sfx(button_click_sfx)

func play_toggle() -> void:
	play_sfx(toggle_sfx)

# --- NEW AUDIO FUNCTIONS ---

func play_tutorial_music() -> void:
	play_music(tutorial_music)

func play_gun_fire() -> void:
	play_sfx(gun_fire_sfx)

func play_laser_beam() -> void:
	play_sfx(laser_beam_sfx)

func play_enemy_destroy() -> void:
	play_sfx(enemy_destroy_sfx)
