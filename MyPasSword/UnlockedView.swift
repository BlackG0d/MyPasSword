import SwiftUI

struct UnlockedView: View {
    @Binding var isUnlocked: Bool
    var body: some View {
        ZStack {
            Color.black
                .edgesIgnoringSafeArea(.all)
            VStack(spacing: 30) {
                Image(systemName: "lock.open.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.green)
                Text("Unlocked!")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Text("Welcome back!")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                Button("Lock Again") {
                    isUnlocked = false
                }
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white)
                .padding(.horizontal, 30)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.2))
                .cornerRadius(25)
            }
        }
    }
} 