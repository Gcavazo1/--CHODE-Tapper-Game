extends CharacterBody2D

@onready var sprite: Sprite2D = $AnimatedSprite
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# Roach states
enum State { IDLE, WALK_RIGHT, WALK_LEFT, CLIMB_UP, CLIMB_DOWN }
var current_state: State = State.WALK_RIGHT # Default state

# Movement parameters (can be adjusted)
const SPEED = 50.0
const GRAVITY = 980.0
var _current_velocity = Vector2.ZERO

func _ready():
	_setup_animations()
	_update_visuals()
	# Start walking by default
	if animation_player.has_animation("walk"):
		animation_player.play("walk")

func _physics_process(delta):
	# Basic movement logic (example - replace with actual movement control)
	match current_state:
		State.WALK_RIGHT:
			_current_velocity.x = SPEED
			_apply_gravity(delta)
		State.WALK_LEFT:
			_current_velocity.x = -SPEED
			_apply_gravity(delta)
		State.CLIMB_UP:
			_current_velocity.y = -SPEED
			_current_velocity.x = 0 # No horizontal movement when climbing
		State.CLIMB_DOWN:
			_current_velocity.y = SPEED
			_current_velocity.x = 0 # No horizontal movement when climbing
		State.IDLE:
			_current_velocity.x = 0
			_apply_gravity(delta)

	velocity = _current_velocity
	move_and_slide()
	_update_visuals() # Update visuals after movement

func _apply_gravity(delta):
	# Simplified gravity for walking states
	if not is_on_floor() and (current_state == State.WALK_LEFT or current_state == State.WALK_RIGHT or current_state == State.IDLE):
		_current_velocity.y += GRAVITY * delta
	else:
		_current_velocity.y = 0 # Reset y velocity if on floor or climbing

func _setup_animations():
	# Create the walk animation if it doesn't exist
	if not animation_player.has_animation("walk"):
		var anim = Animation.new()
		anim.loop_mode = Animation.LOOP_LINEAR
		anim.length = 1.2 # 12 frames * 0.1s per frame
		var track_idx = anim.add_track(Animation.TYPE_VALUE)
		anim.track_set_path(track_idx, "AnimatedSprite:frame")

		# Add keyframes for the 12 frames (A1-A4, B1-B4, C1-C4)
		# Sprite sheet has 4 columns (hframes=4)
		# Frame numbers are calculated as: row_index * hframes + col_index
		# A1-A4 are frames 0-3
		# B1-B4 are frames 4-7
		# C1-C4 are frames 8-11
		for i in range(12):
			anim.track_insert_key(track_idx, i * 0.1, i)

		animation_player.add_animation("walk", anim)

	# Create an idle animation (e.g., first frame)
	if not animation_player.has_animation("idle"):
		var anim_idle = Animation.new()
		anim_idle.loop_mode = Animation.LOOP_LINEAR
		anim_idle.length = 0.1
		var track_idx_idle = anim_idle.add_track(Animation.TYPE_VALUE)
		anim_idle.track_set_path(track_idx_idle, "AnimatedSprite:frame")
		anim_idle.track_insert_key(track_idx_idle, 0.0, 0) # Use frame 0 for idle
		animation_player.add_animation("idle", anim_idle)

func _update_visuals():
	match current_state:
		State.WALK_RIGHT:
			sprite.flip_h = false
			sprite.rotation_degrees = 0
			if animation_player.current_animation != "walk": animation_player.play("walk")
		State.WALK_LEFT:
			sprite.flip_h = true
			sprite.rotation_degrees = 0
			if animation_player.current_animation != "walk": animation_player.play("walk")
		State.CLIMB_UP:
			sprite.flip_h = false # Or true, depending on desired orientation on wall
			sprite.rotation_degrees = -90 # Rotated to climb up
			if animation_player.current_animation != "walk": animation_player.play("walk")
		State.CLIMB_DOWN:
			sprite.flip_h = false # Or true
			sprite.rotation_degrees = 90  # Rotated to climb down
			if animation_player.current_animation != "walk": animation_player.play("walk")
		State.IDLE:
			sprite.flip_h = false # Assuming default facing right for idle
			sprite.rotation_degrees = 0
			if animation_player.current_animation != "idle": animation_player.play("idle")

# Public function to change the roach's state
func set_state(new_state: State):
	if current_state != new_state:
		current_state = new_state
		# Reset velocity when changing state to avoid carry-over if needed by game logic
		# For example, if switching from climbing to walking, x velocity might need reset.
		_current_velocity = Vector2.ZERO 
		_update_visuals() # Update immediately on state change

# Example of how to use set_state from another script or input:
# func _input(event):
# 	if event.is_action_pressed("move_left"):
# 		set_state(State.WALK_LEFT)
# 	elif event.is_action_pressed("move_right"):
# 		set_state(State.WALK_RIGHT)
# 	elif event.is_action_pressed("climb_up"):
# 		set_state(State.CLIMB_UP)
# 	elif event.is_action_pressed("climb_down"):
# 		set_state(State.CLIMB_DOWN)
# 	else:
# 		set_state(State.IDLE) # Fallback to idle or maintain current walking state 