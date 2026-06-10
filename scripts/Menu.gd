extends Control

@onready var settings_panel = $SettingsPanel
@onready var credits_panel = $CreditsPanel
@onready var music = $AudioStreamPlayer

func _ready():
	$TextureRect/VBoxContainer/HighScoreLabel.text = "High Score: %d" % Global.high_score
	settings_panel.visible = false
	credits_panel.visible = false

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_settings_button_pressed():
	settings_panel.visible = true

func _on_credits_button_pressed():
	credits_panel.visible = true

func _on_settings_close_pressed():
	settings_panel.visible = false

func _on_credits_close_pressed():
	credits_panel.visible = false

# music volume slider
func _on_h_slider_value_changed(value: float):
	music.volume_db = linear_to_db(value)


func _on_close_button_pressed() -> void:
	settings_panel.visible = false
	credits_panel.visible = false
