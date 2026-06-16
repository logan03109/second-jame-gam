extends Node
var high_score := 0
var score := 0.0
var last_score := 0
var active_powerup := ""
var powerup_time_remaining := 0.0
var p1_speed := 0.0
var p1_jump := 0.0
var p2_speed := 0.0
var p2_jump := 0.0

func _unhandled_key_input(event):
	if event.pressed and event.keycode == KEY_N:
		_change_volume(2.0)
	elif event.pressed and event.keycode == KEY_M:
		_change_volume(-2.0)

func _change_volume(amount: float):
	var bus_idx := AudioServer.get_bus_index("Master")
	var current_db := AudioServer.get_bus_volume_db(bus_idx)
	var new_db: float = clamp(current_db + amount, -40.0, 10.0)
	AudioServer.set_bus_volume_db(bus_idx, new_db)
	print("Master volume: ", new_db)
func _ready():
	print("GLOBAL SINGLETON READY, instance id: ", get_instance_id())
