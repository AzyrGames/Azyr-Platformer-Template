@tool
class_name CharacterMovementSetting
extends Resource

## Movement Settings
@export_group("Moving Speed")
@export var max_moving_speed: float = 200.0: set = _set_max_moving_speed

@export var terminal_horizontal_speed: float = 300.0: set = _set_terminal_horizontal_speed
@export var terminal_vertical_speed: float = 600.0: set = _set_terminal_vertical_speed

## Running Settings - Ticks
@export_group("Running - Ticks")
@export var time_to_max_speed_ticks: int = 20: set = _set_time_to_max_speed_ticks
@export var time_to_turn_ticks: int = 12: set = _set_time_to_turn_ticks
@export var time_to_stop_ticks: int = 15: set = _set_time_to_stop_ticks

## Jump Settings - Height and timing based
@export_group("Jump - Ticks")
@export var max_jump_height: float = 60.0: set = _set_max_jump_height
@export var jump_time_to_peak_ticks: int = 24: set = _set_jump_time_to_peak_ticks
@export var jump_time_to_fall_ticks: int = 18: set = _set_jump_time_to_fall_ticks
@export var variable_jump_enabled: bool = true: set = _set_variable_jump_enabled
@export var head_bump_velocity: float = -100.0
@export var running_horizontal_boost: float = 50.0: set = _set_running_horizontal_boost



## Gravity Settings - Calculated from jump parameters
@export_group("Gravity")
@export var gravity_multiplier: float = 1.0: set = _set_gravity_multiplier
@export var apex_threshold: float = 50.0: set = _set_apex_threshold
@export var dynamic_gravity_transition: bool = true: set = _set_dynamic_gravity_transition
@export var jump_cutoff_multiplier: float = 0.3: set = _set_jump_cutoff_multiplier
## Set to < 0 if use mulitpler
@export var variable_fast_fall_speed: float = 400.0: set = _set_variable_fast_fall_speed
@export var fast_fall_multiplier: float = 2.0: set = _set_fast_fall_multiplier

## Air Control Settings - Time-based
@export_group("Air Control (Time-based)")
@export var air_control_time_to_max_ticks: int = 40: set = _set_air_control_time_to_max_ticks
@export var air_friction_time_to_stop_ticks: int = 50: set = _set_air_friction_time_to_stop_ticks

## Input Settings (in frames at 60fps)
@export_group("Input Timing (Frames at 60fps)")
@export var input_buffer_frames: int = 9: set = _set_input_buffer_frames
@export var coyote_time_frames: int = 6: set = _set_coyote_time_frames
@export var jump_grace_period_frames: int = 9: set = _set_jump_grace_period_frames

# Setter functions for Movement group
func _set_terminal_horizontal_speed(value: float) -> void:
	terminal_horizontal_speed = value
	emit_changed()

func _set_terminal_vertical_speed(value: float) -> void:
	terminal_vertical_speed = value
	emit_changed()

func _set_max_moving_speed(value: float) -> void:
	max_moving_speed = value
	emit_changed()

# Setter functions for Running group
func _set_time_to_max_speed_ticks(value: int) -> void:
	time_to_max_speed_ticks = value
	emit_changed()

func _set_time_to_turn_ticks(value: int) -> void:
	time_to_turn_ticks = value
	emit_changed()

func _set_time_to_stop_ticks(value: int) -> void:
	time_to_stop_ticks = value
	emit_changed()

# Setter functions for Jump group
func _set_max_jump_height(value: float) -> void:
	max_jump_height = value
	emit_changed()

func _set_jump_time_to_peak_ticks(value: int) -> void:
	jump_time_to_peak_ticks = value
	emit_changed()

func _set_jump_time_to_fall_ticks(value: int) -> void:
	jump_time_to_fall_ticks = value
	emit_changed()

func _set_variable_jump_enabled(value: bool) -> void:
	variable_jump_enabled = value
	emit_changed()

# Setter functions for Gravity group
func _set_gravity_multiplier(value: float) -> void:
	gravity_multiplier = value
	emit_changed()

func _set_apex_threshold(value: float) -> void:
	apex_threshold = value
	emit_changed()

func _set_dynamic_gravity_transition(value: bool) -> void:
	dynamic_gravity_transition = value
	emit_changed()

func _set_jump_cutoff_multiplier(value: float) -> void:
	jump_cutoff_multiplier = value
	emit_changed()

func _set_fast_fall_multiplier(value: float) -> void:
	fast_fall_multiplier = value
	emit_changed()

func _set_variable_fast_fall_speed(value: float) -> void:
	variable_fast_fall_speed = value
	emit_changed()

# Setter functions for Air Control group
func _set_air_control_time_to_max_ticks(value: int) -> void:
	air_control_time_to_max_ticks = value
	emit_changed()

func _set_air_friction_time_to_stop_ticks(value: int) -> void:
	air_friction_time_to_stop_ticks = value
	emit_changed()

func _set_running_horizontal_boost(value: float) -> void:
	running_horizontal_boost = value
	emit_changed()

# Setter functions for Input Timing group
func _set_input_buffer_frames(value: int) -> void:
	input_buffer_frames = value
	emit_changed()

func _set_coyote_time_frames(value: int) -> void:
	coyote_time_frames = value
	emit_changed()

func _set_jump_grace_period_frames(value: int) -> void:
	jump_grace_period_frames = value
	emit_changed()
