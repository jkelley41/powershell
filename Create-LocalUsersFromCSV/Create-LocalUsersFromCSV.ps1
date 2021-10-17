<# 
    Bulk create local Windows users from .csv
    
    Example CSV layout to be passed as $userFile
        UserName,FullName,Description,Password
        test, Test User,Test Account,Password1

    Written by: Jake Kelley
#>

##--------------------------------------------------------------------------
##    ELEVATE SCRIPT PRIVILEGES TO ADMINISTRATOR
##--------------------------------------------------------------------------
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))
{
  # Relaunch as an elevated process:
  Start-Process powershell.exe "-File",('"{0}"' -f $MyInvocation.MyCommand.Path) -Verb RunAs
  exit
}

# CSV file parameter
Param(
    [string]$userFile
)

if(-not($userFile)) {
    Throw "You must provide a file path for -userFile"
}
else {
    # Import CSV to $AllUsers
    $AllUsers = Import-CSV "$userFile"

    foreach ($User in $AllUsers)
          {
          write-host Creating user account $user.Username
          $objOU = [adsi]"WinNT://."
            # Create user account
          $objUser = $objOU.Create("User", $User.Username)
            # Set password
          $objuser.setPassword($User.Password)
            # Set FullName
          $objUser.put("FullName",$User.FullName)
            # Set Description
          $objUser.put("Description",$User.Description)
            # User must change password on next log on
          #$objuser.PasswordExpired = 0
          }
}
