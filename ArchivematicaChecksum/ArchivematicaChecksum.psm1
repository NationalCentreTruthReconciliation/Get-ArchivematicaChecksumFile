using namespace System;

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
        [Parameter()][String[]] $Exclude,
        [Switch] $ClearDefaultExclude,
        [Switch] $Force,
        [Switch] $WhatIf
    )

    If (-Not $ClearDefaultExclude) {
        $DefaultExcludePatterns = @(
            'Thumbs.db',
            '.DS_Store',
            '.Spotlight-V100',
            '.Trashes'
        )
    }
    Else {
        $DefaultExcludePatterns = @()
    }

    If ($Exclude) {
        $ExcludePatterns = $DefaultExcludePatterns
        ForEach ($Pattern in $Exclude) {
            $ExcludePatterns += $Pattern
        }
    }
    Else {
        $ExcludePatterns = $DefaultExcludePatterns
    }

    If ($Recurse) {
        $FilesToChecksum = Get-ChildItem -File -Recurse -Path "$($Folder)\*" -Exclude $ExcludePatterns
    }
    Else {
        $FilesToChecksum = Get-ChildItem -File -Path "$($Folder)\*" -Exclude $ExcludePatterns
    }

    $ChecksumFolder = Join-Path -Path $Folder -ChildPath 'metadata'
    $ChecksumFile = Join-Path -Path $ChecksumFolder -ChildPath "checksum.$($Algorithm.ToLower())"

    If (-Not(Test-Path -Path $ChecksumFile -PathType Leaf -ErrorAction SilentlyContinue)) {
        If (-Not $WhatIf) {
            New-Item -ItemType File -Path $ChecksumFile -Force | Out-Null
        }
        Else {
            New-Item -ItemType File -Path $ChecksumFile -Force -WhatIf | Out-Null
        }
    }
    ElseIf ($Force) {
        If (-Not $WhatIf) {
            Clear-Content -Path $ChecksumFile -Force
        }
        Else {
            Clear-Content -Path $ChecksumFile -Force -WhatIf
        }
    }
    Else {
        Write-Host "$ChecksumFile already exists. To overwrite, pass -Force parameter." -ForegroundColor Red
        return
    }

    $Checksums = [Collections.ArrayList]@()
    $ResolvedFolder = (Resolve-Path $Folder).Path.TrimEnd('\')

    ForEach ($File in $FilesToChecksum) {
        $ResolvedPath = Resolve-Path $File
        $Path = $ResolvedPath.Path.Replace($ResolvedFolder, '.').Replace('.\', '').Replace('\', '/')
        Write-Verbose "Processing $Path"
        $Hash = (Get-FileHash -Path $File -Algorithm $Algorithm).Hash.ToLower()
        $Checksums.Add("$Hash  $Path") | Out-Null
    }

    If (-Not $WhatIf) {
        Write-Verbose "Writing checksums to file $ChecksumFile"
        [IO.File]::WriteAllText((Resolve-Path $ChecksumFile), ($Checksums -Join "`n"))
    }
    Else {
        Write-Host "What if: Writing the following contents to $($ChecksumFile):"
        ForEach ($line in $Checksums) {
            Write-Host $line
        }
    }

    If (-Not $WhatIf) {
        (Get-Item $ChecksumFile)
    }
}


Export-ModuleMember -Function @(
    'Get-ArchivematicaChecksumFile'
)
