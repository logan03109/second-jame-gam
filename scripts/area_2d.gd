extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		get_tree().call_group("main", "_fade_to_scene", "res://scenes/distortion.tscn")
