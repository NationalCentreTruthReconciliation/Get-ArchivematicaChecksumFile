Function FileOkayToCreateOrOverwrite {
    Param(
        [Parameter(Position=1, Mandatory=$True)][String] $Path,
        [Parameter(Position=2, Mandatory=$False)][Switch] $Force
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
        [Parameter(Position=2, Mandatory=$False)][Switch] $WhatIf
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
        [Parameter(Mandatory=$True)]
        [String]
        $Folder,

        [Parameter(Mandatory=$True)]
        [AllowEmptyCollection()]
        [String[]]
        $ExcludePatterns,

        [Parameter(Mandatory=$False)]
        [Switch]
        $Recurse
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
        [Parameter(Position=1, Mandatory=$True)]
        [String]
        $File,

        [Parameter(Position=2, Mandatory=$True)]
        [String[]]
        $Checksums,

        [Parameter(Mandatory=$False)]
        [Switch]
        $WhatIf
    )

    # Resolve Path even if it does not exist
    If (Resolve-Path -Path $File -ErrorAction SilentlyContinue) {
        $ResolvedFile = Resolve-Path $File
    }
    Else {
        $ResolvedFile = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($File)
    }

    If (-Not $WhatIf) {
        Write-Verbose "Writing checksums to file $File"
        [IO.File]::WriteAllText($ResolvedFile, ($Checksums -Join "`n"))
        (Get-Item $File)
    }
    Else {
        Write-Host "What if: Writing the following contents to $($File):"
        ForEach ($line in $Checksums) {
            Write-Host $line
        }
    }
}
