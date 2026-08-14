extends CharacterBody3D

@export var sway_width: float = 6.0       # How far left/right it travels (X axis)
@export var sway_depth: float = 2.5       # How far forward/back it curves (Z axis)
@export var sway_speed: float = 1.2       # Speed of the side-to-side pattern
@export var hover_amplitude: float = 0.25  # How high/low it bobs (Y axis)
@export var hover_speed: float = 2.8      # Frequency of vertical bobbing
@export var tilt_amount: float = 0.15     # Dynamic banking/leaning angle

var time_passed: float = 0.0
var spawn_pos: Vector3

func _ready() -> void:
	# Lock down the initial spawn spot as the center point of the flight path
	spawn_pos = global_position

func _physics_process(delta: float) -> void:
	time_passed += delta
	
	# 1. Unpredictable Curved Movement (Combined Sine + Cosine Waves)
	var offset_x = sin(time_passed * sway_speed) * sway_width
	var offset_z = cos(time_passed * sway_speed * 0.7) * sway_depth
	var offset_y = sin(time_passed * hover_speed) * hover_amplitude
	
	# Calculate target position around its spawn center
	var target_pos = spawn_pos + Vector3(offset_x, offset_y, offset_z)
	
	# 2. Smooth Banking/Tilting into the Curve
	var current_move_dir_x = cos(time_passed * sway_speed) # Derivative of X movement
	rotation.z = lerp_angle(rotation.z, -current_move_dir_x * tilt_amount, delta * 4.0)
	
	# Apply path position directly
	global_position = global_position.lerp(target_pos, delta * 8.0)
	
	move_and_slide()
