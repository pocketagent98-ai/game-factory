extends Node
## GlobalLanguage: Multi-language translation manager (Autoload)
## Supports 30+ languages. Loads translations from CSV files at runtime.

var current_language: String = "en"
var available_languages: Array[String] = []
var translations: Dictionary = {}

const DEFAULT_LANG := "en"
const TRANSLATIONS_DIR := "res://translations"
const ALL_LANGUAGES: Array[String] = [
	"en", "hi", "es", "fr", "de", "ar", "zh", "ja", "ko", "pt",
	"ru", "tr", "it", "id", "vi", "th", "fa", "pl", "uk", "nl",
	"sv", "da", "fi", "no", "cs", "sk", "hu", "ro", "bg", "el",
	"he", "bn", "ta", "te", "mr", "ur"
]
const FALLBACK_TRANSLATIONS := {
	"game_title": "Endless Dash", "play": "Play", "settings": "Settings",
	"quit": "Quit", "score": "Score", "high_score": "High Score",
	"game_over": "Game Over", "pause": "Pause", "resume": "Resume",
	"level_complete": "Level Complete!", "loading": "Loading...",
	"tap_to_start": "Tap to Start", "coins": "Coins", "speed": "Speed",
	"new_high_score": "New High Score!", "tap_to_retry": "Tap to Retry",
	"tap_to_restart": "Tap to Restart", "main_menu": "Main Menu",
	"language": "Language", "sound": "Sound", "music": "Music",
	"on": "On", "off": "Off", "distance": "Distance",
	"magnet": "Magnet Active!", "shield": "Shield Active!",
	"speed_boost": "Speed Boost!", "tutorial_swipe": "Swipe to move",
	"tutorial_jump": "Swipe up to jump", "tutorial_slide": "Swipe down to slide",
}


func _ready() -> void:
	var os_lang := OS.get_locale().get_slice("_", 0)
	if os_lang in ALL_LANGUAGES:
		current_language = os_lang
	else:
		current_language = DEFAULT_LANG
	_load_available_languages()
	_load_translations(current_language)
	print("[GlobalLanguage] Language set to: ", current_language)


func set_language(lang_code: String) -> void:
	if lang_code not in ALL_LANGUAGES:
		return
	current_language = lang_code
	_load_translations(lang_code)


func tr_key(key: String) -> String:
	if translations.has(key):
		return translations[key]
	if FALLBACK_TRANSLATIONS.has(key):
		return FALLBACK_TRANSLATIONS[key]
	return key


func _load_available_languages() -> void:
	available_languages = []
	var dir := DirAccess.open(TRANSLATIONS_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".csv"):
				available_languages.append(file_name.get_basename())
			file_name = dir.get_next()
	if available_languages.is_empty():
		available_languages = [DEFAULT_LANG]


func _load_translations(lang_code: String) -> void:
	translations = FALLBACK_TRANSLATIONS.duplicate()
	var file_path := TRANSLATIONS_DIR + "/" + lang_code + ".csv"
	var file := FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return
	while not file.eof_reached():
		var line := file.get_line()
		if line.strip_edges() == "":
			continue
		var parts := _parse_csv_line(line)
		if parts.size() >= 2:
			translations[parts[0]] = parts[1]
	file.close()


func _parse_csv_line(line: String) -> PackedStringArray:
	var result: PackedStringArray = []
	var in_quotes := false
	var current := ""
	for i in range(line.length()):
		var ch := line[i]
		if ch == '"':
			if in_quotes and i + 1 < line.length() and line[i + 1] == '"':
				current += '"'
				continue
			in_quotes = not in_quotes
		elif ch == ',' and not in_quotes:
			result.append(current)
			current = ""
		else:
			current += ch
	if current != "" or result.size() > 0:
		result.append(current)
	return result


func get_language_name(code: String) -> String:
	var names := {
		"en": "English", "hi": "हिन्दी", "es": "Español", "fr": "Français",
		"de": "Deutsch", "ar": "العربية", "zh": "中文", "ja": "日本語",
		"ko": "한국어", "pt": "Português", "ru": "Русский", "tr": "Türkçe",
		"it": "Italiano", "id": "Indonesia", "vi": "Tiếng Việt", "th": "ไทย",
		"fa": "فارسی", "pl": "Polski", "uk": "Українська", "nl": "Nederlands",
		"sv": "Svenska", "da": "Dansk", "fi": "Suomi", "no": "Norsk",
		"cs": "Čeština", "sk": "Slovenčina", "hu": "Magyar", "ro": "Română",
		"bg": "Български", "el": "Ελληνικά", "he": "עברית", "bn": "বাংলা",
		"ta": "தமிழ்", "te": "తెలుగు", "mr": "मराठी", "ur": "اردو",
	}
	return names.get(code, code)
