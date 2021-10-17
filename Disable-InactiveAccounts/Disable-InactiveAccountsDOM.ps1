﻿<#
    Disable-InactiveAccountsDOM.ps1
    Last modified by Jake Kelley 11NOV2020
#>

<# Set msDS-LogonTimeSyncInterval (days) to '1'.
        By default lastLogonDate only replicates between DCs every 9-14 
        days unless this attribute is set to a shorter interval.

   Logs actions to:
        - EventID 9090, 9091
        - $inactiveScanCSV = "C:\ADMIN\Inactive_Scan\InactiveUsers_$(Get-Date -Format MM-dd-yyyy_HHmm).csv"
        - $neverLoggedInCSV = "C:\ADMIN\NeverLoggedIn_Scan\InactiveUsers_$(Get-Date -Format MM-dd-yyyy_HHmm).csv"
 
   Remove "-WhatIf" flags if you want the script to disable rather than no-op.
#> 


#----------------------------
# VARIABLES
#---------------------------- 
$activityThreshold = 90
$daysInactive=(Get-Date).AddDays(-($activityThreshold))
$inactiveScanCSV = "C:\ADMIN\Inactive_Scan\InactiveUsers_$(Get-Date -Format MM-dd-yyyy_HHmm).csv"
$neverLoggedInCSV = "C:\ADMIN\NeverLoggedIn_Scan\InactiveUsers_$(Get-Date -Format MM-dd-yyyy_HHmm).csv"

$exclusions = "WDAGUtilityAccount", "DefaultAccount", "administrator"


#----------------------------
# FIND INACTIVE USERS
#---------------------------- 
Import-Module ActiveDirectory
$inactiveUsers = Get-ADUser -Filter {Enabled -eq $TRUE} -Properties lastLogonDate, whenCreated, distinguishedName | Where-Object {($_.lastLogonDate -lt $daysInactive) -and ($_.lastLogonDate -ne $NULL) -and ($_.Name -notin $exclusions)}
$inactiveUsers | Format-Table -Property SamAccountName, lastLogonDate, Enabled, whenCreated -AutoSize | Out-File $inactiveScanCSV
$neverLoggedInUsers = Get-ADUser -Filter {Enabled -eq $TRUE} -Properties lastLogonDate, whenCreated, distinguishedName | Where-Object {($_.whenCreated -lt $daysInactive) -and ($_.lastLogonDate -eq $NULL) -and ($_.Name -notin $exclusions)}
$neverLoggedInUsers | Format-Table -Property SamAccountName, lastLogonDate, Enabled, whenCreated -AutoSize | Out-File $neverLoggedInCSV 


#----------------------------
# REPORTING
#----------------------------
# Check if event log exists
$logExists = [System.Diagnostics.EventLog]::SourceExists("Disable-InactiveAccountsDOM.ps1")
if($logExists -eq $false){
    New-EventLog -Source "Disable-InactiveAccountsDOM.ps1" -LogName Application
}


#----------------------------
# INACTIVE USER MANAGEMENT
#----------------------------
# INACTIVE USERS - Identify and disable users who have not logged in in x days
 $inactiveUsers | ForEach-Object {
   Disable-ADAccount $_ -WhatIf
   Write-Host "Disabling $_.Name"
   Write-EventLog -Source "Disable-InactiveAccountsDOM.ps1" -EventId 9090 -LogName Application -Message "Disabled user $_ because the last login was more than $activityThreshold ago."
   }

# NEVER LOGGED IN - Identify and disable users who were created x days ago and never logged in
 $neverLoggedInUsers | ForEach-Object {
   Disable-ADAccount $_ -WhatIf
   Write-Host "Disabling $_.Name"
   Write-EventLog -Source "Disable-InactiveAccountsDOM.ps1" -EventId 9091 -LogName Application -Message "Disabled user $_ because user has never logged in and $activityThreshold days have passed."
   }
