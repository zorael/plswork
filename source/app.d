/**
    Uffie Patchy Fixy.

    Extracts zips for ModEngine2, a custom HoodiePatcher, and Dark Souls 3 Seamless Co-op.

    Modifies the ModEngine .toml file and Seamless Co-op .ini file for use with
    The Convergence mod.

    Removes unwanted files from the root directory.

    Verifies the installation.

    plswork

    See_Also:
        https://github.com/soulsmods/ModEngine2/releases
        https://www.nexusmods.com/darksouls3/mods/1933
        https://www.nexusmods.com/darksouls3/mods/1895
 */
module jr.plswork;

private:

import std.file;
import std.path;
import std.stdio : File, readln, stdin, writeln;


// unzipArchive
/**
    Unzips an archive into the current working directory.
    A subdirectory and a nuber of directories to skip may optionally be supplied.

    Params:
        zipFilename = The filename of the zip file.
        subdirectory = The optional subdirectory to unzip into.
        numDirsToSkip = The optional number of directories to skip.

    Throws:
        Exception if the number of directories to skip is greater than the
        number of directories for any one file in the zip file.
 */
void unzipArchive(
    const string zipFilename,
    const string subdirectory = string.init,
    const uint numDirsToSkip = 0)
{
    import std.algorithm.searching : endsWith;
    import std.array : array, join;
    import std.file : write;
    import std.range : walkLength;
    import std.zip : ZipArchive;

    writeln(i"Extracting: $(zipFilename.baseName) ...");

    auto zip = new ZipArchive(zipFilename.read);

    foreach (const filename, member; zip.directory)
    {
        string path = filename;

        if (numDirsToSkip > 0)
        {
            auto split = pathSplitter(filename);

            if (numDirsToSkip > split.walkLength)
            {
                import std.format : format;
                enum pattern = "File %s in %s did not have %d directories to skip";
                const message = pattern.format(filename, zipFilename, numDirsToSkip);
                throw new Exception(message);
            }

            path = split
                .array[numDirsToSkip..$]
                .join(dirSeparator);
        }

        if (subdirectory.length > 0)
        {
            path = buildPath(subdirectory, path);
        }

        if (path.exists) continue;

        if (filename.endsWith(dirSeparator) || member.fileAttributes.attrIsDir)
        {
            mkdirRecurse(path);
            continue;
        }

        mkdirRecurse(path.dirName);
        zip.expand(member);
        write(path, member.expandedData);
    }
}


// modifyTOML
/**
    Modifies the ModEngine2 .toml file.

    Params:
        filename = The filename of the .toml file.
 */
void modifyTOML(const string filename)
{
    import std.algorithm.iteration : splitter;
    import std.algorithm.searching : startsWith;
    import std.array : Appender, join;

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

    writeln(i"Modifying: $(filename) ...");
    const fileString = sink[].join("\n");
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

    writeln(i"Modifying: $(filename) ...");
    const fileString = sink[].join("\n");
    File(filename, "w").writeln(fileString);
}


// removeUnwantedRootFiles
/**
    Removes unwanted files from the root directory.

    Returns:
        true if all files were removed successfully; false otherwise.
 */
auto removeUnwantedRootFiles()
{
    import std.algorithm.comparison : among;

    auto root = dirEntries(".", SpanMode.shallow);
    bool success = true;

    foreach (/*const*/ filename; root)
    {
        const fileBaseName = filename.baseName;

        if (fileBaseName.globMatch("*.dll") ||
            fileBaseName.globMatch("*.ini") ||
            fileBaseName.among!(
                "launchmod_armoredcore6.bat",
                "launchmod_eldenring.bat",
                "config_armoredcore6.toml",
                "config_eldenring.toml",
                "README.txt",
                "mod"))
        {
            try
            {
                if (filename.isDir)
                {
                    writeln(i"Removing unwanted directory: $(fileBaseName) ...");
                    rmdir(filename);
                }
                else
                {
                    writeln(i"Removing unwanted file: $(fileBaseName) ...");
                    remove(filename);
                }
            }
            catch (FileException e)
            {
                if (success) writeln();
                writeln(e.msg);
                success = false;
            }
        }
    }

    return success;
}


// verifyInstallation
/**
    Verifies the installation.

    Returns:
        true if the installation is OK; false otherwise.
 */
auto verifyInstallation()
{
    static immutable mustExist =
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

    static immutable mustNotExist =
    [
        "HoodiePatcher.dll",
        "HoodiePatcher.ini",
        "modengine.ini",
        "dinput8.dll",
    ];

    writeln("Verifying ...");

    bool success = true;

    foreach (const filename; mustExist)
    {
        if (!filename.exists)
        {
            if (success) writeln();
            writeln(i"[ERROR] Missing file: $(filename)");
            success = false;
        }
    }

    foreach (const filename; mustNotExist)
    {
        if (filename.exists)
        {
            if (success) writeln();
            writeln(i"[ERROR] File must not exist: $(filename)");
            success = false;
        }
    }

    return success;
}


public:


// main
/**
    The main function.

    Returns:
        0 if successful; 1 otherwise.
 */
int main()
{
    writeln("Uffie Patchy Fixy v0.1");
    writeln("======================");
    writeln();

    string modengineZipFilename;
    string hoodiePatcherZipFilename;
    string seamlessZipFilename;

    auto files = dirEntries(".", SpanMode.shallow);

    foreach (const entry; files)
    {
        const fileBaseName = entry.name.baseName;

        if (fileBaseName.globMatch("ModEngine-2*.zip"))
        {
            modengineZipFilename = entry.name;
        }
        else if (fileBaseName.globMatch("HoodiePatcher*.zip"))
        {
            hoodiePatcherZipFilename = entry.name;
        }
        else if (fileBaseName.globMatch("DS3 Seamless*.zip"))
        {
            seamlessZipFilename = entry.name;
        }
    }

    bool success;

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
            success = false;
        }
        else
        {
            unzipArchive(zipFilename: modengineZipFilename, numDirsToSkip: 1);
            unzipArchive(zipFilename: hoodiePatcherZipFilename, subdirectory: "HoodiePatcher");
            unzipArchive(zipFilename: seamlessZipFilename);
            writeln();

            modifyTOML("config_darksouls3.toml");
            modifyINI(buildPath("SeamlessCoop", "ds3sc_settings.ini"));
            writeln();

            const removeSuccess = removeUnwantedRootFiles();
            writeln();

            const verifySuccess = verifyInstallation();
            success = removeSuccess && verifySuccess;
        }
    }
    catch (Exception e)
    {
        writeln(e);
        success = false;
    }

    writeln();

    if (!success)
    {
        writeln("There were errors :c");
    }
    else
    {
        writeln(r"No errors \o/");
    }

    writeln();
    writeln("Press Enter to exit.");

    stdin.flush();
    readln();

    return success ? 0 : 1;
}
