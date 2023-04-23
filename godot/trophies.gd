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

extends Node2D

#-------------------------------------------------------------------------------
# sound effects
var snd_move   : AudioStreamSample;
var snd_choice : AudioStreamSample;
var snd_cancel : AudioStreamSample;

# what menu item is the user hovering right now?
var cursor_index : int = 0;

# are we viewing a discovery's details right now?
var drill_down : bool  = false;

# track/control the drill-down widget transitioning in and out
var drill_down_anim_clock : int = 0;
var drill_down_anim_direction : bool = true; # true for in. false for out
var drill_down_anim_active : bool;

const DRILL_DOWN_ANIM_CLOCK_MAX : int = 50;

#-------------------------------------------------------------------------------
func _ready():
    # --- transition in smoothly
    var screenwipe = load("res://helper_screenwipe.tscn");
    add_child(screenwipe.instance());
    Global.new_scene_screenwipe_start();
    Global.load_options_data();

    # --- load sounds
    snd_choice  = load("res://mainmenu/cursor_select.wav");
    snd_move    = load("res://mainmenu/cursor_move.wav");
    snd_cancel  = load("res://mainmenu/cursor_cancel.wav");
    $sfx_player.volume_db = Global.get_sfx_vol_in_db();
    

    # TODO: discovery list population, but we
    # probably shouldn't do it ourselves, but 
    # instead have some kind of reusable discovery
    # manager or component or something  

    # --- reset everything to a sensible/known state
    cursor_index = 0;
    drill_down = false;
    drill_down_anim_clock = 0;
    drill_down_anim_direction = true;
    $drill_down_root.hide();

    set_process(true);

    return;

#-------------------------------------------------------------------------------
func drilldown_start_animate_in():
    if ((drill_down_anim_active == true) and (drill_down_anim_direction == true)):
        return;
    
    drill_down = true;
    drill_down_anim_active = true;
    drill_down_anim_direction = true;
    $drill_down_root.show();
    
    return;

#-------------------------------------------------------------------------------
func drilldown_start_animate_out():
    if ((drill_down_anim_active == true) and (drill_down_anim_direction == false)):
        return;
    
    drill_down_anim_active = true;
    drill_down_anim_direction = false;

    return;

#-------------------------------------------------------------------------------
func drilldown_do_anim_tick():
    if not (drill_down_anim_active):
        return;
    
    if (drill_down_anim_direction):
        drill_down_anim_clock += 1;
        #$drill_down_root.show();
        if (drill_down_anim_clock >= DRILL_DOWN_ANIM_CLOCK_MAX):
            drill_down_anim_active = false;
    else:
        drill_down_anim_clock -= 1;
        if (drill_down_anim_clock <= 0):
            drill_down_anim_active = false;
            $drill_down_root.hide();
            drill_down = false;
    
    return;
    
#-------------------------------------------------------------------------------
func _process(_ignored):
    
    # --- INPUT ---------------------------------------------------------------
    # handle xbox (back) and [esc]
    if (Global._menu_cancel == 1):
        $sfx_player.stop();
        $sfx_player.stream = snd_cancel;
        $sfx_player.play();        
        if (drill_down):
            drill_down = false;
            drilldown_start_animate_out();
        else:
            Global.change_scene_to(load("res://main_menu.tscn"));
            
    if (Global._menu_accept == 1):

        if (drill_down):
            $drill_down_root/flavour_text_root.next_page();
            if not ($drill_down_root/flavour_text_root.at_end_of_text):
                $sfx_player.stop();
                $sfx_player.stream = snd_choice;
                $sfx_player.play();
        else:
            $sfx_player.stop();
            $sfx_player.stream = snd_choice;
            $sfx_player.play();
            drill_down = true;
            print_debug("drill down into discovery #" + str(cursor_index));
            drilldown_start_animate_in();
            $CalloutNext.show();
            $drill_down_root/flavour_text_root.reset();
            
    if (Global._menu_down == 1):
        if not (drill_down):
            cursor_index += 1;
            $sfx_player.stop();
            $sfx_player.stream = snd_move;
            $sfx_player.play();
            
    if (Global._menu_up == 1):
        if not (drill_down):
            cursor_index -= 1;
            $sfx_player.stop();
            $sfx_player.stream = snd_move;
            $sfx_player.play();

    # --- DRILL DOWN ANIM ------------------------------------------------------
    drilldown_do_anim_tick();
    
    # fade in discovery model & flavour text.
    $drill_down_root.modulate = Color(1.0, 1.0, 1.0, (drill_down_anim_clock/float(DRILL_DOWN_ANIM_CLOCK_MAX - 1)));
    
    # crossfade button callouts
    $CalloutExitDrilldown.modulate = Color(1.0, 1.0, 1.0, (drill_down_anim_clock/float(DRILL_DOWN_ANIM_CLOCK_MAX - 1)));
    $CalloutNext.modulate = Color(1.0, 1.0, 1.0, (drill_down_anim_clock/float(DRILL_DOWN_ANIM_CLOCK_MAX - 1)));

    if ($drill_down_root/flavour_text_root.at_end_of_text):
        $CalloutNext.hide();

    $CalloutEnterDrilldown.modulate = Color(1.0, 1.0, 1.0, ((DRILL_DOWN_ANIM_CLOCK_MAX - drill_down_anim_clock)/float(DRILL_DOWN_ANIM_CLOCK_MAX - 1)));
    $CalloutMainmenu.modulate = Color(1.0, 1.0, 1.0, ((DRILL_DOWN_ANIM_CLOCK_MAX - drill_down_anim_clock)/float(DRILL_DOWN_ANIM_CLOCK_MAX - 1)));
    
    $Label.text = "State: anim clock = " + str(drill_down_anim_clock) + " drill down shown? " + str($drill_down_root.visible);
