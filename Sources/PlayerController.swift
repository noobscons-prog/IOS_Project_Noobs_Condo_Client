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
            
            // 🚨 HARDCODED SCALE 🚨
            // Since boundingBox is unreliable before rendering, we force a tiny scale.
            // If this is too small, change 0.05 to 0.1 or 0.2.
            importedRoot.scale = SCNVector3(0.05, 0.05, 0.05)
            
            // Center the model inside our physics box
            importedRoot.position = SCNVector3(0, 0, 0)
            
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
    
    // 🚨 SMARTER LIMB SEARCH 🚨
    private func findR6Parts(in node: SCNNode) {
        var foundParts = 0
        node.enumerateChildNodes { (child, _) in
            guard let name = child.name?.lowercased() else { return }
            
            // Using 'contains' so it catches names like "mixamorig:LeftArm" or "Left Arm 1"
            if name.contains("torso") || name.contains("body") {
                self.torso = child
                foundParts += 1
            } else if name.contains("head") {
                self.head = child
                foundParts += 1
            } else if (name.contains("left") || name.contains("l_")) && name.contains("arm") {
                self.leftArm = child
                foundParts += 1
            } else if (name.contains("right") || name.contains("r_")) && name.contains("arm") {
                self.rightArm = child
                foundParts += 1
            } else if (name.contains("left") || name.contains("l_")) && name.contains("leg") {
                self.leftLeg = child
                foundParts += 1
            } else if (name.contains("right") || name.contains("r_")) && name.contains("leg") {
                self.rightLeg = child
                foundParts += 1
            }
        }
        print("R6 Search Results: Found \(foundParts) parts. Torso:\(torso != nil) Head:\(head != nil) LArm:\(leftArm != nil) RArm:\(rightArm != nil) LLeg:\(leftLeg != nil) RLeg:\(rightLeg != nil)")
    }
    
    private func setupLimbPivots() {
        // Adjusted pivots for the smaller scale
        let armPivot = SCNMatrix4MakeTranslation(0, 1, 0)
        leftArm?.pivot = armPivot
        rightArm?.pivot = armPivot
        
        let legPivot = SCNMatrix4MakeTranslation(0, -1, 0)
        leftLeg?.pivot = legPivot
        rightLeg?.pivot = legPivot
    }
    
    private func setupPhysics() {
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
