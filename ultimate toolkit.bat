@echo off
setlocal
title Ultimate Toolkit V3
set "PS1=%TEMP%\UltimateToolkit_%RANDOM%%RANDOM%.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$f='%~f0'; $o='%PS1%'; $c=[IO.File]::ReadAllLines($f); $m=[Array]::IndexOf($c,':__POWERSHELL_PAYLOAD__'); if($m -lt 0){exit 2}; [IO.File]::WriteAllLines($o, $c[($m+1)..($c.Length-1)], (New-Object System.Text.UTF8Encoding($false)))"
if errorlevel 1 (
  echo Could not start the toolkit.
  pause
  exit /b 1
)
powershell -NoProfile -ExecutionPolicy Bypass -STA -File "%PS1%"
del "%PS1%" >nul 2>&1
exit /b

:__POWERSHELL_PAYLOAD__
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$script:Form = New-Object Windows.Forms.Form
$script:Form.Text = "Ultimate Toolkit V3 - By Bhaskar"
$script:Form.Size = New-Object Drawing.Size(1180,760)
$script:Form.MinimumSize = New-Object Drawing.Size(1000,650)
$script:Form.StartPosition = "CenterScreen"
$script:Form.BackColor = [Drawing.Color]::FromArgb(14,17,27)
$script:Form.ForeColor = [Drawing.Color]::White
$script:Form.Font = New-Object Drawing.Font("Segoe UI",9)

$script:nav = New-Object Windows.Forms.Panel
$script:nav.Dock = "Left"; $script:nav.Width = 245
$script:nav.BackColor = [Drawing.Color]::FromArgb(21,26,40)
$script:Form.Controls.Add($script:nav)

$script:main = New-Object Windows.Forms.Panel
$script:main.Dock = "Fill"; $script:main.BackColor = [Drawing.Color]::FromArgb(14,17,27)
$script:main.AutoScroll = $true
$script:Form.Controls.Add($script:main)

function New-Label($parent,$text,$x,$y,$w,$h,$size=10,$color='White',$bold=$false) {
    $l=New-Object Windows.Forms.Label
    $l.Text=$text; $l.Location=New-Object Drawing.Point($x,$y); $l.Size=New-Object Drawing.Size($w,$h)
    $l.ForeColor=[Drawing.Color]::FromName($color)
    $style=[Drawing.FontStyle]::Regular; if($bold){$style=[Drawing.FontStyle]::Bold}
    $l.Font=New-Object Drawing.Font("Segoe UI",$size,$style)
    $parent.Controls.Add($l); return $l
}
function New-Button($parent,$text,$x,$y,$w,$h,$action,$accent=$false) {
    $b=New-Object Windows.Forms.Button
    $b.Text=$text; $b.Location=New-Object Drawing.Point($x,$y); $b.Size=New-Object Drawing.Size($w,$h)
    $b.FlatStyle='Flat'; $b.FlatAppearance.BorderColor=[Drawing.Color]::FromArgb(62,72,96)
    $b.FlatAppearance.MouseOverBackColor=[Drawing.Color]::FromArgb(48,59,83)
    $b.BackColor= if($accent){[Drawing.Color]::FromArgb(76,105,220)}else{[Drawing.Color]::FromArgb(31,38,56)}
    $b.ForeColor='White'; $b.Cursor='Hand'; $b.Font=New-Object Drawing.Font("Segoe UI",9,[Drawing.FontStyle]::Bold)
    $b.Add_Click($action); $parent.Controls.Add($b); return $b
}
function Show-Output($title,$body) {
    $f=New-Object Windows.Forms.Form
    $f.Text=$title; $f.Size=New-Object Drawing.Size(850,600); $f.StartPosition='CenterParent'
    $f.BackColor=[Drawing.Color]::FromArgb(17,21,33); $f.ForeColor='White'
    $t=New-Object Windows.Forms.TextBox; $t.Multiline=$true; $t.ReadOnly=$true; $t.ScrollBars='Both'
    $t.WordWrap=$false; $t.Dock='Fill'; $t.BackColor=[Drawing.Color]::FromArgb(10,13,22)
    $t.ForeColor=[Drawing.Color]::FromArgb(205,220,240); $t.Font=New-Object Drawing.Font('Consolas',9)
    $t.Text=$body; $f.Controls.Add($t); [void]$f.ShowDialog($script:Form)
}
function Run-Command($title,$command) {
    $p=Start-Process -FilePath "$env:ComSpec" -ArgumentList "/c $command" -NoNewWindow -PassThru -Wait -RedirectStandardOutput "$env:TEMP\ut_out.txt" -RedirectStandardError "$env:TEMP\ut_err.txt"
    $out=Get-Content "$env:TEMP\ut_out.txt" -Raw -ErrorAction SilentlyContinue
    $err=Get-Content "$env:TEMP\ut_err.txt" -Raw -ErrorAction SilentlyContinue
    Show-Output $title (($out+"`r`n"+$err).Trim())
}
function Run-PowerShell($title,$command) {
    try { $result=Invoke-Expression $command 2>&1 | Out-String; Show-Output $title $result }
    catch { Show-Output $title $_.Exception.Message }
}
function Confirm-Admin {
    $admin=([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    if(-not $admin) { [Windows.Forms.MessageBox]::Show("This action needs Administrator privileges. Close the toolkit and choose Run as administrator.","Administrator required",'OK','Warning') | Out-Null; return $false }
    return $true
}
function Add-Action($panel,$caption,$description,$command,$kind='cmd',$needsAdmin=$false) {
    $y=$panel.Controls.Count * 78 + 8
    $card=New-Object Windows.Forms.Panel; $card.Location=New-Object Drawing.Point(22,$y); $card.Size=New-Object Drawing.Size(850,68)
    $card.BackColor=[Drawing.Color]::FromArgb(25,31,47); $panel.Controls.Add($card)
    New-Label $card $caption 14 8 270 22 10 'White' $true | Out-Null
    New-Label $card $description 14 32 600 26 8 'Silver' $false | Out-Null
    $act={ if($needsAdmin -and -not (Confirm-Admin)){return}; if($kind -eq 'ps'){Run-PowerShell $caption $command}else{Run-Command $caption $command} }.GetNewClosure()
    New-Button $card 'RUN' 700 15 120 38 $act $true | Out-Null
}
$script:modules = @(
@{N='System Administration';I='01';D='System details, processes and event logs';A=@(
@('System Information','Open the Windows system information utility','msinfo32.exe','cmd'),
@('System summary','View OS, BIOS, CPU and memory details','systeminfo','cmd'),
@('Running processes','List active processes and memory use','Get-Process | Sort-Object CPU -Descending | Select-Object -First 35 Name,Id,CPU,WorkingSet | Format-Table -AutoSize','ps'),
@('Event Viewer','Open Windows Event Viewer','eventvwr.msc','cmd'))},
@{N='Network & Internet';I='02';D='Connectivity, adapters and DNS tools';A=@(
@('IP configuration','Show IP addresses and network adapters','ipconfig /all','cmd'),
@('Ping test','Test connectivity to Cloudflare DNS','ping 1.1.1.1','cmd'),
@('DNS cache','Display cached DNS records','ipconfig /displaydns','cmd'),
@('Flush DNS','Clear the local DNS resolver cache','ipconfig /flushdns','cmd'),
@('Network connections','Show active TCP connections','netstat -ano','cmd'),
@('Network settings','Open Network Connections','ncpa.cpl','cmd'))},
@{N='Windows Repair';I='03';D='Built-in Windows diagnostics and repair';A=@(
@('System File Checker (SFC)','Scan and repair protected Windows system files','sfc /scannow','cmd',$true),
@('DISM health scan','Check Windows component store health','DISM /Online /Cleanup-Image /ScanHealth','cmd',$true),
@('DISM restore health','Repair the Windows component store (internet may be needed)','DISM /Online /Cleanup-Image /RestoreHealth','cmd',$true),
@('Disk check status','Check the system drive without scheduling repairs','chkdsk C:','cmd'))},
@{N='Security & Defender';I='04';D='Windows Security and protection status';A=@(
@('Windows Security','Open Windows Security dashboard','windowsdefender:','cmd'),
@('Defender status','Show Microsoft Defender status','Get-MpComputerStatus | Format-List AMServiceEnabled,AntivirusEnabled,RealTimeProtectionEnabled,AntivirusSignatureLastUpdated','ps'),
@('Firewall profiles','Show Windows Firewall profile status','Get-NetFirewallProfile | Format-Table Name,Enabled,DefaultInboundAction,DefaultOutboundAction -AutoSize','ps'),
@('Firewall settings','Open Windows Defender Firewall','firewall.cpl','cmd'))},
@{N='Performance';I='05';D='Startup, resource monitor and performance';A=@(
@('Task Manager','Open Task Manager','taskmgr.exe','cmd'),
@('Resource Monitor','Open detailed resource monitor','resmon.exe','cmd'),
@('Startup apps','Open startup apps settings','start ms-settings:startupapps','cmd'),
@('Power configuration','Show active power plan','powercfg /getactivescheme','cmd'))},
@{N='Storage & Disk';I='06';D='Disk management and storage information';A=@(
@('Disk Management','Open Disk Management console','diskmgmt.msc','cmd'),
@('Disk list','List physical disks and health information','Get-Disk | Format-Table Number,FriendlyName,HealthStatus,OperationalStatus,Size -AutoSize','ps'),
@('Volume list','Show drive letters and free space','Get-Volume | Format-Table DriveLetter,FileSystemLabel,FileSystem,Size,SizeRemaining -AutoSize','ps'),
@('Storage settings','Open Windows storage settings','start ms-settings:storagesense','cmd'))},
@{N='User & Accounts';I='07';D='Local accounts and account settings';A=@(
@('Local users','List local Windows accounts','Get-LocalUser | Format-Table Name,Enabled,LastLogon -AutoSize','ps'),
@('Current identity','Show current user and groups','whoami /all','cmd'),
@('User Accounts','Open classic User Accounts panel','netplwiz','cmd'),
@('Sign-in options','Open Windows sign-in settings','start ms-settings:signinoptions','cmd'))},
@{N='Backup & Restore';I='08';D='Windows recovery and backup utilities';A=@(
@('Recovery settings','Open Windows recovery settings','start ms-settings:recovery','cmd'),
@('System Protection','Open System Protection settings','SystemPropertiesProtection.exe','cmd'),
@('File History','Open File History control panel','control /name Microsoft.FileHistory','cmd'),
@('Backup status','Show Windows backup-related services','Get-Service VSS,SDRSVC,wbengine -ErrorAction SilentlyContinue | Format-Table Name,Status,StartType -AutoSize','ps'))},
@{N='Drive & Hardware';I='09';D='Device Manager and hardware inventory';A=@(
@('Device Manager','Open Device Manager','devmgmt.msc','cmd'),
@('Hardware devices','List present Plug and Play devices','Get-PnpDevice -PresentOnly | Select-Object -First 80 Status,Class,FriendlyName | Format-Table -Wrap','ps'),
@('DirectX Diagnostic','Open DirectX Diagnostic Tool','dxdiag.exe','cmd'),
@('System properties','Open advanced system properties','sysdm.cpl','cmd'))},
@{N='Windows Update';I='10';D='Update settings and update services';A=@(
@('Windows Update','Open Windows Update settings','start ms-settings:windowsupdate','cmd'),
@('Update history','Open installed update history','Get-HotFix | Sort-Object InstalledOn -Descending | Select-Object -First 25 | Format-Table HotFixID,Description,InstalledOn -AutoSize','ps'),
@('Update services','Show Windows Update service status','Get-Service wuauserv,bits,cryptsvc | Format-Table Name,Status,StartType -AutoSize','ps'))},
@{N='Office & Outlook';I='11';D='Office applications and mail settings';A=@(
@('Installed Office apps','Search common Office install locations','Get-ChildItem "$env:ProgramFiles\Microsoft Office","${env:ProgramFiles(x86)}\Microsoft Office" -ErrorAction SilentlyContinue | Select-Object FullName','ps'),
@('Mail settings','Open Mail profile settings if available','control mlcfg32.cpl','cmd'),
@('Default apps','Open default apps settings','start ms-settings:defaultapps','cmd'))},
@{N='Printer & Spooler';I='12';D='Printers, queues and print service';A=@(
@('Devices and Printers','Open printers and devices','control printers','cmd'),
@('Printer list','List installed printers','Get-Printer | Format-Table Name,DriverName,PortName,PrinterStatus -AutoSize','ps'),
@('Print queue','Show print spooler service status','Get-Service Spooler | Format-List Name,Status,StartType','ps'),
@('Restart print spooler','Restart the Windows print spooler service','Restart-Service Spooler -Force; Get-Service Spooler | Format-List Name,Status','ps',$true))},
@{N='Remote Access';I='13';D='Remote Desktop and assistance';A=@(
@('Remote Desktop settings','Open Remote Desktop settings','start ms-settings:remotedesktop','cmd'),
@('Remote Assistance','Open Remote Assistance','msra.exe','cmd'),
@('Computer name','Show hostname and domain information','hostname & echo. & whoami /fqdn','cmd'),
@('Remote Desktop status','Check Remote Desktop configuration','Get-ItemProperty "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name fDenyTSConnections | Format-List','ps'))},
@{N='BIOS / UEFI / Boot';I='14';D='Firmware details and boot configuration';A=@(
@('BIOS information','Show BIOS manufacturer, version and date','Get-CimInstance Win32_BIOS | Format-List Manufacturer,SMBIOSBIOSVersion,ReleaseDate,SerialNumber','ps'),
@('Boot configuration','Display boot configuration entries','bcdedit /enum','cmd'),
@('UEFI firmware settings','Request reboot to firmware settings (confirmation required)','shutdown /r /fw /t 60','cmd',$true))},
@{N='Registry & Group Policy';I='15';D='Policy tools and registry editor';A=@(
@('Registry Editor','Open Registry Editor','regedit.exe','cmd'),
@('Group Policy Editor','Open Local Group Policy Editor (Pro editions)','gpedit.msc','cmd'),
@('Applied policies','Show applied Group Policy summary','gpresult /r','cmd'),
@('Refresh policies','Refresh computer and user policies','gpupdate /force','cmd',$true))},
@{N='Windows Services';I='16';D='Inspect and manage Windows services';A=@(
@('Services console','Open Windows Services manager','services.msc','cmd'),
@('Running services','List running services','Get-Service | Where-Object Status -eq Running | Sort-Object DisplayName | Format-Table -AutoSize','ps'),
@('Stopped automatic services','Find stopped services configured for automatic start','Get-CimInstance Win32_Service | Where-Object {$_.StartMode -eq "Auto" -and $_.State -ne "Running"} | Select-Object Name,DisplayName,State | Format-Table -AutoSize','ps'))}
)

function Show-Module($module) {
    $script:main.Controls.Clear()
    New-Label $script:main ("[{0}]  {1}" -f $module.I,$module.N.ToUpper()) 28 22 850 42 22 'White' $true | Out-Null
    New-Label $script:main $module.D 30 68 850 28 10 'Silver' | Out-Null
    $p=New-Object Windows.Forms.Panel; $p.Location=New-Object Drawing.Point(20,110); $p.Size=New-Object Drawing.Size(900,580)
    $p.AutoScroll=$true; $p.BackColor=[Drawing.Color]::FromArgb(14,17,27); $script:main.Controls.Add($p)
    foreach($a in $module.A) {
        $admin=$false; if($a.Count -gt 4){$admin=[bool]$a[4]}
        Add-Action $p $a[0] $a[1] $a[2] $a[3] $admin
    }
}
function Show-Dashboard {
    $script:main.Controls.Clear()
    New-Label $script:main 'ULTIMATE TOOLKIT V3' 28 18 800 52 28 'White' $true | Out-Null
    New-Label $script:main 'Windows command center  |  Diagnostics, repair tools and system utilities' 30 68 850 28 10 'LightSteelBlue' | Out-Null
    $status=if([Environment]::OSVersion.Version){[Environment]::OSVersion.Version.ToString()}else{'Windows'}
    New-Label $script:main ("SYSTEM  •  {0}    USER  •  {1}" -f $status,$env:USERNAME) 30 102 850 24 9 'Silver' | Out-Null
    $x0=28; $y0=150; $w=205; $h=112; $gap=14
    for($i=0;$i -lt $script:modules.Count;$i++){
        $m=$script:modules[$i]; $col=$i%4; $row=[math]::Floor($i/4)
        $x=$x0+$col*($w+$gap); $y=$y0+$row*($h+$gap)
        $b=New-Object Windows.Forms.Button
        $b.Location=New-Object Drawing.Point($x,$y); $b.Size=New-Object Drawing.Size($w,$h)
        $b.Text=("["+$m.I+"]`r`n"+$m.N.ToUpper())
        $b.TextAlign='MiddleLeft'; $b.Padding=New-Object Windows.Forms.Padding(14,8,8,8)
        $b.FlatStyle='Flat'; $b.FlatAppearance.BorderColor=[Drawing.Color]::FromArgb(63,73,99)
        $b.BackColor=[Drawing.Color]::FromArgb(27,34,51); $b.ForeColor='White'
        $b.Font=New-Object Drawing.Font('Segoe UI',11,[Drawing.FontStyle]::Bold)
        $b.Cursor='Hand'; $mod=$m
        $b.Add_Click({Show-Module $mod}.GetNewClosure())
        $script:main.Controls.Add($b)
    }
    New-Label $script:main 'Tip: Run as administrator for repair and system-management actions.' 30 670 850 25 9 'LightSteelBlue' | Out-Null
}
New-Label $script:nav 'ULTIMATE' 22 22 200 35 20 'White' $true | Out-Null
New-Label $script:nav 'TOOLKIT  V3' 22 55 200 30 16 'LightSteelBlue' $true | Out-Null
New-Label $script:nav 'BY BHASKAR' 24 88 190 22 8 'Silver' $true | Out-Null
$navItems=@(
@('Dashboard / Main Menu',{Show-Dashboard}),
@('One Click Actions',{Show-Module $script:modules[2]}),
@('System Inventory',{Show-Module $script:modules[0]}),
@('All Modules',{Show-Dashboard}),
@('Open CMD Toolkit',{Start-Process cmd.exe})
)
$ny=145
foreach($item in $navItems){
    $action=$item[1]
    New-Button $script:nav $item[0] 14 $ny 215 48 $action | Out-Null
    $ny+=60
}
New-Label $script:nav 'TOOLS' 22 470 180 25 9 'LightSteelBlue' $true | Out-Null
New-Button $script:nav 'Control Panel' 14 505 215 42 {Start-Process control.exe} | Out-Null
New-Button $script:nav 'PowerShell' 14 555 215 42 {Start-Process powershell.exe} | Out-Null
New-Button $script:nav 'Exit Toolkit' 14 620 215 42 {$script:Form.Close()} | Out-Null
Show-Dashboard
[void]$script:Form.ShowDialog()
