extends SceneTree

func _init():
	print("=== ENDLESS DASH RUNTIME TEST ===")
	print("Loading Main scene...")
	var scene = load("res://scenes/Main.tscn")
	if scene == null:
		print("FAIL: Could not load Main.tscn")
		quit(1)
		return
	print("OK: Main.tscn loaded successfully")
	
	var instance = scene.instantiate()
	if instance == null:
		print("FAIL: Could not instantiate Main scene")
		quit(1)
		return
	print("OK: Main scene instantiated")
	
	root.add_child(instance)
	
	var player = instance.get_node_or_null("Player")
	if player:
		print("OK: Player node found (type: %s)" % player.get_class())
	else:
		print("FAIL: Player node not found")
	
	var camera = instance.get_node_or_null("Camera3D")
	if camera:
		print("OK: Camera3D node found")
	else:
		print("FAIL: Camera3D not found")
	
	var track = instance.get_node_or_null("TrackGenerator")
	if track:
		print("OK: TrackGenerator node found")
	else:
		print("FAIL: TrackGenerator not found")
	
	var hud = instance.get_node_or_null("HUD")
	if hud:
		print("OK: HUD node found")
	else:
		print("FAIL: HUD not found")
	
	var menu = instance.get_node_or_null("MainMenu")
	if menu:
		print("OK: MainMenu node found")
	else:
		print("FAIL: MainMenu not found")
	
	print("")
	print("Checking autoloads...")
	var gm = Engine.get_main_loop().get_node_or_null("GameManager")
	if gm:
		print("OK: GameManager autoload active")
	else:
		print("FAIL: GameManager autoload not found")
	
	var gl = Engine.get_main_loop().get_node_or_null("GlobalLanguage")
	if gl:
		print("OK: GlobalLanguage autoload active")
		print("  Current language: ", gl.current_language)
		print("  tr('play') = ", gl.tr_key("play"))
	else:
		print("FAIL: GlobalLanguage autoload not found")
	
	var am = Engine.get_main_loop().get_node_or_null("AnalyticsManager")
	if am:
		print("OK: AnalyticsManager autoload active")
	else:
		print("FAIL: AnalyticsManager autoload not found")
	
	print("")
	print("Testing GameManager...")
	gm.start_game()
	print("  State after start: %d (should be 1=PLAYING)" % gm.state)
	print("  Score: %d" % gm.score)
	print("  Speed: %.1f" % gm.get_current_speed())
	gm.add_coin(5)
	print("  Coins after +5: %d" % gm.coins)
	gm.end_game()
	print("  State after end: %d (should be 3=GAME_OVER)" % gm.state)
	
	print("")
	print("=== ALL TESTS PASSED ===")
	quit(0)
