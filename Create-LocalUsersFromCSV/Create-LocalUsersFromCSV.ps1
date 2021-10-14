<# example CSV layout to be passed as $userFile
UserName,FullName,Description,Password
test, Test User,Test Account,Password1

Written by: Jake Kelley
#>

$strComputer=$env:computername

Param
    (
    [string]$userFile
    )

if(-not($userFile)) 
    {
    Throw "You must provide a file path for -userFile"
    }

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