extends Control

# The roach scene to spawn
@export var roach_scene: PackedScene
# Path to the navigation regions, relative to this node
@export var nav_regions_path: String = ".."
# The Area2D node that defines an occlusion zone for despawning roaches
@export var occlusion_despawn_zone: Area2D 
# Spawn interval range
@export var min_spawn_interval: float = 5.0
@export var max_spawn_interval: float = 15.0
# How many roaches can exist at once
@export var max_roaches: int = 3
# Whether spawning is active
@export var spawning_active: bool = true
# Edge margin for spawning (distance beyond visible area)
@export var edge_spawn_margin: float = 50.0
# Debug drawing
@export var debug_draw: bool = false
# Screen bounds inset (makes the effective screen smaller for edge detection)
@export var screen_bounds_inset: float = 30.0

# Navigation regions (populated at runtime)
var nav_regions: Array[NavigationRegion2D] = []
# Timer for spawning
@onready var spawn_timer: Timer = $Timer
# Container for roaches
var roaches: Array = []
# Screen boundaries
var screen_bounds: Rect2
# Visual bounds for edge detection (with inset applied)
var visual_bounds: Rect2

func _ready():
	print("RoachSpawner: _ready() called")
	
	# Get all navigation regions from the specified path
	var regions_parent = get_node_or_null(nav_regions_path)
	if regions_parent:
		for child in regions_parent.get_children():
			if child is NavigationRegion2D and child.name.begins_with("RoachNavRegion"):
				nav_regions.append(child)
				print("RoachSpawner: Found navigation region: ", child.name)
	
	if nav_regions.is_empty():
		push_error("RoachSpawner: No navigation regions found at path: " + nav_regions_path)
		return
	else:
		print("RoachSpawner: Found " + str(nav_regions.size()) + " navigation regions")
	
	# Check roach scene
	if not roach_scene:
		push_error("RoachSpawner: No roach scene assigned!")
		return
	else:
		print("RoachSpawner: Roach scene assigned correctly")
	
	# Initialize screen boundaries
	_initialize_screen_bounds()
	
	# Setup timer
	if not spawn_timer:
		push_error("RoachSpawner: No Timer node found, creating one")
		spawn_timer = Timer.new()
		spawn_timer.name = "Timer"
		add_child(spawn_timer)
	
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	
	# Start spawning
	_set_random_spawn_time()
	spawn_timer.start()
	print("RoachSpawner: Timer started with initial wait time: ", spawn_timer.wait_time)
	
	# Test spawn immediately
	spawn_roach()

func _initialize_screen_bounds():
	# First, get the parent container (TapperPanelContainer) size
	var parent_container = get_parent()
	if parent_container and parent_container is Control:
		# Use the actual container size
		screen_bounds = Rect2(parent_container.global_position, parent_container.size)
		print("RoachSpawner: Using parent container for bounds: ", screen_bounds)
	else:
		# Fallback to viewport
		var viewport = get_viewport()
		if viewport:
			screen_bounds = Rect2(Vector2.ZERO, viewport.get_visible_rect().size)
			if get_parent():
				screen_bounds.position = get_parent().global_position
			print("RoachSpawner: Using viewport for bounds: ", screen_bounds)
		else:
			# Hardcoded fallback
			screen_bounds = Rect2(Vector2.ZERO, Vector2(640, 480))
			print("RoachSpawner: Using fallback bounds: ", screen_bounds)
	
	# Create the visual bounds with inset for edge detection
	visual_bounds = Rect2(
		screen_bounds.position.x + screen_bounds_inset,
		screen_bounds.position.y + screen_bounds_inset,
		screen_bounds.size.x - (2 * screen_bounds_inset),
		screen_bounds.size.y - (2 * screen_bounds_inset)
	)
	
	print("RoachSpawner: Visual bounds for edge detection: ", visual_bounds)

func _draw():
	if not debug_draw:
		return
	
	# Draw the screen bounds
	draw_rect(screen_bounds, Color(0, 1, 0, 0.2), false, 2.0)
	
	# Draw the visual bounds used for edge detection
	draw_rect(visual_bounds, Color(1, 0, 0, 0.2), false, 2.0)
	
	# Draw the navigation polygons
	for region in nav_regions:
		var nav_poly = region.navigation_polygon
		if nav_poly:
			for i in range(nav_poly.get_outline_count()):
				var outline = nav_poly.get_outline(i)
				var adjusted_outline = []
				
				# Adjust points for global position
				for point in outline:
					adjusted_outline.append(region.global_position + point)
				
				# Draw the outline
				if adjusted_outline.size() > 1:
					for j in range(adjusted_outline.size()):
						var next_idx = (j + 1) % adjusted_outline.size()
						draw_line(adjusted_outline[j], adjusted_outline[next_idx], Color(0, 0, 1, 0.5), 1.5)
	
	# Draw spawnable edge points
	for region in nav_regions:
		var edge_points = _get_all_edge_points(region)
		for point in edge_points:
			draw_circle(point, 3.0, Color(1, 1, 0, 0.8))

func _on_spawn_timer_timeout():
	print("RoachSpawner: Timer timeout, checking if should spawn")
	
	# Clean up roach list
	roaches = roaches.filter(func(r): return is_instance_valid(r))
	
	if spawning_active and roaches.size() < max_roaches:
		spawn_roach()
	else:
		print("RoachSpawner: Not spawning, active=", spawning_active, ", roach count=", roaches.size())
	
	# Reset timer for next spawn
	_set_random_spawn_time()
	spawn_timer.start()
	
	# Request redraw for debug visualization
	if debug_draw:
		queue_redraw()

func spawn_roach():
	if nav_regions.is_empty() or not roach_scene:
		push_error("RoachSpawner: Cannot spawn - missing regions or scene")
		return
	
	print("RoachSpawner: Attempting to spawn roach")
	
	# Try each navigation region until we find a valid spawn point
	var valid_regions = nav_regions.duplicate()
	while not valid_regions.is_empty():
		# Select a random region from the valid ones
		var region_index = randi() % valid_regions.size()
		var region = valid_regions[region_index]
		print("RoachSpawner: Trying region: ", region.name)
		
		# Find a spawn point at the edge
		var spawn_point = find_edge_spawn_point(region)
		if spawn_point == Vector2.ZERO:
			print("RoachSpawner: Could not find edge spawn point in " + region.name + ", trying fallback")
			spawn_point = find_fallback_spawn_point(region)
		
		if spawn_point != Vector2.ZERO:
			print("RoachSpawner: Found spawn point at ", spawn_point, " in region ", region.name)
			_spawn_roach_at_point(region, spawn_point)
			return
		
		# Remove this region from the valid list and try another
		valid_regions.remove_at(region_index)
	
	push_error("RoachSpawner: Failed to find any valid spawn point in any region")

func _spawn_roach_at_point(region: NavigationRegion2D, spawn_point: Vector2):
	print("RoachSpawner: Spawn position: ", spawn_point)
	
	# Instance and add the roach
	var roach = roach_scene.instantiate()
	roach.set_meta("nav_region", region)
	roach.set_meta("visual_bounds_for_exit", visual_bounds)
	if occlusion_despawn_zone:
		roach.set_meta("occlusion_area_node", occlusion_despawn_zone)
	else:
		push_warning("RoachSpawner: Occlusion Despawn Zone not set on Spawner!")
	
	# Add the roach to the scene
	add_child(roach)
	roach.global_position = spawn_point
	roaches.append(roach)
	
	# For the roach state, we need to use the proper enum constants
	# Since the Roach.State is not directly accessible here, we use numbers
	# Based on Roach.gd enum State { IDLE, WALK_RIGHT, WALK_LEFT, CLIMB_UP, CLIMB_DOWN }
	# Where IDLE=0, WALK_RIGHT=1, WALK_LEFT=2, CLIMB_UP=3, CLIMB_DOWN=4
	
	# Determine entering direction based on spawn position
	if spawn_point.x < visual_bounds.position.x:
		# If we're spawning from the left, make it walk right (1 = WALK_RIGHT)
		roach.set_state(1)
	elif spawn_point.x > visual_bounds.position.x + visual_bounds.size.x:
		# If we're spawning from the right, make it walk left (2 = WALK_LEFT)
		roach.set_state(2)
	elif spawn_point.y < visual_bounds.position.y:
		# If we're spawning from the top, make it climb down (4 = CLIMB_DOWN)
		roach.set_state(4)
	elif spawn_point.y > visual_bounds.position.y + visual_bounds.size.y:
		# If we're spawning from the bottom, make it climb up (3 = CLIMB_UP)
		roach.set_state(3)
	
	print("RoachSpawner: Roach spawned, ID: ", roach.get_instance_id())

# Get all edge points for a region (used for debugging)
func _get_all_edge_points(region: NavigationRegion2D) -> Array:
	if not region or not region.navigation_polygon:
		return []
	
	var nav_poly = region.navigation_polygon
	var edge_points = []
	
	# Check all points in the navigation polygon outline
	for i in range(nav_poly.get_outline_count()):
		var outline = nav_poly.get_outline(i)
		for point in outline:
			var world_point = region.global_position + point
			
			# Check if the point is outside the visual bounds (edge spawn)
			if is_point_outside_screen(world_point):
				edge_points.append(world_point)
	
	return edge_points

# Find a spawn point at the edge of the screen within the navigation region
func find_edge_spawn_point(region: NavigationRegion2D) -> Vector2:
	var edge_points = _get_all_edge_points(region)
	
	# If we found edge points, pick a random one
	if edge_points.size() > 0:
		return edge_points[randi() % edge_points.size()]
	
	return Vector2.ZERO

# Find a fallback spawn point if edge points aren't available
func find_fallback_spawn_point(region: NavigationRegion2D) -> Vector2:
	if not region or not region.navigation_polygon:
		return Vector2.ZERO
	
	# Try explicit edge creation on each side of the screen
	var nav_poly = region.navigation_polygon
	var sides = ["left", "right", "top", "bottom"]
	var valid_points = []
	
	# Shuffle sides to try them in random order
	sides.shuffle()
	
	for side in sides:
		var test_points = []
		
		# Generate several test points along this edge
		match side:
			"left":
				for i in range(10):
					var y_pos = visual_bounds.position.y + (visual_bounds.size.y * (i / 10.0))
					test_points.append(Vector2(visual_bounds.position.x - edge_spawn_margin, y_pos))
			"right":
				for i in range(10):
					var y_pos = visual_bounds.position.y + (visual_bounds.size.y * (i / 10.0))
					test_points.append(Vector2(visual_bounds.position.x + visual_bounds.size.x + edge_spawn_margin, y_pos))
			"top":
				for i in range(10):
					var x_pos = visual_bounds.position.x + (visual_bounds.size.x * (i / 10.0))
					test_points.append(Vector2(x_pos, visual_bounds.position.y - edge_spawn_margin))
			"bottom":
				for i in range(10):
					var x_pos = visual_bounds.position.x + (visual_bounds.size.x * (i / 10.0))
					test_points.append(Vector2(x_pos, visual_bounds.position.y + visual_bounds.size.y + edge_spawn_margin))
		
		# Check which points are inside the navigation mesh
		for point in test_points:
			var local_point = point - region.global_position
			for i in range(nav_poly.get_outline_count()):
				var outline = nav_poly.get_outline(i)
				if is_point_in_polygon(local_point, outline):
					valid_points.append(point)
					break
	
	# If we found valid points, return a random one
	if valid_points.size() > 0:
		return valid_points[randi() % valid_points.size()]
	
	# Last resort - check all vertices in the polygon for any outside the screen
	for i in range(nav_poly.get_outline_count()):
		var outline = nav_poly.get_outline(i)
		var outside_points = []
		
		for point in outline:
			var world_point = region.global_position + point
			if is_point_outside_screen(world_point):
				outside_points.append(world_point)
		
		if outside_points.size() > 0:
			return outside_points[randi() % outside_points.size()]
	
	return Vector2.ZERO

# Check if a point is outside the screen boundaries
func is_point_outside_screen(point: Vector2) -> bool:
	# Use visual bounds (inset from actual screen) for edge detection
	var left = point.x < visual_bounds.position.x
	var right = point.x > visual_bounds.position.x + visual_bounds.size.x
	var top = point.y < visual_bounds.position.y
	var bottom = point.y > visual_bounds.position.y + visual_bounds.size.y
	return left or right or top or bottom

# Check if a point is inside a polygon using ray casting algorithm
func is_point_in_polygon(point: Vector2, polygon: PackedVector2Array) -> bool:
	var inside = false
	var j = polygon.size() - 1
	
	for i in range(polygon.size()):
		if ((polygon[i].y > point.y) != (polygon[j].y > point.y)) and \
		   (point.x < (polygon[j].x - polygon[i].x) * (point.y - polygon[i].y) / \
		   (polygon[j].y - polygon[i].y) + polygon[i].x):
			inside = !inside
		j = i
	
	return inside

func get_roach_count() -> int:
	# Clean up the list first
	roaches = roaches.filter(func(r): return is_instance_valid(r))
	return roaches.size()

func _set_random_spawn_time():
	var interval = randf_range(min_spawn_interval, max_spawn_interval)
	spawn_timer.wait_time = interval
	print("RoachSpawner: Set next spawn time to ", interval, " seconds")

# Utility function to get a random point inside a navigation polygon
func get_random_point_in_navpoly(nav_poly: NavigationPolygon) -> Vector2:
	# If empty polygon, return zero
	if nav_poly.vertices.size() == 0:
		return Vector2.ZERO
	
	# Simple algorithm to get a point inside the polygon:
	# 1. Get the polygon outline
	var outline = nav_poly.get_outline(0)
	
	# 2. Calculate a bounding box
	var min_x = INF
	var min_y = INF
	var max_x = -INF
	var max_y = -INF
	
	for point in outline:
		min_x = min(min_x, point.x)
		min_y = min(min_y, point.y)
		max_x = max(max_x, point.x)
		max_y = max(max_y, point.y)
	
	# 3. Try random points in the bounding box until we find one inside the polygon
	var max_attempts = 30
	for _i in range(max_attempts):
		var random_point = Vector2(
			randf_range(min_x, max_x),
			randf_range(min_y, max_y)
		)
		
		# Test if the point is inside any outline of the navigation polygon
		if is_point_in_polygon(random_point, outline):
			return random_point
	
	# Fallback to a point along the outline
	return outline[randi() % outline.size()]

# Check if a point is on a vertical surface (roughly)
func is_point_on_vertical_surface(point: Vector2, nav_poly: NavigationPolygon) -> bool:
	# Get the outline
	var outline = nav_poly.get_outline(0)
	
	# Look for vertical segments close to the point
	var threshold = 5.0  # Distance threshold
	var j = outline.size() - 1
	
	for i in range(outline.size()):
		var p1 = outline[i]
		var p2 = outline[j]
		
		# Check if the segment is mostly vertical
		if abs(p1.x - p2.x) < 10.0 and abs(p1.y - p2.y) > 20.0:
			# Check if point is close to this vertical segment
			var dist = _point_to_segment_distance(point, p1, p2)
			if dist < threshold:
				return true
		
		j = i
	
	return false

# Helper to calculate distance from point to line segment
func _point_to_segment_distance(p: Vector2, v: Vector2, w: Vector2) -> float:
	var l2 = (v - w).length_squared()
	if l2 == 0.0:
		return (p - v).length()
	
	var t = max(0, min(1, (p - v).dot(w - v) / l2))
	var projection = v + t * (w - v)
	return (p - projection).length() 
