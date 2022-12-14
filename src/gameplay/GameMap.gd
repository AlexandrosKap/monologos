extends Spatial

signal map_visibility_changed()
signal map_position_changed()
signal music_stoped()

enum MapState {
	IDLE, MOVE, ANIMATION
}

const MOVE_VALUE := Vector3(0, 0, -0.815)
const SPIN_VALUE := Vector3(0, PI / 2.0, 0)

var state = 0

export var ground_material : SpatialMaterial

onready var tween: Tween = $Tween
onready var bgmtween: Tween = $BGMTween
onready var camera: Camera = $Camera
onready var noise: Sprite3D = $Camera/Noise
onready var target: TextureRect = $Target
onready var ground : MeshInstance = $Ground
onready var move_sound: AudioStreamPlayer = $MoveSound
onready var ghost_sound: AudioStreamPlayer = $GhostSound
onready var camera_start_translation: Vector3 = camera.translation
onready var run_sound: AudioStreamPlayer = $RunSound
onready var death_sound: AudioStreamPlayer = $DeathSound
onready var anim: AnimationPlayer = $Anim
onready var black: ColorRect = $Black
onready var wind_music: AudioStreamPlayer = $WindMusic
onready var boop_sound: AudioStreamPlayer = $BoopSound
onready var bgm: AudioStreamPlayer = $BGM
onready var boop_sound_pitch := boop_sound.pitch_scale
onready var bgm_vol := bgm.volume_db

func _ready() -> void:
	bgm.volume_db = -80
	tween.connect("tween_all_completed", self, "on_tween_all_completed")
	bgmtween.connect("tween_all_completed", self, "on_bgmtween_all_completed")
	set_material(ground_material)

func is_active() -> bool:
	return tween.is_active()

func show_map(time: float) -> void:
	noise.show()
	tween.interpolate_property(
		noise, "opacity", 1.0, 0.0, time, Tween.TRANS_SINE
	)
	tween.start()
	state = MapState.ANIMATION

func hide_map(time: float) -> void:
	noise.show()
	tween.interpolate_property(
		noise, "opacity", 0.0, 1.0, time, Tween.TRANS_SINE
	)
	tween.start()
	state = MapState.ANIMATION

func set_map_visibility(value: bool, time: float) -> void:
	if value:
		show_map(time)
	else:
		hide_map(time)

func is_map_visible() -> bool:
	return not noise.visible

func set_material(material: SpatialMaterial) -> void:
	ground.set_surface_material(0, material)

func play_sound(sound: AudioStreamPlayer, base := 1.0) -> void:
	sound.pitch_scale = Lib.random_scale(sound.pitch_scale, base)
	sound.play()

func play_music(music: String) -> void:
	if not music.empty():
		bgm.stream = Lib.load_music(music)
		bgm.play()
		bgmtween.interpolate_property(
			bgm, "volume_db",
			-80, bgm_vol,
			3, Tween.TRANS_SINE
		)
		bgmtween.start()
	else:
		bgm.stream = null

func stop_music() -> void:
	if bgm.stream != null:
		bgmtween.interpolate_property(
			bgm, "volume_db",
			bgm_vol, -80,
			1, Tween.TRANS_SINE
		)
		bgmtween.start()

func tweeen(prop: String, value: Vector3, time: float) -> void:
	# Target tween.
	tween.interpolate_property(
		target, "modulate",
		Lib.C0, target.modulate,
		time / 2.0, Tween.TRANS_SINE
	)
	tween.interpolate_property(
		target, "rect_scale",
		Vector2(1, 1), target.rect_scale,
		time / 2.0, Tween.TRANS_SINE
	)
	# Camera tween.
	tween.interpolate_property(
		camera, prop,
		camera.get(prop), value,
		time, Tween.TRANS_SINE
	)
	tween.start()
	state = MapState.MOVE

func dont_move(time: float) -> void:
	tween.interpolate_property(
		camera, "translation",
		camera.translation, camera.translation + MOVE_VALUE.rotated(Vector3.UP, camera.rotation.y) / 2.0,
		time / 2.0, Tween.TRANS_SINE
	)
	tween.interpolate_property(
		camera, "translation",
		camera.translation + MOVE_VALUE.rotated(Vector3.UP, camera.rotation.y) / 2.0, camera.translation,
		time / 2.0, Tween.TRANS_SINE,
		Tween.EASE_IN_OUT, time / 2.0
	)
	tween.start()
	play_sound(boop_sound, boop_sound_pitch)
	state = MapState.MOVE

func move(time: float) -> void:
	tweeen(
		"translation",
		camera.translation + MOVE_VALUE.rotated(Vector3.UP, camera.rotation.y),
		time
	)
	play_sound(move_sound)

func spin_left_now() -> void:
	camera.rotation += SPIN_VALUE

func spin_right_now() -> void:
	camera.rotation -= SPIN_VALUE

func spin_left(time: float) -> void:
	tweeen("rotation", camera.rotation + SPIN_VALUE, time)
	
func spin_right(time: float) -> void:
	tweeen("rotation", camera.rotation - SPIN_VALUE, time)

func death() -> void:
	death_sound.play()
	black.color.a = 1
	wind_music.playing = false

func set_target_texture(texture: StreamTexture) -> void:
	if texture != null and target.texture == null:
		play_sound(ghost_sound)
	elif texture == null and target.texture != null:
		run_sound.play()
	target.texture = texture
	anim.play("black")

func on_tween_all_completed() -> void:
	camera.translation = camera_start_translation
	if noise.opacity == 0.0:
		noise.hide()
	match state:
		MapState.MOVE:
			emit_signal("map_position_changed")
		MapState.ANIMATION:
			emit_signal("map_visibility_changed")
	state = MapState.IDLE

func on_bgmtween_all_completed() -> void:
	emit_signal("music_stoped")
