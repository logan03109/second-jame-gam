#main.gd

extends Node2D
@export var decay_speed        := 200.0
@export var min_zoom           := 1.0
@export var max_zoom           := 4.0
@export var zoom_margin        := 200.0
@export var decay_start_offset := 400
@export var join_action        := "p2_join"
@export var chunk_scenes: Array[PackedScene] = []
@export var start_chunk: PackedScene
@export var safe_chunk_interval := 1
@export var safe_chunk_time := 2.0

@onready var timer_label := $CanvasLayer/TimerLabel
@onready var camera          := $GameCamera
@onready var player1         := $player_1
@onready var player2         := $player_2
@onready var chunk_container := $Chunks
@onready var decay_line := $DecayLine
@onready var powerup := $Powerup
@onready var powerup_scene: Resource = preload("res://scenes/powerup.tscn")

var decay_wall_x        := -200.0
var tile_decay          := {}
var cached_cells        := []
var decay_active        := false
var p2_joined           := false
var active_chunks       := []
var next_chunk_x        := 0.0
var chunks_since_safe   := 0
var triggered_decay_off := {}
var triggered_decay_on  := {}
var pending_spawn       := ""
var spawn_ready         := false  # blocks _check_chunks until ready
var safe_timer := 0.0
var in_safe_chunk := false
var first_safe_chunk := true
var current_chunk: Node2D = null

var rate := 0.1
var powers := ["speed", "jump", "freeze"]

func _ready():
	Global.score = 0

	print(Input.get_connected_joypads())
	print("test with logan for git")
	add_to_group("main")
	camera.zoom = Vector2(3.0, 3.0)
	player2.visible = false
	player2.process_mode = Node.PROCESS_MODE_DISABLED
	_spawn_specific_chunk(start_chunk)
	_spawn_chunk()
	spawn_ready = true
	if active_chunks.size() > 0:
		var spawn = active_chunks[0].get_node_or_null("SpawnPoint")
		if spawn:
			player1.global_position = active_chunks[0].global_position + spawn.position - Vector2(0, 32)
			player2.global_position = player1.global_position + Vector2(50, 0)
			
	#timerlabel
	var settings = LabelSettings.new()
	
	settings.font_size = 25
	settings.font_color = Color(255, 255, 255, 0.8)
	
	timer_label.label_settings = settings


func _process(delta):
	
	
	
	if not p2_joined and Input.is_action_just_pressed(join_action):
		_join_player2()

	if pending_spawn == "safe":
		pending_spawn = ""
		_spawn_specific_chunk(start_chunk)
	elif pending_spawn == "danger":
		pending_spawn = ""
		_spawn_chunk()
	
	_update_chunk_speed()
	if decay_active:
		decay_wall_x += decay_speed * delta

	if spawn_ready:
		_check_chunks()
		
	if pending_spawn == "safe":
		print("=== SPAWNING SAFE ===")
		pending_spawn = ""
		_spawn_specific_chunk(start_chunk)
	elif pending_spawn == "danger":
		print("=== SPAWNING DANGER ===")
		pending_spawn = ""
		_spawn_chunk()
	_apply_decay_to_tiles()
	_update_camera()
	
	# Update the visual line's X position to match your logic wall
	Global.score = _get_living_player_x()

	
	decay_line.global_position.x = decay_wall_x - 1100
	
	if in_safe_chunk:
		safe_timer -= delta

		timer_label.text = "Decay resumes in: %.1f" % safe_timer

		if safe_timer <= 0:
			in_safe_chunk = false
			decay_active = true
			timer_label.visible = false
			safe_timer = -1

			# Start decay from current player position
			decay_wall_x = _get_living_player_x() + decay_start_offset
	else:
			timer_label.visible = false

func _spawn_specific_chunk(scene: PackedScene):
	if scene == null:
		print("NO START CHUNK SET IN INSPECTOR")
		return
	var chunk: Node2D = scene.instantiate()
	chunk_container.add_child(chunk)
	var spawn_marker = chunk.get_node_or_null("SpawnPoint")
	var end_marker   = chunk.get_node_or_null("EndPoint")
	if spawn_marker == null or end_marker == null:
		print("MISSING MARKERS in start chunk")
		return
	chunk.global_position.x = next_chunk_x - spawn_marker.position.x
	next_chunk_x = chunk.global_position.x + end_marker.position.x
	active_chunks.append(chunk)
	_connect_chunk_signals(chunk)
	_add_chunk_cells(chunk)

func _spawn_chunk():
	if chunk_scenes.is_empty():
		print("NO CHUNKS IN ARRAY")
		return
	var scene: PackedScene = chunk_scenes[randi() % chunk_scenes.size()]
	var chunk: Node2D = scene.instantiate()
	chunk_container.add_child(chunk)
	var spawn_marker = chunk.get_node_or_null("SpawnPoint")
	var end_marker   = chunk.get_node_or_null("EndPoint")
	if spawn_marker == null or end_marker == null:
		print("MISSING MARKERS in chunk")
		return
	chunk.global_position.x = next_chunk_x - spawn_marker.position.x
	next_chunk_x = chunk.global_position.x + end_marker.position.x
	active_chunks.append(chunk)
	_connect_chunk_signals(chunk)
	_add_chunk_cells(chunk)
	var powerup_coords: Vector2 = Vector2(next_chunk_x, 0)
	_spawn_powerup_in_chunk(powerup_coords)

func _add_chunk_cells(chunk: Node2D):
	var chunk_tilemap = chunk.get_node_or_null("TileMap")
	if chunk_tilemap:
		var cells = chunk_tilemap.get_used_cells(0)
		print("adding ", cells.size(), " cells from chunk, tilemap id: ", chunk_tilemap.get_instance_id())
		for cell in cells:
			cached_cells.append({"tilemap": chunk_tilemap, "cell": cell})
		print("total cached_cells now: ", cached_cells.size())

func _connect_chunk_signals(chunk: Node2D):
	var checkpoint = chunk.get_node_or_null("checkpoint")
	if checkpoint:
		checkpoint.body_entered.connect(_on_checkpoint_reached)
	var decay_off = chunk.get_node_or_null("DecayOff")
	if decay_off:
		decay_off.body_entered.connect(func(body): _on_chunk_decay_off(body, decay_off, chunk))
	var decay_on = chunk.get_node_or_null("DecayOn")
	if decay_on:
		decay_on.body_entered.connect(func(body): _on_chunk_decay_on(body, decay_on))

func _on_checkpoint_reached(body):
	pass
func _on_chunk_decay_off(body, area, chunk):
	if (body == player1 or (p2_joined and body == player2)) and not triggered_decay_off.get(area, false):
		triggered_decay_off[area] = true
		decay_active = false
		if first_safe_chunk:
			first_safe_chunk = false
			timer_label.visible = false
			in_safe_chunk = false
		else:
			in_safe_chunk = true
			safe_chunk_time = _extend_safe_time(chunk)
			safe_timer = safe_chunk_time

			if timer_label:
				timer_label.visible = true
				timer_label.text = "Decay resumes in: %1d" % int(ceil(safe_timer))

		_respawn_dead_players()

func _on_chunk_decay_on(body, area):
	if (body == player1 or (p2_joined and body == player2)) and not triggered_decay_on.get(area, false):
		triggered_decay_on[area] = true
		decay_active = true
		print("player x:",_get_living_player_x())
		print("Decay x:", _get_living_player_x() + decay_start_offset)
		decay_wall_x = _get_living_player_x() + decay_start_offset
var next_chunk_to_trigger := 1

func _check_chunks():
	if active_chunks.size() <= next_chunk_to_trigger:
		return
	var trigger_chunk = active_chunks[next_chunk_to_trigger]
	var decay_off = trigger_chunk.get_node_or_null("DecayOff")
	if decay_off != null:
		next_chunk_to_trigger += 1
		if pending_spawn == "":
			pending_spawn = "danger"
		return
	var end_marker = trigger_chunk.get_node_or_null("EndPoint")
	if end_marker == null:
		return
	var trigger_end: float = trigger_chunk.global_position.x + end_marker.position.x
	if _get_living_player_x() > trigger_end - 500.0:
		next_chunk_to_trigger += 1
		chunks_since_safe += 1
		if chunks_since_safe >= safe_chunk_interval:
			pending_spawn = "safe"
			chunks_since_safe = 0
		else:
			pending_spawn = "danger"

func _apply_decay_to_tiles():
	for entry in cached_cells.duplicate():
		var tm: TileMap = entry["tilemap"]
		var cell: Vector2i = entry["cell"]
		if not is_instance_valid(tm):
			continue
		if tm.get_cell_source_id(0, cell) != -1:
			var world_pos: Vector2 = tm.to_global(tm.map_to_local(cell))
			var dist_behind: float = decay_wall_x - world_pos.x
			var factor: float = clamp(inverse_lerp(0.0, 600.0, dist_behind), 0.0, 1.0)
			var key := str(tm.get_instance_id()) + ":" + str(cell)
			tile_decay[key] = factor
			if factor >= 1.0:
				cached_cells.erase(entry)
				tm.erase_cell(0, cell)

func _join_player2():
	p2_joined = true
	player2.visible = true
	player2.process_mode = Node.PROCESS_MODE_INHERIT
	player2.global_position = player1.global_position + Vector2(50, 0)

func _update_camera():
	var p1_pos: Vector2 = player1.global_position
	var p2_pos: Vector2 = player2.global_position

	# only include living players in camera calculation
	var use_p2: bool = p2_joined and not player2_dead
	var use_p1: bool = not player1_dead

	if use_p1 and use_p2:
		var midpoint: Vector2 = (p1_pos + p2_pos) / 2.0
		camera.global_position = midpoint
		var distance: float = p1_pos.distance_to(p2_pos) + zoom_margin
		var viewport_size: Vector2 = get_viewport().get_visible_rect().size
		var zoom_x: float = viewport_size.x / distance
		var zoom_y: float = viewport_size.y / distance
		var target_zoom: float = clamp(min(zoom_x, zoom_y), min_zoom, max_zoom)
		var new_zoom: float = lerp(camera.zoom.x, target_zoom, 0.1)
		camera.zoom = Vector2(new_zoom, new_zoom)
	elif use_p2:
		camera.global_position = p2_pos
		camera.zoom = Vector2(3.0, 3.0)
	elif use_p1:
		camera.global_position = p1_pos
		camera.zoom = Vector2(3.0, 3.0)

var player1_dead := false
var player2_dead := false

func _on_player_died(player):
	if player == player1:
		player1_dead = true
		print("player 1 died")
	elif player == player2:
		player2_dead = true
		print("player 2 died")
	if player1_dead and not p2_joined:
		if Global.score > Global.high_score:
			Global.high_score = Global.score  # save new record
		get_tree().change_scene_to_file("res://scenes/Menu.tscn")  # go back to menu
	# both dead = reset
	if player1_dead and player2_dead:
		print("Everyone dead")
		if Global.score > Global.high_score:
			Global.high_score = Global.score  # save new record
		get_tree().change_scene_to_file("res://scenes/Menu.tscn")  # go back to menu
		

	# one dead, one alive = wait for safe chunk to respawn

func _respawn_dead_players():
	if player1_dead and not player2_dead and p2_joined:
		player1_dead = false
		player1.visible = true
		player1.set_physics_process(true)
		player1.velocity = Vector2.ZERO
		player1.global_position = player2.global_position + Vector2(50, 0)
	elif player2_dead and not player1_dead and p2_joined:
		player2_dead = false
		player2.visible = true
		player2.set_physics_process(true)
		player2.velocity = Vector2.ZERO
		player2.global_position = player1.global_position + Vector2(50, 0)
		

func _get_living_player_x() -> float:
	if not player1_dead:
		return player1.global_position.x
	elif not player2_dead and p2_joined:
		return player2.global_position.x
	return player1.global_position.x  # fallback
	
func _update_chunk_speed():
	var player_x = _get_living_player_x()

	for chunk in active_chunks:
		var end_marker = chunk.get_node_or_null("EndPoint")
		if end_marker == null:
			continue

		var chunk_start = chunk.global_position.x
		var chunk_end = chunk.global_position.x + end_marker.position.x

		if player_x >= chunk_start and player_x < chunk_end:
			if chunk != current_chunk:
				current_chunk = chunk

				if "chunk_decay_speed" in chunk:
					decay_speed = chunk.chunk_decay_speed
					print("Decay speed changed to ", decay_speed)

			return

func _extend_safe_time(chunk: Node2D): 
	var safe_chunk_powerup = chunk.get_node_or_null("poweruppointer")
	if safe_chunk_powerup: 
		safe_chunk_time += 3.0 
	return safe_chunk_time
	
func _spawn_powerup_in_chunk(coords):
	var powerup_inst = powerup_scene.instantiate()
	add_child(powerup_inst)
	powerup_inst.set_position(coords)
	print("Spawned at ", coords)

func _on_power_up_body_entered(body: Node2D) -> void:
	pass # Replace with function body.
