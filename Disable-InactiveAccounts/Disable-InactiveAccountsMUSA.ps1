<#
    Disable-InactiveAccountsMUSA.ps1
    Last modified by Jake Kelley 11DEC2020

    Checks for accounts inactive for longer
    than $activityThreshold, disables       
    respective accounts, creates event log,
    and outputs HTML log to $htmlPath
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


##--------------------------------------------------------------------------
##    VARIABLES
##--------------------------------------------------------------------------
# Set the number of days allowed ($activityThreshold) since last logon
$activityThreshold = 90
# Set account $exclusions to ignore. Excluded accounts will not be disabled.
$exclusions = "WDAGUtilityAccount", "DefaultAccount", "administrator"
# Query to check date
$daysInactive = (Get-Date).AddDays(-($ActivityThreshold))
$body = @"
<style>
TABLE {
    border-width: 2px;
    border-style: solid;
    border-color: black;
    border-collapse: collapse;
    width: 100%;
}
tr:nth-child(odd) {
    background-color: #DCDCDC;
}
TH {
    background-color: SteelBlue;
    text-align: left;
    border-width: 1px;
    padding: 3px;
    border-style: solid;
    border-color: black;
    font-family: Courier;
}
TD {
    text-align: left;
    border-width: 1px;
    padding: 8px;
    border-style: solid;
    border-color: black;
}
</style>
"@
$htmlPath = "C:\Admin\InactiveUsers\InactiveUsers_$(Get-Date -Format MM-dd-yyyy_HHmm).html"


##--------------------------------------------------------------------------
##    FIND INACTIVE USERS
##--------------------------------------------------------------------------
# Get Local Users that haven't logged on in xx days and are not Service Accounts, write to CSV log
$inactiveUsers = Get-LocalUser | 
Where-Object -FilterScript {$_.LastLogon -lt $daysInactive -and $_.Enabled} | 
Select-Object Name, LastLogon | 
Where-Object {$_.Name -notin $exclusions}

$inactiveUsers | 
ConvertTo-Html -Property SamAccountName, lastLogonDate, Enabled, whenCreated -Body $body | 
Out-File $htmlPath


##--------------------------------------------------------------------------
##    REPORTING
##--------------------------------------------------------------------------
# Check if event log exists
$logExists = [System.Diagnostics.EventLog]::SourceExists("Disable-InactiveAccountsMUSA.ps1")
if($logExists -eq $false){
    New-EventLog -Source "Disable-InactiveAccountsMUSA.ps1" -LogName Application
}


##--------------------------------------------------------------------------
##    INACTIVE USER MANAGEMENT
##--------------------------------------------------------------------------
# Disable inactive users and write EventID 9091 to Application log
$inactiveUsers | ForEach-Object {
    Disable-LocalUser $_.Name
    Write-EventLog -Source "Disable-InactiveAccountsMUSA.ps1" -EventId 9091 -LogName Application -Message "Disabled user $_ due to inactivity passing the $activityThreshold day threshold"
}
