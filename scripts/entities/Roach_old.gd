extends CharacterBody2D

@onready var sprite: Sprite2D = $AnimatedSprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Roach states
enum State { IDLE, WALK_RIGHT, WALK_LEFT, CLIMB_UP, CLIMB_DOWN }
var current_state: State = State.WALK_RIGHT # Default state

# Roach behavior states
enum BehaviorState { ENTERING, WANDERING, EXITING, FLEEING }
var behavior_state: BehaviorState = BehaviorState.ENTERING

# Movement parameters (can be adjusted)
@export var SPEED: float = 50.0
@export var FLEE_SPEED_MULTIPLIER: float = 2.5 # How much faster the roach moves when fleeing
@export var GRAVITY: float = 980.0
@export var min_idle_time: float = 0.5
@export var max_idle_time: float = 3.0
@export var chance_to_change_direction: float = 0.2
@export var lifespan: float = 20.0 # Seconds before starting exit behavior
@export var path_recalculation_distance: float = 5.0 # Distance threshold to recalculate path
@export var wander_time_min: float = 10.0 # Minimum time to spend wandering
@export var wander_time_max: float = 15.0 # Maximum time to spend wandering
@export var flee_distance: float = 150.0 # How far away a tap must be to scare the roach

var _current_velocity = Vector2.ZERO
var nav_region: NavigationRegion2D  # Set via set_meta by spawner
var visual_bounds_for_exit: Rect2 # Set via set_meta by spawner, defines the "on-screen" area
var occlusion_area: Area2D # Will be set from metadata in _ready
var target_position: Vector2
var idle_timer: float = 0.0
var idle_duration: float = 0.0
var is_idle: bool = false
var life_timer: float = 0.0
var wander_duration: float = 0.0
var spawn_edge_position: Vector2 # Where the roach spawned (for debugging)

var _path_calculation_retries: int = 0
const MAX_PATH_CALCULATION_RETRIES: int = 3

# Screen boundaries for edge detection
var screen_bounds: Rect2
var screen_edge_margin: float = 50.0 # Distance beyond screen to consider as "edge"

# Navigation path variables
var current_path: PackedVector2Array = []
var current_path_index: int = 0
var path_update_timer: float = 0.0
var path_update_interval: float = 1.0 # Seconds between path recalculations

func _ready():
	# Debug sprite reference
	if not sprite:
		push_error("Roach: AnimatedSprite reference is null. Ensure node is named correctly.")
	
	if not animation_player:
		push_error("Roach: AnimationPlayer reference is null. Ensure node is named correctly.")
	
	# Setup animations and visuals
	_setup_animations()
	_update_visuals()
	
	# Get the navigation region assigned by the spawner
	if has_meta("nav_region"):
		nav_region = get_meta("nav_region")
	else:
		push_error("Roach: No navigation region assigned!")
	
	# Get the occlusion area if passed by the spawner
	if has_meta("occlusion_area_node"):
		occlusion_area = get_meta("occlusion_area_node")
		if not occlusion_area is Area2D:
			push_warning("Roach: occlusion_area_node passed from spawner is not an Area2D! Type: " + str(typeof(occlusion_area)))
			occlusion_area = null # Ensure it's null if type is wrong
		else:
			print("Roach: Successfully received occlusion_area_node from spawner.")

	if has_meta("visual_bounds_for_exit"):
		visual_bounds_for_exit = get_meta("visual_bounds_for_exit")
	else:
		# Fallback if not passed, but spawner should always pass this
		var current_viewport = get_viewport()
		if current_viewport:
			visual_bounds_for_exit = Rect2(Vector2.ZERO, current_viewport.get_visible_rect().size)
			if get_parent():
				visual_bounds_for_exit.position = get_parent().global_position
		else:
			visual_bounds_for_exit = Rect2(Vector2.ZERO, Vector2(640,480))
		push_warning("Roach: visual_bounds_for_exit not passed from spawner, using fallback.")

	# Initialize screen boundaries (based on TapperCenter size)
	var viewport = get_viewport()
	if viewport:
		screen_bounds = Rect2(Vector2.ZERO, viewport.get_visible_rect().size)
		# Adjust based on position in the scene hierarchy
		if get_parent():
			var parent_global_pos = get_parent().global_position
			screen_bounds.position = parent_global_pos
	else:
		# Fallback default size if viewport can't be determined
		screen_bounds = Rect2(Vector2.ZERO, Vector2(640, 480))
	
	# Store initial spawn position for edge validation
	spawn_edge_position = global_position
	
	# Set initial behavior state
	behavior_state = BehaviorState.ENTERING
	
	# Initialize wander duration
	wander_duration = randf_range(wander_time_min, wander_time_max)
	
	# Set first target inside the visible area
	_set_target_inside_screen()
	
	# Start the life timer
	life_timer = lifespan
	
	# Connect to tap signals from TapperArea
	var tapper_area = _find_tapper_area()
	if tapper_area and tapper_area.has_signal("tapped"):
		tapper_area.connect("tapped", _on_tapper_area_tapped)
	
	# Print debug info
	print("Roach: Ready at position ", global_position, " with state ", current_state, " and behavior ", behavior_state)

func _physics_process(delta):
	# Update life timer
	life_timer -= delta
	
	# State transitions based on lifecycle
	match behavior_state:
		BehaviorState.ENTERING:
			# Once we've reached our first target inside the screen, switch to wandering
			if current_path_index >= current_path.size():
				behavior_state = BehaviorState.WANDERING
				print("Roach: Transitioned to WANDERING behavior")
				_set_random_target_inside_screen()
		
		BehaviorState.WANDERING:
			# If we've wandered long enough, start exiting
			if life_timer <= 0:
				behavior_state = BehaviorState.EXITING
				print("Roach: Transitioned to EXITING behavior")
				_set_target_outside_screen()
		
		BehaviorState.EXITING, BehaviorState.FLEEING:
			# Check if we've reached our exit point OR if we are in an occlusion zone
			if current_path_index >= current_path.size():
				# We've reached the exit point, despawn
				print("Roach: Reached exit target, despawning")
				queue_free()
				return
			
			# Check for occlusion area despawn
			if occlusion_area and occlusion_area.get_overlapping_bodies().has(self):
				print("Roach: Inside occlusion area, despawning")
				queue_free()
				return
	
	# Handle idle state
	if is_idle:
		idle_timer += delta
		if idle_timer >= idle_duration:
			is_idle = false
			_pick_target_based_on_behavior()
		return
	
	# Update path timer
	path_update_timer += delta
	if path_update_timer >= path_update_interval:
		path_update_timer = 0.0
		# Periodically recalculate path to stay within navigation region
		if target_position != Vector2.ZERO:
			_calculate_path_to_target()
	
	# If we have a valid path and not at the end
	if current_path.size() > 0 and current_path_index < current_path.size():
		# Get next point in path
		var next_point = current_path[current_path_index]
		
		# Calculate direction to next point
		var direction = (next_point - global_position).normalized()
		
		# Determine state based on direction vector
		_update_state_from_direction(direction)
		
		# Set velocity based on state
		_set_velocity_from_state()
		
		# Check if reached current path point
		if global_position.distance_to(next_point) < path_recalculation_distance:
			current_path_index += 1
			
			# If reached end of path
			if current_path_index >= current_path.size():
				_on_target_reached()
	else:
		# No path or at end of path
		_pick_target_based_on_behavior()
	
	# Apply movement
	velocity = _current_velocity
	var collision = move_and_slide()
	
	# If we collided with something, recalculate path
	if collision:
		_pick_target_based_on_behavior()
	
	# Update visuals after movement
	_update_visuals()

# Find the TapperArea in the scene
func _find_tapper_area():
	var tapper_center = get_parent()
	if tapper_center.has_node("TapperPanelContainer/TapperCenterNode2D/TapperArea"):
		return tapper_center.get_node("TapperPanelContainer/TapperCenterNode2D/TapperArea")
	
	# Fallback: search for any TapperArea in the scene
	var possible_areas = get_tree().get_nodes_in_group("tapper_areas")
	if possible_areas.size() > 0:
		return possible_areas[0]
	
	return null

# Handle tap events from TapperArea
func _on_tapper_area_tapped(tap_position):
	# Check if tap is close enough to scare the roach
	var distance_to_tap = global_position.distance_to(tap_position)
	
	if distance_to_tap < flee_distance:
		# Roach is scared, flee to the nearest edge
		behavior_state = BehaviorState.FLEEING
		
		# Set target to nearest edge point
		_set_flee_target(tap_position)
		
		# Debug
		print("Roach: Fleeing from tap at ", tap_position, ", distance: ", distance_to_tap)

# Set a flee target away from the tap position
func _set_flee_target(tap_position):
	# Calculate flee direction (away from tap)
	var flee_direction = (global_position - tap_position).normalized()
	
	var best_edge_point = Vector2.ZERO
	var best_score = -INF  # We want to maximize this score (dot product)
	
	var potential_flee_points = []
	if nav_region:
		var nav_poly = nav_region.navigation_polygon
		if nav_poly:
			for i in range(nav_poly.get_outline_count()):
				var outline = nav_poly.get_outline(i)
				for point_index in range(outline.size()):
					var local_point = outline[point_index]
					var world_point = nav_region.global_position + local_point
					# Consider points that are outside the main visual area as potential flee targets
					if not visual_bounds_for_exit.has_point(world_point):
						potential_flee_points.append(world_point)
	
	if potential_flee_points.size() > 0:
		for point in potential_flee_points:
			var direction_to_point = (point - global_position).normalized()
			# Calculate dot product: higher value means the point is more aligned with flee_direction
			var score = flee_direction.dot(direction_to_point)
			
			# Optional: Add a small penalty for distance to avoid choosing extremely far points if directions are similar
			# score -= global_position.distance_to(point) * 0.001 
			
			if score > best_score:
				best_score = score
				best_edge_point = point
	else:
		push_warning("Roach: Fleeing, but no navmesh edge points found outside visual_bounds. This may indicate a navmesh setup issue.")
	
	if best_edge_point != Vector2.ZERO:
		target_position = best_edge_point
		_calculate_path_to_target()
		print("Roach: Fleeing to navmesh edge: ", target_position)
	else:
		# Fallback: If no suitable edge point was found (e.g., roach is trapped or navmesh is too small),
		# try to move far away in the flee_direction. This might lead roach off navmesh.
		var fallback_distance = visual_bounds_for_exit.size.length() * 0.75 # A considerable distance
		var fallback_target = global_position + (flee_direction * fallback_distance)
		
		target_position = fallback_target
		_calculate_path_to_target()
		print("Roach: Fleeing to fallback target: ", fallback_target)

# Pick a target based on current behavior state
func _pick_target_based_on_behavior():
	match behavior_state:
		BehaviorState.ENTERING:
			_set_target_inside_screen()
		BehaviorState.WANDERING:
			_set_random_target_inside_screen()
		BehaviorState.EXITING, BehaviorState.FLEEING:
			_set_target_outside_screen()

# Set a target point inside the visible screen area
func _set_target_inside_screen():
	# Make sure the target is within the visual_bounds_for_exit
	var inner_margin = 30.0  # Margin from screen edge
	var target_rect = Rect2(
		visual_bounds_for_exit.position.x + inner_margin,
		visual_bounds_for_exit.position.y + inner_margin,
		visual_bounds_for_exit.size.x - 2 * inner_margin,
		visual_bounds_for_exit.size.y - 2 * inner_margin
	)
	
	_set_random_target_in_rect(target_rect)

# Set a target point outside the visible screen
func _set_target_outside_screen():
	# Find an exit point beyond the visual_bounds_for_exit edge but still on the navmesh
	var exit_points = []
	
	if nav_region:
		var nav_poly = nav_region.navigation_polygon
		if nav_poly:
			for i in range(nav_poly.get_outline_count()): 
				var outline = nav_poly.get_outline(i)
				
				# Find points on the outline that are outside visual_bounds_for_exit
				for point_index in range(outline.size()):
					var local_point = outline[point_index]
					var world_point = nav_region.global_position + local_point
					
					# Check if this point is outside the main visual area
					if not visual_bounds_for_exit.has_point(world_point):
						# This point is outside, add it to exit points
						exit_points.append(world_point)
	
	if exit_points.size() > 0:
		# Pick a random exit point from the valid ones
		target_position = exit_points[randi() % exit_points.size()]
		_calculate_path_to_target()
		print("Roach: Set exit target to navmesh edge: ", target_position)
	else:
		# Fallback: If no suitable edge points on navmesh are found outside visual_bounds,
		# try to pick a point far away in a general direction.
		push_warning("Roach: Could not find navmesh edge point outside visual_bounds for exiting. Using fallback.")
		var fallback_target = global_position
		var random_angle = randf_range(0, TAU)
		fallback_target += Vector2(cos(random_angle), sin(random_angle)) * (screen_edge_margin * 5) # Move far away
		
		target_position = fallback_target
		_calculate_path_to_target()

# Set a random target inside the visible screen
func _set_random_target_inside_screen():
	_set_target_inside_screen()

# Check if a position is within the screen boundaries
func _is_position_on_screen(pos: Vector2, margin: float = 0) -> bool:
	var check_rect = visual_bounds_for_exit
	if margin != 0:
		check_rect = visual_bounds_for_exit.grow(margin) # grow can take negative margin
	return check_rect.has_point(pos)

# Update state based on movement direction
func _update_state_from_direction(direction: Vector2):
	# Only change state if direction is significant
	if direction.length() < 0.1:
		return
		
	# Determine if movement is more horizontal or vertical
	if abs(direction.x) > abs(direction.y):
		# Horizontal movement
		if direction.x > 0 and current_state != State.WALK_RIGHT:
			set_state(State.WALK_RIGHT)
		elif direction.x < 0 and current_state != State.WALK_LEFT:
			set_state(State.WALK_LEFT)
	else:
		# Vertical movement
		if direction.y < 0 and current_state != State.CLIMB_UP:
			set_state(State.CLIMB_UP)
		elif direction.y > 0 and current_state != State.CLIMB_DOWN:
			set_state(State.CLIMB_DOWN)

# Set velocity based on current state
func _set_velocity_from_state():
	# Base speed depends on if we're fleeing or not
	var speed = SPEED
	if behavior_state == BehaviorState.FLEEING:
		speed *= FLEE_SPEED_MULTIPLIER
	
	match current_state:
		State.WALK_RIGHT:
			_current_velocity.x = speed
			_current_velocity.y = 0
		State.WALK_LEFT:
			_current_velocity.x = -speed
			_current_velocity.y = 0
		State.CLIMB_UP:
			_current_velocity.y = -speed
			_current_velocity.x = 0
		State.CLIMB_DOWN:
			_current_velocity.y = speed
			_current_velocity.x = 0
		State.IDLE:
			_current_velocity = Vector2.ZERO

func _apply_gravity(delta):
	# Roaches should generally ignore gravity, as they stick to surfaces
	# This function is kept minimal in case we want special gravity behavior later
	
	# Only apply minor gravity if we're in a walking state AND not on a floor AND gravity is set
	if GRAVITY > 0 and (current_state == State.WALK_LEFT or current_state == State.WALK_RIGHT):
		# Apply very minimal gravity - roaches shouldn't fall fast
		_current_velocity.y += (GRAVITY * 0.1) * delta
	
	# Clamp vertical velocity to avoid excessive falling
	_current_velocity.y = clamp(_current_velocity.y, -SPEED * 1.5, SPEED * 1.5)

func _setup_animations():
	# Skip if animation player is null
	if not animation_player:
		return
	
	# Create a new animation library (Godot 4 method)
	var anim_lib = AnimationLibrary.new()
	
	# Create the walk animation
	if not animation_player.has_animation("walk"):
		var walk_anim = Animation.new()
		walk_anim.loop_mode = Animation.LOOP_LINEAR
		walk_anim.length = 1.2 # 12 frames * 0.1s per frame
		
		# Add track for frame
		var track_idx = walk_anim.add_track(Animation.TYPE_VALUE)
		walk_anim.track_set_path(track_idx, "AnimatedSprite:frame")
		
		# Add keyframes for the 12 frames
		for i in range(12):
			walk_anim.track_insert_key(track_idx, i * 0.1, i)
		
		# Add to library
		anim_lib.add_animation("walk", walk_anim)
	
	# Create the idle animation
	if not animation_player.has_animation("idle"):
		var idle_anim = Animation.new()
		idle_anim.loop_mode = Animation.LOOP_LINEAR
		idle_anim.length = 0.1
		
		var track_idx_idle = idle_anim.add_track(Animation.TYPE_VALUE)
		idle_anim.track_set_path(track_idx_idle, "AnimatedSprite:frame")
		idle_anim.track_insert_key(track_idx_idle, 0.0, 0) # Use frame 0 for idle
		
		# Add to library
		anim_lib.add_animation("idle", idle_anim)
	
	# Add the library to the animation player
	animation_player.add_animation_library("roach_animations", anim_lib)
	
	# Play default animation
	animation_player.play("roach_animations/walk")

func _update_visuals():
	# Skip if sprite is null
	if not sprite or not animation_player:
		return
	
	match current_state:
		State.WALK_RIGHT:
			sprite.flip_h = false
			sprite.rotation_degrees = 0
			if animation_player.current_animation != "roach_animations/walk": 
				animation_player.play("roach_animations/walk")
		State.WALK_LEFT:
			sprite.flip_h = true
			sprite.rotation_degrees = 0
			if animation_player.current_animation != "roach_animations/walk": 
				animation_player.play("roach_animations/walk")
		State.CLIMB_UP:
			sprite.flip_h = false
			sprite.rotation_degrees = -90
			if animation_player.current_animation != "roach_animations/walk": 
				animation_player.play("roach_animations/walk")
		State.CLIMB_DOWN:
			sprite.flip_h = false
			sprite.rotation_degrees = 90
			if animation_player.current_animation != "roach_animations/walk": 
				animation_player.play("roach_animations/walk")
		State.IDLE:
			sprite.flip_h = false
			sprite.rotation_degrees = 0
			if animation_player.current_animation != "roach_animations/idle": 
				animation_player.play("roach_animations/idle")

# Public function to change the roach's state
func set_state(new_state: State):
	if current_state != new_state:
		current_state = new_state
		# Reset velocity when changing state to avoid carry-over if needed by game logic
		_current_velocity = Vector2.ZERO 
		_update_visuals() # Update immediately on state change

# Set a random target in a specific rectangle area
func _set_random_target_in_rect(rect: Rect2):
	if not nav_region:
		push_error("Roach: No navigation region assigned for target selection")
		return
	
	var nav_poly = nav_region.navigation_polygon
	if not nav_poly:
		push_error("Roach: Navigation region has no polygon")
		return
	
	# Try to find a valid point inside both the navigation polygon and the specified rectangle
	var found_point = false
	var attempts = 0
	var point = Vector2.ZERO
	var world_point = Vector2.ZERO
	var max_attempts = 50
	
	while not found_point and attempts < max_attempts:
		# Generate a random point in the rect
		point = Vector2(
			randf_range(rect.position.x, rect.position.x + rect.size.x),
			randf_range(rect.position.y, rect.position.y + rect.size.y)
		)
		
		# Convert to local space for the navigation polygon
		var local_point = point - nav_region.global_position
		
		# Check if this point is inside the navigation polygon
		if _is_point_in_polygon(local_point, nav_poly):
			found_point = true
			world_point = point
		
		attempts += 1
	
	if found_point:
		target_position = world_point
		_calculate_path_to_target()
	else:
		# Fallback: try to get any valid point in the navigation polygon
		_set_random_target()

# Function to set a random target within the navigation region
func _set_random_target():
	if not nav_region:
		push_error("Roach: No navigation region assigned for target selection")
		return
	
	var nav_poly = nav_region.navigation_polygon
	if not nav_poly:
		push_error("Roach: Navigation region has no polygon")
		return
	
	# Try to get a point within the navigation polygon
	var outline = nav_poly.get_outline(0)
	if outline.size() == 0:
		push_error("Roach: Navigation polygon has no outline")
		return
	
	# Calculate bounding box of the outline
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for point in outline:
		min_x = min(min_x, point.x)
		min_y = min(min_y, point.y)
		max_x = max(max_x, point.x)
		max_y = max(max_y, point.y)
	
	# Try to find a valid point inside the polygon
	var found_point = false
	var attempts = 0
	var point = Vector2.ZERO
	
	while not found_point and attempts < 30:
		point = Vector2(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y)
		)
		
		# Check if point is inside polygon
		if _is_point_in_polygon(point, nav_poly):
			found_point = true
		else:
			attempts += 1
	
	# If we couldn't find a point inside, use a point from the outline
	if not found_point:
		point = outline[randi() % outline.size()]
	
	# Set as target (converting from local polygon coordinates to global)
	target_position = nav_region.global_position + point
	
	# Calculate a path to the target
	_calculate_path_to_target()

# Check if a point is inside a navigation polygon
func _is_point_in_polygon(point: Vector2, nav_poly: NavigationPolygon) -> bool:
	for i in range(nav_poly.get_outline_count()):
		var outline = nav_poly.get_outline(i)
		if _is_point_in_polygon_outline(point, outline):
			return true
	return false

# Check if a point is inside a polygon outline using ray casting algorithm
func _is_point_in_polygon_outline(point: Vector2, polygon: PackedVector2Array) -> bool:
	var inside = false
	var j = polygon.size() - 1
	
	for i in range(polygon.size()):
		if ((polygon[i].y > point.y) != (polygon[j].y > point.y)) and \
		   (point.x < (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) / \
		   (polygon[j].y - polygon[i].y) + polygon[i].x):
			inside = !inside
		j = i
	
	return inside

# Calculate a path from current position to target position
func _calculate_path_to_target():
	if not nav_region:
		print("Roach: Cannot calculate path, nav_region is null. Roach ID: ", get_instance_id())
		_path_calculation_retries += 1
		if _path_calculation_retries > MAX_PATH_CALCULATION_RETRIES:
			print("Roach: Exceeded retries due to null nav_region. Despawning. Roach ID: ", get_instance_id())
			queue_free()
			return
		if behavior_state != BehaviorState.EXITING and behavior_state != BehaviorState.FLEEING:
			_pick_target_based_on_behavior()
		else:
			queue_free()
		return

	if target_position == Vector2.ZERO: # Check if target_position is valid
		print("Roach: Cannot calculate path, target_position is Vector2.ZERO. Roach ID: ", get_instance_id())
		_path_calculation_retries += 1
		if _path_calculation_retries > MAX_PATH_CALCULATION_RETRIES:
			print("Roach: Exceeded retries due to zero target_position. Despawning. Roach ID: ", get_instance_id())
			queue_free()
			return
		if behavior_state != BehaviorState.EXITING and behavior_state != BehaviorState.FLEEING:
			_pick_target_based_on_behavior()
		else:
			queue_free()
		return

	# Get the navigation map ID
	var map_rid = nav_region.get_world_2d().get_navigation_map()
	if not map_rid.is_valid():
		print("Roach: Cannot calculate path, nav_region returned invalid map_rid. Roach ID: ", get_instance_id())
		_path_calculation_retries += 1
		if _path_calculation_retries > MAX_PATH_CALCULATION_RETRIES:
			print("Roach: Exceeded retries due to invalid map_rid. Despawning. Roach ID: ", get_instance_id())
			queue_free()
			return
		if behavior_state != BehaviorState.EXITING and behavior_state != BehaviorState.FLEEING:
			_pick_target_based_on_behavior()
		else:
			queue_free()
		return
	
	# Calculate the path using NavigationServer2D
	current_path = NavigationServer2D.map_get_path(
		map_rid,
		global_position,
		target_position,
		true  # optimize path
	)
	
	# Reset path index
	current_path_index = 0
	
	# Debug output
	if current_path.size() > 0:
		# print("Roach: Path calculated with ", current_path.size(), " points. Retries reset. Roach ID: ", get_instance_id()) # Optional: reduce verbose logging
		_path_calculation_retries = 0 # Reset on success
	else:
		print("Roach: Failed to calculate path from ", global_position, " to ", target_position, ". Attempt: ", _path_calculation_retries + 1, ". Roach ID: ", get_instance_id())
		_path_calculation_retries += 1
		if _path_calculation_retries > MAX_PATH_CALCULATION_RETRIES:
			print("Roach: Exceeded max path calculation retries. Despawning. Roach ID: ", get_instance_id())
			queue_free()
			return

		# If path calculation failed, try a new target or despawn
		if behavior_state == BehaviorState.EXITING or behavior_state == BehaviorState.FLEEING:
			# If we're trying to exit, just despawn if we can't find a path
			print("Roach: Exiting/Fleeing and failed to calculate path. Despawning. Roach ID: ", get_instance_id())
			queue_free()
		else:
			print("Roach: Retrying to pick a new target. Roach ID: ", get_instance_id())
			_pick_target_based_on_behavior()

# Function to handle reaching the target
func _on_target_reached():
	# Handle target reached differently based on behavior state
	match behavior_state:
		BehaviorState.ENTERING:
			# We've reached our entry target, switch to wandering
			behavior_state = BehaviorState.WANDERING
			_set_random_target_inside_screen()
		
		BehaviorState.WANDERING:
			# Chance to go idle for a while
			if randf() < 0.4:  # 40% chance
				set_state(State.IDLE)
				is_idle = true
				idle_timer = 0.0
				idle_duration = randf_range(min_idle_time, max_idle_time)
			else:
				# Set a new random target inside screen
				_set_random_target_inside_screen()
		
		BehaviorState.EXITING, BehaviorState.FLEEING:
			# We've reached our exit target, despawn
			queue_free()
