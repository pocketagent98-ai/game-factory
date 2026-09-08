extends CanvasLayer
## PauseScreen: Shown when game is paused

@onready var _pause_label: Label = $MarginContainer/VBoxContainer/PauseLabel
@onready var _resume_button: Button = $MarginContainer/VBoxContainer/ResumeButton
@onready var _restart_button: Button = $MarginContainer/VBoxContainer/RestartButton
@onready var _menu_button: Button = $MarginContainer/VBoxContainer/MenuButton


func _ready() -> void:
	visible = false
	GameManager.game_paused.connect(_on_game_paused)
	GameManager.game_resumed.connect(_on_game_resumed)
	_pause_label.text = GlobalLanguage.tr_key("pause")
	_resume_button.text = GlobalLanguage.tr_key("resume")
	_restart_button.text = GlobalLanguage.tr_key("tap_to_restart")
	_menu_button.text = GlobalLanguage.tr_key("main_menu")
	_resume_button.pressed.connect(_on_resume_pressed)
	_restart_button.pressed.connect(_on_restart_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)


func _on_game_paused() -> void:
	visible = true


func _on_game_resumed() -> void:
	visible = false


func _on_resume_pressed() -> void:
	GameManager.resume_game()


func _on_restart_pressed() -> void:
	GameManager.resume_game()
	GameManager.start_game()
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	GameManager.resume_game()
	GameManager.return_to_menu()
