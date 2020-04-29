$GLOBAL:TestEnvironmentFolder = "TestDrive:\TestEnvironment"
$GLOBAL:InitialLocation = $Null

Function TestSetup {
    Import-Module $PSScriptRoot\ArchivematicaChecksum.psm1
    $GLOBAL:InitialLocation = Get-Location
    Set-Location 'TestDrive:\'
    New-Item -Path $GLOBAL:TestEnvironmentFolder -ItemType Directory
}

Function ResetState {
    Set-Location 'TestDrive:\'
    Remove-Item -Path $GLOBAL:TestEnvironmentFolder -Recurse -Force
    New-Item -Path $GLOBAL:TestEnvironmentFolder -ItemType Directory
}

Function TestTeardown {
    Set-Location $GLOBAL:InitialLocation
}

Describe 'System Tests' {
    TestSetup

    # Run system tests here

    TestTeardown
}
