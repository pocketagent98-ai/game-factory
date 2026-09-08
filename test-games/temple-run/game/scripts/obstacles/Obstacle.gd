extends Area3D
## Obstacle: Detects collision with the player. Sends hit signal.

signal obstacle_hit(obstacle_type: String)

var _obstacle_type: String = "rock"


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_obstacle_type = get_meta("obstacle_type", "rock")


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("_die"):
		var action: String = get_meta("action", "jump")
		var player := body as CharacterBody3D
		
		if action == "slide" and player.is_sliding:
			return
		
		if action == "jump" and not player.is_on_floor():
			var obstacle_top: float = global_position.y + scale.y / 2.0
			if player.global_position.y > obstacle_top + 0.3:
				return
		
		obstacle_hit.emit(_obstacle_type)
		AnalyticsManager.track_event("obstacle_hit", {
			"type": _obstacle_type,
			"lane": int(round((global_position.x + 2.5) / 2.5)),
		})
		player._die()
