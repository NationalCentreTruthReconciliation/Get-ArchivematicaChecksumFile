using namespace System;

. $PSScriptRoot\FileSystem.ps1
. $PSScriptRoot\Exclude.ps1
. $PSScriptRoot\Checksum.ps1

Function Get-ArchivematicaChecksumFile {
    <#
    .Synopsis
    Generate an Archivematica checksum file for a folder full of files.

    .Description
    Generates a checksum file for a folder, and places the file into a metadata folder in the folder
    you're targeting. Checksums can be created with MD5, SHA1, SHA256, or SHA512. Checksums can be
    created for a nested directory structure, by passing the -Recurse parameter. By default,
    excludes common junk files like Thumbs.db and .DS_Store. You may override this behaviour with
    the -Exclude parameter.

    .Parameter Algorithm
    Choose which algorithm to generate checksums with. May be MD5, SHA1, SHA256, or SHA512.

    .Parameter Folder
    Choose which folder to target to generate checksums for.

    .Parameter Recurse
    Descend into sub directories and generate checksums for all files in all directories below the
    targeted directory.

    .Parameter Exclude
    Array of files to exclude from checksum generation. Appends to the default list of files to
    exclude like Thumbs.db and .DS_Store. To clear default exclude files, pass -ClearDefaultExclude

    .Parameter ClearDefaultExclude
    Clear the list of commonly excluded files. They are:
    Thumbs.db
    .DS_Store
    .Spotlight-V100
    .Trashes

    .Example
    Generate MD5 checksum file for C:\Users\you\transfer, ignoring any text files:

    Get-ArchivematicaChecksumFile -Folder C:\Users\you\transfer -Algorithm MD5 -Exclude *.txt

    .Example
    Generate SHA512 checksum file for the current folder and all files in all subfolders:

    Get-ArchivematicaChecksumFile -Folder . -Algorithm SHA512 -Recurse

    .Example
    Generate SHA256 checksum file for .\transfers\2020_transfer\, exclude jpgs, tifs, and pngs.
    Include the normally excluded files like Thumbs.db. Generate checksums for every file in every
    subfolder (minus the excluded images):

    Get-ArchivematicaChecksumFile -Folder .\transfers\2020_transfer\ -Algorithm SHA256 -Exclude
    *.jpg, *.tif, *.png -ClearDefaultExclude -Recurse
    #>

    [CmdletBinding()] Param(
        [Parameter(Position=1, Mandatory=$True)]
        [ValidateScript({ If (Test-Path $_ -PathType Container -ErrorAction SilentlyContinue) {
            $True
        } Else {
            Throw "$_ does not exist or is not a folder."
        }})]
        [String] $Folder,
        [Parameter(Position=2, Mandatory=$True)][ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA512')][String] $Algorithm,
        [Switch] $Recurse,
        [String[]] $Exclude,
        [Switch] $ClearDefaultExclude,
        [Switch] $Force,
        [Switch] $WhatIf
    )

    If (-Not $Exclude) {
        $Exclude = @()
    }
    $ChecksumFile = Get-ChecksumFilePath $Folder $Algorithm
    $Exclude += (Split-Path $ChecksumFile -Leaf)
    $ExcludePatterns = Get-ExcludePatterns $Exclude $ClearDefaultExclude
    $FilesToChecksum = Get-Files $Folder $Recurse $ExcludePatterns

    If (-Not $FilesToChecksum) {
        Write-Host 'No files found to process!'
        return
    }

    If (-Not (FileOkayToCreateOrOverwrite $ChecksumFile $Force)) {
        return
    }
    $Checksums = Get-ChecksumsForFiles $Folder $FilesToChecksum $Algorithm
    # Getting checksums may take a long time. Maybe the file was created in the meantime by a
    # separate process or user, so check again.
    If (-Not (FileOkayToCreateOrOverwrite $ChecksumFile $Force)) {
        return
    }
    CreateOrOverwriteFile $ChecksumFile $WhatIf
    Write-ChecksumsToFile $ChecksumFile $Checksums $WhatIf
}

Export-ModuleMember -Function @(
    'Get-ArchivematicaChecksumFile'
)
