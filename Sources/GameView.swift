import SwiftUI
import SceneKit

struct GameView: UIViewRepresentable {
    @Binding var showGame: Bool
    
    func makeUIView(context: Context) -> SCNView {
        let view = SCNView()
        view.backgroundColor = UIColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1.0) // Sky blue
        view.allowsCameraControl = false
        view.autoenablesDefaultLighting = true
        
        let scene = SCNScene()
        view.scene = scene
        
        // 1. Setup Baseplate
        let baseplate = SCNBox(width: 100, height: 1, length: 100, chamferRadius: 0)
        let baseplateNode = SCNNode(geometry: baseplate)
        baseplateNode.position = SCNVector3(0, -0.5, 0)
        
        // Add the stud texture
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.darkGray // Placeholder for texture
        baseplate.materials = [material]
        
        // Add physics to ground
        baseplateNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        scene.rootNode.addChildNode(baseplateNode)
        
        // 2. Setup Character
        let player = PlayerController()
        scene.rootNode.addChildNode(player)
        
        // 3. Setup Camera (Roblox style over-the-shoulder)
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 5, 10)
        cameraNode.eulerAngles.x = -0.3 // Look slightly down
        scene.rootNode.addChildNode(cameraNode)
        view.pointOfView = cameraNode
        
        // 4. Handle Joystick Input
        let joystick = JoystickView { vector in
            player.move(direction: vector)
        } onRelease: {
            player.stop()
        }
        
        let hostingController = UIHostingController(rootView: 
            ZStack {
                Color.clear
                VStack {
                    HStack {
                        Button("Leave") { showGame = false }
                            .padding()
                            .background(Color.black.opacity(0.7))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .padding()
                        Spacer()
                    }
                    Spacer()
                    HStack {
                        joystick.padding(.leading, 30).padding(.bottom, 30)
                        Spacer()
                        Button(action: { player.jump() }) {
                            Image(systemName: "arrow.up")
                                .font(.largeTitle)
                                .padding(30)
                                .background(Color.white.opacity(0.3))
                                .foregroundColor(.white)
                                .clipShape(Circle())
                        }
                        .padding(.trailing, 30).padding(.bottom, 30)
                    }
                }
            }
            .background(Color.clear)
        )
        
        let overlay = hostingController.view!
        overlay.backgroundColor = .clear
        view.addSubview(overlay)
        overlay.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            overlay.topAnchor.constraint(equalTo: view.topAnchor),
            overlay.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            overlay.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            overlay.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        return view
    }
    
    func updateUIView(_ uiView: SCNView, context: Context) {}
}
