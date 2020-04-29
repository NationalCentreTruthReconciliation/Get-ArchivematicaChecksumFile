$GLOBAL:TestEnvironmentFolder = "$PSScriptRoot\TestEnvironment"
$GLOBAL:InitialLocation = $Null

Function TestSetup {
    Import-Module $PSScriptRoot\ArchivematicaChecksum.psm1
    $GLOBAL:InitialLocation = Get-Location
    New-Item -Path $GLOBAL:TestEnvironmentFolder -ItemType Directory
}

Function TestTeardown {
    Set-Location $GLOBAL:InitialLocation
    Remove-Item -Path $GLOBAL:TestEnvironmentFolder -Recurse -Force
}

Describe 'System Tests' {
    TestSetup

    # Run system tests here

    TestTeardown
}
