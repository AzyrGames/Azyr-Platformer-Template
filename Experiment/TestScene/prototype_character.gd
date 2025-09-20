extends CharacterBody2D
class_name PlatformerController

## Signals for major events
signal jumped(jump_velocity: float, was_running: bool)           ## Emitted when character starts a jump
signal landed(landing_velocity: float, was_fast_falling: bool)   ## Emitted when character lands on ground
signal hit_ceiling(bump_velocity: float)                         ## Emitted when character hits ceiling
signal hit_wall(wall_normal: Vector2)                            ## Emitted when character hits a wall
signal direction_changed(new_direction: int)                     ## Emitted when facing direction changes
signal started_fast_falling()                                    ## Emitted when fast fall begins
signal coyote_time_started()                                     ## Emitted when leaving ground (coyote time begins)
signal grace_period_started()                                    ## Emitted when high-speed grace period begins

## Movement Settings
@export_group("Movement")
@export var terminal_horizontal_speed: float = 300.0
@export var terminal_vertical_speed: float = 800.0
@export var max_moving_speed: float = 400.0  ## Can exceed terminal speed through boosts

## Running Settings - Time-based for intuitive control
@export_group("Running (Time-based)")
@export var time_to_max_speed_ticks: int = 20: set = _set_time_to_max_speed     ## Ticks to reach max speed from standstill
@export var time_to_turn_ticks: int = 12: set = _set_time_to_turn              ## Ticks to turn around at max speed  
@export var time_to_stop_ticks: int = 15: set = _set_time_to_stop              ## Ticks to stop from max speed
@export var momentum: float = 0.8                                              ## How much running speed carries into jump (0-1)

## Jump Settings - Height and timing based
@export_group("Jump (Time-based)")
@export var max_jump_height: float = 120.0: set = _set_max_jump_height         ## Primary jump height control (pixels)
@export var jump_time_to_peak_ticks: int = 24: set = _set_jump_time_to_peak    ## Ticks to reach peak (0.4s at 60fps)
@export var jump_time_to_fall_ticks: int = 18: set = _set_jump_time_to_fall    ## Ticks to fall from peak (0.3s at 60fps)
@export var momentum_velocity_multiplier: float = 0.5
@export var jump_height_curve: Curve
@export var variable_jump_enabled: bool = true

## Gravity Settings - Calculated from jump parameters
@export_group("Gravity (pixels/second²)")
@export var gravity_multiplier: float = 1.0: set = _set_gravity_multiplier     ## Multiplier for calculated gravity
@export var apex_threshold: float = 50.0                                       ## Speed threshold for apex detection (pixels/second)
@export var dynamic_gravity_transition: bool = true
@export var jump_cutoff_multiplier: float = 0.3
@export var fast_fall_multiplier: float = 2.0
@export var variable_fast_fall_speed: float = 600.0                           ## pixels/second
@export var stomp_bounce_velocity: float = 200.0                              ## pixels/second

## Air Control Settings - Time-based
@export_group("Air Control (Time-based)")
@export var air_control_time_to_max_ticks: int = 40: set = _set_air_control_time    ## Ticks to reach max speed in air
@export var air_friction_time_to_stop_ticks: int = 50: set = _set_air_friction_time ## Ticks to stop in air
@export var running_horizontal_boost: float = 50.0                                 ## pixels/second

## Collision Settings
@export_group("Collision")
@export var floor_collision_shape: CollisionShape2D
@export var air_collision_shape: CollisionShape2D
@export var air_down_collision_shape_1: CollisionShape2D
@export var air_down_collision_shape_2: CollisionShape2D

@export var head_bump_velocity: float = -100.0

## Input Settings (in frames at 60fps)
@export_group("Input Timing (Frames at 60fps)")
@export var input_buffer_frames: int = 9      ## 0.15 seconds
@export var coyote_time_frames: int = 6       ## 0.1 seconds
@export var jump_grace_period_frames: int = 9 ## 0.15 seconds
@export var short_hop_frames: int = 6         ## 0.1 seconds
@export var tap_vs_hold_frames: int = 12      ## 0.2 seconds

## Visual Settings
@export_group("Visual")
@export var sprite: Sprite2D
@export var flip_sprite_on_direction_change: bool = true
@export var is_show_debug: bool = true:
	set(value):
		is_show_debug = value
		debug_label.visible = value
@export var debug_label: Label                ## Label to display debug information

## Debug Display - Read-only calculated values
@export_group("Debug Values (Read-Only)")
@export var _debug_forward_acceleration: float = 0.0    ## Calculated forward acceleration (pixels/second²)
@export var _debug_turn_acceleration: float = 0.0       ## Calculated turn acceleration (pixels/second²)
@export var _debug_friction: float = 0.0                ## Calculated friction (pixels/second²)
@export var _debug_air_acceleration: float = 0.0        ## Calculated air acceleration (pixels/second²)
@export var _debug_air_friction: float = 0.0            ## Calculated air friction (pixels/second²)
@export var _debug_initial_jump_velocity: float = 0.0   ## Calculated initial jump velocity (pixels/second)
@export var _debug_up_gravity: float = 0.0              ## Calculated up gravity (pixels/second²)
@export var _debug_down_gravity: float = 0.0            ## Calculated down gravity (pixels/second²)

## Internal state variables - Not for external access
var _jump_hold_time: float = 0.0
var _is_jumping: bool = false
var _is_falling: bool = false
var _is_fast_falling: bool = false
var _was_on_floor_last_frame: bool = false
var _last_horizontal_input: float = 0.0
var _running_speed_when_jumped: float = 0.0
var _is_stomping: bool = false
var _current_gravity: float
var _facing_direction: int = 1  ## 1 for right, -1 for left
var _last_facing_direction: int = 1  ## Track direction changes

## Timer nodes for input buffering and grace periods
var _jump_buffer_timer: Timer
var _coyote_timer: Timer
var _grace_period_timer: Timer

## Calculated movement physics values - Updated when export values change
var _forward_acceleration: float        ## pixels/second² - calculated from time_to_max_speed
var _turn_acceleration: float           ## pixels/second² - calculated from time_to_turn
var _friction: float                    ## pixels/second² - calculated from time_to_stop
var _air_acceleration: float            ## pixels/second² - calculated from air control time
var _air_friction: float                ## pixels/second² - calculated from air friction time

## Calculated jump physics values - Updated when export values change
var _initial_jump_velocity: float       ## pixels/second - calculated from max_jump_height
var _up_gravity: float                 ## pixels/second² - calculated from jump parameters
var _down_gravity: float               ## pixels/second² - calculated from jump parameters
var _jump_time_to_peak: float          ## seconds - converted from ticks
var _jump_time_to_fall: float          ## seconds - converted from ticks

## Converted frame times to seconds
var _input_buffer_time: float
var _coyote_time: float
var _jump_grace_period: float
var _short_hop_time: float
var _tap_vs_hold_threshold: float

## Initialize physics calculations and setup timers
func _ready() -> void:
	# Convert frame times to seconds (assuming 60fps)
	_input_buffer_time = input_buffer_frames / 60.0
	_coyote_time = coyote_time_frames / 60.0
	_jump_grace_period = jump_grace_period_frames / 60.0
	_short_hop_time = short_hop_frames / 60.0
	_tap_vs_hold_threshold = tap_vs_hold_frames / 60.0
	
	# Convert jump timing from ticks to seconds
	_jump_time_to_peak = jump_time_to_peak_ticks / 60.0
	_jump_time_to_fall = jump_time_to_fall_ticks / 60.0
	
	# Setup timer nodes
	_setup_timers()
	
	# Calculate movement physics from timing
	_calculate_movement_physics()
	
	# Calculate jump physics from max_jump_height
	_calculate_jump_physics()
	
	# Initialize jump height curve if not set
	if jump_height_curve == null:
		jump_height_curve = Curve.new()
		jump_height_curve.add_point(Vector2(0.0, 0.0))
		jump_height_curve.add_point(Vector2(0.5, 0.8))
		jump_height_curve.add_point(Vector2(1.0, 1.0))
	
	_current_gravity = _down_gravity

## Setup all timer nodes for input buffering and grace periods
func _setup_timers() -> void:
	# Jump buffer timer
	_jump_buffer_timer = Timer.new()
	_jump_buffer_timer.wait_time = _input_buffer_time
	_jump_buffer_timer.one_shot = true
	_jump_buffer_timer.timeout.connect(_on_jump_buffer_timeout)
	add_child(_jump_buffer_timer)
	
	# Coyote time timer
	_coyote_timer = Timer.new()
	_coyote_timer.wait_time = _coyote_time
	_coyote_timer.one_shot = true
	_coyote_timer.timeout.connect(_on_coyote_time_timeout)
	add_child(_coyote_timer)
	
	# Grace period timer
	_grace_period_timer = Timer.new()
	_grace_period_timer.wait_time = _jump_grace_period
	_grace_period_timer.one_shot = true
	_grace_period_timer.timeout.connect(_on_grace_period_timeout)
	add_child(_grace_period_timer)

## Timer timeout callbacks
func _on_jump_buffer_timeout() -> void:
	pass  # Jump buffer expired - handled by checking timer state

func _on_coyote_time_timeout() -> void:
	pass  # Coyote time expired - handled by checking timer state

func _on_grace_period_timeout() -> void:
	pass  # Grace period expired - handled by checking timer state

## Main physics update loop
func _physics_process(delta: float) -> void:
	_handle_input(delta)
	_update_collision_shape()
	_apply_gravity(delta)
	_handle_horizontal_movement(delta)
	_handle_jumping(delta)
	_handle_collisions()
	_update_sprite_direction()
	_update_debug_display()
	
	move_and_slide()
	
	# Update timers after move_and_slide to get accurate floor state
	_update_timers(delta)
	
	# Check for landing
	if not _was_on_floor_last_frame and is_on_floor():
		var was_fast_falling: bool = _is_fast_falling
		landed.emit(velocity.y, was_fast_falling)
	
	# Update state tracking
	_was_on_floor_last_frame = is_on_floor()

## Process player input and store state
func _handle_input(delta: float) -> void:
	# Jump input
	if Input.is_action_just_pressed("jump"):
		_jump_buffer_timer.start()
	
	if Input.is_action_pressed("jump") and _is_jumping:
		_jump_hold_time += delta
	
	if Input.is_action_just_released("jump"):
		if _is_jumping and variable_jump_enabled:
			_apply_jump_cutoff()
	
	# Fast fall input
	var was_fast_falling: bool = _is_fast_falling
	if Input.is_action_pressed("move_down") and not is_on_floor():
		_is_fast_falling = true
		if not was_fast_falling:
			started_fast_falling.emit()
	else:
		_is_fast_falling = false
	
	# Store horizontal input
	_last_horizontal_input = Input.get_axis("move_left", "move_right")

## Update coyote time and grace period timers
func _update_timers(delta: float) -> void:
	# Start coyote time when leaving the ground
	if _was_on_floor_last_frame and not is_on_floor():
		# Just left the ground - start coyote time
		_coyote_timer.start()
		coyote_time_started.emit()
		
		# Extended grace period for high-speed movement
		if abs(velocity.x) > terminal_horizontal_speed * 0.8:
			_grace_period_timer.start()
			grace_period_started.emit()

func _update_collision_shape() -> void:
	if !floor_collision_shape or !floor_collision_shape:
		return
	if !air_down_collision_shape_1 or !air_down_collision_shape_2:
		return

	if !is_on_floor() and !_is_falling:
		if floor_collision_shape.disabled == false:
			floor_collision_shape.disabled = true
		if air_collision_shape.disabled == true:
			air_collision_shape.disabled = false

		if air_down_collision_shape_1.disabled == false:
			air_down_collision_shape_1.disabled = true
		if air_down_collision_shape_2.disabled == false:
			air_down_collision_shape_2.disabled = true
	elif _is_falling:
		if air_down_collision_shape_1.disabled == true:
			air_down_collision_shape_1.disabled = false
		if air_down_collision_shape_2.disabled == true:
			air_down_collision_shape_2.disabled = false
	else:
		if floor_collision_shape.disabled == true:
			floor_collision_shape.disabled = false
		if air_collision_shape.disabled == false:
			air_collision_shape.disabled = true

		if air_down_collision_shape_1.disabled == false:
			air_down_collision_shape_1.disabled = true
		if air_down_collision_shape_2.disabled == false:
			air_down_collision_shape_2.disabled = true
	pass



## Apply gravity with variable rates and fast falling
func _apply_gravity(delta: float) -> void:
	if is_on_floor():
		_current_gravity = _down_gravity
		_is_jumping = false
		_jump_hold_time = 0.0
		_is_fast_falling = false
		return
	
	# Handle stomp bounce
	if _is_stomping and is_on_floor():
		velocity.y = -stomp_bounce_velocity
		_is_stomping = false
		return
	
	# Apply different gravity based on jump state
	if velocity.y < 0:  # Going up
		_is_falling = false
		if dynamic_gravity_transition and abs(velocity.y) < apex_threshold:
			# Near apex, blend between up and down gravity
			var blend_factor: float = (apex_threshold - abs(velocity.y)) / apex_threshold
			_current_gravity = lerp(_up_gravity, _down_gravity, blend_factor)
		else:
			_current_gravity = _up_gravity
	else:  # Falling
		_is_falling = true
		_current_gravity = _down_gravity
		
		# Fast falling
		if _is_fast_falling:
			if variable_fast_fall_speed > 0:
				velocity.y = min(velocity.y + _current_gravity * delta, min(variable_fast_fall_speed, terminal_vertical_speed))
			else:
				_current_gravity *= fast_fall_multiplier
	
	velocity.y += _current_gravity * delta
	
	# Clamp vertical velocity to terminal speed
	velocity.y = min(velocity.y, terminal_vertical_speed)

## Handle ground and air horizontal movement with different acceleration
func _handle_horizontal_movement(delta: float) -> void:
	var input_dir: float = _last_horizontal_input
	var target_velocity: float = input_dir * terminal_horizontal_speed
	
	if is_on_floor():
		# Ground movement
		if input_dir != 0:
			var acceleration: float = _forward_acceleration
			# Use turn acceleration if changing direction
			if sign(input_dir) != sign(velocity.x):
				acceleration = _turn_acceleration
			
			velocity.x = move_toward(velocity.x, target_velocity, acceleration * delta)
		else:
			# Apply friction
			velocity.x = move_toward(velocity.x, 0, _friction * delta)
	else:
		# Air movement
		if input_dir != 0:
			velocity.x = move_toward(velocity.x, target_velocity, _air_acceleration * delta)
		else:
			# Apply air friction
			velocity.x = move_toward(velocity.x, 0, _air_friction * delta)
	
	# Clamp horizontal velocity to max moving speed
	velocity.x = clamp(velocity.x, -max_moving_speed, max_moving_speed)

## Process jump input with buffering and coyote time
func _handle_jumping(delta: float) -> void:
	var can_jump: bool = is_on_floor() or not _coyote_timer.is_stopped() or not _grace_period_timer.is_stopped()
	
	# Check for jump input (including buffered)
	if not _jump_buffer_timer.is_stopped() and can_jump and not _is_jumping:
		_perform_jump()
		_jump_buffer_timer.stop()

## Execute jump with momentum and speed boosts
func _perform_jump() -> void:
	# Store running speed for momentum calculation
	_running_speed_when_jumped = abs(velocity.x)
	var was_running: bool = _running_speed_when_jumped >= terminal_horizontal_speed * 0.7
	
	# Calculate base jump velocity
	var jump_vel: float = -_initial_jump_velocity
	
	# Higher speed momentum only affects horizontal movement, not vertical
	# Add running boost if at high speed (horizontal only)
	if _running_speed_when_jumped >= terminal_horizontal_speed * 0.9:
		velocity.x += sign(velocity.x) * running_horizontal_boost
	
	velocity.y = jump_vel
	_is_jumping = true
	_jump_hold_time = 0.0
	
	# Stop timers
	_coyote_timer.stop()
	_grace_period_timer.stop()
	
	# Emit jump signal
	jumped.emit(jump_vel, was_running)

## Reduce jump height when button is released early
func _apply_jump_cutoff() -> void:
	if velocity.y < 0:  # Only cut off upward velocity
		velocity.y *= jump_cutoff_multiplier

## Handle head bumps, wall collisions, and corner correction
func _handle_collisions() -> void:
	# Head bump detection
	if is_on_ceiling() and velocity.y < 0:
		var bump_vel: float = velocity.y
		velocity.y = head_bump_velocity
		_is_jumping = false
		hit_ceiling.emit(bump_vel)
	
	# Wall bump detection
	if is_on_wall():
		var wall_normal: Vector2 = get_wall_normal()
		hit_wall.emit(wall_normal)
	

## Update sprite facing direction based on movement input
func _update_sprite_direction() -> void:
	if not flip_sprite_on_direction_change or sprite == null:
		return
	
	# Update facing direction based on horizontal input
	if _last_horizontal_input > 0:
		_facing_direction = 1
	elif _last_horizontal_input < 0:
		_facing_direction = -1
	
	# Check for direction change and emit signal
	if _facing_direction != _last_facing_direction:
		direction_changed.emit(_facing_direction)
		_last_facing_direction = _facing_direction
	
	# Only flip sprite if direction changed
	if _facing_direction == 1 and sprite.flip_h:
		sprite.flip_h = false
	elif _facing_direction == -1 and not sprite.flip_h:
		sprite.flip_h = true

## Update debug label with current state information
func _update_debug_display() -> void:

	if debug_label == null:
		return
	
	if !is_show_debug:
		return

	var debug_text: String = ""
	debug_text += "=== PLATFORMER DEBUG ===\n"
	debug_text += "Velocity: (%.1f, %.1f)\n" % [velocity.x, velocity.y]
	debug_text += "Facing: %s\n" % ("Right" if _facing_direction == 1 else "Left")
	debug_text += "On Floor: %s\n" % str(is_on_floor())
	debug_text += "Jumping: %s\n" % str(_is_jumping)
	debug_text += "Falling: %s\n" % str(_is_falling)

	debug_text += "Fast Falling: %s\n" % str(_is_fast_falling)
	debug_text += "\n=== TIMERS ===\n"
	
	# Jump Buffer Timer
	var jump_buffer_left: float = _jump_buffer_timer.time_left if not _jump_buffer_timer.is_stopped() else 0.0
	var jump_buffer_ticks: int = int(jump_buffer_left * 60.0)
	debug_text += "Jump Buffer: %.3fs (%d ticks)\n" % [jump_buffer_left, jump_buffer_ticks]
	
	# Coyote Timer
	var coyote_left: float = _coyote_timer.time_left if not _coyote_timer.is_stopped() else 0.0
	var coyote_ticks: int = int(coyote_left * 60.0)
	debug_text += "Coyote Time: %.3fs (%d ticks)\n" % [coyote_left, coyote_ticks]
	
	# Grace Period Timer
	var grace_left: float = _grace_period_timer.time_left if not _grace_period_timer.is_stopped() else 0.0
	var grace_ticks: int = int(grace_left * 60.0)
	debug_text += "Grace Period: %.3fs (%d ticks)\n" % [grace_left, grace_ticks]
	
	# Jump Hold Time
	var hold_ticks: int = int(_jump_hold_time * 60.0)
	debug_text += "Jump Hold: %.3fs (%d ticks)\n" % [_jump_hold_time, hold_ticks]
	
	debug_text += "\n=== CURRENT PHYSICS ===\n"
	
	# Current acceleration being used
	var current_accel: float = 0.0
	var accel_name: String = "None"
	if is_on_floor():
		if _last_horizontal_input != 0:
			if sign(_last_horizontal_input) != sign(velocity.x):
				current_accel = _turn_acceleration
				accel_name = "Turn"
			else:
				current_accel = _forward_acceleration
				accel_name = "Forward"
		else:
			current_accel = _friction
			accel_name = "Friction"
	else:
		if _last_horizontal_input != 0:
			current_accel = _air_acceleration
			accel_name = "Air Control"
		else:
			current_accel = _air_friction
			accel_name = "Air Friction"
	
	debug_text += "Current Accel: %s (%.0f px/s²)\n" % [accel_name, current_accel]
	
	# Current gravity type
	var gravity_type: String = "Down"
	if velocity.y < 0:
		if dynamic_gravity_transition and abs(velocity.y) < apex_threshold:
			var blend_factor: float = (apex_threshold - abs(velocity.y)) / apex_threshold
			gravity_type = "Apex Blend (%.1f%%)" % (blend_factor * 100.0)
		else:
			gravity_type = "Up"
	elif _is_fast_falling:
		if variable_fast_fall_speed > 0:
			gravity_type = "Fast Fall (Capped)"
		else:
			gravity_type = "Fast Fall (%.1fx)" % fast_fall_multiplier
	
	debug_text += "Current Gravity: %s (%.0f px/s²)\n" % [gravity_type, _current_gravity]
	
	debug_text += "\n=== CALCULATED PHYSICS ===\n"
	debug_text += "Forward Accel: %.0f px/s²\n" % _forward_acceleration
	debug_text += "Turn Accel: %.0f px/s²\n" % _turn_acceleration
	debug_text += "Friction: %.0f px/s²\n" % _friction
	debug_text += "Air Accel: %.0f px/s²\n" % _air_acceleration
	debug_text += "Air Friction: %.0f px/s²\n" % _air_friction
	debug_text += "Jump Velocity: %.0f px/s\n" % _initial_jump_velocity
	debug_text += "Up Gravity: %.0f px/s²\n" % _up_gravity
	debug_text += "Down Gravity: %.0f px/s²\n" % _down_gravity
	
	debug_label.text = debug_text

## Calculate movement accelerations from timing parameters
func _calculate_movement_physics() -> void:
	# Calculate accelerations from timing parameters
	# Using: acceleration = velocity_change / time
	# For reaching max speed: a = max_speed / time_to_max
	
	var time_to_max_speed: float = time_to_max_speed_ticks / 60.0
	var time_to_turn: float = time_to_turn_ticks / 60.0
	var time_to_stop: float = time_to_stop_ticks / 60.0
	var air_time_to_max: float = air_control_time_to_max_ticks / 60.0
	var air_time_to_stop: float = air_friction_time_to_stop_ticks / 60.0
	
	# Forward acceleration: time to reach terminal speed from standstill
	_forward_acceleration = terminal_horizontal_speed / time_to_max_speed
	
	# Turn acceleration: time to go from max speed one direction to max speed other direction
	# Total velocity change = 2 * max_speed (from +max to -max)
	_turn_acceleration = (2.0 * terminal_horizontal_speed) / time_to_turn
	
	# Friction: time to stop from max speed
	_friction = terminal_horizontal_speed / time_to_stop
	
	# Air control acceleration
	_air_acceleration = terminal_horizontal_speed / air_time_to_max
	
	# Air friction
	_air_friction = terminal_horizontal_speed / air_time_to_stop
	
	# Update debug values
	_update_debug_movement_values()

## Calculate jump physics from height and timing parameters
func _calculate_jump_physics() -> void:
	# Calculate gravity and initial velocity from jump height and timing
	# Using kinematic equations:
	# h = v₀t - ½gt²  (for upward motion)
	# v = v₀ - gt     (velocity equation)
	
	# Calculate up gravity from time to peak and jump height
	# At peak: v = 0, so v₀ = g * t_up
	# h = v₀ * t_up - ½ * g * t_up²
	# h = g * t_up² - ½ * g * t_up² = ½ * g * t_up²
	# Therefore: g = 2h / t_up²
	_up_gravity = (2.0 * max_jump_height) / (_jump_time_to_peak * _jump_time_to_peak)
	_up_gravity *= gravity_multiplier
	
	# Calculate down gravity from fall time
	# h = ½ * g * t_fall²
	# Therefore: g = 2h / t_fall²
	_down_gravity = (2.0 * max_jump_height) / (_jump_time_to_fall * _jump_time_to_fall)
	_down_gravity *= gravity_multiplier
	
	# Calculate initial jump velocity
	# v₀ = g * t_up
	_initial_jump_velocity = _up_gravity * _jump_time_to_peak
	
	# Update debug values
	_update_debug_jump_values()

## Update debug display values for movement physics
func _update_debug_movement_values() -> void:
	_debug_forward_acceleration = _forward_acceleration
	_debug_turn_acceleration = _turn_acceleration
	_debug_friction = _friction
	_debug_air_acceleration = _air_acceleration
	_debug_air_friction = _air_friction

## Update debug display values for jump physics
func _update_debug_jump_values() -> void:
	_debug_initial_jump_velocity = _initial_jump_velocity
	_debug_up_gravity = _up_gravity
	_debug_down_gravity = _down_gravity

# Setter functions for automatic recalculation when export values change

func _set_time_to_max_speed(value: int) -> void:
	time_to_max_speed_ticks = value
	if is_inside_tree():
		_calculate_movement_physics()

func _set_time_to_turn(value: int) -> void:
	time_to_turn_ticks = value
	if is_inside_tree():
		_calculate_movement_physics()

func _set_time_to_stop(value: int) -> void:
	time_to_stop_ticks = value
	if is_inside_tree():
		_calculate_movement_physics()

func _set_air_control_time(value: int) -> void:
	air_control_time_to_max_ticks = value
	if is_inside_tree():
		_calculate_movement_physics()

func _set_air_friction_time(value: int) -> void:
	air_friction_time_to_stop_ticks = value
	if is_inside_tree():
		_calculate_movement_physics()

func _set_max_jump_height(value: float) -> void:
	max_jump_height = value
	if is_inside_tree():
		_calculate_jump_physics()
		_current_gravity = _down_gravity

func _set_jump_time_to_peak(value: int) -> void:
	jump_time_to_peak_ticks = value
	if is_inside_tree():
		_jump_time_to_peak = value / 60.0
		_calculate_jump_physics()
		_current_gravity = _down_gravity

func _set_jump_time_to_fall(value: int) -> void:
	jump_time_to_fall_ticks = value
	if is_inside_tree():
		_jump_time_to_fall = value / 60.0
		_calculate_jump_physics()
		_current_gravity = _down_gravity

func _set_gravity_multiplier(value: float) -> void:
	gravity_multiplier = value
	if is_inside_tree():
		_calculate_jump_physics()
		_current_gravity = _down_gravity

# Public utility functions for external use

## Check if current jump is a short hop
func is_short_hop() -> bool:
	return _jump_hold_time > 0 and _jump_hold_time < _short_hop_time

## Check if current jump is a full hop
func is_full_hop() -> bool:
	return _jump_hold_time >= _tap_vs_hold_threshold

## Get normalized jump height ratio based on hold time
func get_jump_height_ratio() -> float:
	if not variable_jump_enabled or not _is_jumping:
		return 1.0
	
	var time_ratio: float = min(_jump_hold_time / _tap_vs_hold_threshold, 1.0)
	return jump_height_curve.sample(time_ratio)

## Get current facing direction (1 = right, -1 = left)
func get_facing_direction() -> int:
	return _facing_direction

## Check if character is currently jumping
func is_jumping() -> bool:
	return _is_jumping

## Check if character is currently fast falling
func is_fast_falling() -> bool:
	return _is_fast_falling

## Check if coyote time is active
func has_coyote_time() -> bool:
	return not _coyote_timer.is_stopped()

## Check if grace period is active
func has_grace_period() -> bool:
	return not _grace_period_timer.is_stopped()

## Check if jump buffer is active
func has_jump_buffer() -> bool:
	return not _jump_buffer_timer.is_stopped()

# Public functions for special moves and terrain interaction

## Trigger a stomp/ground pound move
func trigger_stomp() -> void:
	_is_stomping = true
	velocity.y = variable_fast_fall_speed
	_is_fast_falling = true

## Change friction based on terrain (ice, mud, etc.)
func set_terrain_friction(new_friction: float) -> void:
	_friction = new_friction

## Add horizontal speed boost (power-ups, wind, etc.)
func add_horizontal_boost(boost: float) -> void:
	velocity.x += boost
	# Ensure we don't exceed max moving speed
	velocity.x = clamp(velocity.x, -max_moving_speed, max_moving_speed)

## Recalculate all physics (useful for runtime parameter changes)
func recalculate_all_physics() -> void:
	_jump_time_to_peak = jump_time_to_peak_ticks / 60.0
	_jump_time_to_fall = jump_time_to_fall_ticks / 60.0
	_calculate_movement_physics()
	_calculate_jump_physics()
	_current_gravity = _down_gravity

## Get comprehensive debug information
func get_debug_info() -> Dictionary:
	return {
		"velocity": velocity,
		"is_jumping": _is_jumping,
		"is_falling": _is_falling,
		"is_fast_falling": _is_fast_falling,
		"has_coyote_time": has_coyote_time(),
		"has_jump_buffer": has_jump_buffer(),
		"has_grace_period": has_grace_period(),
		"jump_hold_time": _jump_hold_time,
		"current_gravity": _current_gravity,
		"facing_direction": _facing_direction,
		"can_jump": is_on_floor() or has_coyote_time() or has_grace_period(),
		"running_speed_when_jumped": _running_speed_when_jumped,
		"calculated_physics": {
			"forward_acceleration": _forward_acceleration,
			"turn_acceleration": _turn_acceleration,
			}
	}
