import AppKit
import CoreImage
import Foundation

guard CommandLine.arguments.count == 3 else {
    fputs("Usage: generate-qr.swift <text> <output.png>\n", stderr)
    exit(1)
}

let value = CommandLine.arguments[1]
let outputURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard
    let data = value.data(using: .utf8),
    let filter = CIFilter(name: "CIQRCodeGenerator")
else {
    fputs("Unable to create QR filter.\n", stderr)
    exit(1)
}

filter.setValue(data, forKey: "inputMessage")
filter.setValue("M", forKey: "inputCorrectionLevel")

guard let outputImage = filter.outputImage?.transformed(
    by: CGAffineTransform(scaleX: 12, y: 12)
) else {
    fputs("Unable to render QR image.\n", stderr)
    exit(1)
}

let representation = NSCIImageRep(ciImage: outputImage)
let image = NSImage(size: representation.size)
image.addRepresentation(representation)

guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let png = bitmap.representation(using: .png, properties: [:])
else {
    fputs("Unable to encode PNG.\n", stderr)
    exit(1)
}

try png.write(to: outputURL, options: .atomic)
