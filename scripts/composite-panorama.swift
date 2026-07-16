// Composites real app screenshots onto the magenta placeholder screens of a
// generated App Store panorama (see generate-appstore-previews.ts).
//
// The panorama contains three front-facing phone mockups whose screens are
// solid magenta (#FF00FF). For each horizontal third, this tool finds the
// magenta region, scales the matching screenshot to its bounding box, and
// replaces only the magenta pixels (soft mask), preserving bezels and
// anti-aliased edges. The panorama file is rewritten in place.
//
// Usage: swift composite-panorama.swift <panorama.png> <left.png> <center.png> <right.png>

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

func fail(_ message: String) -> Never {
  FileHandle.standardError.write(Data("\(message)\n".utf8))
  exit(1)
}

func loadImage(_ path: String) -> CGImage {
  let url = URL(fileURLWithPath: path)
  guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
    let image = CGImageSourceCreateImageAtIndex(source, 0, nil)
  else { fail("Cannot read image: \(path)") }
  return image
}

func rgbaBitmap(of image: CGImage, width: Int, height: Int) -> (CGContext, UnsafeMutablePointer<UInt8>) {
  let bytesPerRow = width * 4
  guard
    let context = CGContext(
      data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
  else { fail("Cannot create bitmap context") }
  context.interpolationQuality = .high
  context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
  guard let data = context.data else { fail("Bitmap context has no data") }
  return (context, data.assumingMemoryBound(to: UInt8.self))
}

// How strongly a pixel reads as the magenta placeholder, in 0...1.
func magentaWeight(_ pixels: UnsafeMutablePointer<UInt8>, _ offset: Int) -> Double {
  let r = Double(pixels[offset])
  let g = Double(pixels[offset + 1])
  let b = Double(pixels[offset + 2])
  return max(0, min(1, (min(r, b) - g - 60) / 80))
}

let arguments = CommandLine.arguments
guard arguments.count == 5 else {
  fail("Usage: swift composite-panorama.swift <panorama.png> <left.png> <center.png> <right.png>")
}
let panoramaPath = arguments[1]
let panoramaImage = loadImage(panoramaPath)
let width = panoramaImage.width
let height = panoramaImage.height
let (panoramaContext, panorama) = rgbaBitmap(of: panoramaImage, width: width, height: height)

for third in 0..<3 {
  let xStart = width * third / 3
  let xEnd = width * (third + 1) / 3

  // Bounding box of confidently-magenta pixels in this third.
  var minX = Int.max
  var maxX = Int.min
  var minY = Int.max
  var maxY = Int.min
  for y in 0..<height {
    for x in xStart..<xEnd {
      if magentaWeight(panorama, (y * width + x) * 4) > 0.8 {
        minX = min(minX, x)
        maxX = max(maxX, x)
        minY = min(minY, y)
        maxY = max(maxY, y)
      }
    }
  }
  // Sentinel check must come first: with no magenta at all, computing a width from the
  // Int.max/Int.min sentinels would trap on overflow.
  guard minX <= maxX else {
    fail("No magenta screen found in third \(third + 1) of \(panoramaPath)")
  }
  let screenWidth = maxX - minX + 1
  let screenHeight = maxY - minY + 1
  guard screenWidth > (xEnd - xStart) / 5, screenHeight > height / 5 else {
    fail("No magenta screen found in third \(third + 1) of \(panoramaPath)")
  }

  // A screen that is not screenshot-shaped would silently stretch the UI when filled.
  let screenshotRatio = 1206.0 / 2622.0
  let screenRatio = Double(screenWidth) / Double(screenHeight)
  guard abs(screenRatio - screenshotRatio) / screenshotRatio < 0.05 else {
    fail(
      "Screen in third \(third + 1) has ratio \(screenRatio) but screenshots are \(screenshotRatio); regenerate the panorama")
  }

  let screenshot = loadImage(arguments[2 + third])
  let (scaledContext, scaled) = rgbaBitmap(of: screenshot, width: screenWidth, height: screenHeight)

  // Replace magenta pixels with the scaled screenshot, blending on the soft mask
  // so anti-aliased screen edges keep their bezel transition. The contexts own
  // the pixel buffers, so keep them alive for the whole loop.
  withExtendedLifetime((panoramaContext, scaledContext)) {
    for y in 0..<screenHeight {
      // Both buffers come from identically-configured contexts, so rows line up 1:1.
      for x in 0..<screenWidth {
        let target = ((minY + y) * width + (minX + x)) * 4
        let weight = magentaWeight(panorama, target)
        if weight <= 0 { continue }
        let source = (y * screenWidth + x) * 4
        for channel in 0..<3 {
          let original = Double(panorama[target + channel])
          let replacement = Double(scaled[source + channel])
          panorama[target + channel] = UInt8(max(0, min(255, (original + (replacement - original) * weight).rounded())))
        }
      }
    }
  }
}

guard let output = panoramaContext.makeImage(),
  let destination = CGImageDestinationCreateWithURL(
    URL(fileURLWithPath: panoramaPath) as CFURL, UTType.png.identifier as CFString, 1, nil)
else { fail("Cannot encode output image") }
CGImageDestinationAddImage(destination, output, nil)
guard CGImageDestinationFinalize(destination) else { fail("Cannot write \(panoramaPath)") }
