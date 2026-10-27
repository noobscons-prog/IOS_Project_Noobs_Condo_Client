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
    
    // Store the bone log here so the UI can access it
    var boneLogText: String = "No character loaded."
    
    override init() {
        super.init()
        loadCharacter()
        setupPhysics()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func loadCharacter() {
        // Prioritize FBX
        var url = Bundle.main.url(forResource: "Roblox_R6_Rigged", withExtension: "fbx")
        if url == nil {
            url = Bundle.main.url(forResource: "Roblox_R6_Rigged", withExtension: "usdz")
        }
        
        guard let finalUrl = url else {
            boneLogText = "ERROR: Could not find .fbx or .usdz in bundle."
            return
        }
        
        do {
            // Use SCNSceneSource to load FBX properly
            let source = SCNSceneSource(url: finalUrl, options: nil)
            // 🚨 FIXED: Use try? instead of the error parameter
            let scene = try? source?.scene(options: nil)
            
            guard let rootNode = scene?.rootNode.childNodes.first else {
                boneLogText = "ERROR: Failed to extract root node from file."
                return
            }
            
            // Hardcoded scale down
            rootNode.scale = SCNVector3(0.1, 0.1, 0.1)
            
            // Align feet to the bottom of the physics box (-2.5)
            let (min, _) = rootNode.boundingBox
            let bottomOffset = -min.y * 0.1
            rootNode.position = SCNVector3(0, -2.5 + bottomOffset, 0)
            
            self.characterRoot = rootNode
            self.addChildNode(rootNode)
            
            // Generate the log of all nodes
            boneLogText = "Character Hierarchy:\n"
            findR6PartsAndLog(in: rootNode)
            
            setupLimbPivots()
            playIdle()
            
        } catch {
            boneLogText = "ERROR loading file: \(error)"
        }
    }
    
    private func findR6PartsAndLog(in node: SCNNode) {
        // 🚨 FIXED: Changed var to let to remove the warning
        let depth = 0
        
        // Recursive function to print and find parts
        func traverse(currentNode: SCNNode, currentDepth: Int) {
            let indent = String(repeating: "  ", count: currentDepth)
            if let name = currentNode.name {
                boneLogText += "\(indent)- \(name)\n"
                
                // Match common naming conventions
                let lower = name.lowercased()
                if lower.contains("torso") || lower.contains("body") { self.torso = currentNode }
                else if lower.contains("head") { self.head = currentNode }
                else if (lower.contains("left") || lower.contains("l_")) && lower.contains("arm") { self.leftArm = currentNode }
                else if (lower.contains("right") || lower.contains("r_")) && lower.contains("arm") { self.rightArm = currentNode }
                else if (lower.contains("left") || lower.contains("l_")) && lower.contains("leg") { self.leftLeg = currentNode }
                else if (lower.contains("right") || lower.contains("r_")) && lower.contains("leg") { self.rightLeg = currentNode }
            }
            
            for child in currentNode.childNodes {
                traverse(currentNode: child, currentDepth: currentDepth + 1)
            }
        }
        traverse(currentNode: node, currentDepth: depth)
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
        physicsBody?.friction = 0.5 
        physicsBody?.restitution = 0.0 
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
        if presentation.position.y <= 3.0 { return true }
        return false
    }
    
    func jump() {
        if checkGrounded() { 
            physicsBody?.velocity.y = 15.0
            playJumpPose()
        }
    }
    
    func move(direction: SIMD2<Float>) {
        let speed: Float = 12.0
        physicsBody?.velocity.x = direction.x * speed
        physicsBody?.velocity.z = direction.y * speed
        
        if simd_length(direction) > 0.1 {
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
