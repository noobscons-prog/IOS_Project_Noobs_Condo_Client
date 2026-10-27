extends Node3D

var character_controller
var anim_tree
var anim_player

func _ready():
    _setup_environment()
    _setup_baseplate()
    _setup_character()
    _setup_camera()
    #_setup_ui() # We will add the UI in the next step

func _setup_environment():
    # Create Sun
    var light = DirectionalLight3D.new()
    light.rotation_degrees = Vector3(-45, -45, 0)
    light.shadow_enabled = true
    add_child(light)
    
    # Create Sky (Simplified)
    var env = WorldEnvironment.new()
    var environment = Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.4, 0.6, 0.8) # Roblox classic blue sky
    env.environment = environment
    add_child(env)

func _setup_baseplate():
    # Create the Baseplate
    var baseplate = StaticBody3D.new()
    var mesh = MeshInstance3D.new()
    var box = BoxMesh.new()
    box.size = Vector3(100, 1, 100)
    mesh.mesh = box
    
    # Apply your stud texture!
    var material = StandardMaterial3D.new()
    var texture = load("res://textures/stud_texture.jpeg")
    if texture:
        material.albedo_texture = texture
        # Tiling the texture so the studs repeat like Roblox
        material.uv1_scale = Vector3(50, 50, 50) 
    mesh.material_override = material
    
    var collision = CollisionShape3D.new()
    var shape = BoxShape3D.new()
    shape.size = box.size
    collision.shape = shape
    
    baseplate.add_child(mesh)
    baseplate.add_child(collision)
    baseplate.position = Vector3(0, -0.5, 0)
    add_child(baseplate)

func _setup_character():
    # Load the FBX you provided
    var fbx_scene = load("res://character_files/r6_default_character.fbx")
    if not fbx_scene:
        print("ERROR: FBX not found!")
        return
        
    var character_model = fbx_scene.instantiate()
    
    # We create a CharacterBody3D and attach our C++ script
    character_controller = CharacterBody3D.new()
    # Assuming the C++ class is registered as CharacterController
    # character_controller.set_script(load("res://src/character_controller.gdns")) # If using C++
    # For now, we assume C++ class is attached directly
    character_controller.add_child(character_model)
    
    # Find the AnimationPlayer inside the FBX
    anim_player = character_model.find_child("AnimationPlayer", true, false)
    
    if anim_player:
        _setup_animations()
        
    add_child(character_controller)

func _setup_animations():
    # Dynamically create the AnimationTree
    anim_tree = AnimationTree.new()
    anim_tree.tree_root = AnimationNodeStateMachine.new()
    
    var state_machine = anim_tree.tree_root as AnimationNodeStateMachine
    
    # Create nodes
    var idle_node = AnimationNodeAnimation.new()
    idle_node.animation = "Idle"
    
    var walk_node = AnimationNodeAnimation.new()
    walk_node.animation = "Walk"
    
    var jump_node = AnimationNodeAnimation.new()
    jump_node.animation = "Jump"
    
    var fall_node = AnimationNodeAnimation.new()
    fall_node.animation = "Fall"
    
    # Add them to the state machine
    state_machine.add_node("idle", idle_node)
    state_machine.add_node("walk", walk_node)
    state_machine.add_node("jump", jump_node)
    state_machine.add_node("fall", fall_node)
    
    # Connect them (Transitions)
    state_machine.add_transition("idle", "walk", AnimationNodeStateMachineTransition.new())
    state_machine.add_transition("walk", "idle", AnimationNodeStateMachineTransition.new())
    state_machine.add_transition("walk", "jump", AnimationNodeStateMachineTransition.new())
    state_machine.add_transition("jump", "fall", AnimationNodeStateMachineTransition.new())
    state_machine.add_transition("fall", "walk", AnimationNodeStateMachineTransition.new())
    
    anim_tree.anim_player = anim_tree.get_path_to(anim_player)
    character_controller.add_child(anim_tree)
    
    anim_tree.active = true

func _setup_camera():
    # Create a Roblox-style over-the-shoulder camera
    var spring_arm = SpringArm3D.new()
    spring_arm.spring_length = 10.0
    
    var camera = Camera3D.new()
    camera.current = true
    
    spring_arm.add_child(camera)
    character_controller.add_child(spring_arm)
    spring_arm.position = Vector3(0, 2, 0) # Position at head height
