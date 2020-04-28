Function Get-ChecksumFilePath {
    Param(
        [Parameter(Position=1, Mandatory=$True)][String] $Folder,
        [Parameter(Position=2, Mandatory=$True)][String] $Algorithm
    )

    $ChecksumFolder = Join-Path -Path $Folder -ChildPath 'metadata'
    $ChecksumFile = Join-Path -Path $ChecksumFolder -ChildPath "checksum.$($Algorithm.ToLower())"
    return $ChecksumFile
}

Function Get-ChecksumsForFiles {
    Param(
        [Parameter(Position=1, Mandatory=$True)][String] $Folder,
        [Parameter(Position=2, Mandatory=$True)][Object[]] $FilesToChecksum,
        [Parameter(Position=3, Mandatory=$True)][String] $Algorithm
    )

    $Checksums = [Collections.ArrayList]@()
    $ResolvedFolder = (Resolve-Path $Folder).Path.TrimEnd('\')

    ForEach ($File in $FilesToChecksum) {
        $ResolvedPath = Resolve-Path $File
        $Path = $ResolvedPath.Path.Replace($ResolvedFolder, '.').Replace('.\', '').Replace('\', '/')
        Write-Verbose "Creating $Algorithm checksum for $Path"
        $Hash = (Get-FileHash -Path $File -Algorithm $Algorithm).Hash.ToLower()
        $Checksums.Add("$Hash  $Path") | Out-Null
    }

    return $Checksums
}
