#ifndef CHARACTER_CONTROLLER_H
#define CHARACTER_CONTROLLER_H

#include <godot_cpp/classes/character_body3d.hpp>
#include <godot_cpp/classes/animation_tree.hpp>
#include <godot_cpp/classes/input.hpp>

namespace godot {

class CharacterController : public CharacterBody3D {
    GDCLASS(CharacterController, CharacterBody3D)

private:
    float max_run_speed = 16.0f;
    float jump_velocity = 8.0f;
    float gravity = 32.0f;
    
    AnimationTree* anim_tree;
    Vector2 input_dir;

protected:
    static void _bind_methods();

public:
    CharacterController();
    ~CharacterController();

    void _ready() override;
    void _physics_process(double delta) override;
};

}

#endif
