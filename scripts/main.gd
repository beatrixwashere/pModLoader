# ------------------ main.gd ------------------
# handles most of the modloader's functionality
# ---------------------------------------------
extends Control
# preload necessary scenes
const modbutton:PackedScene = preload("res://scenes/modbutton.tscn")
var ptdir:String
var cmenu:String
var modselected:String
# startup the modloader
func _ready()->void:
	# load polytrack directory if stored
	if FileAccess.file_exists("user://directory.pmlconfig"):
		var dirfile:FileAccess = FileAccess.open("user://directory.pmlconfig", FileAccess.READ)
		ptdir = dirfile.get_pascal_string()
		# check if directory is valid
		if !DirAccess.dir_exists_absolute(ptdir) || \
		(!FileAccess.file_exists(ptdir + "/PolyTrack.exe") && \
		!FileAccess.file_exists(ptdir + "/PolyTrack")):
			$loader/polydir.visible = true
		$loader/directory.text = ptdir
		if !DirAccess.dir_exists_absolute(ptdir + "/mods"): setup_mod_environment(ptdir)
		reload_mods()
	else: $loader/polydir.visible = true
	cmenu = "loader"
# loads the selected mod and runs polytrack
func run_mod()->void:
	# replace current app.asar with mod's app.asar
	var polydir:DirAccess = DirAccess.open(ptdir)
	if polydir.file_exists("resources/app.asar"):
		polydir.remove("resources/app.asar")
	polydir.copy(ptdir + "/mods/" + modselected + "/app.asar", ptdir + "/resources/app.asar")
	# run polytrack
	if polydir.file_exists("PolyTrack"):
		OS.execute(ptdir + "/PolyTrack", PackedStringArray())
	elif polydir.file_exists("PolyTrack.exe"):
		OS.execute(ptdir + "/PolyTrack.exe", PackedStringArray())
# deletes the selected mod
func delete_mod()->void:
	# remove mod folder
	var moddir:DirAccess = DirAccess.open(ptdir + "/mods/" + modselected)
	for i in moddir.get_files():
		moddir.remove(i)
	DirAccess.remove_absolute(ptdir + "/mods/" + modselected)
	# switch to loader
	reload_mods()
	change_menu("loader")
# reloads the mod list
func reload_mods(searchstr:String = "")->void:
	# delete current list options
	for i in %modlist.get_children():
		if i.name != "_scrollfix": i.free()
	# generate list options
	var modsdir:DirAccess = DirAccess.open(ptdir + "/mods")
	for i in modsdir.get_directories():
		# use for searching mods
		if searchstr in i || searchstr == "": 
			# set info
			var btn:Control = modbutton.instantiate()
			btn.get_node("label").text = i
			btn.get_node("button").connect("button_down", select_mod.bind(i))
			# get mod version if available
			if FileAccess.file_exists(ptdir + "/mods/" + i + "/info.txt"):
				var vrsn:FileAccess = FileAccess.open(ptdir + "/mods/" + i + "/info.txt", FileAccess.READ)
				vrsn.get_line() # skip description
				vrsn.get_line() # skip authors
				btn.get_node("version").text = vrsn.get_line()
			# add to list
			%modlist.add_child(btn)
	# fix scrolling
	%modlist.move_child(%modlist.get_node("_scrollfix"), %modlist.get_child_count() - 1)
# selects a mod and displays it in the modmenu
func select_mod(modname:String)->void:
	# open mod folder
	modselected = modname
	var moddir:DirAccess = DirAccess.open(ptdir + "/mods/" + modselected)
	$modmenu/info/modname/label.text = modselected
	# reset thumbnail and info
	$modmenu/info/thumbnail.texture = null
	$modmenu/info/description/label.text = "{description}"
	$modmenu/info/authors/label.text = "{authors}"
	$modmenu/info/modversion/label.text = "{mod version}"
	# load thumbnail
	if moddir.file_exists("thumbnail.png"):
		# set sprite texture
		var thumb:ImageTexture = ImageTexture.create_from_image(Image.load_from_file(ptdir + "/mods/" + modselected + "/thumbnail.png"))
		$modmenu/info/thumbnail.texture = thumb
		# adjust scale
		var idealscale:Vector2 = Vector2(1024, 512)
		var scalefactor:float
		if 1.0 * thumb.get_width() / thumb.get_height() > 2:
			scalefactor = idealscale.x / thumb.get_width()
		else:
			scalefactor = idealscale.y / thumb.get_height()
		$modmenu/info/thumbnail.scale = Vector2(scalefactor, scalefactor)
	else:
		push_error("thumbnail.png doesn't exist in mod folder")
	# load info
	if moddir.file_exists("info.txt"):
		# read from info
		var infofile:FileAccess = FileAccess.open(ptdir + "/mods/" + modselected + "/info.txt", FileAccess.READ)
		var description:String = infofile.get_line()
		var authors:String = infofile.get_line()
		var modversion:String = infofile.get_line()
		# apply to info labels
		$modmenu/info/description/label.text = description
		$modmenu/info/authors/label.text = authors
		$modmenu/info/modversion/label.text = modversion
	else:
		push_error("info.txt doesn't exist in mod folder")
	# tweak some stuff if vanilla is selected
	if modselected == "PolyTrack":
		$modmenu/play.text = "play polytrack"
		$modmenu/delete.visible = false
	else:
		$modmenu/play.text = "play mod"
		$modmenu/delete.visible = true
	# switch to modmenu
	change_menu("modmenu")
# changes the currently displayed menu
func change_menu(newmenu:String)->void:
	# prepare for tween
	var prevmenu:Control = get_node(cmenu)
	var nextmenu:Control = get_node(newmenu)
	nextmenu.position.x = 1920
	nextmenu.visible = true
	cmenu = newmenu
	# tween into place
	var tween0:Tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	var tween1:Tween = create_tween().set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_IN_OUT)
	tween0.tween_property(prevmenu, "position", Vector2(-1920,0), 1)
	tween1.tween_property(nextmenu, "position", Vector2(0,0), 1)
	await tween0.finished
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
	for i in reader.get_files():
		filebuffer = reader.read_file(i)
		var file:FileAccess = FileAccess.open(ptdir + "/mods/" + modname + "/" + i, FileAccess.WRITE)
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
		$loader/directory.text = "the directory selected doesn't contain a polytrack executable."
		return
	# generate mods folder if necessary
	if !polydir.dir_exists("mods"):
		$loader/setup.visible = true
		$loader/setup/loading.rotation = 0
		var tween0:Tween = create_tween()
		tween0.tween_property($loader/setup/loading, "rotation", -180, 60)
		polydir.make_dir("mods")
		# install vanilla from repo
		var http:HTTPRequest = HTTPRequest.new()
		add_child(http)
		var reqcompleted:Callable = func _request_completed(result:int, _response_code:int, _headers:PackedStringArray, _body:PackedByteArray):
			if result != OK:
				push_error("download failed")
			remove_child(http)
			if polydir.file_exists("mods/PolyTrack.zip"):
				unpack_zip("PolyTrack")
			else:
				push_error("zip not found")
			reload_mods()
			$loader/setup.visible = false
		http.connect("request_completed", reqcompleted)
		http.set_download_file(ptdir + "/mods/PolyTrack.zip")
		var request:Error = http.request("https://raw.githubusercontent.com/beatrixwashere/pModLoader/main/PolyTrack.zip")
		if request != OK:
			push_error("http request failed")
			$loader/setup.visible = false
	reload_mods()
	# set directory display
	$loader/directory.text = dir
	# save directory path
	var dirfile:FileAccess = FileAccess.open("user://directory.pmlconfig", FileAccess.WRITE)
	dirfile.store_pascal_string(ptdir)
