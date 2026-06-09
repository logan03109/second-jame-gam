extends Area2D
@onready var sfx = $AudioStreamPlayer
#@onready var powerup_sprite: Resource = preload("res://scenes/powerup.tscn")

var rate := 0.1
var powers := {"speed":10.0, "jump":10.0, "freeze":3.0}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_shape_entered(body_rid: RID, body: Node2D, body_shape_index: int, local_shape_index: int):
	print("COLLIDE")
	if body.is_in_group("player"):
		var keys = powers.keys()
		var random_key = keys[randi() % keys.size()]
		body.apply_effect(random_key, powers[random_key])
		sfx.play()
		await sfx.finished
		queue_free()
