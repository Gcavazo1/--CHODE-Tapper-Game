extends Control

# Scene to instance for the rats
@export var rat_scene: PackedScene

# Timer for spawning rats
@onready var spawn_timer: Timer = $Timer # Assumes a child node named "Timer"

# Min/max time between rat spawns (in seconds)
@export var min_spawn_interval: float = 3.0
@export var max_spawn_interval: float = 8.0

# Min/max speed for spawned rats
@export var min_rat_speed: float = 50.0
@export var max_rat_speed: float = 120.0

# Maximum number of rats allowed on screen at once from this spawner
@export var max_active_rats: int = 3

# Y-position offset for spawning rats. Adjust this in the inspector if rats spawn too high/low.
# Positive values move spawn point down, negative up.
@export var y_offset: float = 0.0


func _ready():
	if not rat_scene:
		push_error("RatSpawner: Rat Scene is not set in the inspector!")
		set_process(false) # Disable spawner if scene not set
		return

	if not spawn_timer:
		push_error("RatSpawner: Spawn Timer node not found or not assigned. Ensure a Timer node named 'Timer' is a child.")
		set_process(false)
		return
	
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	_schedule_next_spawn()

func _on_spawn_timer_timeout():
	_spawn_rat()
	_schedule_next_spawn()

func _schedule_next_spawn():
	var interval = randf_range(min_spawn_interval, max_spawn_interval)
	spawn_timer.start(interval)

func _get_active_rat_count() -> int:
	var count = 0
	for child in get_children():
		if child is CharacterBody2D and child.is_in_group("rats"): # Assuming rats will be added to a group "rats"
			count += 1
	return count

func _spawn_rat():
	# Check if we can spawn more rats
	if get_child_count() -1 >= max_active_rats: # -1 because the Timer is also a child
		#print("Max rats reached, skipping spawn.")
		return

	if not rat_scene:
		return

	var rat_instance = rat_scene.instantiate()
	
	# Determine spawn edge (left or right) and initial direction
	var spawn_on_left_edge = randf() < 0.5
	
	# Get the global rect of this spawner node (which should fill TapperCenter)
	var spawner_global_rect = get_global_rect()
	
	# Use collision shape for a more accurate body size for positioning
	# This assumes the Rat scene has a CollisionShape2D node we can inspect, which is a good practice.
	# We access it from the packed scene's root node before it's added to the tree.
	var rat_collision_shape_node = rat_instance.get_node_or_null("CollisionShape2D")
	var rat_body_half_width = 0.0
	if rat_collision_shape_node and rat_collision_shape_node.shape:
		# Note: global_scale won't be accurate until added to tree and scaled. 
		# Assume default scale or small enough that unscaled is fine for spawn positioning.
		rat_body_half_width = (rat_collision_shape_node.shape.size.x / 2.0)
	else:
		push_warning("RatSpawner: Could not determine rat body width for precise spawning. Rat might pop in.")

	var spawn_position = Vector2()
	
	if spawn_on_left_edge:
		rat_instance.direction = 1 # Move right
		spawn_position.x = spawner_global_rect.position.x - rat_body_half_width - 5 # Spawn just off the left edge
	else:
		rat_instance.direction = -1 # Move left
		spawn_position.x = spawner_global_rect.end.x + rat_body_half_width + 5 # Spawn just off the right edge
	
	# Spawn near the bottom of the spawner area, adjusted by y_offset
	# The spawner (Control node) is set to Full Rect, so its size.y covers TapperCenter's height.
	# Its global_position.y will be the top of TapperCenter.
	spawn_position.y = spawner_global_rect.position.y + spawner_global_rect.size.y - (rat_instance.get_node("AnimatedSprite2D").sprite_frames.get_frame_texture("walk",0).get_height() / 2.0) + y_offset

	rat_instance.global_position = spawn_position
	rat_instance.speed = randf_range(min_rat_speed, max_rat_speed)
	
	# Add the rat as a child of this RatSpawner node.
	# The rat's script will use this node (its parent) for boundary checks.
	add_child(rat_instance)
	# Optionally, add to a group for easier counting or management if needed elsewhere
	# rat_instance.add_to_group("rats") 


# Ensure the spawner is in the correct position relative to the area it should fill.
# This is mostly for debugging if you see rats spawning in weird places.
func _draw():
	#pass # Uncomment to draw a debug rectangle
	#draw_rect(Rect2(Vector2.ZERO, size), Color.BLUE, false, 2.0)
	pass 