import SwiftUI
import SceneKit

struct GameView: View {
    @Binding var showGame: Bool
    
    @State private var scene = SCNScene()
    @State private var cameraNode = SCNNode()
    @State private var player = PlayerController()
    
    var body: some View {
        ZStack {
            SceneView(scene: scene, pointOfView: cameraNode, options: [.autoenablesDefaultLighting])
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
                    .padding([.leading, .bottom], 30)
                    
                    Spacer()
                    
                    Button(action: { player.jump() }) {
                        Image(systemName: "arrow.up")
                            .font(.largeTitle)
                            .padding(30)
                            .background(Color.white.opacity(0.3))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                    }
                    .padding([.trailing, .bottom], 30)
                }
            }
        }
        .onAppear {
            setupScene()
        }
    }
    
    func setupScene() {
        // 1. Sky Blue Background
        scene.background.contents = UIColor(red: 0.4, green: 0.6, blue: 0.8, alpha: 1.0)
        
        // 2. Thick Baseplate
        let baseplateGeo = SCNBox(width: 200, height: 5, length: 200, chamferRadius: 0)
        let baseplateNode = SCNNode(geometry: baseplateGeo)
        baseplateNode.position = SCNVector3(0, -2.5, 0) // Center it so top is at y=0
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor.darkGray
        baseplateGeo.materials = [material]
        
        // Explicit physics shape for ground
        let physicsShape = SCNPhysicsShape(geometry: baseplateGeo, options: nil)
        baseplateNode.physicsBody = SCNPhysicsBody(type: .static, shape: physicsShape)
        scene.rootNode.addChildNode(baseplateNode)
        
        // 3. Player (Spawn safely above ground)
        player.position = SCNVector3(0, 5, 0)
        scene.rootNode.addChildNode(player)
        
        // 4. Camera (Tracking)
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(0, 10, 15) 
        scene.rootNode.addChildNode(cameraNode)
        
        // Make camera follow player smoothly
        let followAction = SCNAction.customAction(duration: .infinity) { _, _ in
            let playerPos = self.player.presentation.position
            // Keep camera slightly behind and above
            let targetPos = SCNVector3(playerPos.x, playerPos.y + 8, playerPos.z + 15)
            self.cameraNode.position = targetPos
            self.cameraNode.look(at: SCNVector3(playerPos.x, playerPos.y + 2, playerPos.z))
        }
        cameraNode.runAction(followAction)
        
        // 5. Lighting
        let light = SCNNode()
        light.light = SCNLight()
        light.light!.type = .omni
        light.position = SCNVector3(10, 20, 10)
        scene.rootNode.addChildNode(light)
    }
}
