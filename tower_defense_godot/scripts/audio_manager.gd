extends RefCounted


static func build(owner) -> void:
	owner.cannon_audio.stream = make_tone(72.0, 0.26, 0.62, 3)
	owner.arrow_audio.stream = make_tone(940.0, 0.09, 0.28, 4)
	owner.ice_audio.stream = make_tone(610.0, 0.20, 0.34, 5)
	owner.wave_audio.stream = make_tone(118.0, 0.42, 0.56, 6)
	owner.error_audio.stream = make_tone(145.0, 0.16, 0.42, 1)
	owner.build_audio.stream = make_tone(760.0, 0.48, 0.38, 7)
	owner.remove_audio.stream = make_tone(260.0, 0.16, 0.34, 8)
	owner.bgm_audio.stream = make_music_loop()
	for player in [owner.cannon_audio, owner.arrow_audio, owner.ice_audio, owner.wave_audio, owner.error_audio, owner.build_audio, owner.remove_audio, owner.bgm_audio]:
		player.max_polyphony = 6
		owner.add_child(player)
	owner.bgm_audio.finished.connect(func() -> void:
		owner.bgm_audio.play()
	)
	apply_settings(owner)
	owner.bgm_audio.play()


static func apply_settings(owner) -> void:
	var sfx_db: float = -80.0 if not owner.sfx_enabled or owner.sfx_volume <= 0.0 else -9.0 + linear_to_db(owner.sfx_volume)
	for player in [owner.cannon_audio, owner.arrow_audio, owner.ice_audio, owner.wave_audio, owner.error_audio, owner.build_audio, owner.remove_audio]:
		player.volume_db = sfx_db
	owner.bgm_audio.volume_db = -80.0 if not owner.music_enabled or owner.music_volume <= 0.0 else -18.5 + linear_to_db(owner.music_volume)


static func make_tone(frequency: float, duration: float, volume: float, style: int) -> AudioStreamWAV:
	var mix_rate := 44100
	var sample_count := int(duration * mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in range(sample_count):
		var t := float(i) / float(mix_rate)
		var fade := 1.0 - clampf(t / duration, 0.0, 1.0)
		var sample := sin(TAU * frequency * t)
		if style == 1:
			sample = sin(TAU * frequency * t) * 0.75 + sin(TAU * frequency * 0.5 * t) * 0.35
		elif style == 2:
			sample = sin(TAU * frequency * t) * 0.6 + sin(TAU * frequency * 1.52 * t) * 0.35
		elif style == 3:
			sample = sin(TAU * frequency * t) * 0.85 + sin(TAU * frequency * 0.5 * t) * 0.55 + sin(TAU * frequency * 2.0 * t) * 0.18
			sample += randf_range(-0.16, 0.16) * fade
		elif style == 4:
			sample = sin(TAU * frequency * t) * 0.55 + sin(TAU * frequency * 1.98 * t) * 0.2
			if t > duration * 0.45:
				sample *= 0.35
		elif style == 5:
			sample = sin(TAU * frequency * t) * 0.45 + sin(TAU * (frequency * 1.34 + 90.0 * t) * t) * 0.38
			sample += sin(TAU * frequency * 2.01 * t) * 0.16
		elif style == 6:
			var beat := 1.0 if fmod(t, 0.18) < 0.055 else 0.22
			sample = (sin(TAU * frequency * t) * 0.9 + sin(TAU * frequency * 0.5 * t) * 0.45) * beat
			sample += randf_range(-0.12, 0.12) * beat
		elif style == 7:
			var strike_time := fmod(t, 0.16)
			var strike_fade := 1.0 - clampf(strike_time / 0.09, 0.0, 1.0)
			var strike_on := 1.0 if t < 0.42 and strike_time < 0.09 else 0.0
			sample = (sin(TAU * frequency * t) * 0.55 + sin(TAU * frequency * 1.62 * t) * 0.32) * strike_fade * strike_on
			sample += randf_range(-0.18, 0.18) * strike_fade * strike_on
		elif style == 8:
			sample = sin(TAU * (frequency - 80.0 * t) * t) * 0.55 + sin(TAU * frequency * 0.5 * t) * 0.18
		var value := int(clampf(sample * fade * volume, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream


static func make_music_loop() -> AudioStreamWAV:
	var mix_rate := 44100
	var duration := 8.0
	var sample_count := int(duration * mix_rate)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var notes: Array[float] = [196.0, 246.94, 293.66, 392.0, 349.23, 293.66, 246.94, 220.0]
	for i in range(sample_count):
		var t: float = float(i) / float(mix_rate)
		var beat_index: int = int(floor(t * 4.0)) % notes.size()
		var local_t: float = fmod(t, 0.25)
		var fade: float = min(1.0, local_t / 0.025) * min(1.0, (0.25 - local_t) / 0.045)
		var note: float = notes[beat_index]
		var kick_phase: float = fmod(t, 0.5)
		var kick: float = sin(TAU * (86.0 - 45.0 * kick_phase) * t) * max(0.0, 1.0 - kick_phase * 8.0)
		var hat: float = randf_range(-0.18, 0.18) if fmod(t, 0.125) < 0.025 else 0.0
		var sample: float = sin(TAU * note * t) * 0.20 + sin(TAU * note * 2.0 * t) * 0.08
		var bass: float = sin(TAU * 98.0 * t) * 0.12
		var value: int = int(clampf((sample * fade + bass + kick * 0.42 + hat) * 0.55, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix_rate
	stream.stereo = false
	stream.data = data
	return stream
