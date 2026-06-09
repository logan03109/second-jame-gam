extends Area2D

func _ready():
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D):
	print("hit portal, body: ", body.name)
	if body.is_in_group("player"):
		print("changing scene")
		get_tree().change_scene_to_file("res://scenes/distortion.tscn")
