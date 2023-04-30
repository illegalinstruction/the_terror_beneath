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
# ALL DISCOVERIES MUST INCLUDE THIS PORTION
extends KinematicBody;

const id = 0;
const portrait_path     : String = "res://entities/comb_jelly/comb_jelly.jpg";
const can_move          : bool = true;
const can_hurt_player   : bool = false;
const can_aggro         : bool = false;

const x_min             : float =  55.0;
const x_max             : float = 480.0;
const y_min             : float = -50.0;
const y_max             : float = -1.0;

#-----------------------------------------------------------------------

var velocity        : Vector3 = Vector3.ZERO;
var accel           : Vector3 = Vector3(0.0125,0,0);

var logic_clock_1_init      : int;
var logic_clock_1           : int;
var logic_clock_2           : int;
var logic_clock_3           : int;
var logic_clock_4           : int;
var logic_clock_5           : int;
var logic_clock_6           : int;
var logic_clock_7_init      : int;
var logic_clock_7           : int;

const max_velocity = 0.0625; # meters per 60th of a second
const accel_amount = 0.0010237;

#-----------------------------------------------------------------------

func _ready():
    logic_clock_1= rand_range(480,720);
    logic_clock_1_init = logic_clock_1;
    logic_clock_7= rand_range(390,820);
    logic_clock_7_init = logic_clock_7;

    self.translation.z = -rand_range(x_min, x_max);
    self.translation.y = rand_range(y_min, y_max);
    self.translation.x = rand_range(1, 30);
    
    accel = Vector3(1,0,0);
    
    var rot_x : float = rand_range(-180,180);
    var rot_z : float = rand_range(-180,180);
    
    accel = accel.rotated(Vector3.RIGHT, deg2rad(rot_x));
    accel = accel.rotated(Vector3.FORWARD, deg2rad(rot_z));
    
    $Armature.rotate_x(rot_x);
    $Armature.rotate_z(rot_z);
    
    $AnimationPlayer.play("ArmatureAction");
    set_process(true);
    add_to_group("DISCOVERIES");
    return;

#-----------------------------------------------------------------------
#I'm thinking comb jelly, regular jelly, whale, wreck of the lincoln, and that's where we stop for June
#-----------------------------------------------------------------------


#-----------------------------------------------------------------------
func advance_logic_clocks() -> void:
    #-------------------------------------------------------------------------------
    logic_clock_1 -= 1;
    
    if (logic_clock_1_init - logic_clock_1 <= 180):
        accel = accel.rotated(Vector3.UP,deg2rad(
                (3.0 - abs(90 - (logic_clock_1_init - logic_clock_1))/30.0 )) *0.66667
        );
        $Armature.rotate_y(deg2rad(
                (3.0 - abs(90 - (logic_clock_1_init - logic_clock_1))/30.0 )) *0.66667
        );

    if (logic_clock_1 <= 180) and (logic_clock_1 > -1) :
        accel = accel.rotated(Vector3.UP,-deg2rad(
                (3.0 - abs(90 - logic_clock_1)/30.0 ) )*0.66667
        );
        $Armature.rotate_y(-deg2rad(
                (3.0 - abs(90 - logic_clock_1)/30.0 ) )*0.66667
        );
    
    if ( logic_clock_1 < -logic_clock_1_init):
        logic_clock_1= rand_range(480,720);
        logic_clock_1_init = logic_clock_1;

    #-------------------------------------------------------------------------------
    logic_clock_2 += 1;
    accel = accel.rotated(Vector3.UP,cos(logic_clock_2/44.0)/105.0);
    $Armature.rotate(Vector3.UP,cos(logic_clock_2/44.0)/105.0);

    #-------------------------------------------------------------------------------
    logic_clock_3 += 1;
    accel = accel.rotated(Vector3.UP,cos(logic_clock_3/51.0)/86.2);
    $Armature.rotate(Vector3.UP,cos(logic_clock_3/51.0)/86.2);

    #-------------------------------------------------------------------------------
    logic_clock_5 += 1;
    accel = accel.rotated(Vector3.RIGHT,cos(logic_clock_4/186.0)/92.7323);
    $Armature.rotate(Vector3.RIGHT,cos(logic_clock_4/186.0)/92.7323);

    #-------------------------------------------------------------------------------
    logic_clock_4 += 1;
    accel = accel.rotated(Vector3.UP,cos(logic_clock_4/316.0)/107.7323);
    $Armature.rotate(Vector3.UP,cos(logic_clock_4/316.0)/107.7323);

    #-------------------------------------------------------------------------------
    logic_clock_6 += 1;
    accel = accel.rotated(Vector3.RIGHT,cos(logic_clock_6/131.29)/166.6667);
    $Armature.rotate(Vector3.RIGHT,cos(logic_clock_6/131.29)/166.6667);
    
    #-------------------------------------------------------------------------------
    logic_clock_7 -= 1;
    
    if (logic_clock_7_init - logic_clock_7 <= 180):
        accel = accel.rotated(Vector3.RIGHT,deg2rad(
                (3.0 - abs(90 - (logic_clock_7_init - logic_clock_7))/30.0 )) *0.66667
        );

    if (logic_clock_7 <= 180) and (logic_clock_7 > -1) :
        accel = accel.rotated(Vector3.RIGHT,-deg2rad(
                (3.0 - abs(90 - logic_clock_7)/30.0 ) )*0.66667
        );
    
    if ( logic_clock_7 < -logic_clock_7_init):
        logic_clock_7= rand_range(390,820);
        logic_clock_7_init = logic_clock_7;
    return;

#-----------------------------------------------------------------------


func _process(elapsed):
    advance_logic_clocks();

    if (velocity.length() < max_velocity):
        velocity += (accel * accel_amount);
        
    move_and_collide(velocity,false);

    if (translation.y > y_max):
        translation.y = y_max;

    if (translation.y < y_min):
        translation.y = y_min;

    if (translation.x < -10.0):
        translation.x = -10.0;

    if (translation.x > 7.0):
        translation.x = 7.0;

    velocity *= 0.9975;
    return;
