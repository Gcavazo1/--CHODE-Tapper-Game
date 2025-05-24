extends Node2D

# This script will be attached to the TapperArea scene (now a Node2D).
# The tappable interaction has been decoupled to a child TextureButton.

# References to child nodes
@onready var click_button: TextureButton = $ChodeClickZone
@onready var animated_sprite: AnimatedSprite2D = $AnimatedChode
@onready var tap_particles: GPUParticles2D = $TapParticles
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var tap_sfx_player: AudioStreamPlayer2D = $TapSFXPlayer
@onready var mega_slap_sfx_player: AudioStreamPlayer2D = $MegaSlapSFXPlayer

# Signals for UI interactions
signal floating_number_requested(value, position)
signal achievement_unlocked(title, description, duration)

# Preload sound effects
const MEGA_SLAP_SFX = preload("res://assets/audio/sfx/megaSlap.wav")
const NORMAL_TAP_SFX = preload("res://assets/audio/sfx/synth_bloop_01.wav")

# Evolution thresholds
const VEINOUS_VERIDIAN_THRESHOLD: int = 300 # Girth needed for first evolution (was 100)
const CRACKED_CORE_THRESHOLD: int = 1500 # Girth needed for the ultimate evolution (was 300)

# Evolution tracking
var _tier1_unlocked: bool = false
var _tier2_unlocked: bool = false

# Constants for celebration effects
const EVOLUTION_PARTICLE_COUNT: int = 100  # Base particle count for evolutions
const EVOLUTION_SCALE_FACTOR: float = 2.0  # For scaling animation during evolution
const EVOLUTION_CELEBRATORY_GIRTH_BONUS: int = 20 # Base bonus girth for evolving
const ULTIMATE_EVOLUTION_MULTIPLIER: float = 1.5 # For more epic final evolution

# Milestone feedback thresholds (to keep players engaged on the path to evolution)
const MILESTONE_THRESHOLDS = [50, 100, 150, 200, 250, 500, 750, 1000, 1250]
var _reached_milestones = []

func _ready():
	# Connect the button's pressed signal
	# Removed the redundant connection:
	# if click_button:
	# 	click_button.pressed.connect(_on_pressed) 
	# else:
	# 	push_error("ChodeClickZone button not found in TapperArea")
	# Ensure the button is actually found, the error push is still useful
	if not click_button:
		push_error("ChodeClickZone button not found in TapperArea. Check scene setup.")
	
	# Set pivot offset to the center of the button for correct scaling animation
	await get_tree().process_frame # Wait a frame to ensure size is calculated
	
	if click_button:
		# For button scaling animations
		click_button.pivot_offset = click_button.size / 2.0
	
	# Make the neon light reflection invisible except for shader effect
	var light_reflection = $NeonLightReflectionLeft
	if light_reflection:
		# Make the ColorRect itself invisible but let shader do its work
		light_reflection.color = Color(0, 0, 0, 0)
		# Set blend mode to add light only (not supported through script in Godot 4)
		# You'll need to set this in the editor: CanvasItemMaterial with Blend Mode = Add
	
	print("TapperArea ready.")

	# Connect to Global signals for Girth updates
	if Global:
		Global.girth_updated.connect(_on_girth_updated)
		# Check initial state in case game loads with enough girth (not relevant for demo start)
		_on_girth_updated(Global.current_girth) 
	else:
		print("ERROR: Global singleton not found in TapperArea. Cannot connect girth_updated.")
		
	# Make sure we have a default sound assigned to the tap sound player
	if tap_sfx_player and tap_sfx_player.stream == null:
		tap_sfx_player.stream = NORMAL_TAP_SFX
	
	# Make sure we have the mega slap sound assigned
	if mega_slap_sfx_player and mega_slap_sfx_player.stream == null:
		mega_slap_sfx_player.stream = MEGA_SLAP_SFX

	# The self_modulate code for simulated light has been removed, 
	# as this will now be handled by the custom shader on AnimatedChode.


# Called when the ChodeClickZone button is pressed
func _on_pressed():
	# If Giga Slap minigame is active, forward the tap to the SkillTapMeter.
	if Global.is_giga_slap_minigame_active:
		print("TapperArea: Giga Slap minigame active, attempting to forward tap.")
		var main_layout = get_tree().get_first_node_in_group("MainLayout")
		if main_layout and main_layout.has_method("get_skill_tap_meter_node"):
			var skill_tap_meter_node = main_layout.get_skill_tap_meter_node()
			
			if skill_tap_meter_node == null:
				print("TapperArea ERROR: skill_tap_meter_node is NULL after getting from MainLayout.")
				return

			if not is_instance_valid(skill_tap_meter_node):
				print("TapperArea ERROR: skill_tap_meter_node is NOT VALID after getting from MainLayout.")
				return
			
			print("TapperArea INFO: Target SkillTapMeter Path: ", skill_tap_meter_node.get_path())
			print("TapperArea INFO: Target SkillTapMeter IsVisible: ", skill_tap_meter_node.visible)
			print("TapperArea INFO: Target SkillTapMeter Script IsActive: ", skill_tap_meter_node.is_active)
			print("TapperArea INFO: Target SkillTapMeter Script: ", skill_tap_meter_node.get_script())

			if skill_tap_meter_node.has_method("handle_skill_tap"):
				print("TapperArea: --- About to call handle_skill_tap --- ")
				skill_tap_meter_node.handle_skill_tap()
				print("TapperArea: --- Call to handle_skill_tap completed --- ")
			else:
				push_error("TapperArea: ERROR - SkillTapMeter node does NOT have handle_skill_tap method.")
		else:
			push_error("TapperArea: ERROR - Could not find MainLayout or its get_skill_tap_meter_node method.")
		return

	print("TapperArea pressed! Let the Girth flow!")
	
	var perform_giga_slap_minigame = false
	var girth_multiplier = 1 # Default to normal tap
	var is_actual_giga_slap = false

	# Check if Mega Slap is primed (charge meter full)
	if Global.is_mega_slap_primed:
		# Check if we can attempt the Giga Slap minigame
		if Global.can_attempt_giga_slap: # This flag is set true by Global when charge meter fills
			# Attempt to start the Giga Slap minigame
			# Global.attempt_giga_slap_minigame() will emit giga_slap_attempt_ready if successful
			# MainLayout will catch this and show the SkillTapMeter.
			# We don't increment girth here; that happens after minigame result.
			if Global.attempt_giga_slap_minigame():
				perform_giga_slap_minigame = true
				print("TapperArea: Giga Slap Minigame initiated.")
				# DO NOT increment girth or update charge here. Minigame handles outcome.
				# Only play tap effects if minigame doesn't start (shouldn't happen if attempt_giga_slap returns true)
			else: # Should not happen if can_attempt_giga_slap was true, but as a fallback:
				girth_multiplier = Global.MEGA_SLAP_MULTIPLIER
				Global.increment_girth(girth_multiplier)
				Global.update_charge() # Resets charge
		else: # Mega Slap is primed, but Giga Slap already attempted or not eligible, so normal Mega Slap
			girth_multiplier = Global.MEGA_SLAP_MULTIPLIER
			Global.increment_girth(girth_multiplier)
			Global.update_charge() # Resets charge
	else:
		# Normal tap if Mega Slap is not primed
		Global.increment_girth(girth_multiplier) # Standard tap (multiplier is 1)
		Global.update_charge() # Increments charge

	# Visual/Audio Feedback only if NOT starting Giga Slap minigame
	if not perform_giga_slap_minigame:
		# Trigger particle burst 
		if tap_particles: # This line and the rest of the feedback block are now correctly indented
			# For any tap that's not starting the Giga Slap minigame, restart particles.
			# We can add specific visual changes for Mega Slaps vs. normal taps later if needed.
			
			# Example: You might want to change particle amount or lifetime
			# if girth_multiplier > 1: // It's a Mega Slap (but not Giga)
			#    tap_particles.amount = 50 // Or some other enhanced value
			# else: // Normal tap
			#    tap_particles.amount = 20 // Default amount
			#
			tap_particles.restart() # This is the key line!

		if animation_player:
			# Play appropriate animation
			if girth_multiplier > 1: # Mega Slap (not Giga)
				# For Mega Slap, use a more dramatic animation if available
				# If not, just use a more exaggerated version of squash_stretch
				if animation_player.has_animation("mega_slap"):
					animation_player.play("mega_slap")
				else:
					# Create an exaggerated version of squash_stretch
					animated_sprite.scale = Vector2(0.7, 0.3)  # More extreme squash
					var tween = create_tween()
					tween.tween_property(animated_sprite, "scale", Vector2(0.4, 0.8), 0.2)  # More extreme stretch
					tween.tween_property(animated_sprite, "scale", Vector2(0.55, 0.5), 0.2)  # Back to normal
			else:
				# Normal tap animation
				animation_player.play("squash_stretch")

		# Screen shake on normal/mega taps removed as per request for milestone/evolution shakes only
		# If you want shakes on every tap, this is where you would add:
		# emit_signal("girthquake_requested", TAP_SHAKE_AMPLITUDE, TAP_SHAKE_DURATION)

		# Play tap sound effect - use different sound for Mega Slap
		if girth_multiplier > 1 and mega_slap_sfx_player: # Mega Slap (not Giga)
			# Use dedicated Mega Slap sound
			mega_slap_sfx_player.play()
		elif tap_sfx_player:
			# Use normal tap sound (with optional pitch/volume adjustments)
			if girth_multiplier > 1: # Mega Slap (not Giga)
				tap_sfx_player.pitch_scale = 0.7  # Lower, more powerful sound for Mega Slap
				tap_sfx_player.volume_db = 3.0  # Louder
			else:
				tap_sfx_player.pitch_scale = 1.0  # Normal pitch
				tap_sfx_player.volume_db = 0.0  # Normal volume
			
			tap_sfx_player.play()
			
			# Reset sound properties after Mega Slap
			if girth_multiplier > 1: # Mega Slap (not Giga)
				await tap_sfx_player.finished
				tap_sfx_player.pitch_scale = 1.0
				tap_sfx_player.volume_db = 0.0
			
		# Emit signals for floating numbers instead of spawning them directly
		if girth_multiplier == Global.MEGA_SLAP_MULTIPLIER: # Normal Mega Slap
			emit_signal("floating_number_requested", "+" + str(Global.GIRTH_PER_TAP * Global.MEGA_SLAP_MULTIPLIER), global_position)
			await get_tree().create_timer(0.1).timeout
			emit_signal("floating_number_requested", "MEGA SLAP!", global_position - Vector2(0, 30))
			await get_tree().create_timer(0.1).timeout
			emit_signal("floating_number_requested", "THUNDEROUS!", global_position - Vector2(0, 60))
		elif girth_multiplier == 1: # Normal Tap
			emit_signal("floating_number_requested", "+1", global_position)
		# Giga Slap success/failure floating text will be handled by MainLayout or SkillTapMeter itself


func _on_girth_updated(new_girth: int):
	# Check for evolution thresholds in order
	if not _tier1_unlocked and new_girth >= VEINOUS_VERIDIAN_THRESHOLD:
		_celebrate_evolution(1) # Evolve to Tier 1 - Veinous Veridian
	elif _tier1_unlocked and not _tier2_unlocked and new_girth >= CRACKED_CORE_THRESHOLD:
		_celebrate_evolution(2) # Evolve to Tier 2 - Cracked Core Chode
	
	# Check for intermediate milestones to keep player engaged
	for milestone in MILESTONE_THRESHOLDS:
		if new_girth >= milestone and milestone not in _reached_milestones:
			_reached_milestones.append(milestone)
			_celebrate_milestone(milestone, new_girth)


# Celebrate reaching a milestone on the path to evolution
func _celebrate_milestone(milestone: int, current_girth: int):
	# Calculate progress percentage towards next evolution
	var target_threshold = VEINOUS_VERIDIAN_THRESHOLD
	var current_tier = 0
	
	# Determine which tier we're progressing towards
	if _tier1_unlocked and !_tier2_unlocked:
		target_threshold = CRACKED_CORE_THRESHOLD
		current_tier = 1
	elif _tier1_unlocked and _tier2_unlocked:
		# Already at max tier, just celebrate the milestone
		target_threshold = CRACKED_CORE_THRESHOLD  # Use this as reference point even if we're past it
		current_tier = 2
	
	# Calculate percentage progress (cap at 99% if we're at the cusp of evolution)
	var progress_to_next_tier = int(min(float(milestone) / float(target_threshold) * 100, 99))
	
	# Show appropriate message based on tier progression
	var milestone_message = ""
	
	# Tier 0 to Tier 1 messages
	if current_tier == 0:
		if milestone == 50:
			milestone_message = "Keep tapping! Your $CHODE is showing promise!"
		elif milestone == 100:
			milestone_message = "One-third to evolution! Feeling the growth!"
		elif milestone == 150:
			milestone_message = "Halfway there! $CHODE power rising!"
		elif milestone == 200:
			milestone_message = "Getting closer! Your $CHODE is swelling with energy!"
		elif milestone == 250:
			milestone_message = "Almost there! Your $CHODE is pulsating with potential!"

	# Tier 1 to Tier 2 messages
	elif current_tier == 1:
		if milestone == 500:
			milestone_message = "One-third to ultimate form! Your veins are bulging!"
		elif milestone == 750:
			milestone_message = "Halfway to the final evolution! The pressure builds..."
		elif milestone == 1000:
			milestone_message = "Your core is straining! Almost there!"
		elif milestone == 1250:
			milestone_message = "The cracks are forming! Your core is about to split open!"

	# Already at max tier
	elif current_tier == 2:
		milestone_message = "You continue to master the power of the Cracked Core!"
	
	# Emit achievement signal if we have a message
	if milestone_message != "":
		emit_signal("achievement_unlocked", "Milestone: " + str(milestone) + " $GIRTH!", milestone_message, 3.0)
	
	# Display percentage if we're not at max tier
	var display_text = str(progress_to_next_tier) + "%!"
	if current_tier == 2:
		display_text = "EPIC!"
		
	# Emit signal for floating number
	emit_signal("floating_number_requested", display_text, global_position - Vector2(0, 30))
	
	# Small celebration animation
	var tween = create_tween()
	tween.tween_property(animated_sprite, "scale", animated_sprite.scale * 1.2, 0.2)
	tween.tween_property(animated_sprite, "scale", animated_sprite.scale, 0.2)
	
	# Extra particles
	if tap_particles:
		var original_amount = tap_particles.amount
		tap_particles.amount = 20
		tap_particles.restart()
		await get_tree().create_timer(0.5).timeout
		tap_particles.amount = original_amount


# Celebrate the evolution to Veinous Veridian with visual flourish
func _celebrate_evolution(tier: int):
	if animated_sprite:
		# First, play a celebratory animation if you have one
		if animation_player and animation_player.has_animation("evolution_celebration"):
			animation_player.play("evolution_celebration")
		else:
			# If no specific animation, create a simple scale effect
			var tween = create_tween()
			tween.tween_property(self, "scale", Vector2(EVOLUTION_SCALE_FACTOR, EVOLUTION_SCALE_FACTOR), 0.3)
			tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.3)
		
		# Change to the evolved sprite
		animated_sprite.animation = "tier_" + str(tier) + "_idle"
		
		# Set the appropriate tier flag
		if tier == 1:
			_tier1_unlocked = true
		elif tier == 2:
			_tier2_unlocked = true
		
		# Determine celebration intensity based on tier
		var particles_amount = EVOLUTION_PARTICLE_COUNT
		var particle_lifetime = 1.5
		var velocity_min = 150.0
		var velocity_max = 300.0
		var bonus_girth = EVOLUTION_CELEBRATORY_GIRTH_BONUS
		var pitch_scale = 1.5
		
		# For Cracked Core evolution, make everything more intense
		if tier == 2:
			particles_amount = int(EVOLUTION_PARTICLE_COUNT * ULTIMATE_EVOLUTION_MULTIPLIER)
			particle_lifetime = 2.0
			velocity_min = 200.0
			velocity_max = 400.0
			bonus_girth = int(EVOLUTION_CELEBRATORY_GIRTH_BONUS * ULTIMATE_EVOLUTION_MULTIPLIER)
			pitch_scale = 2.0
		
		# Emit more particles for a bigger celebration
		if tap_particles:
			# Store original properties
			var original_amount = tap_particles.amount
			var original_lifetime = tap_particles.lifetime
			var original_process_material = tap_particles.process_material.duplicate()
			
			# Set epic celebration properties
			tap_particles.amount = particles_amount
			tap_particles.lifetime = particle_lifetime
			
			# Update particle process material properties
			var celebration_material = original_process_material.duplicate()
			celebration_material.initial_velocity_min = velocity_min
			celebration_material.initial_velocity_max = velocity_max
			tap_particles.process_material = celebration_material
			
			tap_particles.restart()
			
			# Reset particle properties after celebration
			await get_tree().create_timer(particle_lifetime * 0.8).timeout
			tap_particles.amount = original_amount
			tap_particles.lifetime = original_lifetime
			tap_particles.process_material = original_process_material
		
		# Award bonus girth for reaching this tier
		if Global:
			# Dramatic pause before bonus girth starts flowing
			await get_tree().create_timer(0.8).timeout
			
			for i in range(bonus_girth):
				Global.increment_girth()
				await get_tree().create_timer(0.05).timeout  # Faster increment for more excitement
		
		# Play a celebratory sound if available
		if tap_sfx_player:
			tap_sfx_player.pitch_scale = pitch_scale
			tap_sfx_player.play()
			await tap_sfx_player.finished
			tap_sfx_player.pitch_scale = 1.0  # Reset pitch
		
		# Set appropriate evolution messages based on tier
		var title = ""
		var description = ""
		
		if tier == 1:
			title = "CHODE EVOLVED!"
			description = "Your humble sprout has finally matured into the glorious Veinous Veridian form!"
			print("CHODE EVOLVED! Now Veinous Veridian!")
		elif tier == 2:
			title = "ULTIMATE EVOLUTION!"
			description = "Your $CHODE has reached the legendary Cracked Core state! Throbbing with unfathomable girth energy!"
			print("ULTIMATE EVOLUTION! Now CRACKED CORE CHODE!")
		
		# Emit achievement signal
		emit_signal("achievement_unlocked", title, description, 5.0)
		
		# Emit signals for multiple special evolution floating texts in sequence
		emit_signal("floating_number_requested", "EVOLVED!", global_position - Vector2(0, 50))
		await get_tree().create_timer(0.2).timeout
		
		if tier == 1:
			emit_signal("floating_number_requested", "GIRTH+", global_position - Vector2(-50, 70))
		else:
			emit_signal("floating_number_requested", "MEGA GIRTH+", global_position - Vector2(-50, 70))
		
		await get_tree().create_timer(0.2).timeout
		
		if tier == 1:
			emit_signal("floating_number_requested", "LEGENDARY!", global_position - Vector2(50, 90))
		else:
			emit_signal("floating_number_requested", "GODLIKE!", global_position - Vector2(50, 90))
			
			# For tier 2, add extra floating text celebration
			await get_tree().create_timer(0.3).timeout
			emit_signal("floating_number_requested", "CORE CRACKED!", global_position - Vector2(0, 110))


# Placeholder for functions to update Chode visuals for more tiers later
# func update_chode_visual(girth_tier_index: int):
# 	 match girth_tier_index:
# 		 0:
# 			 # animated_sprite.animation = "humble_sprout"
# 			 # animated_sprite.visible = true # Or manage visibility based on tier logic
# 			 print("Chode visual: Humble Sprout")
# 		 1:
# 			 # animated_sprite.animation = "veinous_veridian"
# 			 # animated_sprite.visible = true
# 			 print("Chode visual: Veinous Veridian")
# 		 _: # Default or error case
# 			 # animated_sprite.visible = false
# 			 print("Unknown Girth tier for visual update: ", girth_tier_index) 
