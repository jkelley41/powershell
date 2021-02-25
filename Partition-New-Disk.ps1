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

# Clear selected disk
Write-Host "Clearing Disk..." -BackgroundColor DarkGreen
Get-Disk $diskSelection | Clear-Disk -RemoveData

# Initialize selected disk
Write-Host "Initializing Disk..." -BackgroundColor DarkGreen
Initialize-Disk -Number $diskSelection

# Create partition and format as NTFS
Write-Host "Partitioning and Formatting..." -BackgroundColor DarkGreen
New-Partition -DiskNumber $diskSelection -UseMaximumSize -DriveLetter $driveLetter| Format-Volume -FileSystem NTFS -NewFileSystemLabel $newFileSystemLabel

Write-Host "Done!" -BackgroundColor Green
# End of Script