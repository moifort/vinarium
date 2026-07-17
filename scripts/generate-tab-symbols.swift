// Generates the 4 custom SF Symbol templates (Vins and Scanner tabs, each in
// outline/fill) into
// ios/Vinarium/Assets.xcassets/<name>.symbolset/.
// Run from the repo root: swift scripts/generate-tab-symbols.swift
//
// Glyphs are drawn in SVG coordinate space (y down), centered on (0,0), in a
// 380-unit-tall design box. The symbol renderer only fills paths (stroke
// styles are ignored), so stroked geometry is expanded to filled outlines with
// CGPath.copy(strokingWithWidth:). Holes are cut belt-and-suspenders: wound
// opposite to their outer path (for nonzero winding, which the renderer was
// observed to use) and also emitted with fill-rule="evenodd".

import AppKit

let assets = FileManager.default.currentDirectoryPath + "/ios/Vinarium/Assets.xcassets"
let centers: [(name: String, x: CGFloat)] = [
  ("Ultralight", 559.219), ("Regular", 1575.99), ("Black", 2592.28),
]
let cy: CGFloat = 892
let strokes: [String: CGFloat] = ["Ultralight": 8, "Regular": 18, "Black": 34]

// MARK: - Path helpers (SVG coordinate space, y down, glyphs centered on 0,0)

let k: CGFloat = 0.5522847498 // cubic approximation of a quarter circle

func bottlePath(sx: CGFloat, sy: CGFloat, dx: CGFloat = 0, dy: CGFloat = 0) -> CGPath {
  let p = CGMutablePath()
  func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * sx + dx, y: y * sy + dy) }
  p.move(to: pt(-28, -190))
  p.addLine(to: pt(-28, -75))
  p.addCurve(to: pt(-70, -5), control1: pt(-28, -45), control2: pt(-70, -38))
  p.addLine(to: pt(-70, 166))
  p.addQuadCurve(to: pt(-46, 190), control: pt(-70, 190))
  p.addLine(to: pt(46, 190))
  p.addQuadCurve(to: pt(70, 166), control: pt(70, 190))
  p.addLine(to: pt(70, -5))
  p.addCurve(to: pt(28, -75), control1: pt(70, -38), control2: pt(28, -45))
  p.addLine(to: pt(28, -190))
  p.closeSubpath()
  return p
}

func viewfinderCorners() -> [CGPath] {
  // Quarter-circle corners of radius 40, arms 80 long, at the 380 box corners.
  let c = 40 * k
  func corner(_ sx: CGFloat, _ sy: CGFloat) -> CGPath {
    let p = CGMutablePath()
    p.move(to: CGPoint(x: sx * 110, y: sy * 190))
    p.addLine(to: CGPoint(x: sx * 150, y: sy * 190))
    p.addCurve(
      to: CGPoint(x: sx * 190, y: sy * 150),
      control1: CGPoint(x: sx * (150 + c), y: sy * 190),
      control2: CGPoint(x: sx * 190, y: sy * (150 + c)))
    p.addLine(to: CGPoint(x: sx * 190, y: sy * 110))
    return p
  }
  return [corner(-1, -1), corner(1, -1), corner(-1, 1), corner(1, 1)]
}

// MARK: - Glyph definitions

enum Element {
  case stroked(CGPath) // expanded to a filled outline at the weight's width
  case filled(CGPath, evenOdd: Bool)
}

struct Glyph {
  let name: String
  let halfWidth: CGFloat
  let elements: [Element]
  /// Extra per-glyph scale on top of glyphScale. The scan symbol sits in the
  /// tab bar's compact trailing circle, so it gets a boost to read at the same
  /// optical size as the regular tabs.
  var extraScale: CGFloat = 1
}

// Vins: three identical bottles side by side, filled in both tab states (the
// tab label always references tab.wines.fill).
let winesBottles = [-122, 0, 122].map { bottlePath(sx: 0.72, sy: 1, dx: CGFloat($0)) }

let glyphs: [Glyph] = [
  Glyph(
    name: "tab.wines.fill", halfWidth: 173,
    elements: winesBottles.map { .filled($0, evenOdd: false) }),
  Glyph(
    name: "tab.scan.fill", halfWidth: 197,
    elements: viewfinderCorners().map { .stroked($0) }
      + [.filled(bottlePath(sx: 0.66, sy: 0.66), evenOdd: false)],
    extraScale: 1.44),
]

// MARK: - SVG emission

func svgPathData(_ path: CGPath) -> String {
  var d = ""
  func f(_ v: CGFloat) -> String { String(format: "%.2f", v) }
  path.applyWithBlock { elem in
    let e = elem.pointee
    switch e.type {
    case .moveToPoint:
      d += "M \(f(e.points[0].x)),\(f(e.points[0].y)) "
    case .addLineToPoint:
      d += "L \(f(e.points[0].x)),\(f(e.points[0].y)) "
    case .addQuadCurveToPoint:
      d += "Q \(f(e.points[0].x)),\(f(e.points[0].y)) \(f(e.points[1].x)),\(f(e.points[1].y)) "
    case .addCurveToPoint:
      d += "C \(f(e.points[0].x)),\(f(e.points[0].y)) \(f(e.points[1].x)),\(f(e.points[1].y)) \(f(e.points[2].x)),\(f(e.points[2].y)) "
    case .closeSubpath:
      d += "Z "
    @unknown default:
      break
    }
  }
  return d.trimmingCharacters(in: .whitespaces)
}

/// System symbols overshoot the capline-baseline band by a wide margin; glyphs
/// drawn inside the 380-unit design box render visibly smaller than their
/// system neighbors (measured: house is 142x120 pt at a 100 pt configuration
/// where a band-fitting glyph is 75x85). Scaling the geometry, but not the
/// stroke widths, matches the system symbols' optical size and line weight.
let glyphScale: CGFloat = 1.70

func variantBody(_ g: Glyph, strokeWidth: CGFloat) -> String {
  let total = glyphScale * g.extraScale
  var scale = CGAffineTransform(scaleX: total, y: total)
  return g.elements.map { element in
    switch element {
    case .stroked(let path):
      let outlined = path.copy(using: &scale)!.copy(
        strokingWithWidth: strokeWidth * total, lineCap: .round, lineJoin: .round, miterLimit: 10)
      return "   <path d=\"\(svgPathData(outlined))\" style=\"fill:black;stroke:none;\"/>"
    case .filled(let path, let evenOdd):
      let rule = evenOdd ? " fill-rule=\"evenodd\"" : ""
      return "   <path\(rule) d=\"\(svgPathData(path.copy(using: &scale)!))\" style=\"fill:black;stroke:none;\"/>"
    }
  }.joined(separator: "\n")
}

func template(_ g: Glyph) -> String {
  let variants = centers.map { center in
    """
      <g id="\(center.name)-M" transform="matrix(1 0 0 1 \(center.x) \(cy))">
    \(variantBody(g, strokeWidth: strokes[center.name]!))
      </g>
    """
  }.joined(separator: "\n")
  let left = String(format: "%.2f", centers[1].x - g.halfWidth * glyphScale * g.extraScale)
  let right = String(format: "%.2f", centers[1].x + g.halfWidth * glyphScale * g.extraScale)
  return """
    <?xml version="1.0" encoding="UTF-8"?>
    <svg version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="3300" height="2200">
     <!--glyph: "\(g.name)", point size: 100.0, template writer version: "8"-->
     <g id="Notes">
      <rect height="2200" id="artboard" style="fill:white;opacity:1" width="3300" x="0" y="0"/>
      <line id="" style="fill:none;stroke:black;opacity:0.5;stroke-width:0.5;" x1="263" x2="3036" y1="292" y2="292"/>
      <text id="template-version" style="stroke:none;fill:black;font-family:sans-serif;font-size:13px;font-weight:bold;" transform="matrix(1 0 0 1 263 322)">Template v.3.0</text>
      <text id="descriptive-name" style="stroke:none;fill:black;font-family:sans-serif;font-size:13px;" transform="matrix(1 0 0 1 263 1953)">\(g.name)</text>
      <text style="stroke:none;fill:black;font-family:sans-serif;font-size:13px;" transform="matrix(1 0 0 1 559.219 1993)">Ultralight</text>
      <text style="stroke:none;fill:black;font-family:sans-serif;font-size:13px;" transform="matrix(1 0 0 1 1575.99 1993)">Regular</text>
      <text style="stroke:none;fill:black;font-family:sans-serif;font-size:13px;" transform="matrix(1 0 0 1 2592.28 1993)">Black</text>
     </g>
     <g id="Guides">
      <line id="Capline-S" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="696" y2="696"/>
      <line id="Baseline-S" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="1088" y2="1088"/>
      <line id="Capline-M" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="696" y2="696"/>
      <line id="Baseline-M" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="1088" y2="1088"/>
      <line id="Capline-L" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="696" y2="696"/>
      <line id="Baseline-L" style="fill:none;stroke:#27AAE1;opacity:1;stroke-width:0.5;" x1="263" x2="3036" y1="1088" y2="1088"/>
      <line id="left-margin" style="fill:none;stroke:#00AEEF;stroke-width:0.5;" x1="\(left)" x2="\(left)" y1="600.785" y2="1183.21"/>
      <line id="right-margin" style="fill:none;stroke:#00AEEF;stroke-width:0.5;" x1="\(right)" x2="\(right)" y1="600.785" y2="1183.21"/>
     </g>
     <g id="Symbols">
    \(variants)
     </g>
    </svg>

    """
}

for g in glyphs {
  let dir = "\(assets)/\(g.name).symbolset"
  try FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
  try template(g).write(toFile: "\(dir)/\(g.name).svg", atomically: true, encoding: .utf8)
  let contents = """
    {
      "info" : {
        "author" : "xcode",
        "version" : 1
      },
      "symbols" : [
        {
          "filename" : "\(g.name).svg",
          "idiom" : "universal"
        }
      ]
    }

    """
  try contents.write(toFile: "\(dir)/Contents.json", atomically: true, encoding: .utf8)
  print("wrote \(g.name)")
}
