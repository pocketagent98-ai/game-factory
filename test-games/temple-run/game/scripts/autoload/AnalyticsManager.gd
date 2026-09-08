extends Node
## AnalyticsManager: Built-in game analytics using HTTPRequest (Autoload)
## Sends events to a backend (Supabase or custom). Zero extra binary size.

signal analytics_sent(event_count: int)
signal analytics_error(error: String)

var _event_queue: Array[Dictionary] = []
var _send_timer: Timer
var _is_sending: bool = false
var _total_events_sent: int = 0
var session_id: String
var player_id: String

const SEND_INTERVAL := 30.0
const MAX_QUEUE_SIZE := 100
const ENDPOINT := ""


func _ready() -> void:
	session_id = str(Time.get_ticks_msec()) + "_" + str(randi() % 100000)
	player_id = "player_" + str(randi() % 1000000)
	_send_timer = Timer.new()
	_send_timer.wait_time = SEND_INTERVAL
	_send_timer.autostart = true
	_send_timer.timeout.connect(_flush_events)
	add_child(_send_timer)
	track_event("session_start", {"session_id": session_id})
	print("[Analytics] Session started: ", session_id)


func track_event(event_name: String, properties: Dictionary = {}) -> void:
	var event := {
		"event": event_name,
		"timestamp": Time.get_unix_time_from_system(),
		"session_id": session_id,
		"player_id": player_id,
		"properties": properties,
	}
	_event_queue.append(event)
	if _event_queue.size() >= MAX_QUEUE_SIZE:
		_flush_events()


func _flush_events() -> void:
	if _event_queue.is_empty() or _is_sending:
		return
	if ENDPOINT == "":
		_total_events_sent += _event_queue.size()
		_event_queue.clear()
		return
	_is_sending = true
	var batch := _event_queue.duplicate()
	_event_queue.clear()
	var http := HTTPRequest.new()
	add_child(http)
	var body := JSON.stringify({"events": batch})
	var headers := PackedStringArray(["Content-Type: application/json"])
	var err := http.request(ENDPOINT, headers, HTTPClient.METHOD_POST, body)
	if err != OK:
		analytics_error.emit("HTTP request failed: " + str(err))
		_is_sending = false
		http.queue_free()
		return
	await http.request_completed
	_total_events_sent += batch.size()
	analytics_sent.emit(batch.size())
	_is_sending = false
	http.queue_free()


func _exit_tree() -> void:
	track_event("session_end", {"duration": GameManager.time_alive})
	_flush_events()


func get_stats() -> Dictionary:
	return {
		"total_events_sent": _total_events_sent,
		"queued_events": _event_queue.size(),
		"session_id": session_id,
		"player_id": player_id,
	}
