import SwiftUI
import SceneKit

struct GameView: View {
    @Binding var showGame: Bool
    
    @State private var scene = SCNScene()
    @State private var cameraNode = SCNNode()
    @State private var player = PlayerController()
    
    var body: some View {
        ZStack {
            // Native SwiftUI SceneKit View
            SceneView(scene: scene, pointOfView: cameraNode, options: [.autoenablesDefaultLighting, .allowsCameraControl])
                .ignoresSafeArea()
            
            // UI Overlay
            VStack {
                HStack {
                    Button(action: { showGame = false }) {
                        Text("Leave")
                            .font(.headline)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    Spacer()
                }
                .padding()
                
                Spacer()
                
                HStack {
                    JoystickView(
                        onMove: { vector in player.move(direction: vector) },
                        onRelease: { player.stop() }
                    )
                    .padding(.leading, 30)
                    .padding(.bottom, 30)
                    
                    Spacer()
                    
                    Button(action: { player.jump() }) {
                        Image(systemName: "arrow.up")
                            .font(.largeTitle)
                            .padding(30)
                            .background(Color.white.opacity(0.3))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .padding(.trailing, 30)
                    .padding(.bottom, 30)
                }
            }
        }
        .onAppear {
            setupScene()
        }
    }
    
    func setupScene() {
        // 1. Baseplate
        let baseplateGeo = SCNBox(width: 100, height: 1, length: 100, chamferRadius: 0)
        let baseplateNode = SCNNode(geometry: baseplateGeo)
        baseplateNode.position = SCNVector3(0, -0.5, 0)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.darkGray
        baseplateGeo.materials = [material]
        
        // Physics for ground
        baseplateNode.physicsBody = SCNPhysicsBody(type: .static, shape: nil)
        scene.rootNode.addChildNode(baseplateNode)
        
        // 2. Player
        player.position = SCNVector3(0, 3, 0)
        scene.rootNode.addChildNode(player)
        
        // 3. Camera (Tracking)
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 8, 12)
        cameraNode.eulerAngles.x = -0.4 // Look down at player
        scene.rootNode.addChildNode(cameraNode)
        
        // Make camera follow player smoothly
        let followAction = SCNAction.customAction(duration: .infinity) { _, _ in
            let playerPos = self.player.presentation.position
            let targetPos = SCNVector3(playerPos.x, playerPos.y + 5, playerPos.z + 12)
            self.cameraNode.position = targetPos
            self.cameraNode.look(at: SCNVector3(playerPos.x, playerPos.y + 2, playerPos.z))
        }
        cameraNode.runAction(followAction)
        
        // 4. Detect Ground (Simple checker)
        let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if self.player.presentation.position.y <= 1.5 {
                self.player.isGrounded = true
            } else {
                self.player.isGrounded = false
                // If falling, clear walk animation
                self.player.removeAction(forKey: "walk")
                self.player.removeAction(forKey: "idle")
            }
        }
        RunLoop.main.add(timer, forMode: .common)
    }
}
