extends MarginContainer
class_name ScreenScale

signal value_changed(_value: float)


@export var value_options : Array[String]


@export var option_text: String = "Lorem ipstum"

@export var text_normal_color: Color = "#ffffffff"
@export var text_focus_color: Color = "#1fcff2"

@onready var option_label : Label = %LabelSlider
@onready var button_value : Button = %ButtonValue

@onready var button_left: TextureButton = %ButtonLeft
@onready var button_right: TextureButton = %ButtonRight

var max_screen_scale: int = 1
var current_screen_scale: int = 1:
	set(value):
		current_screen_scale = value
		button_value.text = "X" + str(current_screen_scale)
		value_changed.emit(current_screen_scale)


func _ready() -> void:
	option_label.text = option_text
	max_screen_scale = int(DisplayServer.screen_get_size().x / GameWindow.game_base_resolution.x)
	current_screen_scale = 1
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


func add_screen_scale(_value: int) -> void:
	current_screen_scale += _value

	if current_screen_scale > max_screen_scale:
		current_screen_scale = 1
	
	if current_screen_scale <= 0:
		current_screen_scale = max_screen_scale
	pass



func _on_button_value_pressed() -> void:
	add_screen_scale(1)
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
	add_screen_scale(-1)

	pass


func _on_button_right_pressed() -> void:
	add_screen_scale(1)

	pass
