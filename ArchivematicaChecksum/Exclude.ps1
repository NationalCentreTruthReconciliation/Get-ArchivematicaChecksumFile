Function Get-ExcludePatterns {
    Param(
        [Parameter(Position=1, Mandatory=$False)]
        [AllowEmptyCollection()]
        [String[]] $Exclude,
        [Parameter(Position=2, Mandatory=$True)][Switch] $ClearDefaultExclude
    )

    $ExcludePatterns = @()

    If (-Not $ClearDefaultExclude) {
        $ExcludePatterns = @(
            'Thumbs.db',
            '.DS_Store',
            '.Spotlight-V100',
            '.Trashes'
        )
    }

    If ($Exclude) {
        ForEach ($Pattern in $Exclude) {
            $ExcludePatterns += $Pattern
        }
    }

    return $ExcludePatterns
}

Export-ModuleMember -Function *
