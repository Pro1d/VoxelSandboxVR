class_name BottomBar
extends PanelContainer

signal back_clicked()
signal close_clicked()


@onready var _title_label := %Label as Label
@onready var _back_button := %BackButton as Button
@onready var _close_button := %CloseButton as Button

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_close_button.pressed.connect(close_clicked.emit)
	_back_button.pressed.connect(back_clicked.emit)

func set_content(title: String, back: bool, close: bool) -> void:
	_title_label.text = title
	_back_button.visible = back
	_close_button.visible = close
