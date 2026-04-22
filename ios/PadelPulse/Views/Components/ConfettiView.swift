import SwiftUI

/// A Canvas-based confetti particle animation.
struct ConfettiView: View {
    let colors: [Color]

    @State private var particles: [Particle] = []
    @State private var started = false

    var body: some View {
        TimelineView(.animation) { timeline in
            Canvas { context, size in
                let now = timeline.date.timeIntervalSinceReferenceDate
                for particle in particles {
                    let age = now - particle.startTime
                    guard age >= 0 && age < particle.lifetime else { continue }

                    let progress = age / particle.lifetime
                    // startXFraction is 0...1; map to actual canvas width at render time
                    // so confetti spans the screen on any device.
                    let baseX = particle.startXFraction * size.width
                    let x = baseX + particle.driftX * sin(age * particle.wobbleFreq) * 40
                    let y = particle.startY + age * particle.fallSpeed + age * age * 30 // gravity
                    let opacity = 1.0 - progress * progress
                    let rotation = Angle(degrees: age * particle.rotationSpeed)

                    guard y < size.height + 20, x > -20, x < size.width + 20 else { continue }

                    context.opacity = opacity
                    context.translateBy(x: x, y: y)
                    context.rotate(by: rotation)

                    let rect = CGRect(
                        x: -particle.width / 2,
                        y: -particle.height / 2,
                        width: particle.width,
                        height: particle.height
                    )

                    if particle.isCircle {
                        context.fill(Path(ellipseIn: rect), with: .color(particle.color))
                    } else {
                        context.fill(Path(roundedRect: rect, cornerRadius: 2), with: .color(particle.color))
                    }

                    context.rotate(by: -rotation)
                    context.translateBy(x: -x, y: -y)
                    context.opacity = 1
                }
            }
        }
        .onAppear {
            guard !started else { return }
            started = true
            let now = Date.timeIntervalSinceReferenceDate
            particles = (0..<60).map { _ in
                Particle(
                    startTime: now + Double.random(in: 0...0.8),
                    lifetime: Double.random(in: 2.5...4.0),
                    startXFraction: CGFloat.random(in: 0...1),
                    startY: CGFloat.random(in: -80 ... -20),
                    fallSpeed: CGFloat.random(in: 80...160),
                    driftX: CGFloat.random(in: -1...1),
                    wobbleFreq: Double.random(in: 1.5...4),
                    rotationSpeed: Double.random(in: -200...200),
                    width: CGFloat.random(in: 6...14),
                    height: CGFloat.random(in: 4...10),
                    isCircle: Bool.random(),
                    color: colors.randomElement() ?? .white
                )
            }
        }
        .allowsHitTesting(false)
    }

    struct Particle {
        let startTime: Double
        let lifetime: Double
        let startXFraction: CGFloat  // 0...1, multiplied by canvas width at render
        let startY: CGFloat
        let fallSpeed: CGFloat
        let driftX: CGFloat
        let wobbleFreq: Double
        let rotationSpeed: Double
        let width: CGFloat
        let height: CGFloat
        let isCircle: Bool
        let color: Color
    }
}
