extends Node
## GameManager: Central game state controller (Autoload)
## Manages score, high score, game state, speed progression

signal score_changed(new_score: int)
signal high_score_changed(new_high: int)
signal game_started
signal game_over
signal game_paused
signal game_resumed
signal coins_changed(new_coins: int)

enum State { MENU, PLAYING, PAUSED, GAME_OVER }

var state: State = State.MENU
var score: int = 0
var high_score: int = 0
var coins: int = 0
var total_coins: int = 0
var speed_multiplier: float = 1.0
var base_speed: float = 12.0
var distance: float = 0.0
var time_alive: float = 0.0

const SCORE_PER_COIN := 10
const SCORE_PER_DISTANCE := 1
const SPEED_INCREASE_RATE := 0.02
const MAX_SPEED_MULT := 3.0
const HIGH_SCORE_KEY := "endless_dash_high_score"
const TOTAL_COINS_KEY := "endless_dash_total_coins"
const SAVE_PATH := "user://save_data.cfg"


func _ready() -> void:
	high_score = int(SaveSystem.get_value(HIGH_SCORE_KEY, 0))
	total_coins = int(SaveSystem.get_value(TOTAL_COINS_KEY, 0))
	high_score_changed.emit(high_score)


func start_game() -> void:
	state = State.PLAYING
	score = 0
	coins = 0
	speed_multiplier = 1.0
	distance = 0.0
	time_alive = 0.0
	score_changed.emit(0)
	coins_changed.emit(0)
	game_started.emit()
	print("[GameManager] Game started")


func end_game() -> void:
	if state != State.PLAYING:
		return
	state = State.GAME_OVER
	if score > high_score:
		high_score = score
		SaveSystem.set_value(HIGH_SCORE_KEY, high_score)
		high_score_changed.emit(high_score)
		print("[GameManager] NEW HIGH SCORE: ", high_score)
	total_coins += coins
	SaveSystem.set_value(TOTAL_COINS_KEY, total_coins)
	game_over.emit()
	print("[GameManager] Game over. Score: ", score, " Coins: ", coins)


func pause_game() -> void:
	if state == State.PLAYING:
		state = State.PAUSED
		get_tree().paused = true
		game_paused.emit()


func resume_game() -> void:
	if state == State.PAUSED:
		state = State.PLAYING
		get_tree().paused = false
		game_resumed.emit()


func return_to_menu() -> void:
	state = State.MENU
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")


func add_score(amount: int) -> void:
	score += amount
	score_changed.emit(score)


func add_coin(amount: int = 1) -> void:
	coins += amount
	add_score(SCORE_PER_COIN * amount)
	coins_changed.emit(coins)


func get_current_speed() -> float:
	return base_speed * speed_multiplier


func _process(delta: float) -> void:
	if state == State.PLAYING:
		time_alive += delta
		distance += get_current_speed() * delta
		score = int(distance * SCORE_PER_DISTANCE)
		score_changed.emit(score)
		speed_multiplier = min(speed_multiplier + SPEED_INCREASE_RATE * delta, MAX_SPEED_MULT)


func is_playing() -> bool:
	return state == State.PLAYING


class SaveSystem:
	static func get_value(key: String, default: Variant) -> Variant:
		var config := ConfigFile.new()
		var err := config.load(SAVE_PATH)
		if err == OK:
			return config.get_value("game", key, default)
		return default

	static func set_value(key: String, value: Variant) -> void:
		var config := ConfigFile.new()
		config.load(SAVE_PATH)
		config.set_value("game", key, value)
		config.save(SAVE_PATH)
