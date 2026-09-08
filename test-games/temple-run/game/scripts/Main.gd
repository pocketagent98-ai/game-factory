extends Node3D
## Main: Root scene controller. Sets up player, camera, track, UI.

@onready var _player: CharacterBody3D = $Player
@onready var _camera: Camera3D = $Camera3D
@onready var _track_generator: Node3D = $TrackGenerator
@onready var _hud: CanvasLayer = $HUD
@onready var _main_menu: CanvasLayer = $MainMenu
@onready var _game_over_screen: CanvasLayer = $GameOverScreen
@onready var _pause_screen: CanvasLayer = $PauseScreen

const CAMERA_OFFSET := Vector3(0, 5.5, 7.0)
const CAMERA_LERP_SPEED := 5.0
const PLAYER_START_POS := Vector3(0, 0.5, 0)


func _ready() -> void:
	_track_generator.setup(_player)
	GameManager.game_started.connect(_on_game_started)
	GameManager.game_over.connect(_on_game_over)
	_main_menu.visible = true
	_hud.visible = false
	_game_over_screen.visible = false
	_pause_screen.visible = false
	_camera.global_position = PLAYER_START_POS + CAMERA_OFFSET
	_camera.look_at(_player.global_position)


func _process(delta: float) -> void:
	if GameManager.is_playing():
		var target_pos := _player.global_position + CAMERA_OFFSET
		_camera.global_position = _camera.global_position.lerp(target_pos, CAMERA_LERP_SPEED * delta)
		_camera.look_at(_player.global_position + Vector3(0, 1, 0))


func _on_game_started() -> void:
	_main_menu.visible = false
	_hud.visible = true
	_game_over_screen.visible = false
	_player.reset()
	_track_generator.setup(_player)


func _on_game_over() -> void:
	_hud.visible = false
	_game_over_screen.visible = true


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if GameManager.state == GameManager.State.PLAYING:
			GameManager.pause_game()
		elif GameManager.state == GameManager.State.PAUSED:
			GameManager.resume_game()
