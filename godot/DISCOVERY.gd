#  _the terror_               
# | |        | |              
# | |__   ___| | _____      __
# | '_ \ / _ \ |/ _ \ \ /\ / /
# | |_) |  __/ | (_) \ V  V / 
# |_.__/ \___|_|\___/ \_/\_/ 
#
# Copyright 2022 Oregon Institute of Technology
# 
# Permission is hereby granted, free of charge, to any person obtaining 
# a copy of this software and associated documentation files (the 
# "Software"), to deal in the Software without restriction, including 
# without limitation the rights to use, copy, modify, merge, publish, 
# distribute, sublicense, and/or sell copies of the Software, and to 
# permit persons to whom the Software is furnished to do so, subject to 
# the following conditions:
# 
# * The above copyright notice and this permission notice shall be 
# 	included in all copies or substantial portions of the Software.
# 
# * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
# 	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
# 	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. 
#	IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY 
#	CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, 
#	TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
#	SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#                                              


extends KinematicBody;

var visual           : Spatial = null;
var portrait         : Texture = null;
var can_move         : bool = false;
var can_aggro        : bool = false;
var accel            : float = 0.0;
var max_veloc        : float = 0.0;
var disc_name        : String;
var flavour_text     : String;
var found_yet        : bool = false;
var photographed_yet : bool = false;
var sonar_echo_timer : int = -1;
var aggro_range      : float = 1.0;
var must_breathe     : bool = false;
var air_timer        : float = 0.0;
var max_air          : float = 100.0;
var noise_idle       : AudioStreamPlayer = null;
var noise_swim       : AudioStreamPlayer = null;
var noise_attack     : AudioStreamPlayer = null;
var should_show_arrow: bool = false;
var dist_in_meters   : float = 0.0;

var ping_sound       : AudioStreamPlayer2D;

var collision_shape  : CollisionShape = null; 
var velocity         : Vector3 = Vector3.ZERO;

var HUD                     = null; # TODO: should be typed
var CAM                     = null;

# distances from player at which we need to display an arrow pointing towards
# ourselves when sonared 
const HUD_ARROW_DISTANCE_MIN_X : int = 641;  
const HUD_ARROW_DISTANCE_MIN_Y : int = 361;  

#--------------------------------------------------------------------------------------------------

func _init():
    # TIL Godot doesn't have a default constructor
    return;

#--------------------------------------------------------------------------------------------------

func _ready():
    # we need to be able to communicate directly with the HUD, so check
    # that we can access it, and throw a tantrum if not. 
    #self.HUD = get_tree().get_root().find_node("HUD");
    #assert(self.HUD != null);
    set_process(true);
    ping_sound = AudioStreamPlayer2D.new();
    ping_sound.stream = load("res://HUD/sounds/sonar_bounce.wav");
    ping_sound.volume_db = Global.get_sfx_vol_in_db();
    add_child(ping_sound);
    return;

#--------------------------------------------------------------------------------------------------
func init_from_json(filename : String, in_hud : Node2D, in_cam : Camera):
        
    var f_in = File.new();
    assert(f_in.open(filename,File.READ) == OK);
    
    var txt = f_in.get_as_text();
    assert(txt != null)
    
    var dict = parse_json(txt);
    assert(dict != null);
    
    HUD = in_hud;
    CAM = in_cam;
    
    assert(HUD != null);
    assert(CAM != null);
    
    # checks to make sure the discovery description file isn't malformed
    # if we're missing a vital field, we throw a tantrum and soft-crash.
    assert("visual" in dict);              #asset path, relative to "res://"
    assert("disc_name" in dict);           #string 
    assert("flavour_text" in dict);        #string
    assert("portrait" in dict);            #asset path, relative to "res://"
    
    self.visual        = load(dict.get("visual")).instance();
    self.portrait      = load(dict.get("portrait")) as Texture;
    self.disc_name     = dict.get("disc_name") as String;
    self.flavour_text  = dict.get("flavour_text") as String;
    
    # make the model visible in the world
    add_child(self.visual);
        
    # test code - remove
    print("Discovery name: " + self.disc_name);
    print("Discovery flavour text: " + self.flavour_text);
        
    f_in.close();

#--------------------------------------------------------------------------------------------------
func init_from_json_at_pos(filename : String, x : float, y : float, in_hud : Node2D, in_cam : Camera):
    init_from_json(filename,in_hud,in_cam);
    translation.z = -x;
    translation.y = y;
    return;

#--------------------------------------------------------------------------------------------------
# check if we're close enough to the player for the echo to hit us.
# if yes, set a counter, wait _n_ frames, then tell the hud to draw
# a sonar echo emanating from our location, plus our name if that's
# appropriate.

func on_sonar(player_pos : Vector3):
    # reset this flag to its default
    self.should_show_arrow = false;

    self.dist_in_meters = sqrt(pow(self.translation.z - player_pos.z,2) + pow(self.translation.y - player_pos.y,2));
    var my_2D_pos = CAM.unproject_position(self.translation);
    var sub_2D_pos = CAM.unproject_position(player_pos);
    
    var pythag_distance : float = sqrt(pow(my_2D_pos.x - sub_2D_pos.x,2) + pow(my_2D_pos.y - sub_2D_pos.y,2));
    if (pythag_distance > Global.MAX_SONAR_PING_DISTANCE):
        # out of range - do nothing.
        sonar_echo_timer = -1;
        
        return;
    else:
        # start a countdown to simulate the delay between the sound leaving
        # the sub and the sound hitting us
        sonar_echo_timer = (pythag_distance / Global.SONAR_WAVE_SPEED);
        
    return;

#--------------------------------------------------------------------------------------------------
# the first time we're within photographing range of the player, tell the HUD to
# display our portrait and flavour text.
func on_found():
    found_yet = true;
    # tell hud to show portrait, play fanfare.

#--------------------------------------------------------------------------------------------------
# the first time we're photographed, notify the rest of the game.
func on_photographed():
    photographed_yet = true;
    # tell rest of the game to update trip report

#--------------------------------------------------------------------------------------------------

func _process(delta):
       
    # handle sonar pings
    if (sonar_echo_timer > -1):
        sonar_echo_timer = sonar_echo_timer - 1;
    
    if (sonar_echo_timer == 0):
        # it's sonar time!
        var screen_pos = CAM.unproject_position(self.translation);
        HUD.spawn_sonar_ping_effect(screen_pos, self.dist_in_meters, self.disc_name);
        ping_sound.position = screen_pos;
        ping_sound.play();

    if (can_move):
        move_and_collide(self.velocity); # should we do this here, or should the child scene we load into self.visual do it?
        
    return;
