extends MarginContainer
class_name ValueSelection

signal value_changed(_value: float)


@export var value_options : Array[String]


@export var is_on: bool = true : set = _set_is_on

@export var option_text: String = "Lorem ipstum"

@export var text_normal_color: Color = "#ffffffff"
@export var text_focus_color: Color = "#1fcff2"

@onready var option_label : Label = %LabelSlider
@onready var button_value : Button = %ButtonValue

@onready var button_left: TextureButton = %ButtonLeft
@onready var button_right: TextureButton = %ButtonRight




func _ready() -> void:
	option_label.text = option_text
	connect_comnonent()

	pass


func _input(event: InputEvent) -> void:
	pass



func setup_value() -> void:
	pass



func connect_comnonent() -> void:
	connect_button()

	mouse_entered.connect(_on_slider_focus_entered)
	mouse_exited.connect(_on_slider_focus_exited)

	button_value.mouse_entered.connect(_on_slider_focus_entered)
	button_value.mouse_exited.connect(_on_slider_focus_exited)

	button_left.mouse_entered.connect(_on_slider_focus_entered)
	button_left.mouse_exited.connect(_on_slider_focus_exited)

	button_right.mouse_entered.connect(_on_slider_focus_entered)
	button_right.mouse_exited.connect(_on_slider_focus_exited)

	


func connect_button() -> void:
	button_value.pressed.connect(_on_button_value_pressed)
	button_left.pressed.connect(_on_button_left_pressed)
	button_right.pressed.connect(_on_button_right_pressed)
	pass


func _set_is_on(_value: bool) -> void:
	is_on = _value
	if is_on:
		button_value.text = "ON"
	else:
		button_value.text = "OFF"
	pass


func _on_button_value_pressed() -> void:
	is_on = !is_on
	pass

func _on_slider_focus_entered() -> void:
	# $MyLabel.remove_theme_color_override("font_color")
	option_label.add_theme_color_override("font_color", text_focus_color)
	pass


func _on_slider_focus_exited() -> void:
	# $MyLabel.remove_theme_color_override("font_color")
	option_label.add_theme_color_override("font_color", text_normal_color)
	pass


func _on_button_left_pressed() -> void:
	is_on = !is_on
	pass


func _on_button_right_pressed() -> void:
	is_on = !is_on
	pass
