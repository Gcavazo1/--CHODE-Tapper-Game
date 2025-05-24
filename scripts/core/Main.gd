extends Node2D

# Script for the Main scene node

var _original_position: Vector2
var _shake_timer: Timer
var _current_shake_amplitude: float = 0.0

# Reference to the MainLayout instance
var main_layout = null

# Screen shake constants
const DEFAULT_SHAKE_AMPLITUDE: float = 1.5 # Default subtle shake
const SHAKE_DURATION: float = 0.1 # Short duration
const INITIAL_HINT_DELAY: float = 2.0 # Seconds to wait before showing initial hint

# IMPORTANT FIXES TO IMPLEMENT IN GODOT EDITOR:
# 1. The AnimationPlayer in TapperArea.tscn needs animations created/fixed
#    - Select TapperArea scene, open AnimationPlayer, create "squash_stretch" animation
#    - Add Scale track on TapperArea node with keyframes:
#      - 0.0s: (1.0, 1.0)
#      - 0.1s: (1.1, 0.9)
#      - 0.2s: (1.0, 1.0)
# 2. Double Chode Image - In TapperArea.tscn, ensure only one sprite is visible at a time
#    - Set AnimatedSprite2D to play "tier_0_idle" by default
#    - Check visibility settings on all sprite nodes
# 3. For large particles - In TapperArea.tscn, adjust the CPUParticles2D:
#    - Reduce scale_amount_min and scale_amount_max (try 0.1-0.3)
#    - Decrease amount of particles (try 5-10)
# 4. For background - In Main.tscn, ensure TextureRect dimensions match viewport:
#    - Set size to cover entire screen
#    - Set layout mode to "Full Rect"
#    - Set texture to dystopian_alley_bg.png

func _ready():
	_original_position = global_position
	
	_shake_timer = Timer.new()
	_shake_timer.wait_time = SHAKE_DURATION
	_shake_timer.one_shot = true
	_shake_timer.timeout.connect(_on_shake_timer_timeout)
	add_child(_shake_timer)
	print("Main.gd ready. Screen shake system initialized.")
	
	main_layout = $MainLayoutInstance
	if main_layout:
		print("MainLayout found, setting up connections...")
		
		if Global:
			main_layout.update_girth_counter(Global.current_girth)
			Global.girth_updated.connect(_on_girth_updated)
			Global.achievement_unlocked.connect(_on_achievement_unlocked)
	else:
		print("ERROR: MainLayout not found")
	
	await get_tree().create_timer(INITIAL_HINT_DELAY).timeout
	_show_initial_hint()

func _on_girth_updated(new_girth):
	if main_layout:
		main_layout.update_girth_counter(new_girth)

func _on_achievement_unlocked(achievement_name, achievement_description, duration = 3.0):
	if main_layout:
		main_layout.show_achievement(achievement_name, achievement_description, duration)

func _show_initial_hint():
	if Global:
		Global.achievement_unlocked.emit(
			"WELCOME TO $CHODE TAPPER", 
			"TAP YOUR $CHODE TO INCREASE $GIRTH!\nREACH 100 $GIRTH TO EVOLVE!",
			5.0
		)

func _process(delta):
	if _current_shake_amplitude > 0:
		global_position = _original_position + Vector2(
			randf_range(-_current_shake_amplitude, _current_shake_amplitude),
			randf_range(-_current_shake_amplitude, _current_shake_amplitude)
		)
		_current_shake_amplitude = max(0, _current_shake_amplitude - delta * 30.0)
		
		if _current_shake_amplitude <= 0:
			global_position = _original_position

# Simple screen shake function
func execute_screen_shake(amplitude: float = DEFAULT_SHAKE_AMPLITUDE, duration: float = SHAKE_DURATION):
	_current_shake_amplitude = amplitude
	_shake_timer.stop()
	_shake_timer.wait_time = duration
	_shake_timer.start()

func _on_shake_timer_timeout():
	var tween = create_tween()
	tween.tween_property(self, "_current_shake_amplitude", 0.0, 0.1)
	tween.tween_callback(func(): global_position = _original_position)

# Note: The girthquake signal connection has been removed to simplify the code
# Screen shake can still be triggered manually by calling execute_screen_shake() if needed 
