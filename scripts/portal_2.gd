extends Area2D
var triggered := false
func _ready():
	print("portal_2 ready, monitoring: ", monitoring)
	body_entered.connect(_on_body_entered)
func _on_body_entered(body: Node2D):
	print("portal_2 detected body: ", body.name)
	if triggered:
		print("already triggered, ignoring")
		return
	if body.is_in_group("player"):
		print("player confirmed, fading")
		triggered = true
		get_tree().call_group("main", "_fade_to_scene", "res://scenes/main.tscn")
	else:
		print("body not in player group: ", body.get_groups())
