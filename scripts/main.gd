# ------------------ main.gd ------------------
# handles most of the modloader's functionality
# ---------------------------------------------
extends Control
# preload necessary scenes
const modbutton:PackedScene = preload("res://scenes/modbutton.tscn")
var ptdir:String
# startup the modloader
func _ready()->void:
	if FileAccess.file_exists("user://directory.pmlconfig"):
		var dirfile:FileAccess = FileAccess.open("user://directory.pmlconfig", FileAccess.READ)
		ptdir = dirfile.get_pascal_string()
		$directory.text = ptdir
	reload_mods()
# loads a mod and runs polytrack
func run_mod(modname:String)->void:
	# replace current app.asar with mod's app.asar
	var polydir:DirAccess = DirAccess.open(ptdir)
	if polydir.file_exists("resources/app.asar"):
		polydir.remove("resources/app.asar")
	polydir.copy(ptdir + "/mods/" + modname + "/app.asar", ptdir + "/resources/app.asar")
	# run polytrack
	if polydir.file_exists("PolyTrack"):
		OS.execute(ptdir + "/PolyTrack", PackedStringArray())
	elif polydir.file_exists("PolyTrack.exe"):
		OS.execute(ptdir + "/PolyTrack.exe", PackedStringArray())
# reloads the mod list
func reload_mods()->void:
	# generate list options
	var modsdir:DirAccess = DirAccess.open(ptdir + "/mods")
	for i in modsdir.get_directories():
		var btn:Control = modbutton.instantiate()
		btn.get_node("label").text = i
		btn.get_node("button").connect("button_down", run_mod.bind(i))
		%modlist.add_child(btn)
	# fix scrolling
	%modlist.move_child(%modlist.get_node("_scrollfix"), %modlist.get_child_count() - 1)
# unpacks a zip file containing a mod
func unpack_zip(modname:String)->void:
	# open zip file in reader
	var reader:ZIPReader = ZIPReader.new()
	var err:Error = reader.open(ptdir + "/mods/" + modname + ".zip")
	var filebuffer:PackedByteArray = PackedByteArray()
	# check if zip file didn't open
	if err != OK:
		push_error("failed to open zip file")
		return
	# copy zip contents
	DirAccess.make_dir_absolute(ptdir + "/mods/" + modname)
	filebuffer = reader.read_file("app.asar")
	var file:FileAccess = FileAccess.open(ptdir + "/mods/" + modname + "/app.asar", FileAccess.WRITE)
	if !file:
		push_error("failed to open new file")
		return
	file.store_buffer(filebuffer)
	reader.close()
	# delete the zip file
	DirAccess.remove_absolute(ptdir + "/mods/" + modname + ".zip")
# sets up the polytrack mods folder
func setup_mod_environment(dir:String)->void:
	# set polytrack directory
	ptdir = dir
	# check if mods folder exists
	var polydir:DirAccess = DirAccess.open(ptdir)
	if !polydir.file_exists("PolyTrack") && !polydir.file_exists("PolyTrack.exe"):
		$directory.text = "the directory selected doesn't contain a polytrack executable."
		return
	# generate mods folder if necessary
	if !polydir.dir_exists("mods"):
		polydir.make_dir("mods")
		polydir.make_dir("mods/PolyTrack")
		# TODO: install vanilla here
	# set directory display
	$directory.text = dir
	# save directory path
	var dirfile:FileAccess = FileAccess.open("user://directory.pmlconfig", FileAccess.WRITE)
	dirfile.store_pascal_string(ptdir)
