# Get-ArchivematicaChecksumFile

This is a PowerShell tool that can be used to generate a checksum file for an [Archivematica](https://www.archivematica.org/en/) transfer. This tool is specifically for generating a checksum file outside of the Archivematica system as per the Archivematica documentation [HERE](https://www.archivematica.org/en/docs/archivematica-1.11/user-manual/transfer/transfer/#transfer-checksums).

This tool can generate a checksum file using MD5, SHA1, SHA256, or SHA512 for a folder full of files. It can also generate a checksum file for files in nested sub-directories.

## Why we Wrote This

Generating checksum files for Archivematica (Unix-based software) in Windows 10 was causing us a lot of headaches because PowerShell and other Windows tools will write files with CRLF line endings, and may even write a Byte-Order-Marker (BOM).

At the time of writing, Archivematica only supports checksum files generated without a BOM, and with LF line endings. This tool writes a checksum file that does not include a BOM, and has LF line endings. This resulting file is compatible with Archivematica. This alleviates the cross-platform issues relating to the encoding of the checksum file generated in Windows.

The other reason for writing this tool was for us to have an easy-to-use and reliable tool to generate checksum files in Windows with the proper encoding, without having to enter a series of complicated PowerShell commands any time an archivist needs to create checksums.

## How to Install It

[First, make sure you have a PowerShell profile](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7#how-to-create-a-profile).

Download or clone this repository, and run the included `DeployModule.ps1` script in PowerShell with the command `.\DeployModule.ps1`. This copies the contents of the repository into your PowerShell Modules folder. You will also need to import the module in your PowerShell profile by adding the line `Import-Module ArchivematicaChecksum` to it. Without telling PowerShell to import it in your profile, the code will not be loaded when you launch PowerShell.

The deploy script will tell you which file you need to add the line to. After deploying and adding the line to your profile, you will need to close and re-open PowerShell to have access to the new command, `Get-ArchivematicaChecksumFile`.

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
