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

    Context 'Get files' {
        Mock Get-ChildItem { return @('file_A', 'file_B') } -ParameterFilter { $Recurse -ne $True }
        Mock Get-ChildItem { return @('file_1', 'folder\file_2') } -ParameterFilter { $Recurse -eq $True }

        It 'Should not get files recursively if Recurse if False' {
            $files = Get-Files -Folder 'folder' -ExcludePatterns @()

            $files | Should -HaveCount 2
            $files[0] | Should -BeExactly 'file_A'
            $files[1] | Should -BeExactly 'file_B'
            Assert-MockCalled Get-ChildItem -ParameterFilter { $Recurse -ne $True }
        }

        It 'Should recursively get files if Recurse is True' {
            $files = Get-Files -Folder 'folder' -Recurse -ExcludePatterns @()

            $files | Should -HaveCount 2
            $files[0] | Should -BeExactly 'file_1'
            $files[1] | Should -BeExactly 'folder\file_2'
            Assert-MockCalled Get-ChildItem -ParameterFilter { $Recurse -eq $True }
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

    Context 'Get files, files present in target folder' {
        $File1 = Join-Path -Path $TestDrive -ChildPath 'first.jpg'
        $File2 = Join-Path -Path $TestDrive -ChildPath 'second.txt'
        $File3 = Join-Path -Path $TestDrive -ChildPath 'Thumbs.db'
        $Folder = Join-Path -Path $TestDrive -ChildPath 'folder'
        $File4 = Join-Path -Path $Folder -ChildPath 'third.jpg'
        $File5 = Join-Path -Path $Folder -ChildPath 'fourth.txt'
        $File6 = Join-Path -Path $Folder -ChildPath '.DS_Store'
        New-Item -Path $Folder -ItemType Directory | Out-Null
        New-Item -Path $File1 -Value '111111' -Force | Out-Null
        New-Item -Path $File2 -Value '222222' -Force | Out-Null
        New-Item -Path $File3 -Value '333333' -Force | Out-Null
        New-Item -Path $File4 -Value '444444' -Force | Out-Null
        New-Item -Path $File5 -Value '555555' -Force | Out-Null
        New-Item -Path $File6 -Value '666666' -Force | Out-Null

        It 'Should not get files in subfolders if Recurse is False' {
            $Files = (Get-Files -Folder $TestDrive -ExcludePatterns @()) -Join "`n"
            $Files | Should -Match 'first.jpg'
            $Files | Should -Match 'second.txt'
            $Files | Should -Match 'Thumbs.db'
        }

        It 'Should not get files excluded by pattern when Recurse is False' {
            $Files = (Get-Files -Folder $TestDrive -ExcludePatterns @('Thumbs.db', '*.txt')) -Join "`n"
            $Files | Should -Match 'first.jpg'
            $Files | Should -Not -Match 'second.txt'
            $Files | Should -Not -Match 'Thumbs.db'
        }

        It 'Should get files in subfolder if Recurse is True' {
            $Files = (Get-Files -Folder $TestDrive -Recurse -ExcludePatterns @()) -Join "`n"
            $Files | Should -Match 'first.jpg'
            $Files | Should -Match 'second.txt'
            $Files | Should -Match 'Thumbs.db'
            $Files | Should -Match 'third.jpg'
            $Files | Should -Match 'fourth.txt'
            $Files | Should -Match '.DS_Store'
        }

        It 'Should not get files excluded by pattern when Recurse is True' {
            $Files = (Get-Files -Folder $TestDrive -Recurse -ExcludePatterns @('first*', '*.db', '*.txt')) -Join "`n"
            $Files | Should -Not -Match 'first.jpg'
            $Files | Should -Not -Match 'second.txt'
            $Files | Should -Not -Match 'Thumbs.db'
            $Files | Should -Match 'third.jpg'
            $Files | Should -Not -Match 'fourth.txt'
            $Files | Should -Match '.DS_Store'
        }
    }

    Context 'Get files, no files in main folder' {
        $FirstFolder = (Join-Path -Path $TestDrive -ChildPath 'folder1')
        $File1 = Join-Path -Path $FirstFolder -ChildPath 'first.jpg'
        $File2 = Join-Path -Path $FirstFolder -ChildPath 'second.txt'
        $File3 = Join-Path -Path $FirstFolder -ChildPath 'Thumbs.db'
        $SecondFolder = Join-Path -Path $FirstFolder -ChildPath 'folder2'
        $File4 = Join-Path -Path $SecondFolder -ChildPath 'third.txt'
        $File5 = Join-Path -Path $SecondFolder -ChildPath 'fourth.txt'
        $File6 = Join-Path -Path $SecondFolder -ChildPath '.DS_Store'
        New-Item -Path $FirstFolder -ItemType Directory | Out-Null
        New-Item -Path $SecondFolder -ItemType Directory | Out-Null
        New-Item -Path $File1 -Value '111111' -Force | Out-Null
        New-Item -Path $File2 -Value '222222' -Force | Out-Null
        New-Item -Path $File3 -Value '333333' -Force | Out-Null
        New-Item -Path $File4 -Value '444444' -Force | Out-Null
        New-Item -Path $File5 -Value '555555' -Force | Out-Null
        New-Item -Path $File6 -Value '666666' -Force | Out-Null

        It 'Should not find any files if Recurse is False' {
            $Files = (Get-Files -Folder $TestDrive -ExcludePatterns @()) -Join "`n"
            $Files | Should -BeNullOrEmpty
        }

        It 'Should get files in subfolder if Recurse is True' {
            $Files = (Get-Files -Folder $TestDrive -Recurse -ExcludePatterns @()) -Join "`n"
            $Files | Should -Match 'first.jpg'
            $Files | Should -Match 'second.txt'
            $Files | Should -Match 'Thumbs.db'
            $Files | Should -Match 'third.txt'
            $Files | Should -Match 'fourth.txt'
            $Files | Should -Match '.DS_Store'
        }

        It 'Should not get files excluded by pattern when Recurse is True' {
            $Files = (Get-Files -Folder $TestDrive -Recurse -ExcludePatterns @('*.jpg', '.DS_Store', '*.db')) -Join "`n"
            $Files | Should -Not -Match 'first.jpg'
            $Files | Should -Match 'second.txt'
            $Files | Should -Not -Match 'Thumbs.db'
            $Files | Should -Match 'third.txt'
            $Files | Should -Match 'fourth.txt'
            $Files | Should -Not -Match '.DS_Store'
        }
    }
}
