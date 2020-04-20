# Get-ArchivematicaChecksumFile
This is a PowerShell tool that can be used to generate a checksum file for an Archivematica transfer. This tool is specifically for generating a checksum file outside of the Archivematica system as per the Archivematica documentation [HERE](https://www.archivematica.org/en/docs/archivematica-1.11/user-manual/transfer/transfer/#transfer-checksums).

This tool can generate a checksum file using MD5, SHA1, SHA256, or SHA512 for a folder full of files. It can also generate a checksum file for nested directories using the `-Recurse` parameter.
