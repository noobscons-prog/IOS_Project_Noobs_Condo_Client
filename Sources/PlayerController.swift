import SceneKit
import simd

class PlayerController: SCNNode {
    
    var characterRoot: SCNNode?
    var torso: SCNNode?
    var head: SCNNode?
    var leftArm: SCNNode?
    var rightArm: SCNNode?
    var leftLeg: SCNNode?
    var rightLeg: SCNNode?
    
    override init() {
        super.init()
        setupFallbackBody() 
        loadCharacterFromUSDZ() 
        setupPhysics()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func setupFallbackBody() {
        // We keep this invisible just in case, but remove it if USDZ loads
        let geo = SCNBox(width: 2, height: 5, length: 2, chamferRadius: 0)
        let mat = SCNMaterial()
        mat.diffuse.contents = UIColor.red
        geo.materials = [mat]
        let fallbackNode = SCNNode(geometry: geo)
        fallbackNode.position = SCNVector3(0, 0, 0)
        self.addChildNode(fallbackNode)
    }
    
    private func loadCharacterFromUSDZ() {
        var url = Bundle.main.url(forResource: "Roblox_R6_Rigged", withExtension: "usdz")
        if url == nil {
            url = Bundle.main.url(forResource: "Roblox_R6_Rigged", withExtension: "usdz", subdirectory: "character_files")
        }
        
        guard let finalUrl = url else {
            print("ERROR: Could not find Roblox_R6_Rigged.usdz. Using fallback red box.")
            return
        }
        
        do {
            let scene = try SCNScene(url: finalUrl, options: nil)
            guard let importedRoot = scene.rootNode.childNodes.first else { return }
            
            // 🚨 DYNAMIC SCALING 🚨
            // Calculate how big the model currently is
            let (min, max) = importedRoot.boundingBox
            let currentHeight = max.y - min.y
            
            // We want the character to be exactly 5 units tall (standard Roblox height)
            let targetHeight: Float = 5.0
            let scaleFactor = targetHeight / currentHeight
            importedRoot.scale = SCNVector3(scaleFactor, scaleFactor, scaleFactor)
            
            // Shift the model so its feet are at the bottom of the physics box (-2.5)
            let bottomOffset = -min.y * scaleFactor
            importedRoot.position = SCNVector3(0, -2.5 + bottomOffset, 0)
            
            // Remove fallback box
            self.childNodes.forEach { $0.removeFromParentNode() }
            
            self.characterRoot = importedRoot
            self.addChildNode(importedRoot)
            
            findR6Parts(in: importedRoot)
            setupLimbPivots()
            playIdle()
            
        } catch {
            print("ERROR: Failed to load USDZ: \(error). Using fallback red box.")
        }
    }
    
    private func findR6Parts(in node: SCNNode) {
        node.enumerateChildNodes { (child, _) in
            switch child.name?.lowercased() {
            case "torso": self.torso = child
            case "head": self.head = child
            case "left arm", "leftarm": self.leftArm = child
            case "right arm", "rightarm": self.rightArm = child
            case "left leg", "leftleg": self.leftLeg = child
            case "right leg", "rightleg": self.rightLeg = child
            default: break
            }
        }
    }
    
    private func setupLimbPivots() {
        // Since the model is dynamically scaled, we need to adjust pivots relative to the new scale
        let armPivot = SCNMatrix4MakeTranslation(0, 1, 0)
        leftArm?.pivot = armPivot
        rightArm?.pivot = armPivot
        
        let legPivot = SCNMatrix4MakeTranslation(0, -1, 0)
        leftLeg?.pivot = legPivot
        rightLeg?.pivot = legPivot
    }
    
    private func setupPhysics() {
        // The physics box is exactly 5 units tall, centered at 0,0,0
        let shape = SCNPhysicsShape(geometry: SCNBox(width: 2, height: 5, length: 2, chamferRadius: 0), options: nil)
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        physicsBody?.isAffectedByGravity = true
        physicsBody?.angularVelocityFactor = SCNVector3(0, 0, 0)
        physicsBody?.friction = 0.0
    }
    
    // MARK: - Animations
    func playIdle() {
        guard let torso = torso else { return }
        let reset = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.2)
        [leftArm, rightArm, leftLeg, rightLeg].forEach { $0?.runAction(reset) }
        
        let breatheUp = SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: 1.0)
        let breatheDown = breatheUp.reversed()
        let breathe = SCNAction.sequence([breatheUp, breatheDown])
        torso.runAction(SCNAction.repeatForever(breathe), forKey: "idle")
    }
    
    func playWalk() {
        torso?.removeAction(forKey: "idle")
        
        let swingForward = SCNAction.rotateTo(x: 0.5, y: 0, z: 0, duration: 0.4)
        let swingBack = SCNAction.rotateTo(x: -0.5, y: 0, z: 0, duration: 0.4)
        let walkCycle = SCNAction.sequence([swingForward, swingBack])
        
        leftLeg?.runAction(SCNAction.repeatForever(walkCycle), forKey: "walk")
        rightLeg?.runAction(SCNAction.repeatForever(walkCycle.reversed()), forKey: "walk")
        leftArm?.runAction(SCNAction.repeatForever(walkCycle.reversed()), forKey: "walk")
        rightArm?.runAction(SCNAction.repeatForever(walkCycle), forKey: "walk")
    }
    
    func playJumpPose() {
        leftArm?.runAction(SCNAction.rotateTo(x: 0, y: 0, z: -2.0, duration: 0.2))
        rightArm?.runAction(SCNAction.rotateTo(x: 0, y: 0, z: 2.0, duration: 0.2))
        leftLeg?.runAction(SCNAction.rotateTo(x: -0.5, y: 0, z: 0, duration: 0.2))
        rightLeg?.runAction(SCNAction.rotateTo(x: -0.5, y: 0, z: 0, duration: 0.2))
    }
    
    // MARK: - Controls
    func checkGrounded() -> Bool {
        // We check if the center of the body is near the floor (since the body is 5 units tall, center is at 2.5)
        if presentation.position.y <= 3.5 { return true }
        return false
    }
    
    func jump() {
        if checkGrounded() { 
            physicsBody?.applyForce(SCNVector3(0, 25, 0), asImpulse: true)
            playJumpPose()
        }
    }
    
    func move(direction: SIMD2<Float>) {
        let speed: Float = 12.0
        let velocity = SCNVector3(direction.x * speed, physicsBody!.velocity.y, direction.y * speed)
        physicsBody?.velocity = velocity
        
        if simd_length(direction) > 0.1 {
            playWalk()
        } else {
            playIdle()
        }
    }
    
    func stop() {
        physicsBody?.velocity = SCNVector3(0, physicsBody!.velocity.y, 0)
        playIdle()
    }
}
