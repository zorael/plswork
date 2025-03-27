/**
    Uffie Puffie Patchy Fixy.

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
import std.stdio;


// coopPassword
/**
    Password for the Seamless Co-op mod.
 */
enum coopPassword = "uffie puffie";


// ZipGlobs
/**
    The glob patterns for the zip files.
 */
enum ZipGlobs
{
    /// Glob for the ModEngine2 zip file.
    modengine = "ModEngine-2*.zip",

    /// Glob for the HoodiePatcher zip file.
    hoodiePatcher = "HoodiePatcher v1.5*.zip",

    /// Glob for the Seamless Co-op zip file.
    seamless = "DS3 Seamless*.zip",
}


// unzipArchive
/**
    Unzips an archive into the current working directory.

    Params:
        zipFilename = The filename of the zip file.
        subdirectory = The optional subdirectory to unzip into.
        numDirsToSkip = The optional number of directories to skip.
        pred = Optional `bool delegate(string)` predicate to filter files;
            if supplied, any filenames passed to it which causes it to return
            `false` will be omitted from extraction.
        showProgress = Whether to show a "progress bar" by outputting a dot
            for each file extracted.

    Throws:
        Exception if the number of directories to skip is greater than the
        number of directories for any one file in the zip file.
 */
void unzipArchive(
    const string zipFilename,
    const string subdirectory = string.init,
    const uint numDirsToSkip = 0,
    bool delegate(string) pred = null,
    const bool showProgress = true)
{
    import std.algorithm.searching : endsWith;
    import std.array : array, join;
    import std.zip : ZipArchive;

    enum progressChar = '.';

    if (showProgress)
    {
        std.stdio.write(i"Extracting: $(zipFilename.baseName) ");
        stdout.flush();
    }
    else
    {
        writeln(i"Extracting: $(zipFilename.baseName) ...");
    }

    scope(exit)
    {
        if (showProgress)
        {
            // Linebreak after progress bar dots
            writeln();
        }
    }

    auto zip = new ZipArchive(zipFilename.read);

    foreach (const filename, member; zip.directory)
    {
        if (!member.compressedSize) continue;

        if (pred && !pred(filename)) continue;

        if (showProgress)
        {
            std.stdio.write(progressChar);
            stdout.flush();
        }

        string path = filename;

        if (numDirsToSkip > 0)
        {
            auto splitPath = pathSplitter(filename).array;

            if (numDirsToSkip > splitPath.length)
            {
                import std.conv : text;
                const message = i"File $(filename) in $(zipFilename) did not have $(numDirsToSkip) directories to skip";
                throw new Exception(message.text);
            }

            path = splitPath[numDirsToSkip..$].join(dirSeparator);
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
        std.file.write(path, member.expandedData);
    }
}


// modifyTOML
/**
    Modifies the ModEngine2 .toml file.

    Params:
        filename = The filename of the .toml file.
 */
void modifyTOML(const string filename) @safe
{
    import std.algorithm.iteration : splitter;
    import std.algorithm.searching : startsWith;
    import std.array : Appender, join;

    Appender!(string[]) sink;
    sink.reserve(64);
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

        if (line.startsWith("external_dlls = ["))
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
        else if (line.startsWith("[extension.scylla_hide]"))
        {
            enum scyllaLine = "enabled = false";
            sink.put(line);
            sink.put(scyllaLine);
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
void modifyINI(const string filename) @safe
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
            enum coopPasswordOverride = "cooppassword = " ~ coopPassword;
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
                writeln();
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
        true if the installation seems correct; false otherwise.
 */
auto verifyInstallation() @safe
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


// waitForEnter
/**
    Waits for the user to press Enter.

    Params:
        success = Whether the previous operations were successful and the
            output message should reflect that.

    Returns:
        0 if the previous operations were successful; 1 otherwise.
 */
auto waitForEnter(const bool success)
{
    const message = success ?
        r"No errors \o/" :
        "There were errors :c";

    writeln();
    writeln(message);
    writeln();
    writeln("Press Enter to exit.");
    stdin.flush();
    readln();

    return success ? 0 : 1;
}


// getZipFilenames
/**
    Looks for zip files that matc the glob patterns of the ZipGlobs enum.
    Populates a Voldemort struct with the filenames and returns it.

    Returns:
        A Voldemort with the filenames of the zip files.
 */
auto getZipFilenames(const bool outputToTerminal)
{
    static struct ZipFilenames
    {
        string modengine;
        string hoodiePatcher;
        string seamless;

        auto success() const
        {
            return
                (modengine.length > 0) &&
                (hoodiePatcher.length > 0) &&
                (seamless.length > 0);
        }
    }

    ZipFilenames zipFilenames;

    auto files = dirEntries(".", SpanMode.shallow);

    foreach (const entry; files)
    {
        const fileBaseName = entry.name.baseName;

        if (fileBaseName.globMatch(cast(string) ZipGlobs.modengine))
        {
            zipFilenames.modengine = entry.name;
        }
        else if (fileBaseName.globMatch(cast(string) ZipGlobs.hoodiePatcher))
        {
            zipFilenames.hoodiePatcher = entry.name;
        }
        else if (fileBaseName.globMatch(cast(string) ZipGlobs.seamless))
        {
            zipFilenames.seamless = entry.name;
        }
    }

    if (outputToTerminal && !zipFilenames.success)
    {
        if (zipFilenames.modengine.length == 0)
        {
            writeln(i`[ERROR] Missing ModEngine zip. (no matches for "$(cast(string) ZipGlobs.modengine)")`);
        }

        if (zipFilenames.hoodiePatcher.length == 0)
        {
            writeln(i`[ERROR] Missing HoodiePatcher zip. (no matches for "$(cast(string) ZipGlobs.hoodiePatcher)")`);
        }

        if (zipFilenames.seamless.length == 0)
        {
            writeln(i`[ERROR] Missing Seamless Co-op zip. (no matches for "$(cast(string) ZipGlobs.seamless)")`);
        }
    }

    return zipFilenames;
}


public:


// main
/**
    The main function.

    Returns:
        0 if the extraction, modification, removal and verification were all
        successful; 1 otherwise.
 */
int main()
{
    writeln("Uffie Puffie Patchy Fixy v0.3");
    writeln("=============================");
    writeln();

    const zipFilenames = getZipFilenames(outputToTerminal: true);

    if (!zipFilenames.success)
    {
        return waitForEnter(success: false);
    }

    try
    {
        unzipArchive(zipFilename: zipFilenames.modengine, numDirsToSkip: 1);
        unzipArchive(zipFilename: zipFilenames.hoodiePatcher, subdirectory: "HoodiePatcher");
        unzipArchive(zipFilename: zipFilenames.seamless);
        writeln();

        modifyTOML("config_darksouls3.toml");
        modifyINI(buildPath("SeamlessCoop", "ds3sc_settings.ini"));
        writeln();

        const removeSuccess = removeUnwantedRootFiles();
        writeln();

        const verifySuccess = verifyInstallation();
        //writeln();

        return waitForEnter(success: (removeSuccess && verifySuccess));
    }
    catch (Exception e)
    {
        writeln(e);
        return waitForEnter(success: false);
    }

    assert(0, "unreachable");
}
