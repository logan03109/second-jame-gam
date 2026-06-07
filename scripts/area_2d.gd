extends Area2D

func _ready():
	body_entered.connect(_test)
	monitoring = true
	monitorable = true

func _test(body):
	print("hit: ", body.name)
