# 
#  _the terror_               
# | |        | |              
# | |__   ___| | _____      __
# | '_ \ / _ \ |/ _ \ \ /\ / /
# | |_) |  __/ | (_) \ V  V / 
# |_.__/ \___|_|\___/ \_/\_/ 
#
# Copyright 202, 2023 Oregon Institute of Technology
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
# This file implements a singleton discovery list which is used both by
# gameplay and the "Discoveries" .tscn from the main menu.
#

extends Node2D;

# the actual list (of dictionaries, containing all the stuff in the json)
# should be treated as module-private
var priv_disc_list = [];

#-----------------------------------------------------------------------
var length : int = 0 setget, get_length;

#-----------------------------------------------------------------------
func get_length():
    return priv_disc_list.length;

#-----------------------------------------------------------------------
# returns a Discovery object if the entry exists, or null if not
func get_entry(index : int):
    
    if (index < 0):
        print_debug("called w/ negative index!");
        print_stack();
        return null;

    if (index >= priv_disc_list.length):
        print_debug("discovery index out of range!");
        print_stack();
        return null;
        
    return priv_disc_list[index];
    
    
#-----------------------------------------------------------------------
# shamelessly stolen from 
# https://godotengine.org/qa/5175/how-to-get-all-the-files-inside-a-folder  
func get_dir_contents(rootPath: String) -> Array:
    var files = []
    var directories = []
    var dir = Directory.new()

    if dir.open(rootPath) == OK:
        dir.list_dir_begin(true, false)
        _add_dir_contents(dir, files, directories)
    else:
        push_error("An error occurred when trying to access the path.")

    return [files, directories]
    
#-----------------------------------------------------------------------
func populate_list():
    var file_list = get_dir_contents("res://entities/json");
    
    for filename in file_list[0]:
        print_debug(filename);
        if (filename.ends_with(".json"):
            var tmp = Discovery.new();
            tmp.init_from_json(filename, null, null);
            

    
    
