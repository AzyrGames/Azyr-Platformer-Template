extends Control


@export var start_button: Button
@export var setting_button: Button
@export var credit_button: Button
@export var quit_button: Button


func _ready() -> void:
	start_button.grab_focus.call_deferred()
	connect_button()


func connect_button() -> void:
	start_button.button_up.connect(_on_start_button_button_up)
	setting_button.button_up.connect(_on_setting_button_button_up)
	credit_button.button_up.connect(_on_credit_button_button_up)
	quit_button.button_up.connect(_on_quit_button_button_up)
	pass


func _on_start_button_button_up() -> void:
	EventBus.start_game.emit()
	GuiManager.switch_gui_panel(GuiManager.GUIPanel.CLOSED)
	pass


func _on_setting_button_button_up() -> void:
	GuiManager.switch_gui_panel(GuiManager.GUIPanel.SETTING_MENU)
	pass

func _on_quit_button_button_up() -> void:
	EventBus.quit_game.emit()
	pass


func _on_credit_button_button_up() -> void:
	GuiManager.switch_gui_panel(GuiManager.GUIPanel.CREDIT_SCREEN)
	pass # Replace with function body.
