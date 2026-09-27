import MetalKit
import SwiftUI

/// Red wine seen from very close, filling the view: a height field of warped
/// noise, slowly moving, coloured deep where the wine lies low and garnet where
/// it rises and tilts, with no reflection on it. Drawn by Metal every frame;
/// still when `moving` is false.
///
/// The shader is compiled from source on the device, off the main thread, the
/// first time the view shows: the build needs no Metal toolchain, which Xcode
/// ships as a separate download. The view stays clear until the shader is
/// ready, and `onReady` tells the curtain to fade it in.
struct WineSurface: UIViewRepresentable {
    /// The moment the wine started moving, so it picks up where it was.
    var start: Date
    var moving = true
    var onReady: @MainActor () -> Void = {}

    func makeCoordinator() -> WineRenderer {
        WineRenderer(start: start)
    }

    func makeUIView(context: Context) -> MTKView {
        let view = MTKView(frame: .zero, device: context.coordinator.device)
        view.isOpaque = false
        view.backgroundColor = .clear
        view.framebufferOnly = true
        view.colorPixelFormat = .bgra8Unorm
        view.preferredFramesPerSecond = 60
        view.isPaused = true
        view.enableSetNeedsDisplay = false
        view.delegate = context.coordinator
        context.coordinator.prepare(view: view, onReady: onReady)
        return view
    }

    func updateUIView(_ view: MTKView, context: Context) {
        context.coordinator.moving = moving
        context.coordinator.apply(to: view)
    }
}

@MainActor
final class WineRenderer: NSObject, MTKViewDelegate {
    let device = MTLCreateSystemDefaultDevice()
    private let queue: MTLCommandQueue?
    private var pipeline: MTLRenderPipelineState?
    private let start: Date
    var moving = true

    init(start: Date) {
        self.start = start
        queue = device?.makeCommandQueue()
    }

    /// Compiles the shader in the background, then starts drawing.
    func prepare(view: MTKView, onReady: @escaping @MainActor () -> Void) {
        guard let device else { return }
        let format = view.colorPixelFormat
        Task { [weak self, weak view] in
            guard let library = try? await device.makeLibrary(source: Self.source, options: nil),
                  let vertex = library.makeFunction(name: "wineVertex"),
                  let fragment = library.makeFunction(name: "wineFragment") else { return }
            let descriptor = MTLRenderPipelineDescriptor()
            descriptor.vertexFunction = vertex
            descriptor.fragmentFunction = fragment
            descriptor.colorAttachments[0].pixelFormat = format
            guard let pipeline = try? await device.makeRenderPipelineState(descriptor: descriptor),
                  let self, let view else { return }
            self.pipeline = pipeline
            self.apply(to: view)
            view.draw()
            onReady()
        }
    }

    /// Runs the display loop while the wine moves and a shader is ready.
    func apply(to view: MTKView) {
        view.isPaused = !(moving && pipeline != nil)
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        if view.isPaused { view.draw() }
    }

    func draw(in view: MTKView) {
        guard let pipeline, let queue,
              let pass = view.currentRenderPassDescriptor,
              let drawable = view.currentDrawable,
              let buffer = queue.makeCommandBuffer(),
              let encoder = buffer.makeRenderCommandEncoder(descriptor: pass) else { return }
        // The shader's `Uniforms`: size, time, and padding to sixteen bytes.
        var uniforms = SIMD4<Float>(
            Float(view.drawableSize.width), Float(view.drawableSize.height),
            Float(Date().timeIntervalSince(start)), 0
        )
        encoder.setRenderPipelineState(pipeline)
        encoder.setFragmentBytes(&uniforms, length: MemoryLayout<SIMD4<Float>>.size, index: 0)
        encoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 3)
        encoder.endEncoding()
        buffer.present(drawable)
        buffer.commit()
    }

    private static let source = """
#include <metal_stdlib>
using namespace metal;

// The three settings of the look, as tuned on the preview.
constant float speed = 1.0;     // how fast the wine moves
constant float tint = 0.35;     // 0 for a purple garnet, 1 for a brick one
constant float depth = 1.6;     // how deep the folds of the surface read

namespace wine {
    float hash(float2 p) {
        p = fract(p * float2(123.34, 456.21));
        p += dot(p, p + 45.32);
        return fract(p.x * p.y);
    }

    float noise(float2 p) {
        float2 i = floor(p);
        float2 f = fract(p);
        f = f * f * (3.0 - 2.0 * f);
        return mix(mix(hash(i), hash(i + float2(1, 0)), f.x),
                   mix(hash(i + float2(0, 1)), hash(i + float2(1, 1)), f.x), f.y);
    }

    float fbm(float2 p) {
        float value = 0.0;
        float amplitude = 0.5;
        for (int octave = 0; octave < 5; octave++) {
            value += amplitude * noise(p);
            p = p * 2.03 + float2(1.7, 9.2);
            amplitude *= 0.5;
        }
        return value;
    }

    /// The wine's height at `p`: noise warped twice by noise, so the surface
    /// folds and drifts like a liquid rather than scrolling like a texture.
    float height(float2 p, float t) {
        float2 q = float2(fbm(p * 0.7 + float2(0.0, t * 0.05)),
                          fbm(p * 0.7 + float2(5.2, -t * 0.04)));
        float2 r = float2(fbm(p + q * 1.6 + float2(t * 0.03, 1.3)),
                          fbm(p + q * 1.6 + float2(8.3, -t * 0.025)));
        return fbm(p + r * 1.3);
    }
}

struct Uniforms {
    float2 size;
    float time;
    float padding;
};

struct Varyings {
    float4 position [[position]];
};

/// One triangle that covers the whole view.
vertex Varyings wineVertex(uint id [[vertex_id]]) {
    float2 corner = float2((id << 1) & 2, id & 2);
    Varyings out;
    out.position = float4(corner * 2.0 - 1.0, 0.0, 1.0);
    return out;
}

/// `size` is the drawable's size in pixels, `time` seconds since the opening
/// began. No light is reflected: the wine reads by its colour alone, deep
/// where it lies low, garnet where it rises and tilts.
fragment half4 wineFragment(Varyings in [[stage_in]], constant Uniforms &uniforms [[buffer(0)]]) {
    float2 size = uniforms.size;
    float time = uniforms.time * speed;
    float2 position = in.position.xy;
    float2 uv = position / size;
    // Centred, y up, the shorter side spanning about two units.
    float2 p = float2(position.x - 0.5 * size.x, 0.5 * size.y - position.y) / size.y * 1.6;

    float e = 0.004;
    float h = wine::height(p, time);
    float hx = wine::height(p + float2(e, 0), time);
    float hy = wine::height(p + float2(0, e), time);
    float3 n = normalize(float3(-(hx - h) / e * 0.09 * depth, -(hy - h) / e * 0.09 * depth, 1.0));

    float3 deep = float3(0.02, 0.0, 0.005);
    float3 body = float3(0.55, 0.03, 0.08);
    float3 garnet = mix(float3(0.75, 0.06, 0.13), float3(0.82, 0.16, 0.09), tint);
    float3 wineColor = mix(deep, body, smoothstep(0.33, 0.66, h));
    wineColor = mix(wineColor, garnet, saturate(pow(1.0 - n.z, 1.5) * 1.6 * smoothstep(0.35, 0.8, h)));

    float vignette = smoothstep(1.25, 0.25, length((uv - 0.5) * float2(1.0, 1.6)));
    wineColor *= 0.55 + 0.45 * vignette;

    return half4(half3(pow(wineColor, float3(0.4545))), 1.0);
}
"""
}
