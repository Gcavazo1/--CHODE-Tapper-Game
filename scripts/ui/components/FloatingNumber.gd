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

func _ready():
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
	scale = Vector2(randf_range(0.9, 1.1), randf_range(0.9, 1.1))
	
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

# Static function to spawn a floating number at a specific position
static func spawn(parent: Node, pos: Vector2, value_text: String = "+1", custom_duration: float = 1.5) -> Node:
	var floating_number_scene = load("res://scenes/ui/components/FloatingNumber.tscn")
	var instance = floating_number_scene.instantiate()
	
	instance.position = pos
	instance.value = value_text
	
	if custom_duration != 1.5:
		instance.animation_timer.wait_time = custom_duration
	
	parent.add_child(instance)
	instance.set_value(value_text)
	
	return instance 