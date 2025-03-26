# Uffie Puffie Patchy Fixy

This will set up Dark Souls III with both The Convergence and Seamless Co-op mods.

## plswork

Create a directory anywhere. It doesn't have to be in the Dark Souls III game directory. Let's call it the root directory.

Download these and place them there:

1. ModEngine2: [https://github.com/soulsmods/ModEngine2/releases](https://github.com/soulsmods/ModEngine2/releases)
2. Seamless Co-op: [https://www.nexusmods.com/darksouls3/mods/1895?tab=files](https://www.nexusmods.com/darksouls3/mods/1895?tab=files)
3. HoodiePatcher **v1.15.2**: [https://www.nexusmods.com/darksouls3/mods/1933?tab=files](https://www.nexusmods.com/darksouls3/mods/1933?tab=files)
4. The Convergence: [https://www.nexusmods.com/darksouls3/mods/672?tab=files](https://www.nexusmods.com/darksouls3/mods/672?tab=files)

For *The Convergence* I suggest scrolling down on the files tab to `The Convergence 2.2.1` zip link and downloading that instead of the installer up top.

Open said *Convergence* zip and copy/extract `The Convergence` directory from inside it into the root. **Only** that directory, not the DLLs adjacent to it. (If you used the installer instead, you will have to find the directory yourself and copy/move it over.)

The file hierarchy should now look like this:

```
root
└── The Convergence
    └── ...
```

Download a prebuilt `.exe` from under [**Releases**](https://github.com/zorael/plswork/release), or [compile it yourself](#compiling-it-yourself). Place it in the root directory next to the zips.

Double-click it to extract the zips to the appropriate places.

The file hierarchy should now look like this:

```
root
├── modengine2
│   └── ...
├── SeamlessCoop
│   └── ds3sc_settings.ini
├── The Convergence
│   └── ...
├── HoodiePatcher
│   └── HoodiePatcher.dll
├── config_darksouls3.toml
├── launchmod_darksouls3.bat
└── modengine2.exe
```

As a last step, edit `ds3sc_settings.ini` inside the `SeamlessCoop` directory and at minimum set a `cooppassword` down near the end. The program will have set it to `uffie puffie` but you might want something else.

### Windows

Double-click the `launchmod_darksouls3.bat` file.

### Linux

In Steam's desktop client, in the menu bar, go *Games* -> *Add a Non-Steam Game*. Press *Browse* and navigate to your root folder.

As *Filter* (underneath the *Name* entry field), select **All Files**. `launchmod_darksouls3.bat` should now be visible. Select it and press *Open*.

You're returned to the *Add Non-Steam Game* list of applications it knows about. Scroll down and make sure it has `launchmod_darksouls3.bat` in it and that it is checked. Finally click *Add Selected Programs*.

Find `launchmod_darksouls3.bat` in your library. **If it is not visible or there's something there but with an empty name, exit Steam fully and open it again.**

Go into its Properties and set a Proton version in the *Compatibility* section. I've been using `8.0-5`, but the currently-latest `GE-Proton9-25` seems to work well too. Also give it a better name.

**(Steam Deck)** Hop back to game mode.

Start the game through Steam.

### Success? [Y/n]: _

You'll know you did it right if the main menu shows The Convergence art while it also says "Seamless Co-op" in the upper left.

## Downloading `.exe`s from strangers is a bad idea

I have no way to prove that the binary I provide is safe. The source is there if you want to peruse it.

### Compiling it yourself

Clone the repository, then download a [D](https://dlang.org) compiler and run `dub build` in the project directory.

## License

This project is licensed under the **Boost Software License 1.0** - see the [LICENSE_1_0.txt](LICENSE_1_0.txt) file for details.
