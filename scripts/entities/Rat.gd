extends CharacterBody2D

@export var speed = 100
# Direction will be set by a spawner, or defaults to 1 (right) if placed manually.
# 1 for right, -1 for left.
var direction = 1

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
# Use collision shape for a more accurate boundary for the rat's "body"
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var boundary_parent_global_rect: Rect2 = Rect2() # Initialize to an empty Rect

func _ready():
	# Attempt to get parent and its global_rect.
	# This is crucial for defining where the rat "lives".
	var parent_node = get_parent()
	if parent_node and parent_node.has_method("get_global_rect"):
		boundary_parent_global_rect = parent_node.get_global_rect()
	else:
		push_error("Rat needs a parent with get_global_rect() to define boundaries. Current parent: " + str(parent_node))
		# queue_free() # Optionally free if no valid boundary can be determined immediately.
		# Or, it might get reparented and then boundary_parent_global_rect can be updated. For now, we'll rely on _physics_process check.

	if direction == -1:
		animated_sprite.flip_h = true
	else:
		animated_sprite.flip_h = false
	
	animated_sprite.play("walk")

func _physics_process(delta):
	# If boundary_parent_global_rect is still empty, try to re-acquire it.
	# This handles cases where the rat might be added to the scene and reparented later.
	if boundary_parent_global_rect == Rect2():
		var parent_node = get_parent()
		if parent_node and parent_node.has_method("get_global_rect"):
			boundary_parent_global_rect = parent_node.get_global_rect()
		else:
			# Still no valid boundary, cannot proceed with movement logic safely.
			# push_warning("Rat has no valid boundary parent, movement and despawn logic paused.")
			return

	velocity.x = direction * speed
	move_and_slide()
	
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
