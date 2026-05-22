extends Node

var _swing_light: AudioStreamPlayer
var _swing_heavy: AudioStreamPlayer
var _dodge: AudioStreamPlayer
var _hit_enemy: AudioStreamPlayer
var _hit_player: AudioStreamPlayer
var _player_death: AudioStreamPlayer

func _ready() -> void:
	_swing_light  = _make(preload("res://sounds/swing_light.ogg"))
	_swing_heavy  = _make(preload("res://sounds/swing_heavy.ogg"))
	_dodge        = _make(preload("res://sounds/dodge.ogg"))
	_hit_enemy    = _make(preload("res://sounds/hit_enemy.ogg"))
	_hit_player   = _make(preload("res://sounds/hit_player.ogg"))
	_player_death = _make(preload("res://sounds/player_death.ogg"))

func _make(stream: AudioStream) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	return p

func play_swing_light() -> void:
	_swing_light.pitch_scale = randf_range(0.95, 1.05)
	_swing_light.play()

func play_swing_heavy() -> void:
	_swing_heavy.pitch_scale = randf_range(0.93, 1.07)
	_swing_heavy.play()

func play_dodge() -> void:
	_dodge.pitch_scale = randf_range(0.95, 1.05)
	_dodge.play()

func play_hit_enemy() -> void:
	_hit_enemy.pitch_scale = randf_range(0.93, 1.07)
	_hit_enemy.play()

func play_hit_player() -> void:
	_hit_player.play()

func play_player_death() -> void:
	_player_death.play()
