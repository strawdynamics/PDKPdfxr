import PlaydateKit

public class Pdfxr {
	public struct Error: Swift.Error, CustomStringConvertible, @unchecked Sendable {
		public let description: String
	}

	let effectPath: String

	public let effect: SoundEffect

	public var synth: Sound.Synth { effect.synth }

	public init(effectPath: String) throws(Pdfxr.Error) {
		self.effectPath = effectPath
		effect = try SoundEffect(effectPath: effectPath)
	}

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
}
