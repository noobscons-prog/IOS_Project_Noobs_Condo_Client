import SwiftUI

struct JoystickView: View {
    var onMove: (simd_float2) -> Void
    var onRelease: () -> Void
    
    @State private var offset: CGSize = .zero
    let maxDistance: CGFloat = 40
    
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.2))
                .frame(width: 120, height: 120)
            
            Circle()
                .fill(Color.white.opacity(0.5))
                .frame(width: 50, height: 50)
                .offset(offset)
        }
        .gesture(
            DragGesture()
                .onChanged { value in
                    let translation = value.translation
                    let distance = sqrt(translation.width * translation.width + translation.height * translation.height)
                    
                    if distance < maxDistance {
                        offset = translation
                    } else {
                        let angle = atan2(translation.height, translation.width)
                        offset = CGSize(width: cos(angle) * maxDistance, height: sin(angle) * maxDistance)
                    }
                    
                    // Normalize vector (-1 to 1)
                    let normalizedX = Float(offset.width / maxDistance)
                    let normalizedY = Float(offset.height / maxDistance)
                    onMove(simd_float2(normalizedX, normalizedY))
                }
                .onEnded { _ in
                    offset = .zero
                    onRelease()
                }
        )
    }
}
