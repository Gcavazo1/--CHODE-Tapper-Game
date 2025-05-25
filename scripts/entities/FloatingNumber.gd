extends Node2D

signal animation_completed

var velocity = Vector2(0, -100)  # Upward movement
var value = "+1"  # Default value
var fade_speed = 1.0  # Speed of fade out

# Glitch effect variables
var glitch_intensity = 3.0  # Maximum offset for glitch effect
var glitch_chance = 0.7  # Probability of glitch occurring on timer
var red_offset = Vector2.ZERO
var green_offset = Vector2.ZERO
var time_to_next_glitch = 0.0

# Shader parameters
var shader_material: ShaderMaterial

@onready var main_label = $GlitchContainer/Label
@onready var red_label = $GlitchContainer/LabelRedOffset
@onready var green_label = $GlitchContainer/LabelGreenOffset
@onready var glitch_container = $GlitchContainer
@onready var animation_timer = $AnimationTimer
@onready var glitch_timer = $GlitchTimer

# Exported properties to be set by EffectsManager
@export var custom_duration: float = 1.5:
	set(new_duration):
		custom_duration = new_duration
		if animation_timer: # Check if node is ready
			animation_timer.wait_time = custom_duration

@export var custom_color: Color = Color.WHITE:
	set(new_color):
		custom_color = new_color
		if main_label: # Check if node is ready
			main_label.modulate = custom_color
			# Optionally, you might want to modulate red_label and green_label too,
			# or adjust their base colors if they are not just white.
			# For now, just modulating the main label.
			# red_label.modulate = new_color 
			# green_label.modulate = new_color

@export var scale_modifier: float = 1.0:
	set(new_scale_mod):
		scale_modifier = new_scale_mod
		if is_inside_tree(): # Check if node is ready
			scale = Vector2(1.0, 1.0) * scale_modifier # Apply relative to base scale of 1

func _ready():
	# Apply exported properties if they were set before _ready (e.g., by EffectsManager)
	if animation_timer and custom_duration != animation_timer.wait_time:
		animation_timer.wait_time = custom_duration
	if main_label and main_label.modulate != custom_color:
		main_label.modulate = custom_color
	# Apply initial scale based on modifier
	scale = Vector2(randf_range(0.9, 1.1), randf_range(0.9, 1.1)) * scale_modifier

	# Set the text value for all labels
	main_label.text = value
	red_label.text = value
	green_label.text = value
	
	# Get the shader material
	shader_material = glitch_container.material as ShaderMaterial
	
	# Configure shader parameters
	if shader_material:
		# Randomize shader parameters for variety
		shader_material.set_shader_parameter("scanline_count", randf_range(30.0, 70.0))
		shader_material.set_shader_parameter("scanline_speed", randf_range(0.5, 2.0))
		shader_material.set_shader_parameter("noise_strength", randf_range(0.05, 0.2))
		shader_material.set_shader_parameter("glitch_intensity", randf_range(0.2, 0.4))
	
	# Start with slight random rotation and scale
	rotation_degrees = randf_range(-10, 10)
	
	# Add a slight random horizontal movement
	velocity.x = randf_range(-20, 20)
	
	# Initial glitch effect
	_apply_random_glitch()
	
func _process(delta):
	# Move upward
	position += velocity * delta
	
	# Slow down as it rises
	velocity.y += 120 * delta  # Gravity effect
	
	# Fade out
	modulate.a -= fade_speed * delta
	
	# Scale up slightly
	scale += Vector2(0.1, 0.1) * delta
	
	# Randomly change shader parameters for more dynamic effect
	if shader_material and randf() < 0.1:  # 10% chance per frame
		var intensity_change = randf_range(-0.1, 0.1)
		var current_intensity = shader_material.get_shader_parameter("glitch_intensity")
		shader_material.set_shader_parameter("glitch_intensity", clamp(current_intensity + intensity_change, 0.1, 0.5))
	
	# Handle random glitches between timer events
	time_to_next_glitch -= delta
	if time_to_next_glitch <= 0:
		time_to_next_glitch = randf_range(0.05, 0.2)
		if randf() < 0.3:  # 30% chance for random glitch between timer events
			_apply_random_glitch()

func _on_animation_timer_timeout():
	# Emit signal before removing
	emit_signal("animation_completed")
	# Remove self when animation is done
	queue_free()

func _on_glitch_timer_timeout():
	# Apply glitch effect randomly
	if randf() < glitch_chance:
		_apply_random_glitch()
	else:
		_reset_glitch()

func _apply_random_glitch():
	# Generate random offsets for chromatic aberration
	red_offset = Vector2(randf_range(-glitch_intensity, -1), randf_range(-1, 1))
	green_offset = Vector2(randf_range(1, glitch_intensity), randf_range(-1, 1))
	
	# Apply the offsets to the colored labels
	red_label.position = red_offset
	green_label.position = green_offset
	
	# Random chance to apply horizontal slicing/distortion
	if randf() < 0.4:
		# Instead of moving the whole container, just offset individual labels
		var slice_offset_red = Vector2(randf_range(-glitch_intensity, 0), 0)
		var slice_offset_green = Vector2(randf_range(0, glitch_intensity), 0)
		red_label.position += slice_offset_red
		green_label.position += slice_offset_green
		
		# Random opacity changes
		var red_opacity = randf_range(0.4, 0.8)
		var green_opacity = randf_range(0.4, 0.8)
		red_label.modulate.a = red_opacity
		green_label.modulate.a = green_opacity
	
	# Random chance for white text to jitter slightly
	if randf() < 0.3:
		main_label.position = Vector2(randf_range(-2, 2), randf_range(-2, 2))
		
	# Update shader parameters for a more intense glitch moment
	if shader_material and randf() < 0.5:
		shader_material.set_shader_parameter("distortion_strength", randf_range(0.0005, 0.003))
		shader_material.set_shader_parameter("noise_strength", randf_range(0.1, 0.3))

func _reset_glitch():
	# Reset to normal state occasionally
	red_label.position = Vector2(-2, 0)
	green_label.position = Vector2(2, 0)
	main_label.position = Vector2.ZERO
	
	# Reset opacities
	red_label.modulate.a = 0.6
	green_label.modulate.a = 0.6
	
	# Reset shader parameters to more subtle values
	if shader_material:
		shader_material.set_shader_parameter("distortion_strength", 0.001)
		shader_material.set_shader_parameter("noise_strength", 0.1)

# Public method to set the floating number's value
func set_value(new_value):
	value = new_value
	if is_inside_tree():
		main_label.text = value 
		red_label.text = value
		green_label.text = value

# Method for EffectsManager to set duration
func set_duration(new_duration: float):
	custom_duration = new_duration # Store it
	if animation_timer: # If ready
		animation_timer.wait_time = new_duration
		print("FloatingNumber: Duration set to ", new_duration)
	else: # If not ready, it will be applied in _ready()
		print("FloatingNumber: Duration will be set in _ready() to ", new_duration)

# Method for EffectsManager to set color
func set_color(new_color: Color):
	custom_color = new_color # Store it
	if main_label: # If ready
		main_label.modulate = new_color
		# red_label.modulate = new_color # Optional: modulate glitch labels too
		# green_label.modulate = new_color
		print("FloatingNumber: Color set to ", new_color)
	else: # If not ready, it will be applied in _ready()
		print("FloatingNumber: Color will be set in _ready() to ", new_color)

# Method for EffectsManager to set scale modifier
func set_scale_modifier(new_scale_mod: float):
	scale_modifier = new_scale_mod # Store it
	if is_inside_tree(): # If ready
		# Apply relative to a base random scale, then modify
		var base_random_scale = Vector2(randf_range(0.9, 1.1), randf_range(0.9, 1.1))
		scale = base_random_scale * new_scale_mod
		print("FloatingNumber: Scale modifier set to ", new_scale_mod, ", final scale: ", scale)
	else: # If not ready, it will be applied in _ready()
		print("FloatingNumber: Scale modifier will be set in _ready() to ", new_scale_mod) 