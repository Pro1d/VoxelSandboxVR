extends Node

@onready var ui_pressed_sound := AudioStreamPlayer.new()
@onready var ui_hovered_sound := AudioStreamPlayer.new()
var _hover_rumble := XRToolsRumbleEvent.new()
var _press_rumble := XRToolsRumbleEvent.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	ui_pressed_sound.bus = &"UI"
	ui_hovered_sound.bus = &"UI"
	ui_pressed_sound.stream = preload("res://assets/sounds/tuck.ogg")
	ui_hovered_sound.stream = preload("res://assets/sounds/touck.ogg")
	add_child(ui_pressed_sound)
	add_child(ui_hovered_sound)
	_hover_rumble.duration_ms = 15
	_hover_rumble.magnitude = 0.25
	_press_rumble.duration_ms = 30
	_press_rumble.magnitude = 0.6

func keep_until_finished(audio: Node) -> void: # AudioStreamPlayer[2D]
	audio.get_parent().remove_child(audio)
	add_child(audio)
	
	var asp := audio as AudioStreamPlayer
	if asp != null:
		asp.finished.connect(audio.queue_free)
		return
	var asp2d := audio as AudioStreamPlayer2D
	if asp2d != null:
		asp2d.finished.connect(audio.queue_free)
		return
	var asp3d := audio as AudioStreamPlayer3D
	if asp3d != null:
		asp3d.finished.connect(audio.queue_free)
		return

func connect_all_buttons(node: Node) -> void:
	if node is HoldToPressButton:
		connect_hold_to_press_button(node as HoldToPressButton)
	elif node is BaseButton:
		connect_button(node as BaseButton)
	elif node is OptionButton:
		connect_option_button(node as OptionButton)
	for c in node.get_children():
		connect_all_buttons(c)

func connect_button(button: BaseButton) -> void:
	button.pressed.connect(ui_pressed_sound.play)
	#button.mouse_entered.connect(ui_hovered_sound.play)
	button.pressed.connect(_play_rumble_on_press)
	button.mouse_entered.connect(_play_rumble_on_hover)

func connect_hold_to_press_button(button: HoldToPressButton) -> void:
	button.hold_pressed.connect(ui_pressed_sound.play)
	#button.mouse_entered.connect(ui_hovered_sound.play)
	button.hold_pressed.connect(_play_rumble_on_press)
	button.mouse_entered.connect(_play_rumble_on_hover)

func connect_option_button(button: OptionButton) -> void:
	connect_button(button)
	button.item_selected.connect(ui_pressed_sound.play)

func _play_rumble_on_hover() -> void:
	XRToolsRumbleManager.add("button", _hover_rumble, [&"right_hand"])
func _play_rumble_on_press() -> void:
	XRToolsRumbleManager.add("button", _press_rumble, [&"right_hand"])
