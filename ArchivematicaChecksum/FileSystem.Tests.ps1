. $PSScriptRoot\FileSystem.ps1

Describe 'File System Unit Tests' -Tag 'Unit' {
    Context 'File okay to create or overwrite' {
        It 'Should return False if file exists' {
            Mock Test-Path { return $True }
            FileOkayToCreateOrOverwrite 'dummypath' | Should -BeFalse
        }

        It 'Should return True if file does not exist' {
            Mock Test-Path { return $False }
            FileOkayToCreateOrOverwrite 'dummypath' | Should -BeTrue
        }

        It 'Should return True if file exists and Force is True' {
            Mock Test-Path { return $True }
            FileOkayToCreateOrOverwrite 'dummypath' -Force | Should -BeTrue
        }
    }

    Context 'Create or overwrite file' {
        Mock New-Item { }
        Mock Clear-Content { }

        It 'Should create file if it does not exist' {
            Mock Test-Path { return $False }
            CreateOrOverWriteFile 'dummypath'
            Assert-MockCalled New-Item -ParameterFilter { $Path -eq 'dummypath' }
        }

        It 'Should clear files contents if it exists' {
            Mock Test-Path { return $True }
            CreateOrOverWriteFile 'dummypath'
            Assert-MockCalled Clear-Content -ParameterFilter { $Path -eq 'dummypath' }
        }
    }
}

Describe 'File System Integration Tests' -Tag 'Integration' {
    Context 'Create or overwrite file' {
        $File = Join-Path -Path $TestDrive -ChildPath 'test.txt'

        It 'Should create file if it does not exist' {
            CreateOrOverWriteFile -Path $File
            $File | Should -Exist
            Remove-Item $File -Force
        }

        It 'Should clear file contents if it exists' {
            New-Item -Path $File -ItemType File -Value 'test contents'
            CreateOrOverWriteFile -Path $File
            $File | Should -Exist
            Get-Content $File | Should -BeNullOrEmpty
            Remove-Item $File
        }

        It 'Should not create file if WhatIf is True' {
            CreateOrOverWriteFile -Path $File -WhatIf
            $File | Should -Not -Exist
        }

        It 'Should not clear file contents if WhatIf is True' {
            New-Item -Path $File -ItemType File -Value 'test contents'
            CreateOrOverWriteFile -Path $File -WhatIf
            $File | Should -Exist
            Get-Content $File | Should -BeExactly 'test contents'
        }
    }
}
