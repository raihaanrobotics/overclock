extends CharacterBody3D

# ==============================================================================
# OVERCLOCK - MERGED PLAYER CONTROLLER
# Features Isometric Locomotion with Clamped Side-to-Side Twist, Standard Weapon,
# Overclock Chest Beam, Heat Core, Vent Freeze, EMP Pulse, and Health Systems.
# ==============================================================================

# --- LOCOMOTION SETTINGS ---
@export_group("Locomotion")
@export var SPEED: float = 4.0
@export var SPRINT_SPEED: float = 6.5
@export var ROTATION_SPEED: float = 12.0
@export var ACCELERATION: float = 10.0
@export var MAX_TWIST_ANGLE: float = 25.0 # Max degrees character twists left/right

# --- HEALTH SYSTEM ---
@export_group("Health System")
@export var max_health: float = 100.0
var current_health: float = 100.0

# --- OVERCLOCK HEAT SYSTEM ---
@export_group("Overclock Heat Core")
@export var heat_level: float = 0.0            # 0.0% to 100.0%
@export var heat_buildup_rate: float = 35.0     # Heat gained per second firing chest beam
@export var heat_cool_rate: float = 30.0        # Cooling speed per second during Vent Freeze
@export var vent_freeze_duration: float = 2.0   # Seconds frozen while cooling suit

var is_overclocking: bool = false
var is_venting: bool = false
var is_shooting: bool = false
var is_dead: bool = false
var vent_timer: float = 0.0

# --- WEAPON SETTINGS ---
@export_group("Weapons")
@export var laser_scene: PackedScene = preload("res://scenes/laserbullet/laser_bullet.tscn")

# --- SIGNALS FOR HUD & GAME CONTROLLER ---
signal health_changed(new_health: float, max_health: float)
signal heat_changed(new_heat: float, in_danger_zone: bool, multiplier: float)
signal player_overheated()
signal player_died()
signal emp_pulse_emitted()

# --- SAFE NODE REFERENCES ---
@onready var anim_player: AnimationPlayer = find_child("AnimationPlayer", true, false)
@onready var muzzle: Node3D = _get_muzzle_node()
@onready var chest_origin: Node3D = find_child("chestbeamorigin", true, false)
@onready var beam_mesh: MeshInstance3D = find_child("BeamMesh", true, false)

# Dynamically assigned to align player's back straight to camera
var locked_back_angle: float = 0.0

func _ready() -> void:
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)
	emit_emp_pulse() # Suit emits EMP pulse on wave start

	# Force beam mesh hidden on start
	if beam_mesh:
		beam_mesh.visible = false

	# Safely lock back angle to the camera's flat horizontal orientation only
	var camera := get_viewport().get_camera_3d()
	if camera:
		var cam_forward := -camera.global_transform.basis.z
		cam_forward.y = 0 # Flatten onto the XZ plane
		cam_forward = cam_forward.normalized()
		locked_back_angle = atan2(-cam_forward.x, -cam_forward.z)
		rotation.y = locked_back_angle

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	# Keep height locked on the arena surface
	velocity.y = 0

	# --- VENTING PROCESS (MOVEMENT REMAINS ACTIVE) ---
	if is_venting:
		_process_venting(delta)

	# --- INPUT DIRECTION ---
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var raw_dir := Vector3(input_dir.x, 0, input_dir.y)
	
	# Translate directional vectors into isometric 45-degree world movement
	var direction := raw_dir.rotated(Vector3.UP, deg_to_rad(-45)).normalized()

	# --- DYNAMIC BODY TWIST (NEVER FACES FRONT) ---
	var target_angle := locked_back_angle
	if input_dir.x != 0.0 and not is_shooting and not is_overclocking:
		var twist_rad : float = clamp(-input_dir.x * deg_to_rad(MAX_TWIST_ANGLE), deg_to_rad(-MAX_TWIST_ANGLE), deg_to_rad(MAX_TWIST_ANGLE))
		target_angle += twist_rad

	# Lock body straight forward when shooting or deploying chest beam
	if is_overclocking or is_shooting:
		rotation.y = locked_back_angle
	else:
		rotation.y = lerp_angle(rotation.y, target_angle, ROTATION_SPEED * delta)

	# --- OVERCLOCK CHEST BEAM (RIGHT CLICK / E KEY) ---
	if not is_venting and (Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT) or Input.is_key_pressed(KEY_E)):
		_process_overclock_beam(delta)
	elif is_overclocking:
		_stop_overclock_and_vent()

	# --- STANDARD SHOOTING (LEFT CLICK / SPACEBAR) ---
	if not is_venting and (Input.is_action_just_pressed("ui_accept") or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)) and not is_overclocking:
		shoot_laser()

	# --- LOCOMOTION & ACCELERATION ---
	if direction != Vector3.ZERO:
		var is_sprinting := Input.is_action_pressed("sprint") and not is_shooting and not is_overclocking
		var current_speed := SPRINT_SPEED if is_sprinting else SPEED
		velocity.x = lerp(velocity.x, direction.x * current_speed, ACCELERATION * delta)
		velocity.z = lerp(velocity.z, direction.z * current_speed, ACCELERATION * delta)
		
		_play_movement_animation()
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED * delta * 5.0)
		velocity.z = move_toward(velocity.z, 0, SPEED * delta * 5.0)
		
		_play_idle_animation()

	move_and_slide()

# ==============================================================================
# MECHANIC: OVERCLOCK CHEST BEAM & RISK/REWARD HEAT SYSTEM
# ==============================================================================

func _process_overclock_beam(delta: float) -> void:
	# Trigger laser beam sound when first activating overclocking
	if not is_overclocking:
		audiomanager.play_laser_beam()

	is_overclocking = true
	
	# Force player alignment straight forward
	rotation.y = locked_back_angle

	# Lock beam origin level with ground in world space so skeletal bone tilt/roll never bends the beam
	if chest_origin:
		chest_origin.global_rotation = Vector3(0.0, rotation.y, 0.0)

	heat_level += heat_buildup_rate * delta
	
	if beam_mesh:
		beam_mesh.visible = true

	# Danger Zone (80% to 95%): Score Multiplier skyrockets
	var in_danger_zone := heat_level >= 80.0 and heat_level <= 95.0
	var multiplier := 5.0 if in_danger_zone else (1.0 + (heat_level / 20.0))
	
	emit_signal("heat_changed", heat_level, in_danger_zone, multiplier)
	
	# Vigorous camera shake
	_trigger_camera_shake(0.35)

	# 100% Heat: Overheat Detonation
	if heat_level >= 100.0:
		detonate_suit()

func _stop_overclock_and_vent() -> void:
	is_overclocking = false
	if beam_mesh:
		beam_mesh.visible = false
		
	if heat_level > 0.0:
		is_venting = true
		vent_timer = vent_freeze_duration

func _process_venting(delta: float) -> void:
	# Cool down heat level while movement stays fully active
	heat_level = max(heat_level - heat_cool_rate * delta, 0.0)
	
	var in_danger_zone := heat_level >= 80.0 and heat_level <= 95.0
	var multiplier := 1.0
	
	emit_signal("heat_changed", heat_level, in_danger_zone, multiplier)

	vent_timer -= delta
	if vent_timer <= 0.0 or heat_level <= 0.0:
		is_venting = false

func reduce_heat_on_kill(amount: float = 15.0) -> void:
	if is_overclocking:
		heat_level = max(heat_level - amount, 0.0)
		var in_danger_zone := heat_level >= 80.0 and heat_level <= 95.0
		emit_signal("heat_changed", heat_level, in_danger_zone, 5.0 if in_danger_zone else 1.0)

# ==============================================================================
# MECHANIC: STANDARD WEAPON & ANIMATIONS (Pistol_Idle, Sprint, Pistol_Shoot)
# ==============================================================================

func shoot_laser() -> void:
	audiomanager.play_gun_fire()

	rotation.y = locked_back_angle

	var active_muzzle = muzzle if muzzle else _get_muzzle_node()
	
	if laser_scene and active_muzzle:
		var bullet = laser_scene.instantiate()
		get_tree().current_scene.add_child(bullet)
		bullet.global_position = active_muzzle.global_position
		bullet.global_rotation = Vector3(0, rotation.y, 0)
		_trigger_camera_shake(0.15)

	var shoot_anim := _find_matching_anim(["Pistol_Shoot", "pisotl_shoot"])
	if shoot_anim != "" and anim_player:
		is_shooting = true
		anim_player.stop()
		anim_player.play(shoot_anim)
		
		var anim_len = anim_player.get_animation(shoot_anim).length
		get_tree().create_timer(anim_len).timeout.connect(func(): is_shooting = false)

func _play_movement_animation() -> void:
	if anim_player and not is_shooting and not is_overclocking:
		var target_anim := _find_matching_anim(["Sprint", "sprint"])
		if target_anim != "" and anim_player.current_animation != target_anim:
			anim_player.play(target_anim)

func _play_idle_animation() -> void:
	if anim_player and not is_shooting:
		var idle_anim := _find_matching_anim(["Pistol_Idle", "pistol_idle"])
		if idle_anim != "" and anim_player.current_animation != idle_anim:
			anim_player.play(idle_anim)

func _find_matching_anim(candidates: Array[String]) -> String:
	if not anim_player:
		return ""
	for anim_name in candidates:
		if anim_player.has_animation(anim_name):
			return anim_name
	return ""

# ==============================================================================
# MECHANIC: EMP PULSE, HEALTH & DEATH
# ==============================================================================

func emit_emp_pulse() -> void:
	emit_signal("emp_pulse_emitted")

func take_damage(amount: float) -> void:
	if is_dead:
		return
		
	current_health = max(current_health - amount, 0.0)
	emit_signal("health_changed", current_health, max_health)
	
	if current_health <= 0.0:
		die()

func detonate_suit() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector3.ZERO
	emit_signal("player_overheated")
	emit_signal("player_died")

func die() -> void:
	if is_dead:
		return
	is_dead = true
	velocity = Vector3.ZERO
	emit_signal("player_died")

func _trigger_camera_shake(amount: float) -> void:
	var camera = get_viewport().get_camera_3d()
	if camera and camera.has_method("add_shake"):
		camera.add_shake(amount)

func _get_muzzle_node() -> Node3D:
	var found = find_child("Muzzle", true, false)
	if not found:
		found = find_child("muzzle", true, false)
	return found as Node3D
