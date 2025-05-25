extends Control

signal giga_slap_success
signal giga_slap_failure(timed_out: bool)

@onready var bar_background: Panel = $BarBackground
@onready var sweet_spot: Panel = $BarBackground/SweetSpot
@onready var slider: Panel = $BarBackground/Slider
@onready var click_area: Button = $ClickArea
@onready var slider_move_timer: Timer = $SliderMoveTimer
@onready var timeout_timer: Timer = $TimeoutTimer

# Gameplay parameters (can be tweaked)
var slider_speed: float = 350.0  # Increased from 200.0 - Pixels per second
var current_slider_direction: int = 1 # 1 for right, -1 for left
var sweet_spot_width_percentage: float = 0.15 
var max_bounces: int = 10 # Reduced from 15 - How many times the slider bounces before auto-failing if no click
var current_bounces: int = 0

var is_active: bool = false

# Achievement tracking
var last_second_threshold: float = 0.5 # If less than this amount of time left, it's a "last second" hit

# Sound effects are now handled by SkillTapUIManager
# Removed: const MEGA_SLAP_SFX = preload("res://assets/audio/sfx/megaSlap.wav")
# Removed: @onready var sfx_player: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready():
	# Sound player has been moved to SkillTapUIManager
	# Removed: add_child(sfx_player)
	# Removed: sfx_player.stream = MEGA_SLAP_SFX

	if click_area:
		click_area.pressed.connect(_on_click_area_pressed)
	else:
		push_error("SkillTapMeter: ClickArea not found!")
		
	if slider_move_timer:
		slider_move_timer.timeout.connect(_on_slider_move_timer_timeout)
	else:
		push_error("SkillTapMeter: SliderMoveTimer not found!")
		
	if timeout_timer:
		timeout_timer.timeout.connect(_on_timeout_timer_timeout)
	else:
		push_error("SkillTapMeter: TimeoutTimer not found!")
		
	hide() # Start hidden
	
	# Verify node references
	if !sweet_spot or !slider or !bar_background:
		push_error("SkillTapMeter: One or more required nodes not found!")

func start_minigame():
	print("SkillTapMeter: Starting minigame")
	if Global:
		Global.is_giga_slap_minigame_active = true
	is_active = true
	visible = true
	current_bounces = 0

	# Reset slider position (e.g., to the left)
	if slider:
		slider.position.x = 0
	current_slider_direction = 1
	
	# Adjust SweetSpot size and position dynamically based on BarBackground width
	if bar_background and sweet_spot:
		var bar_width = bar_background.size.x
		sweet_spot.size.x = bar_width * sweet_spot_width_percentage
		# Center the sweet spot (can be randomized later if desired)
		sweet_spot.position.x = (bar_width / 2.0) - (sweet_spot.size.x / 2.0)

	# Make sure timers have valid values before starting
	if slider_move_timer:
		if slider_move_timer.wait_time <= 0:
			slider_move_timer.wait_time = 0.016
		slider_move_timer.start()
		
	if timeout_timer:
		timeout_timer.wait_time = 5.0 # Set timeout to 5 seconds
		timeout_timer.start()

func _on_slider_move_timer_timeout():
	if not is_active: 
		return
		
	if !slider or !bar_background:
		push_error("SkillTapMeter: Required nodes missing during timer tick")
		return

	var delta = slider_move_timer.wait_time
	slider.position.x += slider_speed * current_slider_direction * delta

	# Check for bounce
	var bar_width = bar_background.size.x
	var slider_width = slider.size.x

	if slider.position.x + slider_width >= bar_width:
		slider.position.x = bar_width - slider_width # Clamp to edge
		current_slider_direction = -1
		current_bounces += 1
		# print("Slider bounced right. Bounces: ", current_bounces)
	elif slider.position.x <= 0:
		slider.position.x = 0 # Clamp to edge
		current_slider_direction = 1
		current_bounces += 1
		# print("Slider bounced left. Bounces: ", current_bounces)

	if current_bounces > max_bounces:
		_fail_minigame(true) # Timed out due to too many bounces

func _on_click_area_pressed():
	print("SkillTapMeter: ClickArea button pressed!") # DEBUG
	handle_skill_tap()

func handle_skill_tap():
	print("!!!!!!!!!!!!!!!!! SKILLTAPMETER: handle_skill_tap() WAS CALLED !!!!!!!!!!!!!!!!!") # DEBUG
	if not is_active: 
		print("SkillTapMeter DEBUG: handle_skill_tap called but is_active is FALSE.")
		return
	
	if !slider or !sweet_spot:
		push_error("SkillTapMeter: Required nodes missing during skill tap handling")
		return

	# Note: We no longer play sounds here - SkillTapUIManager handles that now
	# sfx_player.play() <- This line is removed
	
	# Use the check_current_tap_success() method to determine success
	# (Note: check_current_tap_success already calls _cleanup())
	var success = check_current_tap_success()
		
	# We've already set is_active = false in check_current_tap_success()
	
	if success:
		emit_signal("giga_slap_success")
	else:
		emit_signal("giga_slap_failure", false)
	
	# Removed redundant _cleanup() call here, as check_current_tap_success() already calls it

func _on_timeout_timer_timeout():
	_fail_minigame(true)

func _fail_minigame(timed_out: bool):
	if not is_active: return
	print("SkillTapMeter: Minigame FAILED. Timed out: ", timed_out)
	
	# Sound is now handled by SkillTapUIManager
	# Removed: if sfx_player and not sfx_player.playing:
	# Removed:    sfx_player.pitch_scale = 0.8 # Slightly lower pitch for fail/timeout
	# Removed:    sfx_player.play()
	# Removed:    await sfx_player.finished
	# Removed:    sfx_player.pitch_scale = 1.0

	emit_signal("giga_slap_failure", timed_out)
	_cleanup()

func _cleanup():
	if Global:
		Global.is_giga_slap_minigame_active = false
	is_active = false
	visible = false
	slider_move_timer.stop()
	timeout_timer.stop()
	# Consider queue_free() if this is always instantiated on demand
	# For now, just hide it for reuse.

# Placeholder for visual updates
func _update_visuals():
	# This will be called to style the meter based on ChargeMeter.tscn
	# e.g., copy StyleBox resources for BarBackground, SweetSpot, Slider
	pass

# Call this method when the ChargeMeter signals mega_slap_ready
# and Global confirms it's time for the Skill Tap game.
func show_and_start():
	# Potentially re-initialize or reset state if it's reused
	# For now, start_minigame handles basic reset.
	# _update_visuals() # Apply styling
	start_minigame() 

# Called to check if the current tap would be successful.
# This is used by SkillTapUIManager.evaluate_player_tap() to determine 
# Giga Slap success/failure when tapping on TapperArea while the minigame is active.
func check_current_tap_success() -> bool:
	if not is_active:
		print("SkillTapMeter: check_current_tap_success called but not active.")
		return false
	
	if !slider or !sweet_spot:
		push_error("SkillTapMeter: Required nodes missing during check_current_tap_success")
		return false

	# Check if slider is within sweet_spot
	var slider_center = slider.position.x + (slider.size.x / 2.0)
	var sweet_spot_left = sweet_spot.position.x
	var sweet_spot_right = sweet_spot.position.x + sweet_spot.size.x
	
	# Calculate precision (0.0 to 1.0) based on how close to center
	var sweet_spot_center = sweet_spot.position.x + (sweet_spot.size.x / 2.0)
	var distance_from_center = abs(slider_center - sweet_spot_center)
	var max_distance = sweet_spot.size.x / 2.0
	var precision = 1.0 - (distance_from_center / max_distance)
	precision = clamp(precision, 0.0, 1.0)
	
	# A bit of tolerance
	var tolerance = 2.0
	var success = slider_center >= sweet_spot_left - tolerance and slider_center <= sweet_spot_right + tolerance
	
	if success:
		print("SkillTapMeter: check_current_tap_success - TAP SUCCESSFUL! Precision: ", precision)
		# Report precision to Global for achievement tracking
		if Global:
			Global.report_g_spot_precision(precision)
			
		# Check for last second hit achievement
		var time_left = timeout_timer.time_left
		var is_last_second = time_left <= last_second_threshold
		if is_last_second and Global:
			AchievementManager.unlock_achievement("last_second_g_spot")
	else:
		print("SkillTapMeter: check_current_tap_success - Tap MISSED.")
	
	# Call _cleanup() instead of just setting is_active = false
	# This properly resets Global.is_giga_slap_minigame_active and other state
	_cleanup()
	
	return success
 
