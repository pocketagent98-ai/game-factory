extends Node3D
## TrackGenerator: Procedural infinite track generation for endless runner
## Spawns track segments ahead of the player and recycles them behind.
## Each segment contains: ground, optional obstacles, coins, power-ups.

signal segment_spawned(segment: Node3D)
signal segment_recycled(segment: Node3D)

const SEGMENT_LENGTH := 20.0
const SEGMENT_WIDTH := 8.0
const MAX_SEGMENTS := 12
const SPAWN_AHEAD_DISTANCE := 200.0

var _segments: Array[Node3D] = []
var _next_segment_z: float = 0.0
var _player: Node3D = null
var _obstacle_scene: PackedScene
var _coin_scene: PackedScene

const OBSTACLE_TYPES := {
	"rock": {"y": 0.5, "scale": Vector3(1.2, 1.0, 1.2), "action": "jump"},
	"log": {"y": 0.4, "scale": Vector3(2.0, 0.8, 0.8), "action": "jump"},
	"barrier": {"y": 1.2, "scale": Vector3(2.0, 1.5, 0.3), "action": "slide"},
	"tall_wall": {"y": 1.5, "scale": Vector3(2.5, 3.0, 0.3), "action": "avoid"},
}


func _ready() -> void:
	_obstacle_scene = _create_obstacle_scene()
	_coin_scene = _create_coin_scene()


func setup(player: Node3D) -> void:
	_player = player
	for seg in _segments:
		if is_instance_valid(seg):
			seg.queue_free()
	_segments.clear()
	_next_segment_z = 0.0
	for i in range(MAX_SEGMENTS):
		_spawn_segment()


func _process(_delta: float) -> void:
	if _player == null or not GameManager.is_playing():
		return
	var player_z: float = _player.global_position.z
	while _next_segment_z > player_z - SPAWN_AHEAD_DISTANCE:
		_spawn_segment()
	for seg in _segments:
		if seg.global_position.z > player_z + SEGMENT_LENGTH * 2:
			_recycle_segment(seg)


func _spawn_segment() -> void:
	var segment := Node3D.new()
	segment.name = "Segment_%d" % int(abs(_next_segment_z) / SEGMENT_LENGTH)
	var ground := _create_ground_mesh()
	ground.position = Vector3(0, 0, _next_segment_z - SEGMENT_LENGTH / 2)
	segment.add_child(ground)
	_add_side_walls(segment, _next_segment_z)
	var segment_index: int = int(abs(_next_segment_z) / SEGMENT_LENGTH)
	if segment_index > 2:
		_populate_segment(segment, _next_segment_z)
	segment.global_position.z = _next_segment_z
	add_child(segment)
	_segments.append(segment)
	_next_segment_z -= SEGMENT_LENGTH
	segment_spawned.emit(segment)


func _recycle_segment(segment: Node3D) -> void:
	if segment in _segments:
		_segments.erase(segment)
	segment_recycled.emit(segment)
	segment.queue_free()


func _create_ground_mesh() -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(SEGMENT_WIDTH, 0.1, SEGMENT_LENGTH)
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.55, 0.35)
	mat.roughness = 0.9
	mesh.material_override = mat
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var col := BoxShape3D.new()
	col.size = Vector3(SEGMENT_WIDTH, 0.1, SEGMENT_LENGTH)
	shape.shape = col
	body.add_child(shape)
	mesh.add_child(body)
	return mesh


func _add_side_walls(parent: Node3D, z: float) -> void:
	for side in [-1, 1]:
		var wall := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.3, 1.5, SEGMENT_LENGTH)
		wall.mesh = box
		wall.position = Vector3(side * (SEGMENT_WIDTH / 2 + 0.15), 0.75, z - SEGMENT_LENGTH / 2)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 0.4, 0.25)
		wall.material_override = mat
		parent.add_child(wall)


func _populate_segment(segment: Node3D, z: float) -> void:
	var obstacle_count: int = randi() % 3
	var used_lanes: Array[int] = []
	for i in range(obstacle_count):
		var lane: int = randi() % 3
		if lane in used_lanes:
			continue
		used_lanes.append(lane)
		if used_lanes.size() >= 2:
			break
		var obstacle_types: Array = OBSTACLE_TYPES.keys()
		var type_key: String = obstacle_types[randi() % obstacle_types.size()]
		var type_info: Dictionary = OBSTACLE_TYPES[type_key]
		var obstacle := _obstacle_scene.instantiate()
		var lane_x: float = (lane - 1) * 2.5
		obstacle.position = Vector3(lane_x, type_info.y, z - SEGMENT_LENGTH / 2 + randf() * SEGMENT_LENGTH * 0.6)
		obstacle.scale = type_info.scale
		obstacle.set_meta("obstacle_type", type_key)
		obstacle.set_meta("action", type_info.action)
		segment.add_child(obstacle)
	for lane in range(3):
		if lane in used_lanes:
			continue
		if randf() < 0.6:
			var coin_count: int = 3 + randi() % 4
			for c in range(coin_count):
				var coin := _coin_scene.instantiate()
				var lane_x: float = (lane - 1) * 2.5
				coin.position = Vector3(
					lane_x, 1.0,
					z - SEGMENT_LENGTH / 2 + (float(c) / float(coin_count)) * SEGMENT_LENGTH * 0.8
				)
				segment.add_child(coin)


func _create_obstacle_scene() -> PackedScene:
	var root := Area3D.new()
	root.name = "Obstacle"
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1, 1, 1)
	mesh.mesh = box
	mesh.name = "Mesh"
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.3, 0.2)
	mat.roughness = 0.8
	mesh.material_override = mat
	root.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1, 1, 1)
	col.shape = shape
	col.name = "CollisionShape"
	root.add_child(col)
	root.set_script(load("res://scripts/obstacles/Obstacle.gd"))
	var packed := PackedScene.new()
	packed.pack(root)
	return packed


func _create_coin_scene() -> PackedScene:
	var root := Area3D.new()
	root.name = "Coin"
	var mesh := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.3
	cyl.bottom_radius = 0.3
	cyl.height = 0.08
	mesh.mesh = cyl
	mesh.name = "Mesh"
	mesh.rotation.x = deg_to_rad(90)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.84, 0.0)
	mat.metallic = 0.8
	mat.roughness = 0.2
	mesh.material_override = mat
	root.add_child(mesh)
	var col := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 0.3
	shape.height = 0.5
	col.shape = shape
	col.name = "CollisionShape"
	root.add_child(col)
	root.set_script(load("res://scripts/collectibles/Coin.gd"))
	var packed := PackedScene.new()
	packed.pack(root)
	return packed
