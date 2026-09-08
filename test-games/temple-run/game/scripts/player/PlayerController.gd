extends CharacterBody3D
## PlayerController: Temple Run style player movement
## Auto-run forward, 3 lanes, swipe/keyboard controls, jump, slide

signal hit_obstacle
signal coin_collected(value: int)
signal lane_changed(new_lane: int)

const LANE_WIDTH := 2.5
const LANE_COUNT := 3
const GRAVITY := 30.0
const JUMP_VELOCITY := 12.0
const SLIDE_DURATION := 0.6
const LANE_CHANGE_SPEED := 12.0

var current_lane: int = 1
var target_x: float = 0.0
var is_jumping: bool = false
var is_sliding: bool = false
var slide_timer: float = 0.0
var _original_height: float = 1.8
var _slide_height: float = 0.8
var _swipe_start_pos := Vector2.ZERO
var _swipe_detected: bool = false
const SWIPE_THRESHOLD := 50.0

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _mesh: MeshInstance3D = $MeshInstance3D


func _ready() -> void:
	target_x = _lane_to_x(current_lane)
	_original_height = _collision_shape.shape.size.y if _collision_shape and _collision_shape.shape is CapsuleShape3D else 1.8


func _physics_process(delta: float) -> void:
	if not GameManager.is_playing():
		return
	var speed: float = GameManager.get_current_speed()
	velocity.z = -speed
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	if is_jumping and is_on_floor():
		velocity.y = JUMP_VELOCITY
		is_jumping = false
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0:
			_stop_slide()
	var current_pos := global_position
	current_pos.x = lerp(current_pos.x, target_x, LANE_CHANGE_SPEED * delta)
	global_position = current_pos
	move_and_slide()
	if global_position.y < -10:
		_die()


func _input(event: InputEvent) -> void:
	if not GameManager.is_playing():
		return
	if event is InputEventKey and event.pressed:
		if event.is_action("swipe_left"):
			_change_lane(-1)
		elif event.is_action("swipe_right"):
			_change_lane(1)
		elif event.is_action("swipe_up"):
			_jump()
		elif event.is_action("swipe_down"):
			_slide()
		elif event.is_action("pause"):
			GameManager.pause_game()
	if event is InputEventScreenTouch:
		if event.pressed:
			_swipe_start_pos = event.position
			_swipe_detected = false
	if event is InputEventScreenDrag:
		var drag_dist: float = event.position.distance_to(_swipe_start_pos)
		if drag_dist > SWIPE_THRESHOLD and not _swipe_detected:
			_swipe_detected = true
			var drag_vec: Vector2 = event.position - _swipe_start_pos
			if abs(drag_vec.x) > abs(drag_vec.y):
				if drag_vec.x > 0:
					_change_lane(1)
				else:
					_change_lane(-1)
			else:
				if drag_vec.y < 0:
					_jump()
				else:
					_slide()


func _change_lane(direction: int) -> void:
	var new_lane: int = clamp(current_lane + direction, 0, LANE_COUNT - 1)
	if new_lane != current_lane:
		current_lane = new_lane
		target_x = _lane_to_x(current_lane)
		lane_changed.emit(current_lane)
		AnalyticsManager.track_event("lane_change", {"lane": current_lane})


func _jump() -> void:
	if is_on_floor() and not is_sliding:
		is_jumping = true
		AnalyticsManager.track_event("jump")


func _slide() -> void:
	if not is_sliding and is_on_floor():
		_start_slide()
		AnalyticsManager.track_event("slide")


func _start_slide() -> void:
	is_sliding = true
	slide_timer = SLIDE_DURATION
	if _collision_shape and _collision_shape.shape is CapsuleShape3D:
		var shape := _collision_shape.shape as CapsuleShape3D
		shape.height = _slide_height
		_collision_shape.position.y = -0.3
	if _mesh:
		_mesh.scale.y = 0.5
		_mesh.position.y = -0.3


func _stop_slide() -> void:
	is_sliding = false
	if _collision_shape and _collision_shape.shape is CapsuleShape3D:
		var shape := _collision_shape.shape as CapsuleShape3D
		shape.height = _original_height
		_collision_shape.position.y = 0
	if _mesh:
		_mesh.scale.y = 1.0
		_mesh.position.y = 0


func _lane_to_x(lane: int) -> float:
	return (lane - 1) * LANE_WIDTH


func _die() -> void:
	hit_obstacle.emit()
	AnalyticsManager.track_event("player_died", {
		"score": GameManager.score,
		"coins": GameManager.coins,
		"distance": GameManager.distance,
		"lane": current_lane,
	})
	GameManager.end_game()


func get_current_lane() -> int:
	return current_lane


func reset() -> void:
	current_lane = 1
	target_x = _lane_to_x(current_lane)
	is_jumping = false
	is_sliding = false
	slide_timer = 0.0
	velocity = Vector3.ZERO
	global_position = Vector3(0, 0.5, 0)
	_stop_slide()
