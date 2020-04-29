$Global:InitialLocation = $Null

Function Get-TestEnvironFolder {
    If ($Null -ne $TestDrive) {
        return Join-Path $TestDrive 'TestEnvironmentFolder'
    }
    Else {
        throw 'TestDrive is NULL, are you sure you''re calling this function in a Describe or Context block?'
    }
}

Function TestSetup {
    Import-Module $PSScriptRoot\ArchivematicaChecksum.psm1
    $Global:InitialLocation = Get-Location
}

Function PreTest {
    $TestFolder = Get-TestEnvironFolder
    If (Test-Path $TestFolder -ErrorAction SilentlyContinue) {
        Remove-Item $TestFolder -Recurse -Force
    }
    New-Item -Path $TestFolder -ItemType Directory
    Set-Location $TestDrive
}

Function TestTeardown {
    Set-Location $Global:InitialLocation
}

Describe 'System Tests' {
    TestSetup

    # Run system tests here
    Context 'Creating checksum files. No recursion' {
        It 'Should create checksums for files in a folder' {
            PreTest

            $TestFolder = Get-TestEnvironFolder
            $File1 = Join-Path $TestFolder 'file1.txt'
            $File2 = Join-Path $TestFolder 'file2.txt'
            New-Item -Path $File1 -ItemType File -Value 'test test test' -Force
            New-Item -Path $File2 -ItemType File -Value 'testing testing testing' -Force
            $File1MD5Checksum = (Get-FileHash $File1 -Algorithm MD5).Hash.ToLower()
            $File2MD5Checksum = (Get-FileHash $File2 -Algorithm MD5).Hash.ToLower()

            Get-ArchivematicaChecksumFile -Folder $TestFolder -Algorithm 'MD5'

            $GeneratedChecksumFile = Join-Path $TestFolder '\metadata\checksum.md5'
            Test-Path -Path $GeneratedChecksumFile -PathType Leaf | Should -Be $True
            $ChecksumsContents = (Get-Content $GeneratedChecksumFile -Raw)
            $ChecksumsContents | Should -Match $File1MD5Checksum
            $ChecksumsContents | Should -Match $File2MD5Checksum
        }

        It 'Should not create checksums for files in subfolders' {
            PreTest

            $TestFolder = Get-TestEnvironFolder
            $File1 = Join-Path $TestFolder 'file1.txt'
            $File2 = Join-Path $TestFolder 'folder_a\file2.txt'
            New-Item -Path $File1 -ItemType File -Value 'test test test' -Force
            New-Item -Path $File2 -ItemType File -Value 'testing testing testing' -Force
            $File1MD5Checksum = (Get-FileHash $File1 -Algorithm MD5).Hash.ToLower()
            $File2MD5Checksum = (Get-FileHash $File2 -Algorithm MD5).Hash.ToLower()

            Get-ArchivematicaChecksumFile -Folder $TestFolder -Algorithm 'MD5'

            $GeneratedChecksumFile = Join-Path $TestFolder '\metadata\checksum.md5'
            Test-Path -Path $GeneratedChecksumFile -PathType Leaf | Should -Be $True
            $ChecksumsContents = (Get-Content $GeneratedChecksumFile -Raw)
            $ChecksumsContents | Should -Match $File1MD5Checksum
            $ChecksumsContents | Should -Not -Match $File2MD5Checksum
        }

        It 'Should not create checksum file if there are no files in the target folder' {
            PreTest

            $TestFolder = Get-TestEnvironFolder
            $File1 = Join-Path $TestFolder 'folder_a\file1.txt'
            $File2 = Join-Path $TestFolder 'folder_b\file2.txt'
            New-Item -Path $File1 -ItemType File -Value 'test test test' -Force
            New-Item -Path $File2 -ItemType File -Value 'testing testing testing' -Force

            Get-ArchivematicaChecksumFile -Folder $TestFolder -Algorithm 'MD5'

            $GeneratedChecksumFile = Join-Path $TestFolder '\metadata\checksum.md5'
            Test-Path -Path $GeneratedChecksumFile -PathType Leaf | Should -Be $False
        }
    }

    Context 'Creating checksum files. With recursion' {
        It 'Should create checksums for files in target folder and subfolders' {
            PreTest

            $TestFolder = Get-TestEnvironFolder
            $File1 = Join-Path $TestFolder 'file1.txt'
            $File2 = Join-Path $TestFolder 'folder_a\file2.txt'
            $File3 = Join-Path $TestFolder 'folder_a\folder_b\file3.txt'
            New-Item -Path $File1 -ItemType File -Value 'test test test' -Force
            New-Item -Path $File2 -ItemType File -Value 'testing testing testing' -Force
            New-Item -Path $File3 -ItemType File -Value 't t t' -Force
            $File1SHA1Checksum = (Get-FileHash $File1 -Algorithm SHA1).Hash.ToLower()
            $File2SHA1Checksum = (Get-FileHash $File2 -Algorithm SHA1).Hash.ToLower()
            $File3SHA1Checksum = (Get-FileHash $File2 -Algorithm SHA1).Hash.ToLower()

            Get-ArchivematicaChecksumFile -Folder $TestFolder -Algorithm SHA1 -Recurse

            $GeneratedChecksumFile = Join-Path $TestFolder '\metadata\checksum.sha1'
            Test-Path -Path $GeneratedChecksumFile -PathType Leaf | Should -Be $True
            $ChecksumsContents = (Get-Content $GeneratedChecksumFile -Raw)
            $ChecksumsContents | Should -Match $File1SHA1Checksum
            $ChecksumsContents | Should -Match $File2SHA1Checksum
            $ChecksumsContents | Should -Match $File3SHA1Checksum
        }

        It 'Should create checksums for files if there are none in target folder but some in subfolders' {
            PreTest

            $TestFolder = Get-TestEnvironFolder
            $File1 = Join-Path $TestFolder 'folder_a\file2.txt'
            $File2 = Join-Path $TestFolder 'folder_a\folder_b\file3.txt'
            $File3 = Join-Path $TestFolder 'folder_a\folder_b\folder_c\file3.txt'
            New-Item -Path $File1 -ItemType File -Value 'test test test' -Force
            New-Item -Path $File2 -ItemType File -Value 'testing testing testing' -Force
            New-Item -Path $File3 -ItemType File -Value 't t t' -Force
            $File1SHA1Checksum = (Get-FileHash $File1 -Algorithm SHA1).Hash.ToLower()
            $File2SHA1Checksum = (Get-FileHash $File2 -Algorithm SHA1).Hash.ToLower()
            $File3SHA1Checksum = (Get-FileHash $File2 -Algorithm SHA1).Hash.ToLower()

            Get-ArchivematicaChecksumFile -Folder $TestFolder -Algorithm SHA1 -Recurse

            $GeneratedChecksumFile = Join-Path $TestFolder '\metadata\checksum.sha1'
            Test-Path -Path $GeneratedChecksumFile -PathType Leaf | Should -Be $True
            $ChecksumsContents = (Get-Content $GeneratedChecksumFile -Raw)
            $ChecksumsContents | Should -Match $File1SHA1Checksum
            $ChecksumsContents | Should -Match $File2SHA1Checksum
            $ChecksumsContents | Should -Match $File3SHA1Checksum
        }

        It 'Should not create checksum file if there are no files in target folder or subdirectories' {
            PreTest

            $TestFolder = Get-TestEnvironFolder
            New-Item -Path (Join-Path $TestFolder 'folder_a') -ItemType Directory -Force
            New-Item -Path (Join-Path $TestFolder 'folder_a\folder_b') -ItemType Directory -Force

            Get-ArchivematicaChecksumFile -Folder $TestFolder -Algorithm SHA1 -Recurse

            $GeneratedChecksumFile = Join-Path $TestFolder '\metadata\checksum.sha1'
            Test-Path -Path $GeneratedChecksumFile -PathType Leaf | Should -Be $False
        }
    }

    Context 'Testing format of checksum file' {
        It 'Should write file with \n line endings, not \r\n line endings' {

        }

        It 'Should not write file with a Byte-Order-Marker' {

        }
    }

    TestTeardown
}
