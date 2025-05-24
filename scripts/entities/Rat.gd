extends CharacterBody2D

@export var speed = 100
# Direction will be set by a spawner, or defaults to 1 (right) if placed manually.
# 1 for right, -1 for left.
var direction = 1

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
# Use collision shape for a more accurate boundary for the rat's "body"
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var boundary_parent_global_rect: Rect2 = Rect2() # Initialize to an empty Rect
var following_rat: CharacterBody2D = null
var direction_change_cooldown: float = 0.0 # Cooldown to prevent rapid, back-and-forth direction changes

func _ready():
	# Attempt to get parent and its global_rect.
	# This is crucial for defining where the rat "lives".
	var parent_node = get_parent()
	if parent_node and parent_node.has_method("get_global_rect"):
		boundary_parent_global_rect = parent_node.get_global_rect()
	else:
		push_error("Rat needs a parent with get_global_rect() to define boundaries. Current parent: " + str(parent_node))

	# Set initial sprite direction
	update_sprite_direction()
	
	animated_sprite.play("walk")

func _physics_process(delta):
	# Update cooldowns
	if direction_change_cooldown > 0:
		direction_change_cooldown -= delta
		
	# If boundary_parent_global_rect is still empty, try to re-acquire it.
	if boundary_parent_global_rect == Rect2():
		var parent_node = get_parent()
		if parent_node and parent_node.has_method("get_global_rect"):
			boundary_parent_global_rect = parent_node.get_global_rect()
		else:
			return

	# If following a rat, match its direction and stay behind
	if following_rat and is_instance_valid(following_rat):
		follow_behavior(delta)
	else:
		# Normal movement
		velocity.x = direction * speed
		move_and_slide()
		# Check for collisions after moving
		check_rat_collisions_after_move()
	
	# Check if we need to despawn
	check_despawn_conditions()

func check_rat_collisions_after_move():
	# If already following, or on cooldown, don't process new collisions
	if following_rat != null or direction_change_cooldown > 0:
		return

	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		if collision and collision.get_collider() is CharacterBody2D:
			var other_rat = collision.get_collider()
			# Ensure it's another rat and they are moving towards each other
			if other_rat.is_in_group("rats") and other_rat != self and other_rat.direction != self.direction:
				# Head-on collision detected
				# One rat reverses, the other attempts to follow
				# Make this rat the one that reverses direction
				self.direction *= -1
				self.update_sprite_direction()
				self.direction_change_cooldown = 1.0 # Cooldown for self
				
				# Make the other rat try to follow this one
				if other_rat.has_method("attempt_follow"):
					other_rat.attempt_follow(self)
				break # Process one collision at a time

# Public method for another rat to call to initiate following
func attempt_follow(leader_rat: CharacterBody2D):
	# Only follow if not already following and not on direction change cooldown
	if following_rat == null and direction_change_cooldown <= 0 and is_instance_valid(leader_rat):
		following_rat = leader_rat
		direction = leader_rat.direction # Match leader's current direction
		update_sprite_direction()
		speed = leader_rat.speed * randf_range(0.85, 0.95) # Slightly slower
		direction_change_cooldown = 0.5 # Short cooldown to settle into following

func update_sprite_direction():
	if direction == -1:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false

func follow_behavior(delta):
	if not is_instance_valid(following_rat):
		following_rat = null
		speed = randf_range(80, 120) # Reset to a random normal speed
		return

	if following_rat.direction != direction: # Leader changed direction
		direction = following_rat.direction
		update_sprite_direction()

	var follow_distance = 40.0 # Increased follow distance slightly
	var target_pos_x = following_rat.global_position.x - (follow_distance * direction)
	var distance_to_target = target_pos_x - global_position.x

	if abs(distance_to_target) > 5:
		velocity.x = sign(distance_to_target) * speed
	else:
		velocity.x = direction * following_rat.speed * 0.9 # Maintain slightly slower speed
	
	move_and_slide()

	if global_position.distance_to(following_rat.global_position) > 150: # Increased breakaway distance
		following_rat = null
		speed = randf_range(80, 120) # Reset to a random normal speed

func check_despawn_conditions():
	# Use the collision shape's width and global scale for a more accurate body size.
	var rat_body_width = collision_shape.shape.size.x * collision_shape.global_scale.x
	var rat_global_x = global_position.x
	
	var off_screen = false
	if direction == 1: # Moving right
		# Despawn if the rat's LEFT edge is beyond the parent's RIGHT edge.
		if (rat_global_x - rat_body_width / 2.0) > boundary_parent_global_rect.end.x:
			off_screen = true
	else: # Moving left (direction == -1)
		# Despawn if the rat's RIGHT edge is before the parent's LEFT edge.
		if (rat_global_x + rat_body_width / 2.0) < boundary_parent_global_rect.position.x:
			off_screen = true
			
	if off_screen:
		queue_free() 
