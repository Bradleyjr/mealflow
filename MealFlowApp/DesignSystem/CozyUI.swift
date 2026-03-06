import SwiftUI
import UIKit

struct CozyBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppTheme.background,
                    AppTheme.background.opacity(0.94),
                    AppTheme.butter.opacity(0.28)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            VStack {
                HStack {
                    Circle()
                        .fill(AppTheme.sage.opacity(0.18))
                        .frame(width: 220, height: 220)
                        .blur(radius: 20)
                        .offset(x: -60, y: -80)
                    Spacer()
                    Circle()
                        .fill(AppTheme.terracotta.opacity(0.16))
                        .frame(width: 180, height: 180)
                        .blur(radius: 12)
                        .offset(x: 40, y: -40)
                }
                Spacer()
                RoundedRectangle(cornerRadius: 90, style: .continuous)
                    .fill(AppTheme.butter.opacity(0.12))
                    .frame(height: 240)
                    .blur(radius: 18)
                    .offset(y: 70)
            }

            GrainOverlay()
                .blendMode(.softLight)
                .opacity(0.22)
        }
        .ignoresSafeArea()
    }
}

private struct GrainOverlay: View {
    var body: some View {
        TimelineView(.periodic(from: .now, by: 120)) { _ in
            Canvas { context, size in
                let dots = stride(from: 0.0, to: size.width * size.height / 120, by: 1).map { _ in
                    CGPoint(x: .random(in: 0...size.width), y: .random(in: 0...size.height))
                }
                for point in dots {
                    let rect = CGRect(x: point.x, y: point.y, width: 1.4, height: 1.4)
                    context.fill(
                        Path(ellipseIn: rect),
                        with: .color(.white.opacity(Double.random(in: 0.04...0.16)))
                    )
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

struct CozyCardModifier: ViewModifier {
    var padding: CGFloat = 18

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(AppTheme.card)
                    .shadow(color: AppTheme.warmShadow, radius: 18, y: 10)
                    .shadow(color: AppTheme.softShadow.opacity(0.4), radius: 2, y: 1)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(AppTheme.mist.opacity(0.45), lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .strokeBorder(AppTheme.stroke, lineWidth: 0.5)
                            .blur(radius: 0.3)
                    )
            )
    }
}

struct PantryHeader: View {
    let eyebrow: String
    let title: String
    let detail: String
    var icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(eyebrow.uppercased(), systemImage: icon)
                .font(.caption.weight(.bold))
                .tracking(1.2)
                .foregroundStyle(AppTheme.soil.opacity(0.8))

            Text(title)
                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                .foregroundStyle(AppTheme.soil)
                .fixedSize(horizontal: false, vertical: true)

            Text(detail)
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 34, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            AppTheme.butter.opacity(0.55),
                            AppTheme.panel.opacity(0.95)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(alignment: .topTrailing) {
                    Image(systemName: "sparkles")
                        .font(.title.weight(.medium))
                        .foregroundStyle(AppTheme.terracotta.opacity(0.35))
                        .padding(22)
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .stroke(AppTheme.stroke, lineWidth: 1)
                )
        )
    }
}

struct CozySectionHeader: View {
    let title: String
    let detail: String?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(AppTheme.soil)
                if let detail {
                    Text(detail)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 4)
    }
}

struct CozyPill: View {
    let label: String
    var tint: Color = AppTheme.sage
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(label)
        }
        .font(.footnote.weight(.semibold))
        .foregroundStyle(AppTheme.soil)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(tint.opacity(0.16))
                .overlay(Capsule(style: .continuous).stroke(tint.opacity(0.18), lineWidth: 1))
        )
    }
}

struct CozyPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [AppTheme.terracotta, AppTheme.berry],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .shadow(color: AppTheme.terracotta.opacity(0.26), radius: 10, y: 6)
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

struct CozySecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(AppTheme.soil)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: 48)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(AppTheme.panel.opacity(configuration.isPressed ? 0.86 : 1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(AppTheme.stroke, lineWidth: 1)
                    )
            )
            .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
    }
}

struct CozyStatRow: View {
    let items: [(String, String, Color)]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.0)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(item.1)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(AppTheme.soil)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(item.2.opacity(0.12))
                )
            }
        }
    }
}

extension View {
    func mealFlowCard(padding: CGFloat = 18) -> some View {
        modifier(CozyCardModifier(padding: padding))
    }

    func cozySurface() -> some View {
        background(CozyBackground())
    }
}

enum CozyFeedback {
    static func tap(style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}
