extends Control

@onready var music = $AudioStreamPlayer
func _ready():
	var highScoreText = "HIGH SCORE: %d" % Global.high_score
	var lastScoreText = "LATEST SCORE: %d" % Global.score
	$TextureRect/HighScoreLabel.text = lastScoreText + "\n" + highScoreText
	
func _on_play_button_pressed():
	get_tree().change_scene_to_file("res://scenes/Main.tscn")
