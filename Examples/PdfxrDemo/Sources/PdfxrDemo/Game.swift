import PlaydateKit
import PDKPdfxr

// MARK: - Game

final class Game: PlaydateGame {
	// MARK: Lifecycle

	init() {

	}

	// MARK: Internal

	static nonisolated(unsafe) let sfx = [
		try! Pdfxr(effectPath: "sfx/droid"),
		try! Pdfxr(effectPath: "sfx/raygun"),
		try! Pdfxr(effectPath: "sfx/vibtest"),
		try! Pdfxr(effectPath: "sfx/trem"),
		try! Pdfxr(effectPath: "sfx/weird"),
		try! Pdfxr(effectPath: "sfx/swhistle"),
	]

	var sfxIndex = 0

	func update() -> Bool {
		Graphics.clear(color: .white)

		Graphics.drawText("⬅️➡️: \(Game.sfx[sfxIndex].name)", at: Point(
			x: 145,
			y: 100,
		))

		Graphics.drawText("Ⓐ: Play effect", at: Point(
			x: 145,
			y: 120,
		))

		let pushed = System.buttonState.pushed

		if pushed.contains(.a) {
			Game.sfx[sfxIndex].play()
		} else if pushed.contains(.right) {
			sfxIndex = (sfxIndex + 1) % Game.sfx.count
		} else if pushed.contains(.left) {
			sfxIndex = (sfxIndex - 1 + Game.sfx.count) % Game.sfx.count
		}

		return true
	}
}
