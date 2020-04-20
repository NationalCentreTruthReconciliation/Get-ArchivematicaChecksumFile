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
    Array of files to exclude from checksum generation. Overrides the default list of files to
    exclude like Thumbs.db and .DS_Store.
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
        [Parameter()][String[]] $Exclude
    )

    $DefaultExcludePatterns = @(
        'Thumbs.db',
        '.DS_Store',
        '.Spotlight-V100',
        '.Trashes'
    )

    If ($Exclude) {
        $ExcludePatterns = $Exclude
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
        New-Item -ItemType File -Path $ChecksumFile -Force | Out-Null
    }
    ElseIf ($Force) {
        Clear-Content -Path $ChecksumFile -Force
    }
    Else {
        Write-Host "$ChecksumFile already exists. To overwrite, pass -Force parameter." -ForegroundColor Red
        return
    }

    $Checksums = [Collections.ArrayList]@()
    $ResolvedFolder = (Resolve-Path $Folder).Path.TrimEnd('\')

    ForEach ($File in $FilesToChecksum) {
        $Hash = (Get-FileHash -Path $File -Algorithm $Algorithm).Hash.ToLower()
        $ResolvedPath = Resolve-Path $File
        $Path = $ResolvedPath.Path.Replace($ResolvedFolder, '.').Replace('.\', '').Replace('\', '/')
        $Checksums.Add("$Hash  $Path") | Out-Null
    }

    [IO.File]::WriteAllText($ChecksumFile, ($Checksums -Join "`n"))

    $ChecksumFile
}


Export-ModuleMember -Function @(
    'Get-ArchivematicaChecksumFile'
)
