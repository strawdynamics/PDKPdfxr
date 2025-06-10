import PlaydateKit
import CPlaydate
import UTF8ViewExtensions

public class SoundEffect {
	public let name: String
	public let note: MIDINote
	public let volume: Float
	public let duration: Float
	public let totalDuration: Float

	public let wave: SoundWaveform

	public let lockNoteToInteger: Bool

	let synth: Sound.Synth

	class ModDef {
		var arpeggio: [Float] = []
		var arpeggioEnabled = false
		var center: Float = 0.5
		var delayFade: Float = 0
		var delayStart: Float = 0
		var depth: Float = 0
		var enabled = false
		var phase: Float = 0
		var rate: Float = 0
		var startPhase: Float = 0
		var type: Int = 0

		func toLFO() -> Sound.LFO? {
			if !enabled {
				return nil
			}

			let realType: LFOType
			switch type {
			case 1:
				realType = .square
			case 2:
				realType = .sawtoothUp
			case 3:
				realType = .sawtoothDown
			case 4:
				realType = .triangle
			case 5:
				realType = .sine
			case 6:
				realType = .sampleAndHold
			default:
				print("[SoundEffect] Unknown LFOType \(type)")
				realType = .sine
			}

			let lfo = Sound.LFO(type: realType)

			if arpeggioEnabled {
				if arpeggio[4] > 0 {
					lfo.setArpeggiation(arpeggio.prefix(5).map { floorf($0) })
				} else if arpeggio[3] > 0 {
					lfo.setArpeggiation(arpeggio.prefix(4).map { floorf($0) })
				} else if arpeggio[2] > 0 {
					lfo.setArpeggiation(arpeggio.prefix(3).map { floorf($0) })
				} else if arpeggio[1] > 0 {
					lfo.setArpeggiation(arpeggio.prefix(2).map { floorf($0) })
				} else if arpeggio[0] > 0 {
					lfo.setArpeggiation(arpeggio.prefix(1).map { floorf($0) })
				} else {
					lfo.setArpeggiation([0])
				}
			}

			lfo.setCenter(center)
			lfo.setDelay(holdoff: delayStart, ramptime: delayFade)
			lfo.setDepth(depth)
			lfo.setPhase(phase)
			lfo.setStartPhase(startPhase)
			lfo.setRate(rate)
			lfo.setRetrigger(true)

			return lfo
		}
	}

	private class DecodeContext {
		var decodingModDef: ModDef?

		var name: String = ""
		var note = MIDINote(NOTE_C4)
		var volume: Float = 0
		var duration: Float = 0
		var attack: Float = 0
		var decay: Float = 0
		var wave: SoundWaveform = .sine

		var lockNoteToInteger = false

		var amplitudeModDef: ModDef?
		var frequencyModDef: ModDef?

		let synth = Sound.Synth()
	}

	init(effectPath: String) throws(Pdfxr.Error) {
		let jsonEffectPath = "\(effectPath).json"
		guard let stat = try? File.stat(path: jsonEffectPath) else {
			throw Pdfxr.Error(description: "[SoundEffect] missing file \(jsonEffectPath)")
		}

		let file = try! File.open(path: jsonEffectPath, mode: File.Options.read)

		let fileBuffer = UnsafeMutableRawPointer.allocate(byteCount: Int(stat.size), alignment: 1)

		let bytesRead = try! file.read(buffer: fileBuffer, length: stat.size)

		let uint8Buffer = UnsafeBufferPointer<UInt8>(start: fileBuffer.assumingMemoryBound(to: UInt8.self), count: bytesRead)
		let jsonString = String(decoding: uint8Buffer, as: Unicode.UTF8.self)

		var decoder = JSON.Decoder()
		let ctx = DecodeContext()
		decoder.userdata = Unmanaged.passRetained(ctx).toOpaque()
		decoder.decodeError = Self.decodeError
		decoder.willDecodeSublist = Self.willDecodeSublist
		decoder.didDecodeTableValue = Self.didDecodeTableValue
		decoder.didDecodeArrayValue = Self.didDecodeArrayValue
		decoder.didDecodeSublist = Self.didDecodeSublist

		var value = JSON.Value()

		_ = JSON.decodeString(using: &decoder, jsonString: jsonString, value: &value)

		name = ctx.name
		note = ctx.note
		volume = ctx.volume
		duration = ctx.duration
		lockNoteToInteger = ctx.lockNoteToInteger
		wave = ctx.wave
		totalDuration = ctx.duration + ctx.attack + ctx.decay

		if let ampMod = ctx.amplitudeModDef {
			ctx.synth.setAmplitudeModulator(ampMod.toLFO())
		}

		if let freqMod = ctx.frequencyModDef {
			ctx.synth.setFrequencyModulator(freqMod.toLFO())
		}

		Unmanaged<DecodeContext>.fromOpaque(decoder.userdata!).release()
		fileBuffer.deallocate()

		synth = ctx.synth
	}

	static nonisolated(unsafe) var decodeError: @convention(c)
	(UnsafeMutablePointer<json_decoder>?, UnsafePointer<CChar>?, Int32) -> Void
	= { _, err, line in
		if let e = err.map({ String(cString: $0) }) {
			System.error("JSON error at \(line): \(e)")
		}
	}

	static nonisolated(unsafe) var willDecodeSublist: @convention(c)
	(UnsafeMutablePointer<json_decoder>?, UnsafePointer<CChar>?, json_value_type) -> Void
	= { ptr, keyC, type in
		guard
			let ptr = ptr,
			let ctx = ptr.pointee.userdata
				.flatMap({ Unmanaged<DecodeContext>.fromOpaque($0).takeUnretainedValue() }),
			let key = keyC.map(String.init(cString:))?.utf8
		else { return }

		switch (key, type) {
		case ("amp_mod".utf8, .table):
			ctx.amplitudeModDef = ModDef()
			ctx.decodingModDef = ctx.amplitudeModDef
		case ("freq_mod".utf8, .table):
			ctx.frequencyModDef = ModDef()
			ctx.decodingModDef = ctx.frequencyModDef
		default:
			break
		}
	}

	static nonisolated(unsafe) var didDecodeTableValue: @convention(c)
	(UnsafeMutablePointer<json_decoder>?, UnsafePointer<CChar>?, json_value) -> Void
	= { ptr, keyC, val in
		guard
			let ptr = ptr,
			let keyC = keyC,
			let ctxPtr = ptr.pointee.userdata
		else { return }

		let key = String(cString: keyC).utf8

		let ctx = Unmanaged<DecodeContext>
			.fromOpaque(ctxPtr)
			.takeUnretainedValue()

		let type = json_value_type(rawValue: numericCast(val.type))

		if var modDef = ctx.decodingModDef {
			switch key {
			case "arpeggio_enabled":
				modDef.arpeggioEnabled = type! == json_value_type.true
			case "center":
				modDef.center = val.data.floatval
			case "delay_fade":
				modDef.delayFade = val.data.floatval
			case "delay_start":
				modDef.delayStart = val.data.floatval
			case "depth":
				modDef.depth = val.data.floatval
			case "enabled":
				modDef.enabled = type! == json_value_type.true
			case "phase":
				modDef.phase = val.data.floatval
			case "rate":
				modDef.rate = val.data.floatval
			case "start_phase":
				modDef.startPhase = val.data.floatval
			case "type":
				modDef.type = Int(val.data.intval)
			default:
				break
			}
		} else {
			switch key {
			case "name":
				ctx.name = String(cString: val.data.stringval)
			case "note":
				ctx.note = MIDINote(val.data.floatval)
			case "volume":
				ctx.volume = val.data.floatval
			case "duration":
				ctx.duration = val.data.floatval
			case "attack":
				ctx.attack = val.data.floatval
				ctx.synth.setAttackTime(val.data.floatval)
			case "decay":
				ctx.decay = val.data.floatval
				ctx.synth.setDecayTime(val.data.floatval)
			case "sustain":
				ctx.synth.setSustainLevel(val.data.floatval)
			case "release":
				ctx.synth.setReleaseTime(val.data.floatval)
			case "curvature":
				ctx.synth.setEnvelopeCurvature(val.data.floatval)
			case "wave":
				let waveform: SoundWaveform
				switch val.data.intval {
				case 1:
					waveform = .sine
				case 2:
					waveform = .square
				case 3:
					waveform = .sawtooth
				case 4:
					waveform = .triangle
				case 5:
					waveform = .noise
				case 6:
					waveform = .poPhase
				case 7:
					waveform = .poDigital
				case 8:
					waveform = .povOsim
				default:
					print("[SoundEffect] Unknown waveform \(val.data.intval)")
					waveform = .sine
				}
				ctx.synth.setWaveform(waveform)
			default:
				break
			}
		}
	}

	static nonisolated(unsafe) var didDecodeArrayValue: @convention(c)
	(UnsafeMutablePointer<json_decoder>?, Int32, json_value) -> Void
	= { ptr, _, val in
		guard let dptr = ptr else { return }
		let ctx = Unmanaged<DecodeContext>
			.fromOpaque(dptr.pointee.userdata!)
			.takeUnretainedValue()
		guard let modDef = ctx.decodingModDef else { return }

		if let cPath = dptr.pointee.path {
			let path = String(cString: cPath).utf8
			let type = json_value_type(rawValue: numericCast(val.type))!

			if path.hasSuffix(".arpeggio") {
				if type == json_value_type.integer {
					modDef.arpeggio.append(Float(val.data.intval))
				} else if type == json_value_type.float {
					modDef.arpeggio.append(val.data.floatval)
				}
			}
		}
	}

	static nonisolated(unsafe) var didDecodeSublist: @convention(c)
	(UnsafeMutablePointer<json_decoder>?, UnsafePointer<CChar>?, json_value_type)
	-> UnsafeMutableRawPointer?
	= { ptr, _, type in
		guard let ptr = ptr,
			  let ctxPtr = ptr.pointee.userdata
		else { return nil }

		let ctx = Unmanaged<DecodeContext>
			.fromOpaque(ctxPtr)
			.takeUnretainedValue()

		switch type {
		case .table where ctx.decodingModDef != nil:
			ctx.decodingModDef = nil

		default:
			break
		}

		return ctxPtr
	}
}
