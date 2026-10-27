#include "character_controller.h"
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/classes/engine.hpp>

using namespace godot;

void CharacterController::_bind_methods() {
    // Bind properties if you want to edit them in the Godot inspector later
}

CharacterController::CharacterController() {}
CharacterController::~CharacterController() {}

void CharacterController::_ready() {
    anim_tree = Object::cast_to<AnimationTree>(get_node_or_null("AnimationTree"));
}

void CharacterController::_physics_process(double delta) {
    if (Engine::get_singleton()->is_editor_hint()) return;

    // 1. Get Joystick Input (Dynamic Magnitude for Walk/Run)
    input_dir = Input::get_singleton()->get_vector("move_left", "move_right", "move_forward", "move_back");
    float input_magnitude = input_dir.length();

    // 2. Apply Gravity
    if (!is_on_floor()) {
        Vector3 vel = get_velocity();
        vel.y -= gravity * delta;
        set_velocity(vel);
    }

    // 3. Handle Jump
    if (Input::get_singleton()->is_action_just_pressed("jump") && is_on_floor()) {
        Vector3 vel = get_velocity();
        vel.y = jump_velocity;
        set_velocity(vel);
        if (anim_tree) anim_tree->set("parameters/StateMachine/transition_request", "jump");
    }

    // 4. Dynamic Movement (Matches Roblox Thumbstick)
    // The speed scales based on how far the thumbstick is pushed
    Vector3 current_vel = get_velocity();
    Vector3 target_vel = Vector3(input_dir.x, 0, input_dir.y).normalized() * (max_run_speed * input_magnitude);
    current_vel.x = target_vel.x;
    current_vel.z = target_vel.z;
    set_velocity(current_vel);
    move_and_slide();

    // 5. Animation State Management
    if (anim_tree) {
        // BlendSpace1D handles the transition from Idle -> Walk -> Run based on magnitude
        anim_tree->set("parameters/StateMachine/MoveBlend/blend_position", input_magnitude);
        
        if (!is_on_floor()) {
            // If falling and velocity is negative, play fall. Otherwise play jump.
            String state = (get_velocity().y < 0) ? "fall" : "jump";
            anim_tree->set("parameters/StateMachine/transition_request", state);
        } else if (input_magnitude > 0.1f) {
            anim_tree->set("parameters/StateMachine/transition_request", "walk");
        } else {
            anim_tree->set("parameters/StateMachine/transition_request", "idle");
        }
    }
}
