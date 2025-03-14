/**
    Uffie Patchy Fixy.
 */
module plswork;

private:

import std.stdio;


// unzipModengine
/**
    Unzips the ModEngine zip file.

    Params:
        zipFilename = The filename of the zip file.
 */
void unzipModengine(const string zipFilename)
{
    import std.array : array, join;
    import std.file : attrIsDir, exists, mkdirRecurse, read, write;
    import std.path : baseName, dirName, dirSeparator, pathSplitter;
    import std.zip : ZipArchive;

    writeln("Extracting ", zipFilename.baseName, " ...");

    auto zip = new ZipArchive(zipFilename.read);

    foreach (immutable filename, member; zip.directory)
    {
        const path = pathSplitter(filename)
            .array[1..$]
            .join(dirSeparator);

        if (path.exists) continue;

        if (member.fileAttributes.attrIsDir)
        {
            mkdirRecurse(path);
            continue;
        }

        mkdirRecurse(path.dirName);
        zip.expand(member);
        write(path, member.expandedData);
    }
}


// unzipOther
/**
    Unzips a file.

    Params:
        zipFilename = The filename of the zip file.
        subDir = The optional subdirectory to unzip into.
 */
void unzipOther(const string zipFilename, const string subDir = string.init)
{
    import std.array : array, join;
    import std.file : FileException, attrIsDir, exists, mkdirRecurse, read, write;
    import std.path : baseName, buildPath, dirName, dirSeparator, pathSplitter;
    import std.zip : ZipArchive;

    writeln("Extracting ", zipFilename.baseName, " ...");

    auto zip = new ZipArchive(zipFilename.read);

    foreach (immutable filename, member; zip.directory)
    {
        const path = (subDir.length > 0) ?
            buildPath(subDir, filename) :
            filename;

        if (path.exists) continue;

        if (member.fileAttributes.attrIsDir)
        {
            mkdirRecurse(path);
            continue;
        }


        try
        {
            mkdirRecurse(path.dirName);
            zip.expand(member);
            write(path, member.expandedData);
        }
        catch (FileException e)
        {
            if (e.msg == "Is a directory") continue;
        }
    }
}


// modifyTOML
/**
    Modifies the ModEngine .toml file.

    Params:
        filename = The filename of the .toml file.
 */
void modifyTOML(const string filename)
{
    import std.algorithm.iteration : splitter;
    import std.algorithm.searching : startsWith;
    import std.array : Appender, join;
    import std.file : readText;

    Appender!(string[]) sink;
    sink.reserve(128);
    bool skipNext;

    auto fileLines = filename
        .readText
        .splitter("\n");

    foreach (const line; fileLines)
    {
        if (skipNext)
        {
            skipNext = false;
            continue;
        }

        if (line.startsWith("external_dlls"))
        {
            enum dllLine = `external_dlls = [ "SeamlessCoop/ds3sc.dll", "HoodiePatcher/HoodiePatcher.dll" ]`;
            sink.put(dllLine);
        }
        else if (line.startsWith("mods = ["))
        {
            enum convergenceLine = `    { enabled = true, name = "Convergence", path = "The Convergence" }`;
            sink.put(line);
            sink.put(convergenceLine);
            skipNext = true;
        }
        else
        {
            sink.put(line);
        }
    }

    writeln("Writing modified ModEngine .toml file to ", filename, " ...");
    immutable fileString = sink[].join("\n");
    File(filename, "w").writeln(fileString);
}


// modifyINI
/**
    Modifies the Seamless Co-op .ini file.

    Params:
        filename = The filename of the .ini file.
 */
void modifyINI(const string filename)
{
    import std.algorithm.iteration : splitter;
    import std.algorithm.searching : startsWith;
    import std.array : Appender, join;
    import std.file : readText;

    Appender!(string[]) sink;
    sink.reserve(128);

    auto fileLines = filename
        .readText
        .splitter("\n");

    foreach (const line; fileLines)
    {
        if (line.startsWith("allow_invaders"))
        {
            enum allowInvadersOverride = "allow_invaders = 0";
            sink.put(allowInvadersOverride);
        }
        else if (line.startsWith("death_debuffs"))
        {
            enum deathDebuffsOverride = "death_debuffs = 0";
            sink.put(deathDebuffsOverride);
        }
        else if (line.startsWith("overhead_player_display"))
        {
            enum overheadPlayerDisplayOverride = "overhead_player_display = 5";
            sink.put(overheadPlayerDisplayOverride);
        }
        else if (line.startsWith("cooppassword"))
        {
            enum coopPasswordOverride = "cooppassword = uffie puffie";
            sink.put(coopPasswordOverride);
        }
        else
        {
            sink.put(line);
        }
    }

    writeln("Writing modified Seamless .ini file to ", filename, " ...");
    immutable fileString = sink[].join("\n");
    File(filename, "w").writeln(fileString);
}


// removeUnwantedRootFiles
/**
    Removes unwanted files from the root directory.
 */
void removeUnwantedRootFiles()
{
    import std.file : SpanMode, dirEntries, rename;
    import std.path : baseName, globMatch;

    auto root = dirEntries(".", SpanMode.shallow);

    foreach (const file; root)
    {
        if (file.baseName.globMatch("*.dll") || file.baseName.globMatch("*.ini"))
        {
            rename(file, file ~ ".bak");
        }
    }
}


// verifyInstallation
/**
    Verifies the installation.

    Returns:
        true if the installation is OK; false otherwise.
 */
auto verifyInstallation()
{
    import std.file : exists;
    import std.path : buildPath;

    const mustExist =
    [
        buildPath("The Convergence", "project.json"),
        buildPath("The Convergence", "parts"),
        buildPath("The Convergence", "chr"),
        buildPath("HoodiePatcher", "HoodiePatcher.dll"),
        buildPath("HoodiePatcher", "HoodiePatcher.ini"),
        buildPath("SeamlessCoop", "ds3sc.dll"),
        buildPath("SeamlessCoop", "ds3sc_settings.ini"),
        buildPath("modengine2", "bin", "modengine2.dll"),
        "modengine2_launcher.exe",
        "config_darksouls3.toml",
    ];

    const mustNotExist =
    [
        "HoodiePatcher.dll",
        "HoodiePatcher.ini",
        "modengine.ini",
        "dinput8.dll",
    ];

    bool allOK = true;

    foreach (const filename; mustExist)
    {
        if (!filename.exists)
        {
            writeln("Missing file: ", filename);
            allOK = false;
        }
    }

    foreach (const filename; mustNotExist)
    {
        if (filename.exists)
        {
            writeln("File should not exist: ", filename);
            allOK = false;
        }
    }

    return allOK;
}


public:


// main
/**
    The main function.
 */
int main()
{
    import std.file : SpanMode, dirEntries;
    import std.path : baseName, globMatch;

    writeln("Uffie Patchy Fixy v0.1");
    writeln("======================");
    writeln();

    string modengineZipFilename;
    string hoodiePatcherZipFilename;
    string seamlessZipFilename;

    auto files = dirEntries(".", SpanMode.shallow);

    foreach (const entry; files)
    {
        if (entry.baseName.globMatch("ModEngine-2*.zip"))
        {
            modengineZipFilename = entry.name;
        }
        else if (entry.baseName.globMatch("HoodiePatcher*.zip"))
        {
            hoodiePatcherZipFilename = entry.name;
        }
        else if (entry.baseName.globMatch("DS3 Seamless*.zip"))
        {
            seamlessZipFilename = entry.name;
        }
    }

    uint retval;

    try
    {
        bool missingSometehing;

        if (modengineZipFilename.length == 0)
        {
            writeln("Missing ModEngine zip.");
            missingSometehing = true;
        }

        if (hoodiePatcherZipFilename.length == 0)
        {
            writeln("Missing HoodiePatcher zip.");
            missingSometehing = true;
        }

        if (seamlessZipFilename.length == 0)
        {
            writeln("Missing Seamless Co-op zip.");
            missingSometehing = true;
        }

        if (missingSometehing)
        {
            retval = 2;
        }
        else
        {
            import std.path : buildPath;

            unzipModengine(modengineZipFilename);
            unzipOther(hoodiePatcherZipFilename, "HoodiePatcher");
            unzipOther(seamlessZipFilename);

            modifyTOML("config_darksouls3.toml");
            modifyINI(buildPath("SeamlessCoop", "ds3sc_settings.ini"));

            removeUnwantedRootFiles();
            const allOK = verifyInstallation();

            if (!allOK) retval = 1;
        }
    }
    catch (Exception e)
    {
        writeln(e);
        retval = 1;
    }

    writeln();

    if (retval > 0)
    {
        writeln("There were errors. Press Enter to exit.");
    }
    else
    {
        writeln("No errors! Press Enter to exit.");
    }

    stdin.flush();
    readln();

    return retval;
}
