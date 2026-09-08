extends CanvasLayer
## GameOverScreen: Shown when player hits an obstacle or falls off

@onready var _game_over_label: Label = $MarginContainer/VBoxContainer/GameOverLabel
@onready var _score_label: Label = $MarginContainer/VBoxContainer/ScoreLabel
@onready var _coins_label: Label = $MarginContainer/VBoxContainer/CoinsLabel
@onready var _high_score_label: Label = $MarginContainer/VBoxContainer/HighScoreLabel
@onready var _new_high_label: Label = $MarginContainer/VBoxContainer/NewHighLabel
@onready var _retry_button: Button = $MarginContainer/VBoxContainer/RetryButton
@onready var _menu_button: Button = $MarginContainer/VBoxContainer/MenuButton


func _ready() -> void:
	visible = false
	GameManager.game_over.connect(_on_game_over)
	_game_over_label.text = GlobalLanguage.tr_key("game_over")
	_retry_button.text = GlobalLanguage.tr_key("tap_to_retry")
	_menu_button.text = GlobalLanguage.tr_key("main_menu")
	_retry_button.pressed.connect(_on_retry_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)


func _on_game_over() -> void:
	visible = true
	_score_label.text = GlobalLanguage.tr_key("score") + ": " + str(GameManager.score)
	_coins_label.text = GlobalLanguage.tr_key("coins") + ": " + str(GameManager.coins)
	_high_score_label.text = GlobalLanguage.tr_key("high_score") + ": " + str(GameManager.high_score)
	if GameManager.score >= GameManager.high_score and GameManager.score > 0:
		_new_high_label.text = GlobalLanguage.tr_key("new_high_score")
		_new_high_label.visible = true
	else:
		_new_high_label.visible = false
	AnalyticsManager.track_event("game_over_screen_shown", {
		"score": GameManager.score,
		"coins": GameManager.coins,
	})


func _on_retry_pressed() -> void:
	AnalyticsManager.track_event("retry_pressed")
	visible = false
	GameManager.start_game()
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	AnalyticsManager.track_event("menu_pressed_from_gameover")
	GameManager.return_to_menu()
