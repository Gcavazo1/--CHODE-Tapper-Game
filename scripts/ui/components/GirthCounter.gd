extends Control

# Modular GirthCounter component
# Displays the $GIRTH count with cyberpunk glitch effects

# References to the child nodes
@onready var girth_label: Label = $GirthContainer/GirthLabel
@onready var girth_label_red: Label = $GirthContainer/ColorGlitchContainer/GirthLabelRedOffset
@onready var girth_label_green: Label = $GirthContainer/ColorGlitchContainer/GirthLabelGreenOffset
@onready var girth_container: Control = $GirthContainer
@onready var color_glitch_container: Control = $GirthContainer/ColorGlitchContainer
@onready var glitch_timer: Timer = $GlitchTimer
@onready var backbuffer = $BackBufferCopy

# Shader and glitch effect variables
var shader_material: ShaderMaterial
var glitch_intensity = 3.0  # Increased for more visible effect
var glitch_chance = 0.7     # Increased for more frequent glitches
var base_red_offset = Vector2(-2, 0)
var base_green_offset = Vector2(2, 0)

# Signal for when the $GIRTH counter is updated
signal girth_updated(new_value)

func _ready():
	# Get shader material reference
	shader_material = $GirthContainer.material
	
	# Make sure the BackBufferCopy covers our entire control
	_update_backbuffer_area()
	
	# Setup initial glitch effect
	_setup_glitch_effect()
	
	# Connect to the Global singleton's signals
	if Global:
		Global.girth_updated.connect(_on_girth_updated)
		
		# Initialize with the current value from Global
		_on_girth_updated(Global.current_girth)
	else:
		print("ERROR: GirthCounter - Global singleton not found.")
	
	# Connect timer signal
	if glitch_timer:
		glitch_timer.timeout.connect(_on_glitch_timer_timeout)
	
	# Connect to resizing signals to update the backbuffer area
	resized.connect(_update_backbuffer_area)

func _update_backbuffer_area():
	# Update the BackBufferCopy to match our size
	if backbuffer:
		# If we're in the full scene, use the control's actual size
		if get_parent() != get_tree().root:
			var actual_size = get_rect().size
			backbuffer.position = actual_size / 2
			backbuffer.rect = Rect2(-actual_size.x/2, -actual_size.y/2, actual_size.x, actual_size.y)
			print("GirthCounter updating BackBufferCopy in container: ", backbuffer.rect)
		else:
			# If we're running standalone (via F6), use viewport size
			var viewport_size = get_viewport_rect().size
			backbuffer.position = viewport_size / 2
			backbuffer.rect = Rect2(-viewport_size.x/2, -viewport_size.y/2, viewport_size.x, viewport_size.y)
			print("GirthCounter updating BackBufferCopy standalone: ", backbuffer.rect)
			
		# Ensure the glitch effects fit within the new boundaries
		_reset_glitch_effect()

func _setup_glitch_effect():
	# Initialization of glitch effect for $GIRTH counter
	if shader_material:
		shader_material.set_shader_parameter("scanline_count", 50.0)
		shader_material.set_shader_parameter("scanline_speed", 1.2)
		shader_material.set_shader_parameter("noise_strength", 0.15)
		shader_material.set_shader_parameter("distortion_strength", 0.002)
		shader_material.set_shader_parameter("time_scale", 1.0)
		shader_material.set_shader_parameter("glitch_intensity", 0.35)
	
	# Set initial offsets for chromatic aberration
	if girth_label_red and girth_label_green:
		# Use absolute positioning with anchors to prevent container-based misalignment
		girth_label_red.position = base_red_offset
		girth_label_green.position = base_green_offset
		
		# Ensure all labels have proper anchors to stay centered
		_ensure_proper_anchors(girth_label)
		_ensure_proper_anchors(girth_label_red)
		_ensure_proper_anchors(girth_label_green)
		
		# Ensure high contrast colors
		girth_label_red.modulate = Color(1, 0, 0, 0.7)
		girth_label_green.modulate = Color(0, 1, 0, 0.7)

func _ensure_proper_anchors(label: Label):
	# Make sure label is properly anchored to center
	label.anchor_left = 0
	label.anchor_top = 0
	label.anchor_right = 1
	label.anchor_bottom = 1
	label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	label.grow_vertical = Control.GROW_DIRECTION_BOTH
	
	# Ensure text alignment is centered
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# Reset any offsets that might interfere with positioning
	label.position = Vector2.ZERO
	
	# Make sure the label fits within the control
	label.clip_text = false
	label.autowrap_mode = TextServer.AUTOWRAP_OFF

func _on_girth_updated(new_value: int):
	var girth_text = "$GIRTH: %s" % new_value
	
	# Update all labels
	if girth_label:
		girth_label.text = girth_text
	if girth_label_red:
		girth_label_red.text = girth_text
	if girth_label_green:
		girth_label_green.text = girth_text
	
	# Apply a pulse effect on update
	if girth_container:
		girth_container.scale = Vector2(1.1, 1.1)
		var tween = create_tween()
		tween.tween_property(girth_container, "scale", Vector2(1.0, 1.0), 0.2)
	
	# Apply increased glitch on update
	_apply_glitch_effect(true)
	
	# Emit our own signal in case other components need to know
	emit_signal("girth_updated", new_value)

func _on_glitch_timer_timeout():
	# Periodically apply glitch effect
	if randf() < glitch_chance:
		_apply_glitch_effect()
	else:
		_reset_glitch_effect()

func _apply_glitch_effect(intense: bool = false):
	if girth_label_red and girth_label_green:
		var intensity = glitch_intensity
		if intense:
			intensity *= 2.0
		
		# Get the current size to constrain glitch within visible area
		var container_size = girth_container.get_rect().size
		var max_offset_x = min(intensity, container_size.x * 0.05) # Limit to 5% of width
		var max_offset_y = min(1.0, container_size.y * 0.05)       # Limit to 5% of height
			
		# Apply chromatic aberration offsets (relative to base positions)
		var red_x_offset = randf_range(-max_offset_x, -1)
		var red_y_offset = randf_range(-max_offset_y, max_offset_y)
		var green_x_offset = randf_range(1, max_offset_x)
		var green_y_offset = randf_range(-max_offset_y, max_offset_y)
		
		# Set positions relative to container center
		girth_label_red.position = base_red_offset + Vector2(red_x_offset, red_y_offset)
		girth_label_green.position = base_green_offset + Vector2(green_x_offset, green_y_offset)
		
		# Adjust opacity for better visibility
		girth_label_red.modulate.a = randf_range(0.5, 0.8)
		girth_label_green.modulate.a = randf_range(0.5, 0.8)
		
		# Update shader parameters
		if shader_material:
			var distortion = 0.002
			var noise = 0.15
			if intense:
				distortion = 0.004
				noise = 0.25
				
			shader_material.set_shader_parameter("distortion_strength", randf_range(distortion * 0.5, distortion * 1.5))
			shader_material.set_shader_parameter("noise_strength", randf_range(noise * 0.5, noise * 1.5))

func _reset_glitch_effect():
	# Reset to normal state occasionally
	if girth_label_red and girth_label_green:
		# Ensure the positions are reset properly
		girth_label_red.position = base_red_offset
		girth_label_green.position = base_green_offset
		
		# Re-apply proper anchoring to ensure positioning is correct
		_ensure_proper_anchors(girth_label)
		_ensure_proper_anchors(girth_label_red)
		_ensure_proper_anchors(girth_label_green)
		
		# Reset positions on top of anchor settings
		girth_label_red.position = base_red_offset
		girth_label_green.position = base_green_offset
		
		# Reset opacities
		girth_label_red.modulate.a = 0.6
		girth_label_green.modulate.a = 0.6
		
		# Reset shader parameters to more subtle values
		if shader_material:
			shader_material.set_shader_parameter("distortion_strength", 0.001)
			shader_material.set_shader_parameter("noise_strength", 0.1)

# Public method to manually update the displayed value
func update_girth(value: int):
	_on_girth_updated(value) 
