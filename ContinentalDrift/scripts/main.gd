extends Node2D

var Room = preload("res://scenes/room.tscn")
var tile_size: int = 32
var num_rooms: int = 50
var min_size: int = 4
var max_size: int = 10
var hspread: int = 400
var cull_percent: float = 0.5

var path: AStar2D
func _ready():
	randomize()
	make_rooms()

func make_rooms():
	for i in range(num_rooms):
		var pos = Vector2(randi_range(-hspread, hspread), 0)
		var r = Room.instantiate()
		var width = min_size + randi() % (max_size - min_size)
		var height = min_size + randi() % (max_size - min_size)
		r.make_room(pos, Vector2(width, height) * tile_size)
		$Rooms.add_child(r)
	
	await(get_tree().create_timer(1.1).timeout)
	
	var room_positions: Array = []
	for room in $Rooms.get_children():
		if randf() < cull_percent:
			room.queue_free()
		else:
			room.freeze
			room_positions.append(Vector2(room.position.x, room.position.y))
			
	await(get_tree().create_timer(1.1).timeout)
	
	path = find_mst(room_positions)

func find_mst(nodes) -> AStar2D:
	var path = AStar2D.new()
	path.add_point(path.get_available_point_id(), nodes.pop_front())
	
	while nodes:
		var min_distance = INF
		var min_p = null
		var p = null
		
		for p1 in path.get_point_ids():
			var pos_1 = path.get_point_position(p1)
			for p2 in nodes:
				if pos_1.distance_to(p2) < min_distance:
					min_distance = pos_1.distance_to(p2)
					min_p = p2
					p = pos_1
		var n = path.get_available_point_id()
		path.add_point(n, min_p)
		path.connect_points(path.get_closest_point(p), n)
		nodes.erase(min_p)
	
	return path
	
	
func _draw():
	for room in $Rooms.get_children():
		draw_rect(Rect2(room.position - room.size, room.size * 2),
		Color(0, 255,	255), false)
		
	if path:
		for p in path.get_point_ids():
			for c in path.get_point_connections(p):
				var pp = path.get_point_position(p)
				var cp = path.get_point_position(c)
				draw_line(Vector2(pp.x, pp.y), Vector2(cp.x, cp.y), 
				Color(1, 1, 0), 15, true)

func _process(delta: float) -> void:
	queue_redraw()
	
func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("ui_select"):
		for n in $Rooms.get_children():
			n.queue_free()
		make_rooms()
