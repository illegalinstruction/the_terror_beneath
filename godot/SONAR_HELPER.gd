# 
#  _the terror_               
# | |        | |              
# | |__   ___| | _____      __
# | '_ \ / _ \ |/ _ \ \ /\ / /
# | |_) |  __/ | (_) \ V  V / 
# |_.__/ \___|_|\___/ \_/\_/ 
#
# Copyright 2022, 2023 Oregon Institute of Technology
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
#-----------------------------------------------------------------------

extends Spatial;
class_name SONAR_HELPER

var sonar_echo_timer : int = -1;
var should_show_arrow: bool = false;
var dist_in_meters   : float = 0.0;
var ping_sound       : AudioStreamPlayer2D;
var priv_cam         : Camera;
var hud              : Node2D;
var disc_name        : String = "";

#---------------------------------------------------------------------------
# default constructor  
func _init():
    return;
    
#---------------------------------------------------------------------------
func _ready():
    set_process(true);
    ping_sound = AudioStreamPlayer2D.new();
    ping_sound.stream = Global.sonar_bounce;
    ping_sound.volume_db = Global.get_sfx_vol_in_db();
    add_child(ping_sound);
    return;
    
#---------------------------------------------------------------------------
# check if we're close enough to the player for the echo to hit us.
# if yes, set a counter, wait _n_ frames, then tell the hud to draw
# a sonar echo emanating from our location, plus our name if that's
# appropriate.
func on_sonar(name : String, player_pos : Vector3, cam : Camera):
    # reset this flag to its default
    self.should_show_arrow = false;
    disc_name = name;

    self.dist_in_meters = sqrt(pow(self.translation.z - player_pos.z,2) + pow(self.translation.y - player_pos.y,2));
    var my_2D_pos = cam.unproject_position(self.translation);
    var sub_2D_pos = cam.unproject_position(player_pos);
    
    var pythag_distance : float = sqrt(pow(my_2D_pos.x - sub_2D_pos.x,2) + pow(my_2D_pos.y - sub_2D_pos.y,2));
    if (pythag_distance > Global.MAX_SONAR_PING_DISTANCE):
        # out of range - do nothing.
        sonar_echo_timer = -1;
        var parent = get_parent();
        if (parent != null):
            parent.remove_child(self);
            self.queue_free();
        return;
    else:
        # start a countdown to simulate the delay between the sound leaving
        # the sub and the sound hitting us
        sonar_echo_timer = (pythag_distance / Global.SONAR_WAVE_SPEED);
        
    # keep a reference to cam for later
    self.priv_cam = cam;
    return;

#--------------------------------------------------------------------------------------------------
func _process(delta):
    # handle sonar pings
    # sound wave still en route?
    if (sonar_echo_timer > -1):
        sonar_echo_timer = sonar_echo_timer - 1;
    
    # sound wave just reached us - play the echo effect
    if (sonar_echo_timer == 0):
        # it's sonar time!
        var screen_pos = priv_cam.unproject_position(self.translation);
        get_tree().get_current_scene().spawn_sonar_ping_effect(screen_pos, self.dist_in_meters, self.disc_name);
        ping_sound.position = screen_pos;
        ping_sound.play();
    
    # echo effect done playing - destroy ourselves
    if (sonar_echo_timer < 0) and (not ping_sound.playing):
        remove_child(ping_sound);
        ping_sound.queue_free();
        get_parent().remove_child(self);
        queue_free();

    return;
#---------------------------------------------------------------------------

