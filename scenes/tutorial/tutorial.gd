extends Node3D

@onready var player: CharacterBody3D = $Player
@onready var hud: CanvasLayer = $HUD

func _ready() -> void:
	# Plays "The Protagonist.ogg" as soon as the tutorial scene loads
	if audiomanager:
		audiomanager.play_tutorial_music()
	else:
		audiomanager.play_tutorial_music()

	# Wire Player Signals directly to HUD functions
	if player and hud:
		player.health_changed.connect(hud.update_health)
		player.heat_changed.connect(hud.update_heat)
		
		# Connect Death Events
		player.player_died.connect(func(): hud.show_game_over("SYSTEM FAILURE - YOU DIED"))
		player.player_overheated.connect(func(): hud.show_game_over("CRITICAL OVERHEAT DETONATION"))
