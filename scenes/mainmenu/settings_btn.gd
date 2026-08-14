extends Button

# Tweens for smooth transition
var hover_tween: Tween

func _ready() -> void:
	# Set pivot to exact center so scaling happens from the middle
	pivot_offset = size / 2.0
	
	# Connect hover signals automatically
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween().set_parallel(true)
	# Dim the button (darken modulating color)
	hover_tween.tween_property(self, "modulate", Color(0.8, 0.8, 0.8, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
	# Optional slight shrink effect for a tactile feel
	hover_tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.15).set_trans(Tween.TRANS_SINE)

func _on_mouse_exited() -> void:
	if hover_tween:
		hover_tween.kill()
	
	hover_tween = create_tween().set_parallel(true)
	# Reset back to normal brightness
	hover_tween.tween_property(self, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
	# Reset back to normal size
	hover_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_trans(Tween.TRANS_SINE)
