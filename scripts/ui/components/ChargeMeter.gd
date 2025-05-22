extends Control

signal charge_ready
signal charge_used

@onready var meter = $MeterContainer/MeterProgress/ChargeMeter
@onready var overlay = $MeterContainer/MeterProgress/ChargeOverlay
@onready var ready_label = $MeterContainer/MeterProgress/ReadyLabel
@onready var meter_label = $MeterContainer/MeterLabel

var max_charge = 100.0
var current_charge = 0.0
var is_ready = false
var is_in_refactory = false
var ready_label_animation = null

func _ready():
	# Initialize the charge meter
	meter.max_value = max_charge
	meter.value = current_charge
	update_ui()
	
	# Connect to Global signals
	if Global:
		Global.charge_updated.connect(_on_charge_updated)
		Global.mega_slap_ready.connect(_on_mega_slap_ready)
		Global.mega_slap_delivered.connect(_on_mega_slap_delivered)
		Global.refactory_period_started.connect(_on_refactory_started)
		Global.refactory_period_ended.connect(_on_refactory_ended)
		Global.giga_slap_charge_lost.connect(_on_giga_slap_charge_lost)
	else:
		push_error("Global singleton not found in ChargeMeter!")

func update_ui():
	meter.value = current_charge
	
	# Update visual feedback for refactory period
	if is_in_refactory:
		meter.modulate = Color(0.7, 0.7, 0.8)  # Slightly dimmed color during refactory
	else:
		meter.modulate = Color(1, 1, 1)  # Normal color
	
	# Update ready state visuals
	overlay.visible = is_ready
	ready_label.visible = is_ready
	
	# Toggle MeterLabel visibility based on ready state
	if meter_label:
		meter_label.visible = !is_ready

# Called when Global updates the charge value
func _on_charge_updated(new_charge, max_val):
	current_charge = new_charge
	max_charge = max_val
	meter.max_value = max_charge
	update_ui()

# Called when a Mega Slap is ready
func _on_mega_slap_ready():
	is_ready = true
	update_ui()
	emit_signal("charge_ready")
	
	# Add visual feedback - pulse effect on meter only
	var meter_tween = create_tween()
	meter_tween.tween_property(meter, "modulate", Color(1.5, 1.5, 0.5), 0.3)
	meter_tween.tween_property(meter, "modulate", Color(1, 1, 1), 0.3)
	
	# Start the ReadyLabel animation
	_start_ready_label_animation()

# Called when a Mega Slap is delivered
func _on_mega_slap_delivered():
	is_ready = false
	update_ui()
	emit_signal("charge_used")
	
	# Stop the ready label animation
	_stop_ready_label_animation()
	
	# Add visual feedback - flash effect on meter only
	var tween = create_tween()
	tween.tween_property(meter, "modulate", Color(2, 1, 0), 0.2)
	tween.tween_property(meter, "modulate", Color(1, 1, 1), 0.3)

# Called when Giga Slap minigame times out and charge is reset by Global
func _on_giga_slap_charge_lost():
	print("ChargeMeter: Giga Slap charge lost, updating UI.")
	is_ready = false # No longer ready
	# current_charge will be updated by _on_charge_updated when Global emits it
	# For now, ensure UI reflects not-ready state immediately.
	update_ui()
	_stop_ready_label_animation()

# Called when refactory period starts
func _on_refactory_started():
	is_in_refactory = true
	update_ui()
	
	# Add visual feedback - dim meter during refactory
	var tween = create_tween()
	tween.tween_property(meter, "modulate", Color(0.7, 0.7, 0.8), 0.5)

# Called when refactory period ends
func _on_refactory_ended():
	is_in_refactory = false
	update_ui()
	
	# Add visual feedback - return to normal
	var tween = create_tween()
	tween.tween_property(meter, "modulate", Color(1, 1, 1), 0.5)

# Start animation for the ReadyLabel
func _start_ready_label_animation():
	# Stop any existing animation
	_stop_ready_label_animation()
	
	# Make sure the label is visible and reset properties
	ready_label.visible = true
	ready_label.scale = Vector2(1.75, 1.75)  # Reset to default scale
	
	# Create pulsing animation
	ready_label_animation = create_tween()
	ready_label_animation.set_loops()  # Loop indefinitely
	
	# Scale animation
	ready_label_animation.tween_property(ready_label, "scale", Vector2(2.0, 2.0), 0.5).set_trans(Tween.TRANS_SINE)
	ready_label_animation.tween_property(ready_label, "scale", Vector2(1.5, 1.5), 0.5).set_trans(Tween.TRANS_SINE)
	
	# Create color pulse effect
	var color_tween = create_tween()
	color_tween.set_loops()  # Loop indefinitely
	
	# Vibrant yellow to more intense orange
	color_tween.tween_property(ready_label, "modulate", Color(1.2, 0.9, 0.2, 1), 0.5).set_trans(Tween.TRANS_SINE) 
	color_tween.tween_property(ready_label, "modulate", Color(1.0, 0.7, 0.1, 1), 0.5).set_trans(Tween.TRANS_SINE)

# Stop ReadyLabel animation
func _stop_ready_label_animation():
	if ready_label_animation and ready_label_animation.is_running():
		ready_label_animation.kill()
	
	# Reset properties
	ready_label.scale = Vector2(1.75, 1.75)
	ready_label.modulate = Color(1, 1, 1, 1)

# Public methods that MainLayout can call

func use_charge():
	if is_ready:
		# Let Global handle the actual charge usage logic
		# This is now mostly handled via signals, but keep for API compatibility
		return true
	return false

func get_charge_percentage():
	return (current_charge / max_charge) * 100.0 