extends CanvasLayer

# --- TOP LEFT: UNCAPPED XP & WAVE DISPLAY ---
@onready var wave_label: Label = $Control/XPDisplay/MarginContainer/HBoxContainer/WaveLabel
@onready var xp_val_label: Label = $Control/XPDisplay/MarginContainer/HBoxContainer/XPValLabel

# --- TOP RIGHT: HEALTH SYSTEM ---
@onready var health_bar: ProgressBar = $Control/HealthBar
@onready var health_label: Label = $Control/HealthBar/HealthLabel

# --- BOTTOM LEFT: OVERHEAT & MULTIPLIER ---
@onready var heat_bar: ProgressBar = $Control/HeatContainer/HeatBar
@onready var danger_label: Label = $Control/HeatContainer/DangerZoneLabel
@onready var multiplier_label: Label = $Control/HeatContainer/MultiplierLabel

# --- GAME OVER OVERLAY ---
@onready var game_over_panel: ColorRect = $Control/GameOverPanel
@onready var title_label: Label = $Control/GameOverPanel/CenterContainer/VBoxContainer/Titlelabel
@onready var restart_button: Button = $Control/GameOverPanel/CenterContainer/VBoxContainer/RestartButton
@onready var quit_button: Button = $Control/GameOverPanel/CenterContainer/VBoxContainer/QuitButton

var current_xp: int = 0

func _ready() -> void:
	if game_over_panel:
		game_over_panel.visible = false
	if danger_label:
		danger_label.visible = false

	if restart_button:
		restart_button.pressed.connect(_on_restart_pressed)
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)

# Call whenever player gains XP / kills an enemy
func add_xp(amount: int) -> void:
	current_xp += amount
	if xp_val_label:
		xp_val_label.text = "XP: %d" % current_xp

# Call when wave increments
func update_wave(wave_number: int) -> void:
	if wave_label:
		wave_label.text = "WAVE %d" % wave_number

func update_health(current_hp: float, max_hp: float) -> void:
	if health_bar:
		health_bar.max_value = max_hp
		health_bar.value = current_hp
	if health_label:
		health_label.text = "HP: %d / %d" % [int(current_hp), int(max_hp)]

func update_heat(current_heat: float, in_danger_zone: bool, multiplier: float) -> void:
	if heat_bar:
		heat_bar.value = current_heat
		
	if multiplier_label:
		multiplier_label.text = "MULTIPLIER: %.1fx" % multiplier

	if danger_label:
		danger_label.visible = in_danger_zone
		if in_danger_zone:
			danger_label.text = "⚠️ OVERCLOCK DANGER ZONE (5x SCORE) ⚠️"

func show_game_over(reason: String = "CRITICAL SYSTEM FAILURE") -> void:
	if game_over_panel:
		game_over_panel.visible = true
	if title_label:
		title_label.text = reason

func _on_restart_pressed() -> void:
	if audiomanager and audiomanager.has_method("play_button_click"):
		audiomanager.play_button_click()
	get_tree().reload_current_scene()

func _on_quit_pressed() -> void:
	if audiomanager and audiomanager.has_method("play_button_click"):
		audiomanager.play_button_click()
	get_tree().quit()
