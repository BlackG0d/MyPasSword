import SwiftUI

struct ShakeEffect: GeometryEffect {
    var travelDistance: CGFloat = 18
    var shakesPerUnit: CGFloat = 4
    var animatableData: CGFloat

    func effectValue(size: CGSize) -> ProjectionTransform {
        // Один раз тряска без пауз
        let translation = travelDistance * sin(animatableData * .pi * 2) * (1 - animatableData * 0.5)
        return ProjectionTransform(CGAffineTransform(translationX: translation, y: 0))
    }
}
