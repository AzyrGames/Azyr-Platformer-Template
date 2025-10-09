extends Control
class_name SettingMenu

enum AudioBus {
	Master,
	Music,
	SFX
}

@onready var back_button: Button = %BackButton


@export var screen_scale : ScreenScale
@export var value_toggle_fullscreen : ValueToggle
@export var value_toggle_vsync : ValueToggle


@export var value_slider_master: ValueSlider
@export var value_slider_music: ValueSlider 
@export var value_slider_sfx: ValueSlider

@export var value_slider_screen_shake: ValueSlider

var user_settings: UserSettings


func _ready() -> void:
	connect_event_bus()
	setup_setting_gui()
	pass

func setup_setting_gui() -> void:
	user_settings = UserSettings.load_or_create()
	screen_scale.current_screen_scale = user_settings.screen_resolution_scaling
	if value_toggle_fullscreen:
		value_toggle_fullscreen.is_on = user_settings.is_full_screen
		GameWindow.set_full_screen(value_toggle_fullscreen.is_on)

	if value_toggle_vsync:
		value_toggle_vsync.is_on = user_settings.is_vsync
		GameWindow.set_vsync(value_toggle_vsync.is_on)

	value_slider_master.slider_value.value = user_settings.master_volume
	value_slider_music.slider_value.value = user_settings.music_volume
	value_slider_sfx.slider_value.value = user_settings.sfx_volume
	value_slider_screen_shake.slider_value.value = user_settings.screen_shake

	connect_window_related()
	connect_value_slider()
	pass
	

func _load_user_settings() -> void:
	pass


func connect_event_bus() -> void:
	EventBus.is_full_screen.connect(_on_is_full_screen)



func connect_window_related() -> void:
	if screen_scale:
		screen_scale.value_changed.connect(_on_screen_scale_value_changed)
	if value_toggle_fullscreen:
		value_toggle_fullscreen.value_changed.connect(_on_value_toggle_fullscreen_value_changed)
	if value_toggle_vsync:
		value_toggle_vsync.value_changed.connect(_value_toggle_vsync_value_chagned)
	pass


func connect_value_slider() -> void:
	if value_slider_master:
		value_slider_master.value_changed.connect(_on_value_slider_master_value_changed)
	if value_slider_music:
		value_slider_music.value_changed.connect(_on_value_slider_music_value_changed)
	if value_slider_sfx:
		value_slider_sfx.value_changed.connect(_on_value_slider_sfx_value_changed)
	if value_slider_screen_shake:
		value_slider_screen_shake.value_changed.connect(_on_value_slider_screen_shake_value_changed)
	pass



func go_back_setting_menu() -> void:
	if GameManager.is_game_active:
		GuiManager.switch_gui_panel(GuiManager.GUIPanel.PAUSE_MENU)
	else:
		GuiManager.switch_gui_panel(GuiManager.GUIPanel.START_SCREEN)

func set_audio_bus_volume(_bus_name: String, value: float) -> void:
	var _bus_index := AudioServer.get_bus_index(_bus_name)
	AudioServer.set_bus_volume_db(_bus_index, linear_to_db(value))
	var _user_settings := UserSettings.load_or_create()


func _on_is_full_screen(_value: bool) -> void:
	print("value_toggle_fullscreen: ", value_toggle_fullscreen)
	value_toggle_fullscreen.is_on = _value

func _on_back_button_button_up() -> void:
	go_back_setting_menu()


func _on_screen_scale_value_changed(_value: float) -> void:
	GameWindow.set_resolution_scaling(int(_value))
	user_settings.screen_resolution_scaling = int(_value)
	user_settings.save()

	pass


func _on_value_toggle_fullscreen_value_changed(_value: float) -> void:
	GameWindow.set_full_screen(_value)
	user_settings.is_full_screen = _value
	user_settings.save()
	pass


func _value_toggle_vsync_value_chagned(_value: float) -> void:
	GameWindow.set_vsync(_value)
	user_settings.is_vsync = _value
	user_settings.save()
	pass



func _on_value_slider_master_value_changed(value: float) -> void:
	set_audio_bus_volume("Master", value)
	user_settings.master_volume = value
	user_settings.save()
	

func _on_value_slider_music_value_changed(value: float) -> void:
	set_audio_bus_volume("Music", value)
	user_settings.music_volume = value
	user_settings.save()


func _on_value_slider_sfx_value_changed(value: float) -> void:
	set_audio_bus_volume("SFX", value)
	user_settings.sfx_volume = value
	user_settings.save()


func _on_value_slider_screen_shake_value_changed(value: float) -> void:
	user_settings.screen_shake = value
	user_settings.save()
