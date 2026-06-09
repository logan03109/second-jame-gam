extends Control

func _ready():
	$TextureRect/VBoxContainer/HighScoreLabel.text = "High Score: %d" % Global.high_score

func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
