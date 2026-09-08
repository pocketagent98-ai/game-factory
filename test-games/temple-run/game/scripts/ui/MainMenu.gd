extends CanvasLayer
## MainMenu: Start screen with Play button and high score display

@onready var _title_label: Label = $MarginContainer/VBoxContainer/TitleLabel
@onready var _play_button: Button = $MarginContainer/VBoxContainer/PlayButton
@onready var _settings_button: Button = $MarginContainer/VBoxContainer/SettingsButton
@onready var _quit_button: Button = $MarginContainer/VBoxContainer/QuitButton
@onready var _high_score_label: Label = $MarginContainer/VBoxContainer/HighScoreLabel
@onready var _coins_label: Label = $MarginContainer/VBoxContainer/CoinsLabel


func _ready() -> void:
	_title_label.text = GlobalLanguage.tr_key("game_title")
	_play_button.text = GlobalLanguage.tr_key("play")
	_settings_button.text = GlobalLanguage.tr_key("settings")
	_quit_button.text = GlobalLanguage.tr_key("quit")
	_high_score_label.text = GlobalLanguage.tr_key("high_score") + ": " + str(GameManager.high_score)
	_coins_label.text = GlobalLanguage.tr_key("coins") + ": " + str(GameManager.total_coins)
	_play_button.pressed.connect(_on_play_pressed)
	_settings_button.pressed.connect(_on_settings_pressed)
	_quit_button.pressed.connect(_on_quit_pressed)
	GameManager.high_score_changed.connect(func(new_high: int):
		_high_score_label.text = GlobalLanguage.tr_key("high_score") + ": " + str(new_high))


func _on_play_pressed() -> void:
	AnalyticsManager.track_event("menu_play_pressed")
	GameManager.start_game()
	visible = false


func _on_settings_pressed() -> void:
	AnalyticsManager.track_event("menu_settings_pressed")
	print("[MainMenu] Settings not implemented yet")


func _on_quit_pressed() -> void:
	AnalyticsManager.track_event("menu_quit_pressed")
	get_tree().quit()
