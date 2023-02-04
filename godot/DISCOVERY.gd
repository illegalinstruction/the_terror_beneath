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

var collision_shape  : CollisionShape = null; 
var velocity         : Vector3 = Vector3.ZERO;

#--------------------------------------------------------------------------------------------------

func _ready():
    return;

#--------------------------------------------------------------------------------------------------
func init_from_json(filename : String):
    var f_in = File.new();
    f_in.open(filename);
    var dict = parse_json(f_in.get_as_text());
    
    # checks to make sure the discovery description file isn't malformed
    # if we're missing a vital field, we throw a tantrum and soft-crash.
    assert("visual" in dict);              #asset path, relative to "res://"
    assert("disc_name" in dict);           #string 
    assert("flavour_text" in dict);        #string
    assert("portrait" in dict);            #asset path, relative to "res://"
    
    self.visual        = load(dict.get("visual")).instance;
    self.portrait      = load(dict.get("portrait")) as Texture;
    self.disc_name     = dict.get("disc_name") as String;
    self.flavour_text  = dict.get("disc_name") as String;
    
    add_child(self.visual);
    $visual.anim_player.play();
    
    f_in.close();


#--------------------------------------------------------------------------------------------------
# check if we're close enough to the player for the echo to hit us.
# if yes, set a counter, wait _n_ frames, then tell the hud to draw
# a sonar echo emanating from our location, plus our name if that's
# appropriate.

func on_sonar(player_pos : Vector3):
    var pythag_distance : float = sqrt(pow(self.translation.x - player_pos.x,2) + pow(self.translation.y - player_pos.y,2));
    if (pythag_distance > Global.MAX_SONAR_PING_DISTANCE):
        # out of range
        sonar_echo_timer = -1;
        return;
    else:
        sonar_echo_timer = pythag_distance / Global.SONAR_WAVE_SPEED;
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
        # HUD.spawn_sonar_ping_effect(translation.x, translation.y);
        var tmp = 0;
    
    if (can_move):
        move_and_collide(self.velocity);
    
    
    return;
