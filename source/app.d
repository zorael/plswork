/**
    Uffie Puffie Patchy Fixy.

    Extracts zips for ModEngine2, a custom HoodiePatcher, Dark Souls III
    Seamless Co-op and Dark Souls III: The Convergence. If The Convergence seems
    to be installed already, it will not be extracted again.

    Modifies the ModEngine .toml configuration file for Dark Souls III to load
    both Seamless Co-op and The Convergence.

    Modifies the Seamless Co-op .ini file and disables invaders, disables death
    debuffs, modifies the nameplate and sets a default co-op password.

    Removes unwanted files from the root directory.

    Verifies that required files are in place.

    plswork

    See_Also:
        https://github.com/soulsmods/ModEngine2/releases
        https://www.nexusmods.com/darksouls3/mods/1933
        https://www.nexusmods.com/darksouls3/mods/1895
        https://www.nexusmods.com/darksouls3/mods/672

    Copyright: [JR](https://github.com/zorael)
    License: [Boost Software License 1.0](https://www.boost.org/users/license.html)

    Authors:
        [JR](https://github.com/zorael)
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
    hoodiePatcher = "HoodiePatcher v1.5.*.zip",

    /// Glob for the Seamless Co-op zip file.
    seamless = "DS3 Seamless*.zip",

    /// Glob for The Convergence zip file.
    convergence = "The Convergence*.zip",
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
in ((zipFilename.length > 0), "Empty zip filename passed to unzipArchive")
{
    import std.algorithm.searching : endsWith;
    import std.array : array, join;
    import std.mmfile : MmFile;
    import std.zip : ZipArchive;

    enum progressBarCharacter = '.';

    if (showProgress)
    {
        // Use std.stdio.write if we're printing a progress bar.
        std.stdio.write(i"Extracting: $(zipFilename.baseName) ");
        stdout.flush();  // Must flush after each std.stdio.write
    }
    else
    {
        writeln(i"Extracting: $(zipFilename.baseName) ...");
    }

    scope(exit)
    {
        if (showProgress)
        {
            // On function exit, output a linebreak after progress bar dots.
            writeln();
        }
    }

    // mmap the zip file instead of reading all of it into memory.
    scope mmFile = new MmFile(zipFilename);
    scope zip = new ZipArchive(mmFile[]);

    foreach (const filename, member; zip.directory)
    {
        // Some zip files seem to report directories as being 0-sized files.
        if (member.compressedSize == 0) continue;

        // Skip the file if a predicate was passed and this filename fails it.
        if (pred && !pred(filename)) continue;

        if (showProgress)
        {
            // Advance progress bar. Flush after writing to ensure the dot is output.
            std.stdio.write(progressBarCharacter);
            stdout.flush();  // Must flush after each std.stdio.write
        }

        string path = filename;  // mutable

        if (numDirsToSkip > 0)
        {
            /*
                Split the filename into its path components and skip the first
                `numDirsToSkip` directories. The path components are separated
                by the platform-specific directory separator by `pathSplitter`.
                The components are then joined again with the same separator.
             */
            auto splitPath = pathSplitter(filename).array;

            if (numDirsToSkip > splitPath.length)
            {
                import std.conv : text;
                const message = text(
                    i"File $(filename) in $(zipFilename) did not have ",
                    i"$(numDirsToSkip) directories to skip");
                throw new Exception(message);
            }

            path = splitPath[numDirsToSkip..$].join(dirSeparator);
        }

        if (subdirectory.length > 0)
        {
            // Extract the files in a subdirectory if one was specified.
            path = buildPath(subdirectory, path);
        }

        // Unsure if this ever happens.
        if (path.exists) continue;

        if (filename.endsWith(dirSeparator) || member.fileAttributes.attrIsDir)
        {
            // We should have already continued past 0-size "files"...
            mkdirRecurse(path);
            continue;
        }

        // Create the parent directory in case the order of files in the zip is weird.
        mkdirRecurse(path.dirName);
        zip.expand(member);
        std.file.write(path, member.expandedData);
    }
}


// modifyTOML
/**
    Modifies the ModEngine2 .toml file.

    An entry is added to the `external_dlls` array for the Seamless Co-op and
    HoodiePatcher .dll files. An entry is added to the `mods` array for The
    Convergence mod. The `scylla_hide` section is disabled.

    Params:
        filename = The filename of the .toml file.
 */
void modifyTOML(const string filename) @safe
{
    import std.algorithm.iteration : splitter;
    import std.algorithm.searching : startsWith;
    import std.array : Appender, join;
    import std.string : stripRight;

    Appender!(string[]) sink;
    sink.reserve(64);  // ~13
    bool skipNextLine;

    auto rangeOfLines = filename
        .readText
        .splitter("\n");

    foreach (const line; rangeOfLines)
    {
        if (skipNextLine)
        {
            skipNextLine = false;
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
            skipNextLine = true;
        }
        else if (line.startsWith("[extension.scylla_hide]"))
        {
            enum scyllaLine = "enabled = false";
            sink.put(line);
            sink.put(scyllaLine);
            skipNextLine = true;
        }
        else
        {
            // Passthrough.
            sink.put(line);
        }
    }

    // Flatten the array of lines into a single string.
    // Any trailing newlines are removed by stripRight.
    const contents = sink[]
        .join("\n")
        .stripRight;

    writeln(i"Modifying: $(filename) ...");
    File(filename, "w").writeln(contents);
}


// modifyINI
/**
    Modifies the Seamless Co-op .ini file.

    The `allow_invaders`, `death_debuffs` and `overhead_player_display`
    settings are modified to disable invaders, disable debuffs and show player
    level+ping repectively.

    The `cooppassword` setting is set to the value of the `coopPassword` enum.

    Params:
        filename = The filename of the .ini file.
 */
void modifyINI(const string filename) @safe
{
    import std.algorithm.iteration : splitter;
    import std.algorithm.searching : startsWith;
    import std.array : Appender, join;
    import std.string : stripRight;

    Appender!(string[]) sink;
    sink.reserve(128);

    auto rangeOfLines = filename
        .readText
        .splitter("\n");

    foreach (const line; rangeOfLines)
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
            // Passthrough.
            sink.put(line);
        }
    }

    // Flatten the array of lines into a single string.
    // Any trailing newlines are removed by stripRight.
    const contents = sink[]
        .join("\n")
        .stripRight;

    writeln(i"Modifying: $(filename) ...");
    File(filename, "w").writeln(contents);
}


// removeUnwantedRootFiles
/**
    Removes unwanted files from the root directory.

    Not all files break the setup, but they're not needed and can be removed
    to avoid confusion.

    Returns:
        true if all files were removed successfully; false otherwise.
 */
auto removeUnwantedRootFiles()
{
    import std.algorithm.comparison : among;

    auto rootFiles = dirEntries(".", SpanMode.shallow);
    bool success = true;

    foreach (/*const*/ entry; rootFiles)
    {
        const fileBaseName = entry.baseName;

        if (fileBaseName.among!(
                "launchmod_armoredcore6.bat",
                "launchmod_eldenring.bat",
                "config_armoredcore6.toml",
                "config_eldenring.toml",
                "README.txt",
                "mod") ||
            fileBaseName.globMatch("*.dll") ||
            fileBaseName.globMatch("*.ini"))
        {
            try
            {
                if (entry.isDir)
                {
                    writeln(i"Removing unwanted directory: $(fileBaseName) ...");
                    rmdir(entry);
                }
                else
                {
                    writeln(i"Removing unwanted file: $(fileBaseName) ...");
                    remove(entry);
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

    Does not check for the presence of all required files, but only one missing
    should break the setup anyway.

    A special check is made to ensure that stray .dlls and .ini files from
    The Convergence zip archive are not present in the root directory.

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
            if (success) writeln();  // Output a linebreak if this is the first error
            writeln(i"[ERROR] Missing file: $(filename)");
            success = false;
        }
    }

    foreach (const filename; mustNotExist)
    {
        if (filename.exists)
        {
            if (success) writeln();  // As above
            writeln(i"[ERROR] File must not exist: $(filename)");
            success = false;
        }
    }

    return success;
}


// waitForEnter
/**
    Waits for the user to press Enter.

    The return value is meant to be used as the return value of `main`.
    The message output is based on the success of the previous operations.

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


// discoverFiles
/**
    Looks for zip files that match the glob patterns of the ZipGlobs enum.
    Populates a Voldemort struct with the filenames and returns it.

    Params:
        outputToTerminal = Whether to output any error messages to the terminal.

    Returns:
        A Voldemort with resolved filenames.
 */
auto discoverFiles(const bool outputToTerminal)
{
    // Voldemort.
    static struct Discovered
    {
        string modengineZip;
        string hoodiePatcherZip;
        string seamlessZip;
        string convergenceZip;
        string convergenceDir;

        auto success() const
        {
            return
                (modengineZip.length > 0) &&
                (hoodiePatcherZip.length > 0) &&
                (seamlessZip.length > 0) &&
                ((convergenceZip.length > 0) || (convergenceDir.length > 0));
        }
    }

    Discovered found;

    auto rootFiles = dirEntries(".", SpanMode.shallow);

    foreach (const entry; rootFiles)
    {
        const fileBaseName = entry.name.baseName;

        if (fileBaseName.globMatch(cast(string) ZipGlobs.modengine))
        {
            found.modengineZip = entry.name;
        }
        else if (fileBaseName.globMatch(cast(string) ZipGlobs.hoodiePatcher))
        {
            found.hoodiePatcherZip = entry.name;
        }
        else if (fileBaseName.globMatch(cast(string) ZipGlobs.seamless))
        {
            found.seamlessZip = entry.name;
        }
        else if (fileBaseName.globMatch(cast(string) ZipGlobs.convergence))
        {
            found.convergenceZip = entry.name;
        }
        else if (fileBaseName == "The Convergence")
        {
            found.convergenceDir = entry.name;
        }
    }

    if (outputToTerminal && !found.success)
    {
        if (found.modengineZip.length == 0)
        {
            writeln(i`[ERROR] Missing ModEngine zip. (no matches for "$(cast(string) ZipGlobs.modengine)")`);
        }

        if (found.hoodiePatcherZip.length == 0)
        {
            writeln(i`[ERROR] Missing HoodiePatcher zip. (no matches for "$(cast(string) ZipGlobs.hoodiePatcher)")`);
        }

        if (found.seamlessZip.length == 0)
        {
            writeln(i`[ERROR] Missing Seamless Co-op zip. (no matches for "$(cast(string) ZipGlobs.seamless)")`);
        }

        if ((found.convergenceZip.length == 0) && (found.convergenceDir.length == 0))
        {
            // Only mention the zip
            writeln(i`[ERROR] Missing The Convergence zip. (no matches for "$(cast(string) ZipGlobs.convergence)")`);
        }
    }

    return found;
}


public:


// main
/**
    `main`.

    Returns:
        0 if the extraction, modification, removal and verification were all
        successful; 1 in all other cases.
 */
int main()
{
    writeln("Uffie Puffie Patchy Fixy v0.4");
    writeln("=============================");
    writeln();

    // Find the zip files.
    const found = discoverFiles(outputToTerminal: true);

    if (!found.success)
    {
        // At least one file is missing.
        // An error message will already have been output, so just read an Enter and exit.
        return waitForEnter(success: false);
    }

    try
    {
        import std.algorithm.searching : startsWith;

        /*
            Predicate functions to filter out files in the zip archives.
            These are used to skip files in The Convergence and Seamless Co-op
            zips that are not needed.
         */
        auto convergencePred(string filename) => filename.startsWith("The Convergence");
        auto seamlessPred(string filename) => filename.startsWith("SeamlessCoop");

        // Extract all files, applying predicate filters where needed.
        unzipArchive(
            zipFilename: found.modengineZip,
            numDirsToSkip: 1);

        unzipArchive(
            zipFilename: found.hoodiePatcherZip,
            subdirectory: "HoodiePatcher");

        unzipArchive(
            zipFilename: found.seamlessZip,
            pred: &seamlessPred);

        if (found.convergenceDir.length == 0)
        {
            /*
                The `convergence` or `theConvergenceDir` members of `found` must
                either have length at this point; otherwise found.success above
                would have been false
             */
            unzipArchive(
                zipFilename: found.convergenceZip,
                pred: &convergencePred);
        }

        // Make the sure the .toml file refers to the correct mods and .dll files.
        // Modify the Seamless Co-op .ini to change settings and set a password.
        writeln();
        modifyTOML("config_darksouls3.toml");
        modifyINI(buildPath("SeamlessCoop", "ds3sc_settings.ini"));
        writeln();

        // Clean up the root directory.
        const removeSuccess = removeUnwantedRootFiles();
        writeln();

        // Check for the presence of some files to verify the installation.
        const verifySuccess = verifyInstallation();
        //writeln();

        // Read an Enter and exit.
        return waitForEnter(success: (removeSuccess && verifySuccess));
    }
    catch (Exception e)
    {
        // Output the full error, read an Enter and exit.
        writeln(e);
        return waitForEnter(success: false);
    }

    assert(0, "Unreachable");
}
