# Uffie Puffie Patchy Fixy

This will set up **Dark Souls III** with both [**The Convergence**](https://www.nexusmods.com/darksouls3/mods/672) and [**Seamless Co-op**](https://www.nexusmods.com/darksouls3/mods/1895) mods. Tested on Windows, desktop Linux and Steam Deck.

## plswork

Create a directory anywhere. It doesn't have to be in the Dark Souls III game directory and ideally shouldn't be. Let's call it the **root** directory.

> A directory is a folder.

Download these zip files and place them there:

1. ModEngine2: [https://github.com/soulsmods/ModEngine2/releases](https://github.com/soulsmods/ModEngine2/releases)
2. Seamless Co-op: [https://www.nexusmods.com/darksouls3/mods/1895](https://www.nexusmods.com/darksouls3/mods/1895?tab=files)
3. HoodiePatcher **v1.15.2**: [https://www.nexusmods.com/darksouls3/mods/1933](https://www.nexusmods.com/darksouls3/mods/1933?tab=files)
4. The Convergence: [https://www.nexusmods.com/darksouls3/mods/672](https://www.nexusmods.com/darksouls3/mods/672?tab=files)
   * Scroll down and download **the zip** under **Optional Files**, not the downloader

[Download an `.exe`](#downloading-exes-from-strangers-is-exceedingly-dangerous) from under [**Releases**](https://github.com/zorael/plswork/releases), or [compile it yourself](#compiling-it-yourself). Place it in the root directory next to the zips.

Double-click it to extract the files.

> On Linux you will probably need to make it executable first, and instead of double-clicking you may have to right-click it and select *Run In Terminal* instead (or something to that extent).

Excluding the zips, the resulting file hierarchy should look like this:

```
root
├── modengine2
│   └── ...
├── SeamlessCoop
│   ├── ds3sc_settings.ini
│   └── ...
├── The Convergence
│   └── ...
├── HoodiePatcher
│   ├── HoodiePatcher.dll
│   └── HoodiePatcher.ini
├── config_darksouls3.toml
├── launchmod_darksouls3.bat
└── modengine2.exe
```

Optionally, open `ds3sc_settings.ini` found inside the `SeamlessCoop` directory in a text editor and change the `cooppassword` near the end. The program will have set it to "`uffie puffie`" but you might want something else.

### Windows

Double-click the `launchmod_darksouls3.bat` file.

### Linux

In the Steam desktop client, in the menu bar: *Games* -> *Add a Non-Steam Game*. Press *Browse* and navigate to your root folder.

As *Filter* (underneath the *Name* entry field), select **All Files**. `launchmod_darksouls3.bat` should now be visible. Select it and then *Open*.

You're returned to the *Add Non-Steam Game* list of applications it knows about. Scroll down and make sure it now has `launchmod_darksouls3.bat` in it and that it is checked. Finally click *Add Selected Programs*.

Find `launchmod_darksouls3.bat` in your library. **If it is not visible, or if there's *something* there but with an empty name, restart Steam.**

Go into the Properties of the game and set a Proton version in the *Compatibility* section. I've been using `8.0-5`, but the currently-latest `GE-Proton9-26` seems to work well too. Maybe give the game a better name?

**(Steam Deck)** Return to gaming mode.

Start the game through Steam.

### Success? [Y/n]: _

You'll know you succeeded if the game starts up without errors and the main menu shows The Convergence art while also saying "Seamless Co-op" in the upper left.

## Downloading `.exe`s from strangers is exceedingly dangerous

Precompiled binaries for Windows and Linux can be found under [**Releases**](https://github.com/zorael/plswork/releases).

I have no way to prove that they are not malicious. Encouragring you to trust me would just be doubly suspicious. There's not much I can do. Trust me, or don't. The source is there if you want to peruse it. It has basic documentation and comments, so it should be fairly easy to follow what it's doing.

### Compiling it yourself

Clone the repository, download a [**D**](https://dlang.org) compiler, then run `dub build` in the project directory. Copy the resulting binary to your root directory and execute.

## License

This project is licensed under the **Boost Software License 1.0** - see the [LICENSE_1_0.txt](LICENSE_1_0.txt) file for details.
