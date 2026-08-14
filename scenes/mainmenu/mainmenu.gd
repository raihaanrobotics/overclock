extends Control

@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var leaderboard_panel: PanelContainer = $LeaderboardPanel
@onready var tournaments_panel: PanelContainer = $TournamentsPanel

# Connected from SettingsBtn's pressed() signal
func _on_settings_btn_pressed() -> void:
	settings_panel.open_overlay()
