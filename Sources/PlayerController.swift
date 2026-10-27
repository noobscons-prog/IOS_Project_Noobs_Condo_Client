import SceneKit
import simd

class PlayerController: SCNNode {
    var torso = SCNNode()
    var head = SCNNode()
    var leftArm = SCNNode()
    var rightArm = SCNNode()
    var leftLeg = SCNNode()
    var rightLeg = SCNNode()
    
    var isGrounded = false
    
    override init() {
        super.init()
        setupR6Character()
        setupPhysics()
        playIdle()
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func setupR6Character() {
        let blockMaterial = SCNMaterial()
        blockMaterial.diffuse.contents = UIColor.systemBlue
        
        let torsoGeo = SCNBox(width: 2, height: 2, length: 1, chamferRadius: 0)
        torsoGeo.materials = [blockMaterial]
        torso.geometry = torsoGeo
        torso.position = SCNVector3(0, 2, 0)
        addChildNode(torso)
        
        let headGeo = SCNBox(width: 1.2, height: 1.2, length: 1.2, chamferRadius: 0)
        let headMat = SCNMaterial()
        headMat.diffuse.contents = UIColor.systemYellow
        headGeo.materials = [headMat]
        head.geometry = headGeo
        head.position = SCNVector3(0, 1.6, 0)
        torso.addChildNode(head)
        
        let limbGeo = SCNBox(width: 1, height: 2, length: 1, chamferRadius: 0)
        let limbMat = SCNMaterial()
        limbMat.diffuse.contents = UIColor.systemYellow
        limbGeo.materials = [limbMat]
        
        leftArm.geometry = limbGeo
        leftArm.pivot = SCNMatrix4MakeTranslation(0, -1, 0) 
        leftArm.position = SCNVector3(-1.5, 1, 0)
        torso.addChildNode(leftArm)
        
        rightArm.geometry = limbGeo
        rightArm.pivot = SCNMatrix4MakeTranslation(0, -1, 0)
        rightArm.position = SCNVector3(1.5, 1, 0)
        torso.addChildNode(rightArm)
        
        leftLeg.geometry = limbGeo
        leftLeg.pivot = SCNMatrix4MakeTranslation(0, 1, 0)
        leftLeg.position = SCNVector3(-0.5, -1, 0)
        torso.addChildNode(leftLeg)
        
        rightLeg.geometry = limbGeo
        rightLeg.pivot = SCNMatrix4MakeTranslation(0, 1, 0)
        rightLeg.position = SCNVector3(0.5, -1, 0)
        torso.addChildNode(rightLeg)
    }
    
    func setupPhysics() {
        let shape = SCNPhysicsShape(geometry: SCNBox(width: 2, height: 5, length: 1, chamferRadius: 0), options: nil)
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: shape)
        physicsBody?.isAffectedByGravity = true
        physicsBody?.angularVelocityFactor = SCNVector3(0, 0, 0) // This locks rotation
    }
    
    // MARK: - Animations
    func playIdle() {
        removeAction(forKey: "walk")
        removeAction(forKey: "idle")
        
        let reset = SCNAction.rotateTo(x: 0, y: 0, z: 0, duration: 0.2)
        leftArm.runAction(reset)
        rightArm.runAction(reset)
        leftLeg.runAction(reset)
        rightLeg.runAction(reset)
        
        let breatheUp = SCNAction.moveBy(x: 0, y: 0.05, z: 0, duration: 1.0)
        let breatheDown = breatheUp.reversed()
        let breathe = SCNAction.sequence([breatheUp, breatheDown])
        torso.runAction(SCNAction.repeatForever(breathe), forKey: "idle")
    }
    
    func playWalk() {
        removeAction(forKey: "idle")
        if action(forKey: "walk") != nil { return }
        
        let swingForward = SCNAction.rotateTo(x: 0.5, y: 0, z: 0, duration: 0.4)
        let swingBack = SCNAction.rotateTo(x: -0.5, y: 0, z: 0, duration: 0.4)
        let walkCycle = SCNAction.sequence([swingForward, swingBack])
        
        leftLeg.runAction(SCNAction.repeatForever(walkCycle), forKey: "walk")
        rightLeg.runAction(SCNAction.repeatForever(walkCycle.reversed()), forKey: "walk")
        
        leftArm.runAction(SCNAction.repeatForever(walkCycle.reversed()), forKey: "walk")
        rightArm.runAction(SCNAction.repeatForever(walkCycle), forKey: "walk")
    }
    
    func jump() {
        if isGrounded {
            physicsBody?.applyForce(SCNVector3(0, 15, 0), asImpulse: true)
            isGrounded = false
            
            removeAction(forKey: "walk")
            removeAction(forKey: "idle")
            
            leftArm.runAction(SCNAction.rotateTo(x: 0, y: 0, z: -2.5, duration: 0.2))
            rightArm.runAction(SCNAction.rotateTo(x: 0, y: 0, z: 2.5, duration: 0.2))
        }
    }
    
    func move(direction: SIMD2<Float>) {
        if !isGrounded { return }
        
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
