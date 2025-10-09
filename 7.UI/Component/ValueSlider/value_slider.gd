extends MarginContainer
class_name ValueSlider

signal value_changed(_value: float)


@export var option_text: String = "Lorem ipstum"

@export var text_normal_color: Color = "#ffffffff"
@export var text_focus_color: Color = "#1fcff2"

@onready var value_slider : HBoxContainer = %ValueSlider
@onready var label_slider : Label = %LabelSlider
@onready var slider_value : Slider = %SliderValue
@onready var line_edit_value : LineEdit = %LineEditValue

@onready var button_left: TextureButton = %ButtonLeft
@onready var button_right: TextureButton = %ButtonRight


var _button_hold_timer: Timer
# var _button_right_hold_timer: Timer

var _hold_trigger_timer: Timer
var _is_hold_left : bool
var _is_hold_right : bool



func _ready() -> void:
	label_slider.text = option_text
	setup_hold_timer()
	connect_slider() 
	connect_button()
	connect_line_edit_slider()
	pass


func _input(event: InputEvent) -> void:
	if line_edit_value.is_editing():
		if Input.is_action_just_pressed("ui_up"):
			_button_hold_timer.start()
			_is_hold_right = true
			slider_value.value += 1
			line_edit_value.caret_column = line_edit_value.text.length()
			
		if Input.is_action_just_released("ui_up"):
			_is_hold_right = false
	
		if Input.is_action_just_pressed("ui_down"):
			_button_hold_timer.start()
			_is_hold_left = true
			slider_value.value -= 1
			line_edit_value.caret_column = line_edit_value.text.length()
		if Input.is_action_just_released("ui_down"):
			_is_hold_left = false

func setup_hold_timer() -> void:
	_button_hold_timer = Timer.new()
	_button_hold_timer.autostart = false
	_button_hold_timer.one_shot = true
	_button_hold_timer.wait_time = 0.5
	_button_hold_timer.timeout.connect(_on_button_left_hold_timeout)
	add_child(_button_hold_timer)
	

	_hold_trigger_timer = Timer.new()
	_hold_trigger_timer.autostart = false
	_hold_trigger_timer.one_shot = true
	_hold_trigger_timer.wait_time = 0.0501
	_hold_trigger_timer.timeout.connect(_on_hold_trigger_timeout)
	add_child(_hold_trigger_timer)
	pass


func connect_slider() -> void:
	value_slider.mouse_entered.connect(_on_slider_focus_entered)
	value_slider.mouse_exited.connect(_on_slider_focus_exited)
	slider_value.mouse_entered.connect(_on_slider_focus_entered)
	slider_value.mouse_exited.connect(_on_slider_focus_exited)

	button_left.mouse_entered.connect(_on_slider_focus_entered)
	button_left.mouse_exited.connect(_on_slider_focus_exited)

	button_right.mouse_entered.connect(_on_slider_focus_entered)
	button_right.mouse_exited.connect(_on_slider_focus_exited)

	line_edit_value.mouse_entered.connect(_on_slider_focus_entered)
	line_edit_value.mouse_exited.connect(_on_slider_focus_exited)

	slider_value.value_changed.connect(_on_slider_value_changed)
	# slider_value.focus_entered.connect(_on_slider_focus_entered)
	# slider_value.focus_exited.connect(_on_slider_focus_exited)


func connect_button() -> void:
	button_left.button_up.connect(_on_button_left_up)
	button_left.button_down.connect(_on_button_left_down)

	button_right.button_up.connect(_on_button_right_up)
	button_right.button_down.connect(_on_button_right_down)
	pass


func connect_line_edit_slider() -> void:
	line_edit_value.text_submitted.connect(_on_line_edit_submitted)
	line_edit_value.focus_exited.connect(_on_line_edit_focus_lost)
	line_edit_value.text_changed.connect(_on_line_edit_changed)
	line_edit_value.text = str(int(slider_value.value))
	
	# Only allow numeric input
	var regex = RegEx.new()
	regex.compile("^[0-9]*$")
	line_edit_value.text_changed.connect(func(text): 
		if not regex.search(text):
			line_edit_value.text = ""
	)
	line_edit_value.caret_column = line_edit_value.text.length()
	pass

func _on_line_edit_submitted(text: String) -> void:
	_validate_line_edit_text(text)

func _on_line_edit_focus_lost() -> void:
	_validate_line_edit_text(line_edit_value.text)

func _on_line_edit_changed(text: String) -> void:
	if text.is_empty():
		return
	if not text.is_valid_int():
		line_edit_value.text = str(int(slider_value.value))
	line_edit_value.caret_column = line_edit_value.text.length()


func _on_slider_focus_entered() -> void:
	# $MyLabel.remove_theme_color_override("font_color")
	label_slider.add_theme_color_override("font_color", text_focus_color)

	pass


func _on_slider_focus_exited() -> void:
	# $MyLabel.remove_theme_color_override("font_color")
	label_slider.add_theme_color_override("font_color", text_normal_color)
	pass


func _validate_line_edit_text(text: String) -> void:
	if text.is_empty():
		text = str(int(slider_value.value))
	
	var value = clamp(int(text), 0, 100)
	line_edit_value.text = str(value)
	slider_value.value = value
	value_changed.emit(value)
	line_edit_value.caret_column = line_edit_value.text.length()



func _on_slider_value_changed(_value: float) -> void:
	value_changed.emit(_value)
	line_edit_value.text = str(int(_value))
	line_edit_value.caret_column = line_edit_value.text.length()
	pass



func _on_hold_trigger_timeout() -> void:
	if _is_hold_left:
		slider_value.value -= 1
		_hold_trigger_timer.start()
	if _is_hold_right:
		slider_value.value += 1
		_hold_trigger_timer.start()
	pass


func _on_button_left_hold_timeout() -> void:
	_hold_trigger_timer.start()
	pass


func _on_button_left_up() -> void:
	slider_value.value -= 1
	_button_hold_timer.stop()
	_is_hold_left = false
	pass



func _on_button_left_down() -> void:
	_button_hold_timer.start()
	_is_hold_left = true
	pass



func _on_button_right_hold_timeout() -> void:
	_hold_trigger_timer.start()
	pass


func _on_button_right_up() -> void:
	slider_value.value += 1
	_button_hold_timer.stop()
	_is_hold_right = false
	pass


func _on_button_right_down() -> void:
	_button_hold_timer.start()
	_is_hold_right = true
	pass
