$Username = "username"
$Password = ConvertTo-SecureString 'password' -AsPlainText -Force
$Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $Password
    
    
$comps=Get-Content -Path "C:\ops\comps.csv"
foreach ($c in $comps){
    if((Test-WSMan -ErrorAction SilentlyContinue -ComputerName $c) -ne $null){
        Invoke-Command –ComputerName $c -Credential $Credential -ScriptBlock{
            New-Item -ItemType directory -Path C:\ops\logs -Force

            #Do not connect to WU internet locations
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DoNotConnectToWindowsUpdateInternetLocations" /D 1 /t reg_dword /f

            #Do not elevate non admins
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "ElevateNonAdmins" /D 0 /t reg_dword /f

            #Disable OS Upgrade
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "DisableOSUpgrade" /D 1 /t reg_dword /f

            # Target WSUS url
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "WUServer" /D "http://wsus.server.com:8530" /f

            # Target WSUS Reporting server
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" /v "WUStatusServer" /D "http://wsus.server.com:8530" /f

            #Schedule
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "ScheduledInstallDay" /D 0 /t reg_dword /f
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "ScheduledInstallDTime" /D 3 /t reg_dword /f

            #Auto update
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /D 0 /t reg_dword /f

            #No AU shutdown option
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAUShutdownOption" /D 1 /t reg_dword /f

            #Featured software 
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "EnableFeaturedSoftware" /D 1 /t reg_dword /f

            #Detection frequency
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "DetectionFrequency" /D 22 /t reg_dword /f
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "DetectionFrequencyEnabled" /D 1 /t reg_dword /f

            #Auto install minor updates
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AutoInstallMinorUpdates" /D 1 /t reg_dword /f

            #Always allow autoreboot at scheduled time
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AlwaysAutoRebootAtScheduledTime" /D 1 /t reg_dword /f
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AlwaysAutoRebootAtScheduledTimeMinutes" /D 15 /t reg_dword /f

            # Download Updates and Notify User
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "AUOptions" /D 4 /t reg_dword /f

            # Logged on user has option to reboot or not computer
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoRebootWithLoggedOnUsers" /D 1 /t reg_dword /f

            # Enable Automatic Windows Updates
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "NoAutoUpdate" /D 0 /t reg_dword /f

            # The WSUS Server is not used unless this key is set
            reg.exe add "HKLM\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" /v "UseWUServer" /D 1 /t reg_dword /f

            wuauclt.exe /resetauthorization /detectnow
            wuauclt.exe /reportnow /detectnow

            "[SUCCESS] "+$c+" WSUS registry successfully set "+"$(get-date -format `"MM/dd/yyyy hh:mm:ss`")" | Out-File "C:\ops\logs\WSUSRegSetLog.txt" -Append
        }
    }
    else{
        "[WINRMERR] "+$c+" WinRM is not enabled "+"$(get-date -format `"MM/dd/yyyy hh:mm:ss`")" | Out-File "C:\ops\logs\WSUSRegSetLog.txt" -Append
    }
}