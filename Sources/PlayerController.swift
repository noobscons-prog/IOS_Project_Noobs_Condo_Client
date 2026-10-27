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
        // Since physics box center is 0,0,0, we center the visual box at 0,0,0
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
            
            // Scale down the character
            importedRoot.scale = SCNVector3(0.05, 0.05, 0.05)
            
            // 🚨 FIX COLLISION: Align feet to the bottom of the 5-unit physics box (-2.5)
            let (min, _) = importedRoot.boundingBox
            let bottomOffset = -min.y * 0.05 // Taking scale into account
            importedRoot.position = SCNVector3(0, -2.5 + bottomOffset, 0)
            
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
            guard let name = child.name?.lowercased() else { return }
            
            // Matching common naming conventions (e.g., "LeftArm", "Left Arm", "left_arm")
            if name.contains("torso") || name.contains("body") || name.contains("chest") {
                self.torso = child
            } else if name.contains("head") {
                self.head = child
            } else if (name.contains("left") || name.contains("l_")) && name.contains("arm") {
                self.leftArm = child
            } else if (name.contains("right") || name.contains("r_")) && name.contains("arm") {
                self.rightArm = child
            } else if (name.contains("left") || name.contains("l_")) && name.contains("leg") {
                self.leftLeg = child
            } else if (name.contains("right") || name.contains("r_")) && name.contains("leg") {
                self.rightLeg = child
            }
        }
    }
    
    // 🚨 DEBUG: Function to get all bone names for the log UI
    func logBoneNames() -> String {
        guard let root = characterRoot else { return "No character loaded." }
        var log = "Character Hierarchy:\n"
        
        func traverse(_ node: SCNNode, depth: Int) {
            let indent = String(repeating: "  ", count: depth)
            if let name = node.name {
                log += "\(indent)- \(name)\n"
            }
            for child in node.childNodes {
                traverse(child, depth: depth + 1)
            }
        }
        traverse(root, depth: 0)
        return log
    }
    
    private func setupLimbPivots() {
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
        physicsBody?.restitution = 0.0 // Prevents bouncing
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
        // Since the box is 5 units tall and spawns at Y=2.5, if the player is near Y=2.5, they are on the ground.
        if presentation.position.y <= 3.0 { return true }
        return false
    }
    
    func jump() {
        if checkGrounded() { 
            // Direct velocity change is much more reliable than force
            physicsBody?.velocity.y = 15.0
            playJumpPose()
        }
    }
    
    func move(direction: SIMD2<Float>) {
        // Only move horizontally, preserve gravity's vertical pull
        let speed: Float = 12.0
        physicsBody?.velocity.x = direction.x * speed
        physicsBody?.velocity.z = direction.y * speed
        
        if simd_length(direction) > 0.1 {
            // 🚨 FIX ROTATION: Rotate to face the direction of movement
            let angle = atan2(direction.x, direction.y)
            self.eulerAngles.y = angle
            
            if checkGrounded() {
                playWalk()
            }
        } else {
            if checkGrounded() {
                playIdle()
            }
        }
    }
    
    func stop() {
        physicsBody?.velocity.x = 0
        physicsBody?.velocity.z = 0
        if checkGrounded() {
            playIdle()
        }
    }
}
