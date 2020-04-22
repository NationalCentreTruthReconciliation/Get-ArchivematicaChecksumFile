<#
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
 #>

$MODULE_NAME = "ArchivematicaChecksum"
$EXCLUDE_COPYING = @()

If (-Not (Test-Path $Profile -ErrorAction SilentlyContinue)) {
    Write-Host "Create a PowerShell profile first before deploying." -ForegroundColor Red
    Exit
}

$profileFolder = (Get-Item $Profile).Directory
$destinationFolder = Join-Path -Path $profileFolder -ChildPath "Modules\$($MODULE_NAME)"
$sourceFolder = Join-Path (Get-Item $PSScriptRoot) -ChildPath $MODULE_NAME
[String[]] $sourceFiles = @(Get-ChildItem -Recurse -File -Path $sourceFolder -Exclude $EXCLUDE_COPYING | ForEach-Object { $_.FullName })
[System.Collections.ArrayList] $existingDestinationFiles = @()
$existingDestinationFiles = @(Get-ChildItem -Recurse -File -Path $destinationFolder -Exclude $EXCLUDE_COPYING | ForEach-Object { $_.FullName })

If ($sourceFiles.Length -eq 0) {
    Write-Host "There are no files to copy from the module $MODULE_NAME!"
    Exit
}

If (-Not (Test-Path $destinationFolder -PathType Container -ErrorAction SilentlyContinue)) {
    New-Item $destinationFolder -ItemType Directory -Force | Out-Null
}

$filesUpdated = 0
$filesDeleted = 0
# Copy files if they are out of date or do not exist
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

$profileContents = Get-Content $Profile -Raw
If (-Not ($profileContents -Match $MODULE_NAME)) {
    Write-Host "`nWARNING: It appears that you have not imported $($MODULE_NAME) in your PowerShell profile." -ForegroundColor Yellow
    Write-Host "Add the following line to your PowerShell profile ($($Profile)):"
    Write-Host "Import-Module $($MODULE_NAME)"
}
