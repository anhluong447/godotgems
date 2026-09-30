class_name SfxSynth
extends RefCounted
## Procedural placeholder sound effects so the backbone has audio feedback
## before real assets exist. Real files in assets/audio/sfx/ override these.

const MIX_RATE := 22050

enum Wave { SINE, SQUARE, SAW, NOISE }

## Each recipe is a list of layers: [wave, f_start, f_end, duration, volume, delay]
const RECIPES := {
	&"swing": [[Wave.NOISE, 900.0, 2400.0, 0.09, 0.35, 0.0]],
	&"hit": [[Wave.SQUARE, 180.0, 60.0, 0.07, 0.5, 0.0], [Wave.NOISE, 1200.0, 300.0, 0.06, 0.4, 0.0]],
	&"hit_heavy": [[Wave.SQUARE, 140.0, 40.0, 0.14, 0.6, 0.0], [Wave.NOISE, 900.0, 200.0, 0.12, 0.5, 0.0]],
	&"crit": [[Wave.SQUARE, 160.0, 50.0, 0.08, 0.5, 0.0], [Wave.SINE, 1400.0, 1800.0, 0.12, 0.3, 0.02]],
	&"hurt": [[Wave.SQUARE, 220.0, 90.0, 0.14, 0.5, 0.0]],
	&"dodge": [[Wave.NOISE, 400.0, 1600.0, 0.13, 0.3, 0.0]],
	&"shoot": [[Wave.SQUARE, 900.0, 300.0, 0.07, 0.3, 0.0]],
	&"skill": [[Wave.SQUARE, 330.0, 330.0, 0.06, 0.3, 0.0], [Wave.SQUARE, 440.0, 440.0, 0.06, 0.3, 0.06], [Wave.SQUARE, 660.0, 700.0, 0.1, 0.3, 0.12]],
	&"telegraph": [[Wave.SINE, 1100.0, 1100.0, 0.05, 0.2, 0.0], [Wave.SINE, 1100.0, 1100.0, 0.05, 0.2, 0.09]],
	&"enemy_die": [[Wave.NOISE, 1500.0, 100.0, 0.25, 0.45, 0.0], [Wave.SQUARE, 300.0, 60.0, 0.2, 0.3, 0.0]],
	&"break": [[Wave.NOISE, 2500.0, 400.0, 0.12, 0.5, 0.0]],
	&"pickup": [[Wave.SINE, 880.0, 880.0, 0.05, 0.3, 0.0], [Wave.SINE, 1320.0, 1320.0, 0.08, 0.3, 0.05]],
	&"level_up": [[Wave.SQUARE, 523.0, 523.0, 0.08, 0.25, 0.0], [Wave.SQUARE, 659.0, 659.0, 0.08, 0.25, 0.08], [Wave.SQUARE, 784.0, 784.0, 0.08, 0.25, 0.16], [Wave.SQUARE, 1046.0, 1046.0, 0.2, 0.25, 0.24]],
	&"door": [[Wave.SQUARE, 110.0, 70.0, 0.15, 0.4, 0.0], [Wave.NOISE, 600.0, 200.0, 0.1, 0.2, 0.0]],
	&"chest": [[Wave.SINE, 523.0, 523.0, 0.07, 0.3, 0.0], [Wave.SINE, 784.0, 784.0, 0.07, 0.3, 0.07], [Wave.SINE, 1046.0, 1046.0, 0.15, 0.3, 0.14]],
	&"ui_move": [[Wave.SQUARE, 700.0, 700.0, 0.025, 0.15, 0.0]],
	&"ui_confirm": [[Wave.SINE, 880.0, 1175.0, 0.08, 0.25, 0.0]],
	&"ui_back": [[Wave.SINE, 700.0, 440.0, 0.08, 0.25, 0.0]],
	&"text_blip": [[Wave.SQUARE, 520.0, 520.0, 0.015, 0.08, 0.0]],
	&"switch": [[Wave.SINE, 600.0, 1200.0, 0.08, 0.25, 0.0]],
	&"revive": [[Wave.SINE, 440.0, 880.0, 0.3, 0.3, 0.0]],
}


static func has_recipe(id: StringName) -> bool:
	return RECIPES.has(id)


static func make(id: StringName) -> AudioStreamWAV:
	var layers: Array = RECIPES.get(id, [])
	if layers.is_empty():
		return null
	var total := 0.0
	for layer: Array in layers:
		total = maxf(total, float(layer[3]) + float(layer[5]))
	var n := int(total * MIX_RATE) + 1
	var buf := PackedFloat32Array()
	buf.resize(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id)
	for layer: Array in layers:
		_render_layer(buf, layer, rng)
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	for i: int in n:
		bytes.encode_s16(i * 2, int(clampf(buf[i], -1.0, 1.0) * 32000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = MIX_RATE
	wav.stereo = false
	wav.data = bytes
	return wav


static func _render_layer(buf: PackedFloat32Array, layer: Array, rng: RandomNumberGenerator) -> void:
	var wave: int = layer[0]
	var f0: float = layer[1]
	var f1: float = layer[2]
	var duration: float = layer[3]
	var volume: float = layer[4]
	var start := int(float(layer[5]) * MIX_RATE)
	var count := int(duration * MIX_RATE)
	var phase := 0.0
	var noise_hold := 0.0
	var noise_counter := 0.0
	for i: int in count:
		var idx := start + i
		if idx >= buf.size():
			break
		var t := float(i) / float(maxi(count, 1))
		var freq := lerpf(f0, f1, t)
		phase = fmod(phase + freq / MIX_RATE, 1.0)
		var s := 0.0
		match wave:
			Wave.SINE:
				s = sin(phase * TAU)
			Wave.SQUARE:
				s = 1.0 if phase < 0.5 else -1.0
			Wave.SAW:
				s = phase * 2.0 - 1.0
			Wave.NOISE:
				# Sample-and-hold noise: frequency controls brightness.
				noise_counter += freq / MIX_RATE
				if noise_counter >= 1.0:
					noise_counter -= 1.0
					noise_hold = rng.randf_range(-1.0, 1.0)
				s = noise_hold
		var attack := minf(t * 40.0, 1.0)
		var envelope := attack * pow(1.0 - t, 1.6)
		buf[idx] += s * volume * envelope
