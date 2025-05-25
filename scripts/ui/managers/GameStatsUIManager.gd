extends Node

# Manages game statistics UI elements, primarily the GirthCounter.

# --- Dependencies (injected by MainLayout) ---
var girth_counter_node # The GirthCounter scene instance

# --- Initialization ---
func initialize_manager(gc_node):
	girth_counter_node = gc_node
	if not is_instance_valid(girth_counter_node):
		push_error("GameStatsUIManager: GirthCounter node is invalid!")
	else:
		print("GameStatsUIManager: Initialized with GirthCounter: ", girth_counter_node.name)
		# Optionally, update the counter with the initial global value if needed here
		# if Global and girth_counter_node.has_method("update_girth"):
		# 	girth_counter_node.update_girth(Global.current_girth)

# --- Core UI Logic ---

# Updates the GirthCounter display.
func update_girth_display(value: int) -> void:
	if is_instance_valid(girth_counter_node) and girth_counter_node.has_method("update_girth"):
		girth_counter_node.update_girth(value)
	else:
		push_warning("GameStatsUIManager: GirthCounter node not set or lacks update_girth method.")

# --- Signal Handlers ---

# Connected to Global.girth_updated signal.
func _on_global_girth_updated(new_girth_value: int):
	# print("GameStatsUIManager: Received girth update from Global: ", new_girth_value)
	update_girth_display(new_girth_value) 