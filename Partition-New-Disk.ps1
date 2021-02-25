<#
    1. Prompts for disk selection, DriveLetter, and SystemLabel
    2. Cleans, partitions, formats disk with above parameters

    Note: Utilizes all space on disk and formats as NTFS
#>

# List disks to console
Get-Disk

# Prompt for disk selection
$diskSelection = Read-Host "Which disk would you like to modify: "

# Prompt for DriveLetter
$driveLetter = Read-Host "Enter capital drive letter, ex. 'B': "

# Prompt for NewFileSystemLabel
$newFileSystemLabel = Read-Host "Enter label for drive: "

# Initialize selected disk
Initialize-Disk -Number $diskSelection

# Clear selected disk
Get-Disk $diskSelection | Clear-Disk -RemoveData



# Create partition and format as NTFS
New-Partition -DiskNumber $diskSelection -UseMaximumSize -IsActive -DriveLetter $driveLetter | Format-Volume -FileSystem NTFS -NewFileSystemLabel $newFileSystemLabel

# End of Script