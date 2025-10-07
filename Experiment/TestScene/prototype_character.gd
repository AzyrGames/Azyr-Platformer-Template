extends EntityCharacter2D
class_name CharacterPlatformer2D

## Signals for major events
signal jumped(jump_velocity: float, was_running: bool)
signal landed(landing_velocity: float, was_fast_falling: bool)
signal hit_ceiling(bump_velocity: float)
signal hit_wall(wall_normal: Vector2)
signal direction_changed(new_direction: int)
signal started_fast_falling()
signal coyote_time_started()
signal grace_period_started()


@export var movement_setting : CharacterMovementSetting


## Collision Settings
@export_group("Collision")
@export var floor_collision_shape: CollisionShape2D
@export var body_collision_shape: CollisionShape2D


## Visual Settings
@export_group("Visual")
@export var sprite: Sprite2D
@export var flip_sprite_on_direction_change: bool = true
@export var is_show_debug: bool = true
@export var debug_label: Label


## Debug Display - Read-only calculated values
var debug_forward_acceleration: float = 0.0
var debug_turn_acceleration: float = 0.0
var debug_friction: float = 0.0
var debug_air_acceleration: float = 0.0
var debug_air_friction: float = 0.0
var debug_initial_jump_velocity: float = 0.0
var debug_up_gravity: float = 0.0
var debug_down_gravity: float = 0.0



## Internal state variables - Not for external access
var _jump_hold_time: float = 0.0
var _is_jumping: bool = false
var _is_falling: bool = false
var _is_fast_falling: bool = false
var is_playing: bool = false
var canvas_layer: CanvasLayer
var _was_on_floor_last_frame: bool = false
var _last_horizontal_input: float = 0.0
var _running_speed_when_jumped: float = 0.0
var _is_stomping: bool = false
var _current_gravity: float
var _facing_direction: int = 1
var _last_facing_direction: int = 1

## Timer nodes for input buffering and grace periods
var _jump_buffer_timer: Timer
var _coyote_timer: Timer
var _grace_period_timer: Timer

## Calculated movement physics values - Updated when export values change
var _forward_acceleration: float
var _turn_acceleration: float
var _friction: float
var _air_acceleration: float
var _air_friction: float

## Calculated jump physics values - Updated when export values change
var _initial_jump_velocity: float
var _up_gravity: float
var _down_gravity: float
var _jump_time_to_peak: float
var _jump_time_to_fall: float

## Converted frame times to seconds
var _input_buffer_time: float
var _coyote_time: float
var _jump_grace_period: float

## Initialize physics calculations and setup timers
func _ready() -> void:
	if movement_setting:
		# Connect resource changed signal
		if movement_setting.is_connected("changed", _on_settings_changed):
			movement_setting.disconnect("changed", _on_settings_changed)
		movement_setting.connect("changed", _on_settings_changed)
	_update_from_settings()
	_setup_timers()
	_calculate_movement_physics()
	_calculate_jump_physics()
	_current_gravity = _down_gravity

## Update all dependent variables when movement_setting change
func _on_settings_changed() -> void:
	if is_inside_tree():
		_update_from_settings()
		_calculate_movement_physics()
		_calculate_jump_physics()
		_current_gravity = _down_gravity

func _set_settings(value: CharacterMovementSetting) -> void:
	movement_setting = value
	if movement_setting and is_inside_tree():
		if movement_setting.is_connected("changed", _on_settings_changed):
			movement_setting.disconnect("changed", _on_settings_changed)
		movement_setting.connect("changed", _on_settings_changed)
		_update_from_settings()
		_calculate_movement_physics()
		_calculate_jump_physics()
		_current_gravity = _down_gravity

func _update_from_settings() -> void:
	if not movement_setting:
		return
	# Convert frame times to seconds (60 ticks per seconds)
	_input_buffer_time = movement_setting.input_buffer_frames / 60.0
	_coyote_time = movement_setting.coyote_time_frames / 60.0
	_jump_grace_period = movement_setting.jump_grace_period_frames / 60.0
	# Convert jump timing from ticks to seconds
	_jump_time_to_peak = movement_setting.jump_time_to_peak_ticks / 60.0
	_jump_time_to_fall = movement_setting.jump_time_to_fall_ticks / 60.0
	# Update debug visibility
	if debug_label:
		debug_label.visible = is_show_debug

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
	pass

func _on_coyote_time_timeout() -> void:
	pass

func _on_grace_period_timeout() -> void:
	pass

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
	if Input.is_action_just_pressed("move_jump"):
		_jump_buffer_timer.start()
	if Input.is_action_pressed("move_jump") and _is_jumping:
		_jump_hold_time += delta
	if Input.is_action_just_released("move_jump"):
		if _is_jumping and movement_setting.variable_jump_enabled:
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
	if abs(velocity.x) > movement_setting.terminal_horizontal_speed * 0.8:
		_grace_period_timer.start()
		grace_period_started.emit()

func _update_collision_shape() -> void:
	if !movement_setting or !floor_collision_shape or !body_collision_shape:
		return
	if !is_on_floor() and !_is_falling:
		floor_collision_shape.disabled = true
	else:
		floor_collision_shape.disabled = false


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
		velocity.y = -movement_setting.stomp_bounce_velocity
		_is_stomping = false
		return
	# Apply different gravity based on jump state

	if velocity.y < 0:
		_is_falling = false
		if movement_setting.dynamic_gravity_transition and abs(velocity.y) < movement_setting.apex_threshold:
			# Near apex, blend between up and down gravity
			var blend_factor: float = (movement_setting.apex_threshold - abs(velocity.y)) / movement_setting.apex_threshold
			_current_gravity = lerp(_up_gravity, _down_gravity, blend_factor)
		else:
			_current_gravity = _up_gravity
	else:
		_is_falling = true
		_current_gravity = _down_gravity
	
	# Fast falling
	if _is_fast_falling:
		if movement_setting.variable_fast_fall_speed > 0:
			velocity.y = min(velocity.y + _current_gravity * delta, min(movement_setting.variable_fast_fall_speed, movement_setting.terminal_vertical_speed))
		else:
			_current_gravity *= movement_setting.fast_fall_multiplier
	velocity.y += _current_gravity * delta
	# Clamp vertical velocity to terminal speed
	velocity.y = min(velocity.y, movement_setting.terminal_vertical_speed)

## Handle ground and air horizontal movement with different acceleration
func _handle_horizontal_movement(delta: float) -> void:
	var input_dir: float = _last_horizontal_input
	var target_velocity: float = input_dir * movement_setting.max_moving_speed
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
	velocity.x = clamp(velocity.x, -movement_setting.terminal_horizontal_speed, movement_setting.terminal_horizontal_speed)


## Process jump input with buffering and coyote time
func _handle_jumping(delta: float) -> void:
	var can_jump: bool = _check_can_jump()
	# Check for jump input (including buffered)
	if not _jump_buffer_timer.is_stopped() and can_jump and not _is_jumping:
		_perform_jump()
		_jump_buffer_timer.stop()

func _check_can_jump() -> bool:
	return (
		is_on_floor() or
		not _coyote_timer.is_stopped() or
		not _grace_period_timer.is_stopped()
	)

## Execute jump with momentum and speed boosts
func _perform_jump() -> void:
	# Store running speed for momentum calculation
	_running_speed_when_jumped = abs(velocity.x)
	var was_running: bool = _running_speed_when_jumped >= movement_setting.terminal_horizontal_speed * 0.7
	# Calculate base jump velocity
	var jump_vel: float = -_initial_jump_velocity


	add_horizontal_boost(movement_setting.running_horizontal_boost)
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
	if velocity.y < 0:
		velocity.y *= movement_setting.jump_cutoff_multiplier

## Handle head bumps, wall collisions, and corner correction
func _handle_collisions() -> void:
	# Head bump detection
	if is_on_ceiling() and velocity.y < 0:
		var bump_vel: float = velocity.y
		velocity.y = movement_setting.head_bump_velocity
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
	if debug_label == null or not is_show_debug:
		return
	var jump_buffer_left := _jump_buffer_timer.time_left if not _jump_buffer_timer.is_stopped() else 0.0
	var coyote_left := _coyote_timer.time_left if not _coyote_timer.is_stopped() else 0.0
	var grace_left := _grace_period_timer.time_left if not _grace_period_timer.is_stopped() else 0.0
	var current_accel := 0.0
	var accel_name := "None"
	if is_on_floor():
		if _last_horizontal_input != 0:
			accel_name = "Turn" if sign(_last_horizontal_input) != sign(velocity.x) else "Forward"
			current_accel = _turn_acceleration if accel_name == "Turn" else _forward_acceleration
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
	var gravity_type := "Down"
	if velocity.y < 0:
		if movement_setting.dynamic_gravity_transition and abs(velocity.y) < movement_setting.apex_threshold:
			var blend_factor: float = (movement_setting.apex_threshold - abs(velocity.y)) / movement_setting.apex_threshold
			gravity_type = "Apex (%.1f%%)" % (blend_factor * 100.0)
		else:
			gravity_type = "Up"
	elif _is_fast_falling:
		gravity_type = "Fast Fall" if movement_setting.variable_fast_fall_speed > 0 else "FF(%.1fx)" % movement_setting.fast_fall_multiplier
	var debug_text := "Vel (%.1f, %.1f)|Facing %s\nFloor %s|Jump %s|Fall %s|FF %s\n" % [
		velocity.x, velocity.y, "R" if _facing_direction == 1 else "L", is_on_floor(), _is_jumping, _is_falling, _is_fast_falling]
	debug_text += "JumpBuf %.2fs - %d |Coyote %.2fs - %d \nGrace %.2fs - %d |Hold %.2fs - %d \n" % [
		jump_buffer_left, int(jump_buffer_left * 60.0), coyote_left, int(coyote_left * 60.0), 
		grace_left, int(grace_left * 60.0), _jump_hold_time, int(_jump_hold_time * 60.0)]
	debug_text += "Accel %s: %.0f px/s² \nGrav %s : %.0f px/s² \n" % [accel_name, current_accel, gravity_type, _current_gravity]
	debug_text += "FwdAcc %.0f|TurnAcc %.0f|Fric %.0f\n" % [_forward_acceleration, _turn_acceleration, _friction]
	debug_text += "AirAcc %.0f|AirFric %.0f\n" % [_air_acceleration, _air_friction]
	debug_text += "JumpVel %.0f|UpGrav %.0f |HBost %.0f \n" % [_initial_jump_velocity, _up_gravity, movement_setting.running_horizontal_boost]
	debug_text += "DownGrav %.0f px/s²\n" % _down_gravity
	debug_label.text = debug_text

## Calculate movement accelerations from timing parameters
func _calculate_movement_physics() -> void:
	if not movement_setting:
		return
	# Calculate accelerations from timing parameters
	var time_to_max_speed: float = movement_setting.time_to_max_speed_ticks / 60.0
	var time_to_turn: float = movement_setting.time_to_turn_ticks / 60.0
	var time_to_stop: float = movement_setting.time_to_stop_ticks / 60.0
	var air_time_to_max: float = movement_setting.air_control_time_to_max_ticks / 60.0
	var air_time_to_stop: float = movement_setting.air_friction_time_to_stop_ticks / 60.0
	# Forward acceleration
	_forward_acceleration = movement_setting.terminal_horizontal_speed / time_to_max_speed
	# Turn acceleration
	_turn_acceleration = (2.0 * movement_setting.terminal_horizontal_speed) / time_to_turn
	# Friction
	_friction = movement_setting.terminal_horizontal_speed / time_to_stop
	# Air control acceleration
	_air_acceleration = movement_setting.terminal_horizontal_speed / air_time_to_max
	# Air friction
	_air_friction = movement_setting.terminal_horizontal_speed / air_time_to_stop
	# Update debug values
	_update_debug_movement_values()

## Calculate jump physics from height and timing parameters
func _calculate_jump_physics() -> void:
	if not movement_setting:
		return
	# Calculate gravity and initial velocity
	_up_gravity = (2.0 * movement_setting.max_jump_height) / (_jump_time_to_peak * _jump_time_to_peak)
	_up_gravity *= movement_setting.gravity_multiplier
	# Calculate down gravity
	_down_gravity = (2.0 * movement_setting.max_jump_height) / (_jump_time_to_fall * _jump_time_to_fall)
	_down_gravity *= movement_setting.gravity_multiplier
	# Calculate initial jump velocity
	_initial_jump_velocity = _up_gravity * _jump_time_to_peak
	# Update debug values
	_update_debug_jump_values()

## Update debug display values for movement physics
func _update_debug_movement_values() -> void:
	debug_forward_acceleration = _forward_acceleration
	debug_turn_acceleration = _turn_acceleration
	debug_friction = _friction
	debug_air_acceleration = _air_acceleration
	debug_air_friction = _air_friction

## Update debug display values for jump physics
func _update_debug_jump_values() -> void:
	debug_initial_jump_velocity = _initial_jump_velocity
	debug_up_gravity = _up_gravity
	debug_down_gravity = _down_gravity

## Public utility functions for external use
func get_facing_direction() -> int:
	return _facing_direction

func is_jumping() -> bool:
	return _is_jumping

func is_fast_falling() -> bool:
	return _is_fast_falling

func has_coyote_time() -> bool:
	return not _coyote_timer.is_stopped()

func has_grace_period() -> bool:
	return not _grace_period_timer.is_stopped()

func has_jump_buffer() -> bool:
	return not _jump_buffer_timer.is_stopped()

## Public functions for special moves and terrain interaction
func trigger_stomp() -> void:
	_is_stomping = true
	velocity.y = movement_setting.variable_fast_fall_speed
	_is_fast_falling = true

func set_terrain_friction(new_friction: float) -> void:
	_friction = new_friction

func add_horizontal_boost(boost: float) -> void:
	velocity.x += sign(velocity.x) * boost
	velocity.x = clamp(velocity.x, -movement_setting.terminal_horizontal_speed, movement_setting.terminal_horizontal_speed)

func recalculate_all_physics() -> void:
	_jump_time_to_peak = movement_setting.jump_time_to_peak_ticks / 60.0
	_jump_time_to_fall = movement_setting.jump_time_to_fall_ticks / 60.0
	_calculate_movement_physics()
	_calculate_jump_physics()
	_current_gravity = _down_gravity

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
