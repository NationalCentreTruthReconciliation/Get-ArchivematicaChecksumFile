# Get-ArchivematicaChecksumFile

This is a PowerShell tool that can be used to generate a checksum file for an [Archivematica](https://www.archivematica.org/en/) transfer. This tool is specifically for generating a checksum file outside of the Archivematica system as per the Archivematica documentation [HERE](https://www.archivematica.org/en/docs/archivematica-1.11/user-manual/transfer/transfer/#transfer-checksums).

This tool can generate a checksum file using MD5, SHA1, SHA256, or SHA512 for a folder full of files. It can also generate a checksum file for files in nested sub-directories.

## Why we Wrote This

Generating checksum files for Archivematica (Unix-based software) in Windows 10 was causing us a lot of headaches because PowerShell and other Windows tools will write files with CRLF line endings, and may even write a Byte-Order-Marker (BOM).

At the time of writing, Archivematica only supports checksum files generated without a BOM, and with LF line endings. This tool writes a checksum file that does not include a BOM, and has LF line endings. This resulting file is compatible with Archivematica. This alleviates the cross-platform issues relating to the encoding of the checksum file generated in Windows.

The other reason for writing this tool was for us to have an easy-to-use and reliable tool to generate checksum files in Windows with the proper encoding, without having to enter a series of complicated PowerShell commands any time an archivist needs to create checksums.

## How to Install It

[First, make sure you have a PowerShell profile](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7#how-to-create-a-profile).

For those who are not frequent PowerShell users, you may need to update your execution policy if you have never done so. Without having an Unrestricted execution policy, you will not be able to run the deploy script and PowerShell may not be able to load your profile. To update your execution policy, run:

```PowerShell
Set-ExecutionPolicy -ExecutionPolicy Unrestricted -Scope CurrentUser -Force
```

After you have a profile and an appropriate execution policy set, download or clone this repository, and run the included `DeployModule.ps1` script at the top level of this repository. To run the script, open up PowerShell in the same folder as the `DeployModule.ps1` script, and enter the command (optionally using the `-AutoAddImport` option)

```PowerShell
.\DeployModule.ps1 -AutoAddImport
```

This deploy script will copy the code for the ArchivematicaChecksum module into your PowerShell Modules folder, and will add a new line to your profile that tells PowerShell to import the code when you launch PowerShell in the future. If you would prefer to manually edit your profile or otherwise do not want the deploy script to touch your profile file, you can forgo the `-AutoAddImport` option and manually add the line `Import-Module ArchivematicaChecksum` to your profile. If you choose to go this route, the deploy script will let you know where your profile is, in case you forget.

After deploying the code and adding the import statement manually in your profile if you chose to do so, you will need to close and re-open PowerShell to have access to the new command: `Get-ArchivematicaChecksumFile`.

## How to Use It

We will use the following directory structure for these examples:

```Text
C:\Users\transfer\
    |- file1.jpg
    |- file2.txt
    |- Thumbs.db
    |- data\
        |- file3.txt
```

For each call to `Get-ArchivematicaChecksumFile`, it is necessary to pass it which folder you want to process, and what algorithm you want to process the files in the folder with. For algorithms, you may pass one of: MD5, SHA1, SHA256, or SHA512.

If you want to create a SHA1 checksum for file1.jpg and file2.txt in our imaginary directory structure above, and not any files in the data folder or the Thumbs.db file, you should run the following in PowerShell:

```PowerShell
Get-ArchivematicaChecksumFile -Folder C:\Users\transfer\ -Algorithm SHA1
```

The directory structure will then look like:

```Text
C:\Users\transfer\
    |- file1.jpg
    |- file2.txt
    |- Thumbs.db
    |- metadata\
        |- checksums.sha1
    |- data\
        |- file3.txt
```

The new checksums.sha1 file will have the following contents:

```Text
thisisasha1checksum  file1.jpg
thisisasha1checksum  file2.txt
```

If you want to create a SHA256 checksum for all the files, including the file3.txt in the data folder (minus the Thumbs.db file), you will run a similar command in PowerShell, except passing the `-Recurse` parameter that allows for checksumming files in sub-directories.

```PowerShell
Get-ArchivematicaChecksumFile -Folder C:\Users\transfer\ -Algorithm SHA256 -Recurse
```

The resulting checksum.sha256 file created in the `C:\Users\transfer\metadata` folder will have the contents:

```Text
thisisasha256checksum  file1.jpg
thisisasha256checksum  file2.txt
thisisasha256checksum  data/file3.txt
```

### Other Parameters

You must always use the `-Folder` and `-Algorithm` parameters, but there are a number of other optional parameters you can use to have finer control over the operation of `Get-ArchivematicaChecksumFile`. These are:

`-Recurse`: Descend into subdirectories and find files in them to checksum. See example above for how this works.

`-Exclude <string[]>`: You can exclude extra files by pattern using this parameter. In practice, you would use a command like the following to exclude any JPG and TXT files: `Get-ArchivematicaChecksumFile -Exclude *.jpg, *.txt -Folder <fold.> -Algorithm <algo.>`

`-ClearDefaultExclude`: This clears the list of commonly excluded files like Thumbs.db, and .DS_Store, so that they will be checksummed if they're found in the folder.

`-Verbose`: Prints out verbose information. For processing large files or a large number of files, this is useful to see which file the program is currently working on.

`-Force`: Forces the overwriting of a checksum file if it already exists.

`-WhatIf`: Don't actually write to the checksum file, just show what would be written to it.

## Testing

`Get-ArchivematicaChecksum` is tested using Pester 4. To run the tests, you must have Pester 4 installed. These are useful resources for finding out how to install it:
- [Pester Installation Documentation](https://pester.dev/docs/introduction/installation)
- [PowerShell Gallery - Pester](https://www.powershellgallery.com/packages/Pester/4.6.0)

You should install version 4.6.0 or later.

To run the tests, make sure your PowerShell is in the same folder as the deploy script and this README. Then, use the command:

```PowerShell
Invoke-Pester ArchivematicaChecksum
```
