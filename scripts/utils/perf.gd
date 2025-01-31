class_name Perf
extends Object

var t : int

func _init() -> void:
	t = Time.get_ticks_msec()

func print_delta(label: String) -> void:
	var t2 := Time.get_ticks_msec()
	prints(label, t2 - t, "ms")
	t = t2
