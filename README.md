# PDKPdfxr

A [pdfxr](https://psychicteeth.itch.io/pdfxr) playback implementation in Swift for use with [PlaydateKit](https://github.com/finnvoor/PlaydateKit).

https://github.com/user-attachments/assets/2112d0fa-8887-4a75-a83d-dbe36f1d12b2

## Use

See [PdfxrDemo](https://github.com/strawdynamics/PDKPdfxr/blob/main/Examples/PdfxrDemo/Sources/PdfxrDemo/Game.swift) for details.

```swift
let myEffect = try! Pdfxr(effectPath: "sfx/myEffect") // File should have `.json` extension

myEffect.play()
```
