<#
    Generate-Baseline.ps1
    Last Updated by Jake Kelley 11/24/2020
    Compiles hardware and software present in system for hardware/software baselines
#>

##--------------------------------------------------------------------------
##    Variables
##--------------------------------------------------------------------------

# Where to export the baseline.html
$htmlPath = "C:\ADMIN\baseline.html"

# Get Machine Hostname and set as variable
$hostname = Get-Content env:computername

# Date in format(YYYY_MM_DD)
$Date = "(" + (Get-Date -Format MM-dd-yyyy) + ")"

# Classification of the report - default unclassified for collateral systems
$classification = "UNCLASSIFIED"

# Color of the banner in the report - green for UNCLASSIFIED
$color = "green"





##--------------------------------------------------------------------------
##    HTML/CSS Styles
##--------------------------------------------------------------------------

# HTML Banner - Classification & Hostname & Date & Classification
$header = @"
<header style="position: sticky; top: 0; padding: 5px; background: $color; text-align:center; font-size: 20px; font-family: Courier, monospace; font-weight: bold; ">
    $classification - $hostname - $Date - $classification
</header>
"@

# HTML Heading - Processor
$h1 = @" 
<h3 style="text-align:left;font-family:Courier;color:#000000;padding-top:1%">Processor</h3>
"@

# HTML Heading - Motherboard
$h2 = @" 
<h3 style="text-align:left;font-family:Courier;color:#000000;padding-top:1%">Motherboard</h3>
"@

# HTML Heading - RAM
$h3 = @" 
<h3 style="text-align:left;font-family:Courier;color:#000000;padding-top:1%">Memory (Capacity in Bytes)</h3>
"@

# HTML Heading - Disk Drives
$h4 = @" 
<h3 style="text-align:left;font-family:Courier;color:#000000;padding-top:1%">Disk Drives (Capacity in Bytes)</h3>
"@

# HTML Heading - System Information
$h5 = @" 
<h3 style="text-align:left;font-family:Courier;color:#000000;">System Information</h3>
"@

# HTML Heading - Installed Software
$h6 = @" 
<h3 style="text-align:left;font-family:Courier;color:#000000;padding-top:2%">Installed Software</h3>
"@

# HTML Table/Body Formatting
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

# HTML Footer - Classification & Hostname & Date & Classification
$footer = @"
<footer style="position: sticky; bottom: 0; padding: 5px; background: $color; text-align:center; font-size: 20px; font-family: Courier, monospace; font-weight: bold;">
    $classification - $hostname - $Date - $classification
</footer>
"@





##--------------------------------------------------------------------------
##    System Information Query
##--------------------------------------------------------------------------

$sysinfo = get-computerinfo | 
ConvertTo-Html -Property CsName, CsDomain, CsDomainRole, OSLastBootUpTime, WindowsProductName, WindowsVersion -Body $body





##--------------------------------------------------------------------------
##    Hardware Baseline Query
##--------------------------------------------------------------------------

# Hardware information query variables
$cpu = Get-CimInstance -ClassName Win32_Processor | ConvertTo-Html -Property DeviceID, Name -Body $body

$motherboard = Get-CimInstance -ClassName Win32_Baseboard | ConvertTo-Html -Property Manufacturer, Model, SerialNumber -Body $body

$raminfo = Get-CimInstance -ClassName Win32_PhysicalMemory | ConvertTo-Html -Property DeviceLocator, Manufacturer, Capacity, SerialNumber -Body $body

# MAY NOT PROPERLY DETECT NVME SSD >> RESEARCH METHOD FOR CORRECT DETECTION
$storage = Get-CimInstance -ClassName Win32_DiskDrive | ConvertTo-Html -Property Manufacturer, Caption, Model, Size, Partitions, SerialNumber -Body $body





##--------------------------------------------------------------------------
##    Software Baseline Query
##--------------------------------------------------------------------------
# Software Exclusions to leave out of the report
$sw1 = "*Update for Microsoft*"
$sw2 = "*Update for Skype*"
$sw3 = "*MUI*"
$sw4 = "*Office 32-bit Components*"
$sw5 = "*Visual C++*"
$sw6 = "*English*"
$sw7 = "*Français*"
$sw8 = "*español*"
$sw9 = "*Office Proofing*"

# Software information query variables - two location queries to gather all the software installed
$hklm1 = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | 
Where-Object -Property DisplayName -NE $null | 
Where-Object -Property DisplayName -notlike $sw1 |
Where-Object -Property DisplayName -notlike $sw2 |
Where-Object -Property DisplayName -notlike $sw3 |
Where-Object -Property DisplayName -notlike $sw4 |
Where-Object -Property DisplayName -notlike $sw5 |
Where-Object -Property DisplayName -notlike $sw6 |
Where-Object -Property DisplayName -notlike $sw7 |
Where-Object -Property DisplayName -notlike $sw8 |
Where-Object -Property DisplayName -notlike $sw9

$hklm2 = Get-ItemProperty HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\* | 
Where-Object -Property DisplayName -NE $null | 
Where-Object -Property DisplayName -notlike $sw1 |
Where-Object -Property DisplayName -notlike $sw2 |
Where-Object -Property DisplayName -notlike $sw3 |
Where-Object -Property DisplayName -notlike $sw4 | 
Where-Object -Property DisplayName -notlike $sw5 |
Where-Object -Property DisplayName -notlike $sw6 |
Where-Object -Property DisplayName -notlike $sw7 |
Where-Object -Property DisplayName -notlike $sw8 |
Where-Object -Property DisplayName -notlike $sw9

# Combine the two location queries
$values = $hklm1 + $hklm2  | 
ConvertTo-HTML -Property DisplayName, DisplayVersion, Publisher -body $body





##--------------------------------------------------------------------------
##    Create and Launch HTML Report
##--------------------------------------------------------------------------

ConvertTo-Html -head $header -Body ($h5+$sysinfo + $h1+$cpu + $h2+$motherboard + $h3+$raminfo + $h4+$storage + $h6+$values) -PostContent $footer | 
Out-File $htmlPath

# Open generated HTML for review
&$htmlPath
