extends Control

@export var back_button: Button

func _ready() -> void:
	if back_button:
		back_button.grab_focus.call_deferred()
		back_button.pressed.connect(_on_back_button_pressed)
	# back_button.button_up
	pass


func _on_back_button_pressed() -> void:
	GuiManager.switch_gui_panel(GuiManager.GUIPanel.START_SCREEN)
	pass # Replace with function body.
