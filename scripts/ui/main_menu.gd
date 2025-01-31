class_name MainMenu
extends Control

signal button_clicked(b: ButtonType)

enum ButtonType { OPEN, SAVE, SETTINGS, NEW }

@onready var _open_button := %OpenButton as Button
@onready var _save_button := %SaveButton as Button
@onready var _settings_button := %SettingsButton as Button
@onready var _new_button := %NewButton as Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_open_button.pressed.connect(button_clicked.emit.bind(ButtonType.OPEN))
	_save_button.pressed.connect(button_clicked.emit.bind(ButtonType.SAVE))
	_settings_button.pressed.connect(button_clicked.emit.bind(ButtonType.SETTINGS))
	_new_button.pressed.connect(button_clicked.emit.bind(ButtonType.NEW))
