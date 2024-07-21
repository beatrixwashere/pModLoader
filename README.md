# <img src="https://raw.githubusercontent.com/beatrixwashere/pModLoader/main/images/pmodloader.png" width="24"/> pModLoader

---

## about

pModLoader is a lightweight mod loader for PolyTrack that lets you play and download mods in just a couple clicks.

downloading mods isn't available yet since the PolyTrack hasn't been accepted onto gamebanana yet, but i'll be working on the functionality soon.

---

## download

this tool is available on [itch.io](https://beatrixwashere.itch.io/pmodloader). once you download it, all you have to do is unzip and run it!

## setup

you'll need to download and unzip the standalone version of the game from [itch.io](https://kodub.itch.io/polytrack) in order to use this mod loader. once you have, open the tool, select the folder you have polytrack in at the bottom of the screen, and you should be good to go! this will create a mods folder that the tool uses to store and load mods.

since downloading mods isn't automated yet, the process is:
1) download a mod from wherever you can find it
2) copy the folder into the mods folder

---

## creating mods

this process will be automated once gamebanana is up and running, but if you make a mod, share it as a folder with the following files:
- `app.asar`
- `info.txt`
- `thumbnail.png`

the format for `info.txt` looks like this:
```
description
authors
mod version
```

`app.asar` is required for the mod to work, but the other two files are optional and used to display extra info about the mod inside the tool.

---

## suggestions

if you would like to make a suggestion, please open an issue in this repository.

---

## contributing

in order to contribute to this project, please follow this guide:
1) [download godot 4.2.2](https://godotengine.org/download/)
2) fork this repository
3) download the repo zip, and open the project in godot
4) edit the project
5) push your changes to your fork
6) create a pull request

---

## credits

- beatrixwashere, for creating this project and the entire tool so far
- the entire polytrack modding community for making this possible
- kodub for making the original game
