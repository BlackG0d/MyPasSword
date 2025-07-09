import SwiftUI

// Расширения для View с неоморфическими стилями
extension View {
    func neumorphic(cornerRadius: CGFloat = 20) -> some View {
        self.modifier(NeumorphicModifier(cornerRadius: cornerRadius, isCircle: false))
    }
    func neumorphicCircle() -> some View {
        self.modifier(NeumorphicModifier(isCircle: true))
    }
    func insetNeumorphic(cornerRadius: CGFloat = 12) -> some View {
        self.modifier(InsetNeumorphicModifier(cornerRadius: cornerRadius))
    }
} 