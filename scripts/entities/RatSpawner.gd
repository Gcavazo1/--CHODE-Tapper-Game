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

# Y-position for spawning rats. Adjust this in the inspector if rats spawn too high/low.
# Positive values move spawn point down, negative up, relative to the bottom of the spawner.
@export var y_position_offset: float = -10.0 # Default to 10px above the bottom edge


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
		if child is CharacterBody2D and child.is_in_group("rats"):
			count += 1
	return count

func _spawn_rat():
	# Check if we can spawn more rats
	if _get_active_rat_count() >= max_active_rats:
		return

	if not rat_scene:
		return

	var rat_instance = rat_scene.instantiate()
	
	# Add to rats group for collision detection
	rat_instance.add_to_group("rats")
	
	# Determine spawn edge (left or right) and initial direction
	var spawn_on_left_edge = randf() < 0.5
	
	# Get the rect of this spawner node in local coordinates
	var spawner_rect = get_rect()
	
	# Get the collision shape for accurate positioning
	var rat_collision_shape = rat_instance.get_node_or_null("CollisionShape2D")
	var rat_sprite = rat_instance.get_node_or_null("AnimatedSprite2D")
	
	var rat_body_half_width = 20.0  # Default fallback value
	var rat_sprite_half_height = 22.5 # Default based on 45px height
	
	if rat_collision_shape and rat_collision_shape.shape:
		rat_body_half_width = rat_collision_shape.shape.size.x / 2.0
	if rat_sprite and rat_sprite.sprite_frames:
		var frame_texture = rat_sprite.sprite_frames.get_frame_texture("walk", 0)
		if frame_texture:
			rat_sprite_half_height = frame_texture.get_height() / 2.0
			
	# Calculate spawn position to ensure rats are COMPLETELY off-screen
	var spawn_position = Vector2()
	
	if spawn_on_left_edge:
		rat_instance.direction = 1  # Move right
		# Position well outside the left edge 
		spawn_position.x = -rat_body_half_width - 30  # Extra margin to ensure off-screen
	else:
		rat_instance.direction = -1  # Move left
		# Position well outside the right edge
		spawn_position.x = spawner_rect.size.x + rat_body_half_width + 30  # Extra margin
	
	# Calculate Y position based on the bottom of the spawner
	spawn_position.y = spawner_rect.size.y - rat_sprite_half_height + y_position_offset
	
	# Set random speed and add to RatSpawner
	rat_instance.position = spawn_position
	rat_instance.speed = randf_range(min_rat_speed, max_rat_speed)
	
	# Add the rat as a child of this RatSpawner node
	add_child(rat_instance)

# Draw debug bounds (for editor only)
func _draw():
	if Engine.is_editor_hint():
		var rect = Rect2(Vector2.ZERO, size)
		# Draw spawn area bounds
		draw_rect(rect, Color.BLUE, false, 2.0)
