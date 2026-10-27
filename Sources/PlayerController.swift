import SceneKit
import simd

class PlayerController: SCNNode {
    var characterNode: SCNNode?
    var isGrounded = false
    
    // Dictionary to hold your animations
    var animations: [String: CAAnimation] = [:]
    
    override init() {
        super.init()
        loadCustomCharacter()
        setupPhysics()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func loadCustomCharacter() {
        // 1. Load the USDZ file from the app bundle
        guard let url = Bundle.main.url(forResource: "character", withExtension: "usdz") else {
            print("ERROR: Could not find character.usdz in bundle.")
            return
        }
        
        do {
            let scene = try SCNScene(url: url, options: nil)
            
            // 2. Extract the root node of the character
            guard let importedModel = scene.rootNode.childNodes.first else { return }
            
            // 3. Fix scale and positioning if necessary
            // Roblox characters are usually around 5 studs tall. 
            // If your model is huge, try changing scale to 0.1 or 0.01
            importedModel.scale = SCNVector3(1.0, 1.0, 1.0) 
            
            self.characterNode = importedModel
            self.addChildNode(importedModel)
            
            // 4. Extract animations from the USDZ
            extractAnimations(from: importedModel)
            
            // Start idle animation
            playAnimation(name: "Idle")
            
        } catch {
            print("ERROR: Failed to load USDZ file: \(error)")
        }
    }
    
    func setupPhysics() {
        // A basic collision box for the character
        let shape = SCNPhysicsShape(geometry: SCNBox(width: 2, height: 5, length: 2, chamferRadius: 0), options: nil)
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        physicsBody?.isAffectedByGravity = true
        physicsBody?.angularVelocityFactor = SCNVector3(0, 0, 0) // Locks rotation so they don't fall over
        physicsBody?.friction = 0.0 // Prevents getting stuck on baseplate edges
    }
    
    func extractAnimations(from node: SCNNode) {
        // Look for animation players inside the USDZ hierarchy
        if let animationPlayer = node.animationPlayer(forKey: nil) {
            for key in animationPlayer.animationKeys {
                if let animation = animationPlayer.animation(forKey: key) {
                    // Save the animation using the key (e.g., "Idle", "Walk")
                    animations[key] = animation
                }
            }
        }
        
        // Recursively check children
        for child in node.childNodes {
            extractAnimations(from: child)
        }
    }
    
    func playAnimation(name: String) {
        // This looks for an animation with the name you exported from Blender
        if let animation = animations[name] {
            let player = SCNAnimationPlayer(animation: animation)
            player.speed = 1.0
            
            // Add and play the animation on the character node
            if let char = characterNode {
                char.removeAllAnimations()
                char.addAnimationPlayer(player, forKey: name)
                player.play()
            }
        }
    }
    
    // MARK: - Controls
    func jump() {
        if isGrounded {
            physicsBody?.applyForce(SCNVector3(0, 15, 0), asImpulse: true)
            isGrounded = false
            playAnimation(name: "Jump") // Plays jump animation if it exists
        }
    }
    
    func move(direction: SIMD2<Float>) {
        if !isGrounded { return }
        
        let speed: Float = 12.0
        let velocity = SCNVector3(direction.x * speed, physicsBody!.velocity.y, direction.y * speed)
        physicsBody?.velocity = velocity
        
        if simd_length(direction) > 0.1 {
            playAnimation(name: "Walk") // Plays walk animation if it exists
        } else {
            playAnimation(name: "Idle") // Plays idle animation if it exists
        }
    }
    
    func stop() {
        physicsBody?.velocity = SCNVector3(0, physicsBody!.velocity.y, 0)
        playAnimation(name: "Idle")
    }
}
