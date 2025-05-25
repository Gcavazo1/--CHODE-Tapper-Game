extends Node

# Manages UI aspects related to the ChargeMeter.

# --- Dependencies (injected by MainLayout) ---
var charge_meter_node # The ChargeMeter scene instance

# --- Signals (if this manager needs to inform other systems beyond direct UI changes) ---
# Example: signal charge_meter_ui_updated

# --- Initialization ---
func initialize_manager(meter_node):
	charge_meter_node = meter_node
	if not is_instance_valid(charge_meter_node):
		push_error("ChargeMeterUIManager: ChargeMeter node is invalid!")
	else:
		print("ChargeMeterUIManager: Initialized with ChargeMeter: ", charge_meter_node.name)

# --- Core UI Logic & Passthrough functions ---

# Returns the current charge percentage from the ChargeMeter node.
func get_charge_percentage() -> float:
	if is_instance_valid(charge_meter_node) and charge_meter_node.has_method("get_charge_percentage"):
		return charge_meter_node.get_charge_percentage()
	else:
		push_warning("ChargeMeterUIManager: ChargeMeter node not set or lacks get_charge_percentage method.")
	return 0.0

# --- Signal Handlers (Connected by MainLayout to signals from ChargeMeter.gd) ---

# Called when the charge_meter's 'charge_ready' signal is emitted.
func _on_charge_ready():
	print("ChargeMeterUIManager: Charge is READY. Handling UI cues if any.")
	# Add any specific UI changes here, e.g., play an animation on the HUD,
	# make a sound, or emit a signal if other UI parts need to react.
	# For now, this primarily serves as a hook for future UI enhancements.
	# emit_signal("charge_meter_ui_updated") 

# Called when the charge_meter's 'charge_used' signal is emitted.
func _on_charge_used():
	print("ChargeMeterUIManager: Charge has been USED. Handling UI cues if any.")
	# Add any specific UI changes here, e.g., visual feedback for charge depletion.
	# emit_signal("charge_meter_ui_updated") 