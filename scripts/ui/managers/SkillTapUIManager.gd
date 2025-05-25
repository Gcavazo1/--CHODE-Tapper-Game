extends Node

# Manages the SkillTapMeter UI and Giga Slap related UI feedback.

# --- Dependencies (injected by MainLayout) ---
var skill_tap_meter_node # The SkillTapMeter scene instance
var effects_manager # Instance of EffectsManager
var tapper_area_node # Instance of TapperArea for positioning

# Sound effects
var sfx_player: AudioStreamPlayer
const MEGA_SLAP_SFX = preload("res://assets/audio/sfx/megaSlap.wav")

# --- Initialization ---
func initialize_manager(meter_node, fx_manager, tap_area):
	skill_tap_meter_node = meter_node
	effects_manager = fx_manager
	tapper_area_node = tap_area

	if not is_instance_valid(skill_tap_meter_node):
		push_error("SkillTapUIManager: SkillTapMeter node is invalid!")
	if not is_instance_valid(effects_manager):
		push_error("SkillTapUIManager: EffectsManager is invalid!")
	if not is_instance_valid(tapper_area_node):
		push_error("SkillTapUIManager: TapperArea node is invalid!")
	
	# Setup sound player
	sfx_player = AudioStreamPlayer.new()
	sfx_player.stream = MEGA_SLAP_SFX
	sfx_player.volume_db = 2.0  # Make it slightly louder than normal
	add_child(sfx_player)
	
	print("SkillTapUIManager: Initialized.")

# --- Core UI Logic ---

# Shows the SkillTapMeter and starts its minigame.
func _on_giga_slap_attempt_ready():
	if is_instance_valid(skill_tap_meter_node) and skill_tap_meter_node.has_method("show_and_start"):
		print("SkillTapUIManager: Giga Slap attempt ready, showing SkillTapMeter.")
		skill_tap_meter_node.show_and_start()
	else:
		push_error("SkillTapUIManager: SkillTapMeter node not set or lacks show_and_start method.")

# Called by TapperArea when the player taps during an active Giga Slap minigame.
func evaluate_player_tap():
	if not is_instance_valid(skill_tap_meter_node):
		push_error("SkillTapUIManager: evaluate_player_tap called but skill_tap_meter_node is invalid!")
		_on_giga_slap_failure(false) # Treat as failure if meter isn't there
		return

	# Assuming SkillTapMeter.gd has is_active property and check_current_tap_success method
	if not skill_tap_meter_node.get("is_active"): # Check if the meter considers itself active for evaluation
		print("SkillTapUIManager: evaluate_player_tap called but SkillTapMeter is not active. Tap ignored or minigame already concluded.")
		# Potentially do nothing, or count as a miss if strict
		# For now, let's assume if it's not active, the window was missed or it was already handled.
		# If it needs to be a failure, call _on_giga_slap_failure(false)
		return

	if skill_tap_meter_node.has_method("check_current_tap_success"):
		var success = skill_tap_meter_node.check_current_tap_success() # This method should exist on SkillTapMeter.gd
		print("SkillTapUIManager: Tap evaluated by SkillTapMeter. Success: %s" % success)
		if success:
			_on_giga_slap_success()
		else:
			_on_giga_slap_failure(false) # false because it wasn't a timeout, it was a missed tap
	else:
		push_error("SkillTapUIManager: SkillTapMeter node is missing the check_current_tap_success() method.")
		_on_giga_slap_failure(false) # Treat as failure if method is missing

# Handles UI and game logic for a successful Giga Slap.
func _on_giga_slap_success():
	print("SkillTapUIManager: Giga Slap success! Processing...")
	
	# Play the mega slap sound with a higher pitch for success
	if sfx_player:
		sfx_player.pitch_scale = 1.2  # Higher pitch for success
		sfx_player.play()
	
	Global.increment_girth(Global.GIGA_SLAP_MULTIPLIER, true)
	Global.update_charge() # Reset charge or apply giga-specific charge logic

	if is_instance_valid(effects_manager) and is_instance_valid(tapper_area_node):
		var base_pos = tapper_area_node.global_position
		effects_manager._on_floating_number_requested("GIGA SLAP!", base_pos - Vector2(0,60), 2.0, Color.GOLD, 1.5)
		effects_manager._on_floating_number_requested("+" + str(Global.GIRTH_PER_TAP * Global.GIGA_SLAP_MULTIPLIER), base_pos - Vector2(0,20), 2.0, Color.GREEN, 1.2)
	else:
		push_warning("SkillTapUIManager: EffectsManager or TapperArea not available for Giga Slap success feedback.")

# Handles UI and game logic for a failed Giga Slap.
func _on_giga_slap_failure(timed_out: bool):
	print("SkillTapUIManager: Giga Slap failed. Timed out: %s" % timed_out)
	
	# Play the sound with a different pitch based on fail type
	if sfx_player:
		if timed_out:
			sfx_player.pitch_scale = 0.7  # Lower pitch for timeout
		else:
			sfx_player.pitch_scale = 0.9  # Slightly lower pitch for miss
		sfx_player.play()
	
	var msg = ""
	var detail_msg = ""

	if timed_out:
		Global.giga_slap_timed_out() # Penalize for timeout
		msg = "TOO SLOW!"
		detail_msg = "CHARGE LOST!"
	else: 
		# Failed the minigame but didn't time out (e.g., missed the target)
		# For now, treat as a normal Mega Slap as per original MainLayout logic
		print("SkillTapUIManager: Giga Slap missed. Performing normal Mega Slap.")
		Global.increment_girth(Global.MEGA_SLAP_MULTIPLIER, false) # 'false' for not a giga slap
		Global.update_charge() # Update charge as if it was a mega slap
		msg = "MISS! (Mega Slap)"
		detail_msg = "+" + str(Global.GIRTH_PER_TAP * Global.MEGA_SLAP_MULTIPLIER)

	if is_instance_valid(effects_manager) and is_instance_valid(tapper_area_node):
		var base_pos = tapper_area_node.global_position
		effects_manager._on_floating_number_requested(msg, base_pos - Vector2(0,60), 2.0, Color.RED, 1.3)
		if not detail_msg.is_empty():
			effects_manager._on_floating_number_requested(detail_msg, base_pos- Vector2(0,20), 2.0, Color.ORANGE, 1.1)
	else:
		push_warning("SkillTapUIManager: EffectsManager or TapperArea not available for Giga Slap failure feedback.")

# --- Getter (If needed by other systems, though direct calls are discouraged) ---
func get_skill_tap_meter_node():
	return skill_tap_meter_node 