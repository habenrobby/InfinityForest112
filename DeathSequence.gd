extends CanvasLayer

@onready var fade: ColorRect = $Fade
@onready var jumpscare_image: TextureRect = $JumpscareImage
@onready var footstep_player: AudioStreamPlayer = $FootstepPlayer
@onready var jumpscare_sfx: AudioStreamPlayer = $JumpscareSFX

@export var fade_duration := 1.0
@export var footstep_duration := 2.0
@export var silence_gap := 1.0
@export var jumpscare_hold := 1.2

func _ready() -> void:
	fade.material.set_shader_parameter("vignette_strength", 0.0)
	jumpscare_image.visible = false

func play_death_sequence() -> void:
	_lock_player_input(true)

	var tween = create_tween()
	tween.tween_method(_set_vignette_strength, 0.0, 1.0, fade_duration)
	await tween.finished

	footstep_player.play()
	await get_tree().create_timer(footstep_duration).timeout
	footstep_player.stop()

	await get_tree().create_timer(silence_gap).timeout

	jumpscare_image.visible = true
	jumpscare_sfx.play()
	await get_tree().create_timer(jumpscare_hold).timeout

	GameState.increment_loop()
	get_tree().reload_current_scene()

func _set_vignette_strength(value: float) -> void:
	print("Setting vignette strength to: ", value)
	fade.material.set_shader_parameter("vignette_strength", value)

func _lock_player_input(locked: bool) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.set_physics_process(not locked)
		var head = player.get_node("Head")
		if head:
			head.set_process_input(not locked)
