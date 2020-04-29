. $PSScriptRoot\Exclude.ps1

Describe 'Exclude tests' {
    Context 'Get exclude patterns' {
        It 'Returns Thumbs.db, .DS_Store, .Spotlight-V100 and .Trashes by default' {
            $Patterns = Get-ExcludePatterns
            $Patterns | Should -Contain 'Thumbs.db'
            $Patterns | Should -Contain '.DS_Store'
            $Patterns | Should -Contain '.Spotlight-V100'
            $Patterns | Should -Contain '.Trashes'
        }

        It 'Appends extra patterns to default list' {
            $Patterns = Get-ExcludePatterns @('pattern1', 'pattern2')
            $Patterns | Should -Contain 'Thumbs.db'
            $Patterns | Should -Contain '.DS_Store'
            $Patterns | Should -Contain '.Spotlight-V100'
            $Patterns | Should -Contain '.Trashes'
            $Patterns | Should -Contain 'pattern1'
            $Patterns | Should -Contain 'pattern2'
        }

        It 'Returns no patterns if none passed and ClearDefaultExclude is True' {
            $Patterns = Get-ExcludePatterns -ClearDefaultExclude
            $Patterns | Should -BeNullOrEmpty
        }

        It 'Returns only extra patterns if ClearDefaultExclude is True' {
            $Patterns = Get-ExcludePatterns @('pattern1', 'pattern2') -ClearDefaultExclude
            $Patterns | Should -Not -Contain 'Thumbs.db'
            $Patterns | Should -Not -Contain '.DS_Store'
            $Patterns | Should -Not -Contain '.Spotlight-V100'
            $Patterns | Should -Not -Contain '.Trashes'
            $Patterns | Should -Contain 'pattern1'
            $Patterns | Should -Contain 'pattern2'
        }
    }
}
