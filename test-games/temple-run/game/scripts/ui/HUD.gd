extends CanvasLayer
## HUD: In-game heads-up display showing score, coins, distance, speed

@onready var _score_label: Label = $MarginContainer/TopBar/ScoreContainer/ScoreLabel
@onready var _high_score_label: Label = $MarginContainer/TopBar/ScoreContainer/HighScoreLabel
@onready var _coins_label: Label = $MarginContainer/TopBar/CoinsContainer/CoinsLabel
@onready var _distance_label: Label = $MarginContainer/TopBar/DistanceContainer/DistanceLabel
@onready var _speed_label: Label = $MarginContainer/TopBar/SpeedContainer/SpeedLabel
@onready var _pause_button: Button = $MarginContainer/TopBar/PauseButton


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.coins_changed.connect(_on_coins_changed)
	GameManager.high_score_changed.connect(_on_high_score_changed)
	_pause_button.pressed.connect(_on_pause_pressed)
	_pause_button.text = GlobalLanguage.tr_key("pause")
	_update_all()


func _process(_delta: float) -> void:
	if GameManager.is_playing():
		_distance_label.text = "%d m" % int(GameManager.distance)
		_speed_label.text = "%.1fx" % GameManager.speed_multiplier


func _update_all() -> void:
	_on_score_changed(GameManager.score)
	_on_coins_changed(GameManager.coins)
	_on_high_score_changed(GameManager.high_score)


func _on_score_changed(new_score: int) -> void:
	_score_label.text = GlobalLanguage.tr_key("score") + ": " + str(new_score)


func _on_coins_changed(new_coins: int) -> void:
	_coins_label.text = GlobalLanguage.tr_key("coins") + ": " + str(new_coins)


func _on_high_score_changed(new_high: int) -> void:
	_high_score_label.text = GlobalLanguage.tr_key("high_score") + ": " + str(new_high)


func _on_pause_pressed() -> void:
	GameManager.pause_game()
