extends Area3D
## Coin: Collectible item. Spins slowly, collected on player contact.

signal collected(value: int)

const COIN_VALUE := 1
const SPIN_SPEED := 3.0

var _is_collected: bool = false
var _mesh: MeshInstance3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_mesh = get_node_or_null("Mesh")
	collision_layer = 2
	collision_mask = 1


func _process(delta: float) -> void:
	if _is_collected:
		return
	if _mesh:
		_mesh.rotate_y(SPIN_SPEED * delta)


func _on_body_entered(body: Node3D) -> void:
	if _is_collected:
		return
	if body is CharacterBody3D:
		_collect()


func _collect() -> void:
	_is_collected = true
	collected.emit(COIN_VALUE)
	GameManager.add_coin(COIN_VALUE)
	AnalyticsManager.track_event("coin_collected", {"total": GameManager.coins})
	if _mesh:
		var tween := create_tween()
		tween.tween_property(_mesh, "scale", Vector3.ZERO, 0.15)
		tween.tween_callback(queue_free)
	else:
		queue_free()
