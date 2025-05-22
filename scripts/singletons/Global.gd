extends Node

# Signal to notify other nodes (like the HUD) when the Girth count changes.
signal girth_updated(new_girth)

# Signal for when an achievement is unlocked (simulated for the demo).
signal achievement_unlocked(achievement_name, achievement_description, duration)

# Signals for the Mighty Mega Slap mechanic
signal charge_updated(current_charge, max_charge)
signal mega_slap_ready # Player has enough charge
signal mega_slap_delivered # A mega slap (normal or giga) was performed
signal giga_slap_attempt_ready # It's time to show the SkillTapMeter
signal giga_slap_charge_lost # Player failed SkillTapMeter by timeout, charge is lost

# New signals for refactory period
signal refactory_period_started
signal refactory_period_ended

# The current amount of $GIRTH the player has accumulated.
var current_girth: int = 0

# This will be incremented with each tap in the demo.
const GIRTH_PER_TAP: int = 1

# Mighty Mega Slap variables
var current_charge: float = 0.0
var max_charge: float = 100.0
var charge_per_tap: float = 5.0  # Reduced from 10.0 to make it harder (20 taps to fill)
var is_mega_slap_primed: bool = false
const MEGA_SLAP_MULTIPLIER: int = 10  # 10x normal tap worth for an epic Mega Slap
var can_attempt_giga_slap: bool = false # Flag to indicate SkillTapMeter should be shown
const GIGA_SLAP_MULTIPLIER: int = 25 # e.g., 25x normal tap

# Refactory period variables
var refactory_timer: Timer
var is_in_refactory_period: bool = false
var refactory_decay_rate: float = 15.0  # How much charge is lost per second during refactory
var constant_decay_rate: float = 2.5    # NEW: Constant decay rate always active
var refactory_delay: float = 2.0  # Seconds of inactivity before decay starts
var last_tap_time: int = 0
var refactory_periods_overcome: int = 0

# Achievement tracking for Mega Slaps
var total_mega_slaps: int = 0
var mega_slap_girth_earned: int = 0
var mega_slap_achievements_unlocked = []

# Achievement tracking for GigaSlaps and G-spot
var total_giga_slaps: int = 0
var giga_slap_girth_earned: int = 0
var current_giga_slap_streak: int = 0
var highest_giga_slap_streak: int = 0
var giga_slap_miss_count: int = 0
var last_giga_slap_time: int = 0
var giga_slaps_in_time_window: int = 0
var giga_slap_time_window: int = 30000 # 30 seconds in milliseconds

# Flag to indicate if the Giga Slap minigame is currently active
var is_giga_slap_minigame_active: bool = false


# Called when the node enters the scene tree for the first time.
func _ready():
	print("Global.gd is ready. Current Girth: ", current_girth)
	print("Mighty Mega Slap system initialized.")
	
	# Setup refactory timer
	refactory_timer = Timer.new()
	refactory_timer.wait_time = refactory_delay
	refactory_timer.one_shot = true
	refactory_timer.timeout.connect(_on_refactory_timer_timeout)
	add_child(refactory_timer)
	
	# Track process for decay
	set_process(true)
	
	# Connect to AchievementManager if it's ready
	await get_tree().process_frame  # Wait for AchievementManager to be ready
	if AchievementManager.get_instance():
		AchievementManager.get_instance().achievement_unlocked.connect(_on_achievement_manager_achievement_unlocked)


func _process(delta):
	# Always apply a constant decay pressure to the charge
	if current_charge > 0 and !is_mega_slap_primed:
		# Apply constant decay regardless of refactory period
		var decay_amount = constant_decay_rate * delta
		
		# Apply additional decay during refactory period
		if is_in_refactory_period:
			decay_amount += refactory_decay_rate * delta
		
		# Apply the decay
		current_charge = max(0, current_charge - decay_amount)
		emit_signal("charge_updated", current_charge, max_charge)
		
		# Check if we've fully depleted
		if current_charge <= 0 and is_in_refactory_period:
			is_in_refactory_period = false
			emit_signal("refactory_period_ended")
	
	# Update giga slap time window tracking
	var current_time = Time.get_ticks_msec()
	if current_time - last_giga_slap_time > giga_slap_time_window:
		# Reset the count if the window has passed
		giga_slaps_in_time_window = 0


# Function to be called when the player taps the Chode.
func increment_girth(girth_multiplier: int = 1, is_giga_slap: bool = false):
	var girth_gain = GIRTH_PER_TAP * girth_multiplier
	
	# Reset refactory period on any tap - we're actively using it!
	# If we were in refactory period and ended it through tapping, track that achievement
	if is_in_refactory_period:
		refactory_periods_overcome += 1
		_check_refactory_achievements()
		
	_reset_refactory_period()
	
	# mega_slap signal is now generic for any charged slap
	emit_signal("mega_slap_delivered")
	
	if is_giga_slap:
		print("💥💥💥 GIGA G-SPOT SLAP!!! 💥💥💥 Girth +" + str(girth_gain) + "!")
		# Track GigaSlap stats
		total_giga_slaps += 1
		giga_slap_girth_earned += girth_gain
		current_giga_slap_streak += 1
		highest_giga_slap_streak = max(highest_giga_slap_streak, current_giga_slap_streak)
		
		# Update time tracking for marathon achievement
		var current_time = Time.get_ticks_msec()
		if current_time - last_giga_slap_time <= giga_slap_time_window:
			giga_slaps_in_time_window += 1
		else:
			giga_slaps_in_time_window = 1
		last_giga_slap_time = current_time
		
		# Check GigaSlap achievements
		_check_giga_slap_achievements()
		
	elif girth_multiplier > 1: # It's a normal Mega Slap
		print("⚡⚡⚡ MIGHTY MEGA SLAP! ⚡⚡⚡ Girth +" + str(girth_gain) + "!")
		# Track Mega Slap stats
		total_mega_slaps += 1
		mega_slap_girth_earned += girth_gain
		
		# Reset GigaSlap streak if this was a missed G-spot attempt
		if is_giga_slap_minigame_active:
			current_giga_slap_streak = 0
			giga_slap_miss_count += 1
		
		_check_mega_slap_achievements()
	
	current_girth += girth_gain
	emit_signal("girth_updated", current_girth)
	
	if girth_multiplier == 1: # Normal tap
		print("Girth incremented! New Girth: ", current_girth)

	# Check milestone achievements based on girth
	_check_girth_achievements()


# Update the charge meter with each tap
func update_charge():
	# Reset refactory timer since there was activity
	_reset_refactory_period()
	
	if is_mega_slap_primed:
		# Reset after a Mega Slap
		current_charge = 0
		is_mega_slap_primed = false
	else:
		# Increment charge and check if fully charged
		# NOTE: We're still incrementing by charge_per_tap, but the constant decay
		# in _process will counteract this slightly, making it a battle to fill the meter
		current_charge = min(current_charge + charge_per_tap, max_charge)
		
		if current_charge >= max_charge and not is_mega_slap_primed:
			is_mega_slap_primed = true
			can_attempt_giga_slap = true # Player is now eligible for a Giga Slap attempt
			emit_signal("mega_slap_ready")
			# Don't immediately emit giga_slap_attempt_ready here.
			# Let the TapperArea decide when to trigger it (e.g., on the *next* tap after ready)
			print("⚡ MIGHTY MEGA SLAP READY! Potential Giga Slap... ⚡")
	
	emit_signal("charge_updated", current_charge, max_charge)


# Reset and restart the refactory timer
func _reset_refactory_period():
	# If we were in a refactory period, signal that it's ended
	if is_in_refactory_period:
		is_in_refactory_period = false
		emit_signal("refactory_period_ended")
	
	# Reset and start the timer
	last_tap_time = Time.get_ticks_msec()
	refactory_timer.stop()
	refactory_timer.start()


# Called when the refactory timer times out (no taps for a while)
func _on_refactory_timer_timeout():
	# Only enter refactory period if not already in one and there's charge to decay
	if !is_in_refactory_period and current_charge > 0 and !is_mega_slap_primed:
		is_in_refactory_period = true
		print("Entering refactory period - charge decaying!")
		emit_signal("refactory_period_started")


# Check for refactory period achievements
func _check_refactory_achievements():
	# First refactory period overcome
	if refactory_periods_overcome == 1:
		AchievementManager.unlock_achievement("first_refactory_overcome")
	
	# 5 refactory periods overcome
	if refactory_periods_overcome == 5:
		AchievementManager.unlock_achievement("refactory_master")
	
	# 10 refactory periods overcome
	if refactory_periods_overcome == 10:
		AchievementManager.unlock_achievement("refactory_legend")


# Check for Mega Slap achievements
func _check_mega_slap_achievements():
	# First Mega Slap
	if total_mega_slaps == 1:
		AchievementManager.unlock_achievement("first_mega_slap")
	
	# 5 Mega Slaps
	if total_mega_slaps == 5:
		AchievementManager.unlock_achievement("five_mega_slaps")
	
	# 10 Mega Slaps
	if total_mega_slaps == 10:
		AchievementManager.unlock_achievement("ten_mega_slaps")
	
	# 100 Girth from Mega Slaps
	if mega_slap_girth_earned >= 100:
		AchievementManager.unlock_achievement("mega_slap_girth_100")


# Check for GigaSlap and G-spot achievements
func _check_giga_slap_achievements():
	# First GigaSlap
	if total_giga_slaps == 1:
		AchievementManager.unlock_achievement("first_giga_slap")
	
	# Total GigaSlaps milestones
	if total_giga_slaps == 10:
		AchievementManager.unlock_achievement("giga_slap_10")
	
	if total_giga_slaps == 50:
		AchievementManager.unlock_achievement("giga_slap_50")
	
	# Streak achievements
	if current_giga_slap_streak == 3:
		AchievementManager.unlock_achievement("giga_slap_streak_3")
	
	if current_giga_slap_streak == 5:
		AchievementManager.unlock_achievement("giga_slap_streak_5")
	
	if current_giga_slap_streak == 10:
		AchievementManager.unlock_achievement("giga_slap_streak_10")
	
	# Girth earned from GigaSlaps
	if giga_slap_girth_earned >= 500:
		AchievementManager.unlock_achievement("g_spot_girth_500")
	
	# Clutch achievement - hitting G-spot when charge is nearly gone
	if current_charge / max_charge <= 0.05 and not is_in_refactory_period:
		AchievementManager.unlock_achievement("giga_slap_clutch")
	
	# Marathon achievement - 5 GigaSlaps in 30 seconds
	if giga_slaps_in_time_window >= 5:
		AchievementManager.unlock_achievement("giga_slap_marathon")


# Check for milestone girth achievements
func _check_girth_achievements():
	# Genesis tap achievement
	if current_girth >= 10:
		AchievementManager.unlock_achievement("genesis_tap")
	
	# Milestone achievements
	if current_girth >= 50:
		AchievementManager.unlock_achievement("girth_50")
	
	if current_girth >= 100:
		AchievementManager.unlock_achievement("girth_100")
	
	if current_girth >= 150:
		AchievementManager.unlock_achievement("girth_150")
	
	if current_girth >= 250:
		AchievementManager.unlock_achievement("girth_250")
	
	if current_girth >= 500:
		AchievementManager.unlock_achievement("girth_500")
	
	if current_girth >= 1000:
		AchievementManager.unlock_achievement("girth_1000")
	
	# Evolution achievements
	if current_girth >= 300: # First evolution threshold
		AchievementManager.unlock_achievement("first_evolution")
	
	if current_girth >= 1500: # Ultimate evolution threshold
		AchievementManager.unlock_achievement("ultimate_evolution")


# Called when AchievementManager unlocks an achievement, forward to legacy system
func _on_achievement_manager_achievement_unlocked(achievement):
	# Forward the achievement to legacy achievement_unlocked signal for HUD display
	emit_signal("achievement_unlocked", achievement.title, achievement.description, 3.0)


# Called by TapperArea when player taps and a Giga Slap can be attempted
func attempt_giga_slap_minigame():
	if is_mega_slap_primed and can_attempt_giga_slap:
		print("Global: Triggering Giga Slap minigame attempt.")
		can_attempt_giga_slap = false # Consume the immediate eligibility
		is_giga_slap_minigame_active = true # Minigame is now active
		emit_signal("giga_slap_attempt_ready")
		return true
	return false

# Called when Giga Slap minigame is failed due to timeout
func giga_slap_timed_out():
	print("Global: Giga Slap timed out. Charge lost.")
	current_charge = 0
	is_mega_slap_primed = false
	can_attempt_giga_slap = false
	is_giga_slap_minigame_active = false
	current_giga_slap_streak = 0 # Reset streak on timeout
	emit_signal("charge_updated", current_charge, max_charge)
	emit_signal("giga_slap_charge_lost")


# Report precision of G-spot hit (0.0 to 1.0, with 1.0 being perfect center)
func report_g_spot_precision(precision: float):
	# Check for perfect hit achievement
	if precision >= 0.95:
		AchievementManager.unlock_achievement("perfect_g_spot")
	
	# Check for last-second hit achievement
	# This would need to be called from SkillTapMeter when close to timeout
	
	# Reset minigame active flag after reporting
	is_giga_slap_minigame_active = false


# Placeholder for future functions, like spending Girth or handling upgrades.
# func spend_girth(amount: int):
# if current_girth >= amount:
# current_girth -= amount
# emit_signal("girth_updated", current_girth)
# return true
# else:
# return false

# func get_girth() -> int:
# return current_girth 
