extends Area3D

@export var SPEED: float = 22.0
@export var LIFETIME: float = 1.2 # Destroy after 1.2s if no wall/target is hit

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	
	# Cleanup timer
	get_tree().create_timer(LIFETIME).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	# Fly straight forward
	position += -transform.basis.z * SPEED * delta

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		return # Don't collide with the shooter!
	queue_free()

func _on_area_entered(_area: Area3D) -> void:
	queue_free()
