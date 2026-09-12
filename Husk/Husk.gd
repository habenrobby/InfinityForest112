extends CharacterBody3D

enum State { PATROL, INVESTIGATE, CHASE, LOST }
var current_state = State.PATROL

@export var patrol_speed := 2.0
@export var chase_speed := 6.5
@export var lost_duration := 4.0
@export var suppression_radius := 6.0
@export var max_suppression := 0.5
@export var starts_sitting := false

var lost_timer := 0.0
var last_known_position := Vector3.ZERO
var player: Node3D = null

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var detection_area: Area3D = $DetectionArea
@onready var catch_area: Area3D = $CatchArea
@onready var sprite: AnimatedSprite3D = $Sprite3D
@onready var patrol_points: Array = get_node("/root/L_Main/HuskSpawns").get_children()
var patrol_target := Vector3.ZERO
var patrol_wait_timer := 0.0
const PATROL_WAIT_TIME := 2.0
var is_sitting := false

func _ready():
	is_sitting = starts_sitting
	if is_sitting:
		sprite.play("eating")
	player = get_tree().get_first_node_in_group("player")
	detection_area.body_entered.connect(_on_detection_area_entered)
	catch_area.body_entered.connect(_on_catch_area_entered)
	_pick_new_patrol_target()

func _physics_process(delta: float) -> void:
	_update_torch_suppression()

	match current_state:
		State.PATROL:
			if is_sitting:
				sprite.play("eating")
			else:
				if patrol_wait_timer > 0.0:
					patrol_wait_timer -= delta
				else:
					_move_toward(patrol_target, patrol_speed)
					if global_position.distance_to(patrol_target) < 1.5:
						_pick_new_patrol_target()
						patrol_wait_timer = PATROL_WAIT_TIME
		State.INVESTIGATE:
			_move_toward(last_known_position, patrol_speed * 1.5)
			if global_position.distance_to(last_known_position) < 1.0:
				_change_state(State.LOST)
		State.CHASE:
			if player:
				last_known_position = player.global_position
				_move_toward(player.global_position, _get_scaled_chase_speed())
		State.LOST:
			lost_timer -= delta
			if lost_timer <= 0.0:
				_change_state(State.PATROL)

	move_and_slide()

func _pick_new_patrol_target() -> void:
	if patrol_points.size() > 0:
		patrol_target = patrol_points[randi() % patrol_points.size()].global_position

func _get_scaled_chase_speed() -> float:
	var difficulty = GameState.get_difficulty()
	return lerp(chase_speed * 0.6, chase_speed, difficulty)

func _move_toward(target_pos: Vector3, speed: float) -> void:
	nav_agent.target_position = target_pos
	if nav_agent.is_navigation_finished():
		return
	var next_pos = nav_agent.get_next_path_position()
	var direction = (next_pos - global_position).normalized()
	velocity.x = direction.x * speed
	velocity.z = direction.z * speed

func _change_state(new_state) -> void:
	current_state = new_state
	if new_state == State.LOST:
		lost_timer = lost_duration
	elif new_state == State.INVESTIGATE:
		sprite.play("look_back")

func _on_detection_area_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_sitting = false
		sprite.play("spot")
		await sprite.animation_finished
		sprite.play("chase")
		_change_state(State.CHASE)

func _on_catch_area_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		get_tree().call_group("game_manager", "player_caught")

func _update_torch_suppression() -> void:
	if player == null:
		return
	var torch = player.get_node("Head/Camera/Torch")
	var distance = global_position.distance_to(player.global_position)
	var difficulty = GameState.get_difficulty()

	if distance <= suppression_radius and difficulty > 0.0:
		var proximity_factor = 1.0 - (distance / suppression_radius)
		var dim_amount = difficulty * max_suppression * proximity_factor
		torch.set_dim_factor(1.0 - dim_amount)
	else:
		torch.set_dim_factor(1.0)
