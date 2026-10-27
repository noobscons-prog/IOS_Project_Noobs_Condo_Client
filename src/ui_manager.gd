extends Control

# References to UI nodes
@onready var auth_panel = $AuthPanel
@onready var main_menu = $MainMenu
@onready var dob_year = $AuthPanel/YearInput
@onready var profile_pic = $MainMenu/ProfilePic
@onready var avatar_viewport = $AvatarViewport # SubViewport containing the 3D R6 avatar

var current_user_data = {}

func _ready():
    # Setup DOB restrictions
    dob_year.min_value = 1900
    dob_year.max_value = 2026
    show_login()

func show_login():
    auth_panel.visible = true
    main_menu.visible = false

func _on_signup_button_pressed():
    # In a real app, this is where you call your backend API (e.g., Supabase, Firebase)
    var username = $AuthPanel/UsernameInput.text
    var year = dob_year.value
    
    # Mock successful signup
    current_user_data = {
        "username": username,
        "birth_year": year,
        "played_games": []
    }
    
    _login_success()

func _login_success():
    auth_panel.visible = false
    main_menu.visible = true
    
    # Give default R6 avatar
    $MainMenu/AvatarName.text = current_user_data.username
    
    # Render the default avatar to the profile picture instantly
    render_profile_picture()

func render_profile_picture():
    # Wait for 3D rendering to catch up
    await get_tree().process_frame
    
    # Grab the texture from the SubViewport
    var viewport_texture = avatar_viewport.get_texture()
    var img = viewport_texture.get_image()
    
    # Create an ImageTexture to set on the UI Button/Sprite
    var texture = ImageTexture.create_from_image(img)
    profile_pic.texture = texture
    
    # This ensures the profile pic isn't blank!

func _on_game_played(game_id):
    # Update Continue tab
    if not current_user_data.played_games.has(game_id):
        current_user_data.played_games.append(game_id)
    
    # Keep only the last 30
    if current_user_data.played_games.size() > 30:
        current_user_data.played_games.pop_front()
        
    update_continue_tab()

func update_continue_tab():
    # Clear old buttons
    var container = $MainMenu/ContinueTab/ScrollContainer/HBoxContainer
    for child in container.get_children():
        child.queue_free()
        
    # Re-populate based on played_games
    for game_id in current_user_data.played_games:
        var btn = Button.new()
        btn.text = game_id
        container.add_child(btn)
