extends Control

signal achievement_displayed
signal achievement_hidden

@onready var panel = $PanelContainer
@onready var name_label = $PanelContainer/VBoxContainer/AchievementNameLabel
@onready var desc_label = $PanelContainer/VBoxContainer/AchievementDescLabel
@onready var display_timer = $DisplayTimer

var tween: Tween
var glitch_timer: Timer
var is_glitching = false

func _ready():
	panel.visible = false
	
	# Create glitch timer for random glitch effects
	glitch_timer = Timer.new()
	glitch_timer.wait_time = randf_range(0.5, 1.5)
	glitch_timer.autostart = false
	glitch_timer.one_shot = true
	glitch_timer.timeout.connect(_on_glitch_timer_timeout)
	add_child(glitch_timer)

func show_achievement(title: String, description: String, duration: float = 3.0):
	# Update the text content
	name_label.text = title.to_upper()
	desc_label.text = description
	
	# Make sure any previous tween is stopped and reset
	if tween and tween.is_running():
		tween.kill()
	
	# Reset panel state
	panel.modulate = Color(1, 1, 1, 0)
	panel.scale = Vector2(0.8, 0.8)
	panel.visible = true
	
	# Create animation tween
	tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.5).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "scale", Vector2(1, 1), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	
	# Update timer duration
	display_timer.wait_time = duration
	display_timer.start()
	
	# Start the glitch effects
	is_glitching = true
	_schedule_next_glitch()
	
	emit_signal("achievement_displayed")

func hide_achievement():
	if panel.visible:
		# Stop glitching
		is_glitching = false
		glitch_timer.stop()
		
		# Create hide animation
		tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(panel, "modulate", Color(1, 1, 1, 0), 0.5).set_ease(Tween.EASE_IN)
		tween.tween_property(panel, "scale", Vector2(1.1, 1.1), 0.5).set_ease(Tween.EASE_IN)
		tween.tween_callback(func(): panel.visible = false).set_delay(0.5)
		
		emit_signal("achievement_hidden")

func _schedule_next_glitch():
	if is_glitching:
		glitch_timer.wait_time = randf_range(0.5, 2.0)
		glitch_timer.start()

func _on_glitch_timer_timeout():
	if is_glitching and panel.visible:
		# Apply a random glitch effect
		_apply_glitch_effect()
		_schedule_next_glitch()

func _apply_glitch_effect():
	var glitch_type = randi() % 4
	var glitch_tween = create_tween()
	glitch_tween.set_parallel(true)
	
	match glitch_type:
		0: # Color shift
			var random_color = Color(
				randf_range(0.8, 1.0), 
				randf_range(0.0, 0.8), 
				randf_range(0.8, 1.0),
				1.0
			)
			glitch_tween.tween_property(panel, "modulate", random_color, 0.1)
			glitch_tween.tween_property(panel, "modulate", Color(1, 1, 1, 1), 0.1).set_delay(0.15)
		
		1: # Position jitter
			var original_pos = panel.position
			var jitter = Vector2(randf_range(-5, 5), randf_range(-5, 5))
			glitch_tween.tween_property(panel, "position", original_pos + jitter, 0.05)
			glitch_tween.tween_property(panel, "position", original_pos, 0.05).set_delay(0.1)
		
		2: # Scale glitch
			var original_scale = panel.scale
			var scale_mod = Vector2(randf_range(0.95, 1.05), randf_range(0.95, 1.05))
			glitch_tween.tween_property(panel, "scale", original_scale * scale_mod, 0.1)
			glitch_tween.tween_property(panel, "scale", original_scale, 0.1).set_delay(0.15)
			
		3: # Text color glitch
			var original_name_color = name_label.get("theme_override_colors/font_color")
			var original_desc_color = desc_label.get("theme_override_colors/font_color")
			
			var glitch_name_color = Color(
				randf_range(0.8, 1.0),
				randf_range(0.8, 1.0),
				randf_range(0.0, 0.2),
				1.0
			)
			var glitch_desc_color = Color(
				randf_range(0.0, 0.2),
				randf_range(0.8, 1.0), 
				randf_range(0.8, 1.0),
				1.0
			)
			
			glitch_tween.tween_property(name_label, "theme_override_colors/font_color", glitch_name_color, 0.1)
			glitch_tween.tween_property(desc_label, "theme_override_colors/font_color", glitch_desc_color, 0.1)
			glitch_tween.tween_property(name_label, "theme_override_colors/font_color", original_name_color, 0.1).set_delay(0.15)
			glitch_tween.tween_property(desc_label, "theme_override_colors/font_color", original_desc_color, 0.1).set_delay(0.15)

func _on_display_timer_timeout():
	hide_achievement() 
