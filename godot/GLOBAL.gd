# 
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
# This file based upon pre-existing work by C. Rogers.                                              
#                                              


extends Node2D

const DEBUG_MODE : bool = true;
const ANALOGUE_DEAD_ZONE : float = 0.25;

#---- MAIN MENU and DATA VARS --------------------------------------------------
const game_data_base : String = "user://below_data";
const options_path 		= game_data_base + "-options";
const achievements_path = game_data_base + "-trophies";

const GAME_SUPPORTS_SAVING 			: bool = true;
const GAME_SUPPORTS_HIGH_SCORES		: bool = false;
const GAME_SUPPORTS_TROPHIES			: bool = true;

var sfx_vol 		: int 	= 255;
var music_vol 		: int 	= 255;

#-------------------------------------------------------------------------------

func save_options_data():
	var fout : File = File.new();

	fout.open(options_path, fout.WRITE);
	sfx_vol = int(clamp(sfx_vol,0, 255));
	fout.store_8(sfx_vol);
	music_vol = int(clamp(music_vol, 0, 255));
	fout.store_8(music_vol);
	fout.store_8(use_joystick);
	fout.close();
	
	return;
	
#-------------------------------------------------------------------------------

func load_options_data():
	var fin : File = File.new();
		
	if (fin.file_exists(options_path)):
		fin.open(options_path, fin.READ);
		sfx_vol = fin.get_8();
		music_vol = fin.get_8();
		use_joystick = fin.get_8();
		fin.close();
	else:
		save_options_data();
	return;

#---- POTATO PERFORMANCE VARS  -------------------------------------------------
var resolution_scale 		:	float 	= 1.0; 		# between .5 and 1
var shadow_atlas_size 		:	int 	= 10;  		# between 1 & 10, gets multiplied by 256
var nearest_or_trilinear	:	bool	= false;	# true to reduce texture filter quality

#---- SCREEN TRANSITION VARS  --------------------------------------------------
# these are here as a workaround for gdscript not having static vars

const SCREENWIPE_MAX_TICKS	: int = 85;

var screenwipe_anim_clock	: int;
var screenwipe_direction	: bool; # true for out, false for in
var screenwipe_active		: bool;
var screenwipe_next_scene;

#---- JOYSTICK VARS ------------------------------------------------------------

var is_joystick_connected : bool = false;
var use_joystick : bool = true;

enum BUTTON_STATE {
	IDLE,
	PRESSED,
	HELD
};

var _left_stick_angle 		: float;
var _left_stick_distance 	: float;
var _left_stick_x			: float;
var _left_stick_y			: float;
var _right_stick_x 			: float;
var _right_stick_y 			: float;

var _menu_up : int = BUTTON_STATE.IDLE;
var _menu_down : int = BUTTON_STATE.IDLE;
var _menu_accept : int = BUTTON_STATE.IDLE;


var _button_start : int = BUTTON_STATE.IDLE;
var _button_select : int = BUTTON_STATE.IDLE;
var _button_a : int = BUTTON_STATE.IDLE;
var _button_b : int = BUTTON_STATE.IDLE;
var _button_x : int = BUTTON_STATE.IDLE;
var _button_y : int = BUTTON_STATE.IDLE;
var _button_L2 : int = BUTTON_STATE.IDLE;
var _button_R2 : int = BUTTON_STATE.IDLE;

#-----------------------------------------------------------------------

func handle_joystick_connect():
	if (Input.get_connected_joypads().size() < 1):
	  is_joystick_connected = false;
	else:
	  is_joystick_connected = true;
	pass;

#-----------------------------------------------------------------------

func poll_joystick():
	if (screenwipe_active):
		_button_start  = BUTTON_STATE.IDLE;
		_button_select = BUTTON_STATE.IDLE;
		_button_a  = BUTTON_STATE.IDLE;
		_button_b  = BUTTON_STATE.IDLE;
		_button_x  = BUTTON_STATE.IDLE;
		_button_y  = BUTTON_STATE.IDLE;		
		_menu_up  = BUTTON_STATE.IDLE;
		_menu_down  = BUTTON_STATE.IDLE;
		_menu_accept = BUTTON_STATE.IDLE;
		return;
	
	if (use_joystick):
	  
		#--- ANALOGUE STICKS --------------------------
		var left_tmp : Vector2 = Vector2(Input.get_joy_axis(0,JOY_ANALOG_LX), Input.get_joy_axis(0,JOY_ANALOG_LY));
		
		_left_stick_x = left_tmp.x;
		_left_stick_y = left_tmp.y;
		
		_left_stick_distance = left_tmp.length();
		_left_stick_angle = left_tmp.angle();
		
		# not used in this game
		#_right_stick_x = Input.get_joy_axis(0,JOY_ANALOG_RX);
		#_right_stick_y = Input.get_joy_axis(0,JOY_ANALOG_RY);
		
		#--- ugly hack for navigating menus ----------
	  
		if ((left_tmp.y < -0.7) or (Input.is_joy_button_pressed(0, JOY_DPAD_UP)) or (Input.is_key_pressed(KEY_UP))):
			_menu_up = _menu_up + 1;
		else:
			_menu_up = BUTTON_STATE.IDLE;
		
		if ((left_tmp.y > 0.7) or (Input.is_joy_button_pressed(0, JOY_DPAD_DOWN)) or (Input.is_key_pressed(KEY_DOWN))):
			_menu_down = _menu_down + 1;
		else:
			_menu_down = BUTTON_STATE.IDLE;
	  
		if (Input.is_joy_button_pressed(0, JOY_XBOX_A) or (Input.is_joy_button_pressed(0, JOY_START)) or (Input.is_key_pressed(KEY_SPACE)) or (Input.is_key_pressed(KEY_ENTER))):
			_menu_accept = _menu_accept + 1;
			_menu_accept = int(clamp(_menu_accept,0,2.0));
		else:
			_menu_accept = BUTTON_STATE.IDLE;

	
		#--- BUTTONS ----------------------------------
		#----------
		
		if (Input.is_joy_button_pressed(0, JOY_XBOX_A)):
			_button_a = _button_a + 1;
			_button_a = int(clamp(_button_a,0,2.0));
		else:
			_button_a = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_joy_button_pressed(0, JOY_XBOX_B)):
			_button_b = _button_b + 1;
			_button_b = int(clamp(_button_b,0,2.0));
		else:
			_button_b = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_joy_button_pressed(0, JOY_XBOX_X)):
			_button_x = _button_x + 1;
			_button_x = int(clamp(_button_x,0,2.0));
		else:
			_button_x = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_joy_button_pressed(0, JOY_XBOX_Y)):
			_button_y = _button_y + 1;
			_button_y = int(clamp(_button_y,0,2.0));
		else:
			_button_y = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_joy_button_pressed(0, JOY_L2)):
			_button_L2 += 1;
			_button_L2 = int(clamp(_button_L2,0,2));
		else:
			_button_L2 = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_joy_button_pressed(0, JOY_R2)):
			_button_R2 += 1;
			_button_R2 = int(clamp(_button_R2,0,2));
		else:
			_button_R2 = BUTTON_STATE.IDLE;
		
		#----------

		if (Input.is_joy_button_pressed(0, JOY_START)):
			_button_start += 1;
			_button_start = int(clamp(_button_start,0,2));
		else:
			_button_start = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_joy_button_pressed(0, JOY_SELECT)):
			_button_start += 1;
			_button_start = int(clamp(_button_select,0,2));
		else:
			_button_start = BUTTON_STATE.IDLE;
		

		return;
	else: # keyboard;
		#--- ANALOGUE STICKS --------------------------
		var left_tmp : Vector2;
		
		# todo: make these remappable after 1.0
		if ((Input.is_key_pressed(KEY_A)) or (Input.is_key_pressed(KEY_LEFT))):
			left_tmp.x = -1.0;
		if ((Input.is_key_pressed(KEY_D)) or (Input.is_key_pressed(KEY_RIGHT))):
			left_tmp.x = 1.0;
		if ((Input.is_key_pressed(KEY_W)) or (Input.is_key_pressed(KEY_UP))):
			left_tmp.y = -1.0;
		if ((Input.is_key_pressed(KEY_S)) or (Input.is_key_pressed(KEY_DOWN))):
			left_tmp.y = 1.0;
		
		_left_stick_x = left_tmp.x;
		_left_stick_y = left_tmp.y;
		
		_left_stick_distance = left_tmp.normalized().length();
		_left_stick_angle = left_tmp.angle();
		
				#--- BUTTONS ----------------------------------
		#----------
		
		if (Input.is_key_pressed(KEY_H)):
			_button_a = _button_a + 1;
			_button_a = int(clamp(_button_a,0,2.0));
		else:
			_button_a = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_key_pressed(KEY_J)):
			_button_b = _button_b + 1;
			_button_b = int(clamp(_button_b,0,2.0));
		else:
			_button_b = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_key_pressed(KEY_K)):
			_button_x = _button_x + 1;
			_button_x = int(clamp(_button_x,0,2.0));
		else:
			_button_x = BUTTON_STATE.IDLE;
		
		#----------
		
		if (Input.is_key_pressed(KEY_L)):
			_button_y = _button_y + 1;
			_button_y = int(clamp(_button_y,0,2.0));
		else:
			_button_y = BUTTON_STATE.IDLE;
		
		#----------
		
		# not used in this game
		#_right_stick_x = Input.get_joy_axis(0,JOY_ANALOG_RX);
		#_right_stick_y = Input.get_joy_axis(0,JOY_ANALOG_RY);
	return;
		

#==============================================================================
# UI FONT
#==============================================================================
var ui_font : DynamicFont = null;

func ui_font_window_resize_handler():
	ui_font.size = int(OS.window_size.y / 24.0);
	if (ui_font.size < 8):
		ui_font.size = 8;		
	return;

#-------------------------------------------------------------------------------

func _ready():
	
	# ready screen transition mechanism
	# for use
	screenwipe_direction 	= true;
	screenwipe_anim_clock	= 0;
	
	# automagically adjust font to match screen size.
	# this makes it a little big at high resolutions,
	# but easily readable on a handheld or a tv across the room...	
	ui_font = DynamicFont.new();
	ui_font.font_data = preload("res://font/uifont.ttf");
	ui_font.outline_color = Color.black;
	ui_font.outline_size = 1;
	stream_player   = AudioStreamPlayer.new();
	
	var _ignored = get_tree().get_root().connect("size_changed", self, "ui_font_window_resize_handler");
	ui_font_window_resize_handler();
	
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN);
	
	set_process(true);
	return;

#-------------------------------------------------------------------------------

func _process(_ignored):
	# --- gather input
	poll_joystick();
	
	# --- manage screenwipe if needed
	if (screenwipe_active):
		if (screenwipe_direction):
			screenwipe_anim_clock += 1;
	
			if (screenwipe_anim_clock >= SCREENWIPE_MAX_TICKS):
				screenwipe_active = false;
				screenwipe_direction = false;
				if (screenwipe_next_scene == null):
					get_tree().quit();
				else:
					var _unused = get_tree().change_scene_to(screenwipe_next_scene);
		else:
			screenwipe_anim_clock -= 1;
	
			if (screenwipe_anim_clock < 1):
				screenwipe_active = false;
	
	# hotkey to get out 
	if (DEBUG_MODE):
		if (Input.is_key_pressed(KEY_ESCAPE) and Input.is_key_pressed(KEY_Q)):
			get_tree().quit();
	return;

#-------------------------------------------------------------------------------

func change_scene_to(in_scene):
	if (screenwipe_active):
		return;

	screenwipe_direction 	= true;
	screenwipe_active		= true;
	screenwipe_next_scene	= in_scene;
	screenwipe_anim_clock	= 0;
	
#-------------------------------------------------------------------------------

func new_scene_screenwipe_start():
	if (screenwipe_active):
		return;

	screenwipe_active		= true;
	screenwipe_direction 	= false;
	screenwipe_anim_clock	= SCREENWIPE_MAX_TICKS;
	
#==============================================================================
# BACKGROUND MUSIC MANAGEMENT
#==============================================================================

# Background Music Management Variables
const BGM_FADE_PER_TICK = 0.01;

var curr_bgm        = 0;     # start with nothing playing
var next_bgm        = 0;
var user_bgm_vol    = 1.0;   # this is the music volume the user sets in the menu
var bgm_vol         = 1.0;   # this is the actual music volume; we start at user_bgm_vol, then subtract a little until hitting 0.0
var bgm_fade_done   = true;  # checks whether we're still fading

# the fount from which all music floweth forth...
var stream_player   = AudioStreamPlayer.new(); 

##############################################################################
# bgm_switch_helper_priv()
#   a helper method that factors out the starting of a new song (and reduces
#   duplicated code).  Not intended to be called from child nodes...
#
func bgm_switch_helper_priv():
	if (not stream_player.is_inside_tree()):
		add_child(stream_player);

	var tmp = load("res://bgm/%03d.ogg" % curr_bgm);
   
	if (tmp != null):
		stream_player.volume_db = user_bgm_vol;
		stream_player.set_stream(tmp);
		stream_player.play();
	
	return;

##############################################################################
# set_bgm(song_index, should_fade = false)
#   tries to load new background music, starting it straightaway if none is
#   already playing, or, if there _is_ music playing, giving the option to 
#   fade out whatever's playing.  this only -sets- what plays - the actual  
#   fade out logic happens elsewhere.
#
#   by convention, song_index should be an integer; this corresponds to file
#   names in res://bgm/, which, again, by convention, will be a three-digit
#   number, followed by the extension '.ogg'
#
func set_bgm(song_index, should_fade = true):
	if (song_index == curr_bgm):
		return; # it's already playing, nothing to do here
	
	if ((should_fade) and (self.curr_bgm != 0)):
		# we need to fade out, so the music change is deferred
		# the actual fade logic is handled elsewhere in a func
		# called from process()
		next_bgm = song_index;
		bgm_fade_done = false;
		bgm_vol = user_bgm_vol;
	else:
		# no fade needed - stop old music immediately.
		self.curr_bgm = song_index;
		self.next_bgm = song_index;
		bgm_fade_done = true;
		stream_player.stop();
		print("here 2");
	
	# are we asked to go silent?
	if (song_index == 0):
		# yep, we're done here
		return;
		
	# if we got down here, we need to start the req'd song
	bgm_switch_helper_priv();
	return;

##############################################################################
# handle_bgm_fading()
#   if there's an active music fadeout going, handle it here by reducing the
#   bgm volume slightly until it reaches 0, then, switch BGM at that time.
#   needs to be called from process() and run each 'tick' - returns 
#   immediately if it has nothing to do.
#
func handle_bgm_fading():
	if (bgm_fade_done):
		return;
	
	# is there NO music playing at the moment? 
	if (curr_bgm == 0):
		# start the next song straightaway
		bgm_fade_done = true;
		curr_bgm = next_bgm;
		
		# is the next song _also_ silence?
		if (next_bgm == 0):
			# nothing else to do here
			return;
	
		bgm_switch_helper_priv();

	else:
		# no, there's active music still.
		# done fading yet?
		if (bgm_vol > 0.0):
			# no - subtract a 'smidgen' from current volume
			bgm_vol = stream_player.get_volume() - BGM_FADE_PER_TICK;
			stream_player.set_volume(bgm_vol);
			return;
		else:
			# yes - start next track
			curr_bgm = next_bgm;
			bgm_fade_done = true;

		if (next_bgm == 0):
			stream_player.stop();
			return;

		bgm_switch_helper_priv();
	return;
