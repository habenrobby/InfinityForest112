extends SpotLight3D

@export var base_energy := 2.0
@export var flare_energy := 6.0
@export var flare_duration := 0.3
@export var smoothing_speed := 6.0
@export var min_energy_floor := 1.0  # torch can never dim below this

var flare_timer := 0.0
var target_energy := 0.0
var external_dim_factor := 1.0

func _ready():
	target_energy = base_energy
	light_energy = base_energy

func _process(delta: float) -> void:
	if flare_timer > 0.0:
		flare_timer -= delta
		target_energy = flare_energy
	else:
		target_energy = base_energy

	var effective_target = target_energy * external_dim_factor
	effective_target = max(effective_target, min_energy_floor)

	light_energy = lerp(light_energy, effective_target, delta * smoothing_speed)

func flare() -> void:
	flare_timer = flare_duration

func set_dim_factor(factor: float) -> void:
	external_dim_factor = clamp(factor, 0.0, 1.0)
