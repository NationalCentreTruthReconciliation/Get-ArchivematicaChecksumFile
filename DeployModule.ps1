<###############################################################################
 # Purpose: Deploys the module to the user's PowerShell modules in their
 # Documents.
 #
 # It checks to see if the file contents are different before overwriting
 # the outdated files using MD5 hashes. If there are extra files in the
 # corresponding modules folder in the user's Documents, these are removed.
 #
 # If you want to use this script for a different PowerShell module, you
 # simply would need to change $MODULE_NAME and put the script one level
 # above the module you want to copy to the documents folder.
 ##############################################################################>

Param(
    [Switch] $CreateProfile,
    [Switch] $AutoAddImport
)

$MODULE_NAME = "ArchivematicaChecksum" # Change if you want to use this for another module!
$EXCLUDE_COPYING = @()

# Check the existence of the user's PowerShell profile
If (-Not (Test-Path $Profile -ErrorAction SilentlyContinue)) {
    If ($CreateProfile) {
        New-Item -Path $Profile -ItemType File -Force | Out-Null
        If (-Not (Test-Path $Profile -ErrorAction SilentlyContinue)) {
            $Msg = ("Failed to create a new profile at $Profile for you. You will need to " +
                    'create it manually before installing. Visit this link for more info:' +
                    "`nhttps://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7#how-to-create-a-profile")
            Write-Host $Msg -ForegroundColor Red
            Exit
        }
        Else {
            Write-Host "Created a new PowerShell profile for you at $Profile."
        }
    }
    Else {
        $Msg = ('You must create a PowerShell profile before installing. This script can create ' +
                'it for you if you use the -CreateProfile option. If you prefer to create it ' +
                'manually, see this link for instructions:' +
                "`nhttps://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7#how-to-create-a-profile")
        Write-Host $Msg
        Exit
    }
}

# Get the source module folder and the destination module folder
$destinationModulesFolder = Join-Path -Path (Get-Item $Profile).Directory -ChildPath "Modules"
$destinationFolder = Join-Path -Path $destinationModulesFolder -ChildPath $MODULE_NAME
$sourceFolder = Join-Path (Get-Item $PSScriptRoot) -ChildPath $MODULE_NAME

# Create source module folders if necessary
If (-Not (Test-Path $destinationModulesFolder -PathType Container -ErrorAction SilentlyContinue)) {
    New-Item -Path $destinationModulesFolder -ItemType Directory -Force | Out-Null
}
If (-Not (Test-Path $destinationFolder -PathType Container -ErrorAction SilentlyContinue)) {
    New-Item $destinationFolder -ItemType Directory -Force | Out-Null
}

# Get files from source and destination module folders
[String[]] $sourceFiles = @(Get-ChildItem -Recurse -File -Path $sourceFolder -Exclude $EXCLUDE_COPYING | ForEach-Object { $_.FullName })
[System.Collections.ArrayList] $existingDestinationFiles = @()
$existingDestinationFiles = @(Get-ChildItem -Recurse -File -Path $destinationFolder -Exclude $EXCLUDE_COPYING | ForEach-Object { $_.FullName })

If ($sourceFiles.Length -eq 0) {
    Write-Host "There are no files to copy from the module $MODULE_NAME!"
    Exit
}

# Copy files if they are out of date or do not exist
$filesUpdated = 0
$filesDeleted = 0
ForEach ($sourceFile in $sourceFiles) {
    $destinationFile = $sourceFile.Replace($sourceFolder, $destinationFolder)

    If (-Not ($existingDestinationFiles.Contains($destinationFile))) {
        Write-Host "Creating $destinationFile"
        Copy-Item -Path $sourceFile -Destination $destinationFile -Force
        $filesUpdated += 1
    }
    Else {
        $existingDestinationFiles.Remove($destinationFile)
        $destinationFileHash = (Get-FileHash -Path $destinationFile -Algorithm MD5).Hash
        $sourceFileHash = (Get-FileHash -Path $sourceFile -Algorithm MD5).Hash

        If ($destinationFileHash -ne $sourceFileHash) {
            Write-Host "Updating $destinationFile"
            Copy-Item -Path $sourceFile -Destination $destinationFile -Force
            $filesUpdated += 1
        }
    }
}

# Delete any files without a mirror in the source module
ForEach ($remainingDestinationFile in $existingDestinationFiles) {
    Write-Host "Deleting $remainingDestinationFile"
    Remove-Item $remainingDestinationFile -Force
    $filesDeleted += 1
}

# Automatically unblock main module file
$mainModule = "$destinationFolder\$($MODULE_NAME).psm1"
If (Test-Path -Path $mainModule -PathType Leaf -ErrorAction SilentlyContinue) {
    Unblock-File $mainModule
}

Write-Host "All changes deployed."
Write-Host "$($filesUpdated) Files updated."

If ($filesDeleted -gt 0) {
    Write-Host "$($filesDeleted) Files deleted."
}

# Check for Import-Module statement in the profile, add it if -AutoAddImport is used
$profileContents = Get-Content $Profile -Raw
If (-Not ($profileContents -Match $MODULE_NAME)) {
    If ($AutoAddImport) {
        $profileContentsWithNewImport = "$profileContents`r`nImport-Module $MODULE_NAME"
        [System.IO.File]::WriteAllText((Resolve-Path $profile), $profileContentsWithNewImport)
        Write-Host "`nWrote `"Import-Module $MODULE_NAME`" to your profile."
    }
    Else {
        Write-Host "`nIt appears that you have not imported $($MODULE_NAME) in your PowerShell profile." -ForegroundColor Yellow
        Write-Host "Use the -AutoAddImport option or manually add the following line to your PowerShell profile ($($Profile)):"
        Write-Host "`nImport-Module $MODULE_NAME"
    }
}
