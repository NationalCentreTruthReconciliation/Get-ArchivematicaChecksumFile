# Get-ArchivematicaChecksumFile
This is a PowerShell tool that can be used to generate a checksum file for an Archivematica transfer. This tool is specifically for generating a checksum file outside of the Archivematica system as per the Archivematica documentation [HERE](https://www.archivematica.org/en/docs/archivematica-1.11/user-manual/transfer/transfer/#transfer-checksums).

This tool can generate a checksum file using MD5, SHA1, SHA256, or SHA512 for a folder full of files. It can also generate a checksum file for nested directories using the `-Recurse` parameter.

## How to Install It

[First, make sure you have a PowerShell profile](https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_profiles?view=powershell-7#how-to-create-a-profile).

Download or clone this repository, and run the included `DeployModule.ps1` script in PowerShell with the command `.\DeployModule.ps1`. This copies the contents of the repository into your PowerShell Modules folder. You will also need to import the module in your PowerShell profile by adding the line `Import-Module ArchivematicaChecksum` to it. Without telling PowerShell to import it in your profile, the code will not be loaded when you launch PowerShell.

The deploy script will tell you which file you need to add the line to.
