Function FileOkayToCreateOrOverwrite {
    Param(
        [Parameter(Position=1, Mandatory=$True)][String] $Path,
        [Parameter(Position=2, Mandatory=$True)][Switch] $Force
    )

    $FileExists = (Test-Path -Path $Path -PathType Leaf -ErrorAction SilentlyContinue)
    If ($FileExists -And -Not $Force) {
        Write-Host "$Path already exists. To overwrite, pass -Force parameter." -ForegroundColor Red
        return $False
    }
    return $True
}

Function CreateOrOverwriteFile {
    Param(
        [Parameter(Position=1, Mandatory=$True)][String] $Path,
        [Parameter(Position=2, Mandatory=$True)][Switch] $WhatIf
    )

    $FileExists = (Test-Path -Path $Path -PathType Leaf -ErrorAction SilentlyContinue)

    If (-Not $FileExists -And -Not $WhatIf) {
        New-Item -ItemType File -Path $Path -Force | Out-Null
    }
    ElseIf (-Not $FileExists -And $WhatIf) {
        New-Item -ItemType File -Path $Path -Force -WhatIf
    }
    ElseIf (-Not $WhatIf) {
        Clear-Content -Path $Path -Force
    }
    Else {
        Clear-Content -Path $Path -Force -WhatIf
    }
}

Function Get-Files {
    Param(
        [Parameter(Position=1, Mandatory=$True)][String] $Folder,
        [Parameter(Position=2, Mandatory=$True)][Switch] $Recurse,
        [Parameter(Position=3, Mandatory=$True)]
        [AllowEmptyCollection()]
        [String[]] $ExcludePatterns
    )

    If ($Recurse) {
        $Files = Get-ChildItem -File -Recurse -Path $Folder -Exclude $ExcludePatterns
    }
    Else {
        $FolderWithWildcard = $Folder.TrimEnd('\').TrimEnd('/') + '\*'
        $Files = Get-ChildItem -File -Path $FolderWithWildcard -Exclude $ExcludePatterns
    }

    return $Files
}

Function Write-ChecksumsToFile {
    Param(
        [Parameter(Position=1, Mandatory=$True)][String] $File,
        [Parameter(Position=2, Mandatory=$True)][String[]] $Checksums,
        [Parameter(Position=3, Mandatory=$True)][Switch] $WhatIf
    )

    If (-Not $WhatIf) {
        Write-Verbose "Writing checksums to file $File"
        [IO.File]::WriteAllText((Resolve-Path $File), ($Checksums -Join "`n"))
        (Get-Item $File)
    }
    Else {
        Write-Host "What if: Writing the following contents to $($File):"
        ForEach ($line in $Checksums) {
            Write-Host $line
        }
    }
}

Export-ModuleMember -Function *
