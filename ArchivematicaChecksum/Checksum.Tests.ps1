. $PSScriptRoot\Checksum.ps1

Describe 'Checksum Unit Tests' -Tag 'Unit' {
    Context 'Checksum file path generation' {
        It 'Should create checksum.md5 file is Algorithm is MD5' {
            $Path = Get-ChecksumFilePath '.' 'MD5'
            $Path | Should -Match 'checksum\.md5$'
        }

        It 'Should create checksum.sha1 file if Algorithm is SHA1' {
            $Path = Get-ChecksumFilePath '.' 'SHA1'
            $Path | Should -Match 'checksum\.sha1$'
        }

        It 'Should create checksum.sha256 file if Algorithm is SHA256' {
            $Path = Get-ChecksumFilePath '.' 'SHA256'
            $Path | Should -Match 'checksum\.sha256$'
        }

        It 'Should create checksum.sha1 file if Algorithm is SHA512' {
            $Path = Get-ChecksumFilePath '.' 'SHA512'
            $Path | Should -Match 'checksum\.sha512$'
        }

        It 'Should join the Folder with a metadata folder' {
            $Path = Get-ChecksumFilePath 'folder' 'MD5'
            $Path | Should -Match '^folder\\metadata\\.+$'
        }

        It 'Should have path containing the folder, a metadata folder, and a checksum file' {
            $Path = Get-ChecksumFilePath '.' 'MD5'
            $Path | Should -BeExactly '.\metadata\checksum.md5'
        }

        It 'Should return path correctly if folder is parent of the current one' {
            $Path = Get-ChecksumFilePath '..' 'MD5'
            $Path | Should -BeExactly '..\metadata\checksum.md5'
        }

        It 'Should return path correctly if folder is grandparent of the current one' {
            $Path = Get-ChecksumFilePath '..\..\' 'MD5'
            $Path | Should -BeExactly '..\..\metadata\checksum.md5'
        }

        It 'Should change Unix-like "/" path separators to Windows "\" separators' {
            $Path = Get-ChecksumFilePath './folder1/folder2/' 'MD5'
            $Path | Should -BeExactly '.\folder1\folder2\metadata\checksum.md5'
        }
    }

    Context 'Checksum calculation' {
        Mock Get-FileHash { return [PSCustomObject]@{ Hash='MD5MD5' } } -ParameterFilter { $Algorithm -eq 'MD5' }
        Mock Get-FileHash { return [PSCustomObject]@{ Hash='SHA1SHA1' } } -ParameterFilter { $Algorithm -eq 'SHA1' }
        Mock Get-FileHash { return [PSCustomObject]@{ Hash='SHA256SHA256' } } -ParameterFilter { $Algorithm -eq 'SHA256' }
        Mock Get-FileHash { return [PSCustomObject]@{ Hash='SHA512SHA512' } } -ParameterFilter { $Algorithm -eq 'SHA512' }
        Mock Resolve-Path { return [PSCustomObject]@{ Path='C:\folder' } } -ParameterFilter { $Path -eq 'folder' }
        Mock Resolve-Path { return [PSCustomObject]@{ Path="C:\folder\$Path" } } -ParameterFilter { $Path -ne 'folder' }

        It 'Should return lowercase MD5 checksum if Algorithm is MD5' {
            $Checksum = Get-ChecksumsForFiles 'folder' 'testfile' 'MD5'
            $Checksum | Should -Match '^md5md5.+$'
        }

        It 'Should return lowercase SHA1 hash if Algorithm is SHA1' {
            $Checksum = Get-ChecksumsForFiles 'folder' 'test' 'SHA1'
            $Checksum | Should -Match '^sha1sha1.+$'
        }

        It 'Should return lowercase SHA256 hash if Algorithm is SHA256' {
            $Checksum = Get-ChecksumsForFiles 'folder' 'test' 'SHA256'
            $Checksum | Should -Match '^sha256sha256.+$'
        }

        It 'Should return lowercase SHA512 hash if Algorithm is SHA512' {
            $Checksum = Get-ChecksumsForFiles 'folder' 'test' 'SHA512'
            $Checksum | Should -Match '^sha512sha512.+$'
        }

        It 'Should return checksum and filename separated by two spaces' {
            $Checksum = Get-ChecksumsForFiles 'folder' @(,'testfile') 'MD5'
            $Checksum | Should -BeExactly 'md5md5  testfile'
        }

        It 'Should not escape spaces in filenames' {
            $Checksum = Get-ChecksumsForFiles 'folder' @('this is  a   test.txt') 'MD5'
            $Checksum | Should -BeExactly 'md5md5  this is  a   test.txt'
        }

        It 'Should calculate checksums for multiple files' {
            $Checksums = Get-ChecksumsForFiles 'folder' @('file1', 'file2', 'file3', 'file4') 'SHA1'
            $Checksums | Should -HaveCount 4
            $Checksums[0] | Should -BeExactly 'sha1sha1  file1'
            $Checksums[1] | Should -BeExactly 'sha1sha1  file2'
            $Checksums[2] | Should -BeExactly 'sha1sha1  file3'
            $Checksums[3] | Should -BeExactly 'sha1sha1  file4'
        }

        It 'Should return Unix-like "/" path separators for files in subdirectories' {
            $Checksums = Get-ChecksumsForFiles 'folder' @('TestFolder\File_1.txt', 'TestFolder\FooFolder\File_2.txt') 'SHA256'
            $Checksums | Should -HaveCount 2
            $Checksums[0] | Should -BeExactly 'sha256sha256  TestFolder/File_1.txt'
            $Checksums[1] | Should -BeExactly 'sha256sha256  TestFolder/FooFolder/File_2.txt'
        }

        It 'Should not have multiple "\" path separators if folder resolves with trailing "\"' {
            Mock Resolve-Path { return [PSCustomObject]@{ Path='C:\folder\' } } -ParameterFilter { $Path -eq 'folder' }
            $Checksums = Get-ChecksumsForFiles 'folder' @('file1.txt', 'TestFolder\file2.txt') 'SHA512'
            $Checksums | Should -HaveCount 2
            $Checksums[0] | Should -BeExactly 'sha512sha512  file1.txt'
            $Checksums[1] | Should -BeExactly 'sha512sha512  TestFolder/file2.txt'
        }
    }
}

Describe 'Checksum Integration Tests' -Tag 'Integration' {
    $File1 = Join-Path -Path $TestDrive -ChildPath 'file_1.txt'
    $File2 = Join-Path -Path $TestDrive -ChildPath 'file 2.txt'
    $File3 = Join-Path -Path $TestDrive -ChildPath 'folder\file 3.txt'
    New-Item -Path $File1 -ItemType File -Value 'test test test' -Force | Out-Null
    New-Item -Path $File2 -ItemType File -Value 'testing testing testing' -Force | Out-Null
    New-Item -Path $File3 -ItemType File -Value 't t t' -Force | Out-Null

    Context 'Checksum calculation' {
        It 'Should calculate the correct MD5 checksums for each file' {
            $Checksums = Get-ChecksumsForFiles -Folder $TestDrive -FilesToChecksum @($File1, $File2, $File3) -Algorithm MD5
            $JoinedChecksums = $Checksums -Join "`n"
            $JoinedChecksums | Should -Match "$((Get-FileHash -Path $File1 -Algorithm MD5).Hash.ToLower())  file_1.txt"
            $JoinedChecksums | Should -Match "$((Get-FileHash -Path $File2 -Algorithm MD5).Hash.ToLower())  file 2.txt"
            $JoinedChecksums | Should -Match "$((Get-FileHash -Path $File3 -Algorithm MD5).Hash.ToLower())  folder/file 3.txt"
        }
    }
}
