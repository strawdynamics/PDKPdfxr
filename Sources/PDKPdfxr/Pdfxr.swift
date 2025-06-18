import PlaydateKit

public class Pdfxr {
	// MARK: Lifecycle

	public init(effectPath: String) throws(Pdfxr.Error) {
		effect = try SoundEffect(effectPath: effectPath)
	}

	private init(copiedFrom: Pdfxr) {
		effect = SoundEffect(loadedEffect: copiedFrom.effect)
	}

	// MARK: Public

	public struct Error: Swift.Error, CustomStringConvertible, @unchecked Sendable {
		public let description: String
	}

	public var synth: Sound.Synth { effect.synth }

	public var volume: Float { effect.volume }

	public var note: MIDINote { effect.note }

	public var name: String { effect.name }

	public func play(note: MIDINote? = nil, volume: Float? = nil) {
		let note = note ?? (effect.lockNoteToInteger ? MIDINote(Int(effect.note)) : effect.note)
		let volume = volume ?? effect.volume

		effect.synth.playMIDINote(note: note, volume: volume, length: effect.totalDuration)
	}

	public func start(note: MIDINote? = nil, volume: Float? = nil) {
		let note = note ?? (effect.lockNoteToInteger ? MIDINote(Int(effect.note)) : effect.note)
		let volume = volume ?? effect.volume

		let frequency = powf(2, (note - 69) / 12) * 440

		effect.synth.playNote(frequency: frequency, volume: volume)
	}

	public func stop() {
		effect.synth.noteOff()
	}

	public func copy() -> Pdfxr {
		Pdfxr(copiedFrom: self)
	}

	// MARK: Internal

	let effect: SoundEffect
}
