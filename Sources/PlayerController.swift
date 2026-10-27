import SceneKit
import simd

class PlayerController: SCNNode {
    
    // MARK: - Character Nodes
    var characterRoot: SCNNode?
    var torso: SCNNode?
    var head: SCNNode?
    var leftArm: SCNNode?
    var rightArm: SCNNode?
    var leftLeg: SCNNode?
    var rightLeg: SCNNode?
    
    // MARK: - State
    var isGrounded = false
    private var currentAnimation: String = "Idle"
    
    override init() {
        super.init()
        loadCharacterFromUSDZ()
        setupPhysics()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Loading the USDZ
    private func loadCharacterFromUSDZ() {
        // The file is in character_files/Roblox_R6_Rigged.usdz
        guard let url = Bundle.main.url(forResource: "Roblox_R6_Rigged", withExtension: "usdz", subdirectory: "character_files") else {
            print("ERROR: Could not find character_files/Roblox_R6_Rigged.usdz in bundle.")
            return
        }
        
        do {
            let scene = try SCNScene(url: url, options: nil)
            guard let importedRoot = scene.rootNode.childNodes.first else { return }
            
            // Scale down if the model is too large (adjust as needed)
            importedRoot.scale = SCNVector3(0.5, 0.5, 0.5)
            
            self.characterRoot = importedRoot
            self.addChildNode(importedRoot)
            
            // Find the R6 body parts
            findR6Parts(in: importedRoot)
            
            // Setup pivots for limbs
            setupLimbPivots()
            
            // Start Idle
            playIdle()
            
        } catch {
            print("ERROR: Failed to load USDZ: \(error)")
        }
    }
    
    // MARK: - Locating R6 Limbs
    private func findR6Parts(in node: SCNNode) {
        // Recursively search for nodes with standard R6 names
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
        print("R6 Parts Found: Torso:\(torso != nil) Head:\(head != nil) LArm:\(leftArm != nil) RArm:\(rightArm != nil) LLeg:\(leftLeg != nil) RLeg:\(rightLeg != nil)")
    }
    
    // MARK: - Pivots
    private func setupLimbPivots() {
        // Move pivot to the top of the limb so it swings like a shoulder/hip
        let armPivot = SCNMatrix4MakeTranslation(0, 1, 0) // Adjust if necessary
        leftArm?.pivot = armPivot
        rightArm?.pivot = armPivot
        
        let legPivot = SCNMatrix4MakeTranslation(0, -1, 0) // Adjust if necessary
        leftLeg?.pivot = legPivot
        rightLeg?.pivot = legPivot
    }
    
    // MARK: - Physics
    private func setupPhysics() {
        let shape = SCNPhysicsShape(geometry: SCNBox(width: 2, height: 5, length: 2, chamferRadius: 0), options: nil)
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        physicsBody?.isAffectedByGravity = true
        physicsBody?.angularVelocityFactor = SCNVector3(0, 0, 0)
        physicsBody?.friction = 0.0
    }
    
    // MARK: - Animations
    private func playAnimation(name: String) {
        guard currentAnimation != name else { return }
        currentAnimation = name
        
        // Remove all actions from limbs
        [leftArm, rightArm, leftLeg, rightLeg].forEach { $0?.removeAllActions() }
        
        switch name {
        case "Walk": playWalk()
        case "Jump": playJumpPose()
        default: playIdle()
        }
    }
    
    func playIdle() {
        // Reset to neutral
        let reset = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.2)
        [leftArm, rightArm, leftLeg, rightLeg].forEach { $0?.runAction(reset) }
        
        // Simple breathing on torso
        let breatheUp = SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: 1.0)
        let breatheDown = breatheUp.reversed()
        let breathe = SCNAction.sequence([breatheUp, breatheDown])
        torso?.runAction(SCNAction.repeatForever(breathe), forKey: "idle")
    }
    
    private func playWalk() {
        // Stop idle on torso
        torso?.removeAction(forKey: "idle")
        
        let swingForward = SCNAction.rotateTo(x: 0.5, y: 0, z: 0, duration: 0.4)
        let swingBack = SCNAction.rotateTo(x: -0.5, y: 0, z: 0, duration: 0.4)
        let walkCycle = SCNAction.sequence([swingForward, swingBack])
        
        // Legs swing opposite
        leftLeg?.runAction(SCNAction.repeatForever(walkCycle), forKey: "walk")
        rightLeg?.runAction(SCNAction.repeatForever(walkCycle.reversed()), forKey: "walk")
        
        // Arms swing opposite to legs
        leftArm?.runAction(SCNAction.repeatForever(walkCycle.reversed()), forKey: "walk")
        rightArm?.runAction(SCNAction.repeatForever(walkCycle), forKey: "walk")
    }
    
    private func playJumpPose() {
        // Quick pose for jumping
        leftArm?.runAction(SCNAction.rotateTo(x: 0, y: 0, z: -2.0, duration: 0.2))
        rightArm?.runAction(SCNAction.rotateTo(x: 0, y: 0, z: 2.0, duration: 0.2))
        leftLeg?.runAction(SCNAction.rotateTo(x: -0.5, y: 0, z: 0, duration: 0.2))
        rightLeg?.runAction(SCNAction.rotateTo(x: -0.5, y: 0, z: 0, duration: 0.2))
    }
    
    // MARK: - Controls
    func jump() {
        if isGrounded {
            physicsBody?.applyForce(SCNVector3(0, 15, 0), asImpulse: true)
            isGrounded = false
            playAnimation(name: "Jump")
        }
    }
    
    func move(direction: SIMD2<Float>) {
        if !isGrounded { return }
        
        let speed: Float = 12.0
        let velocity = SCNVector3(direction.x * speed, physicsBody!.velocity.y, direction.y * speed)
        physicsBody?.velocity = velocity
        
        if simd_length(direction) > 0.1 {
            playAnimation(name: "Walk")
        } else {
            playAnimation(name: "Idle")
        }
    }
    
    func stop() {
        physicsBody?.velocity = SCNVector3(0, physicsBody!.velocity.y, 0)
        playAnimation(name: "Idle")
    }
}
