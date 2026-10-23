// Renders an SVG to a square PNG with macOS's native SVG renderer (NSImage).
// ImageMagick's built-in MSVG renderer drops the gradient and the rotated stones.
// usage: swift render_svg.swift in.svg out.png size
import AppKit
let a = CommandLine.arguments
let data = try! Data(contentsOf: URL(fileURLWithPath: a[1]))
guard let img = NSImage(data: data) else { fatalError("NSImage could not load SVG") }
let n = Int(a[3])!
let cs = CGColorSpace(name: CGColorSpace.sRGB)!
let ctx = CGContext(data: nil, width: n, height: n, bitsPerComponent: 8, bytesPerRow: 0, space: cs,
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
img.draw(in: NSRect(x: 0, y: 0, width: n, height: n))
NSGraphicsContext.current = nil
let rep = NSBitmapImageRep(cgImage: ctx.makeImage()!)
try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: a[2]))
