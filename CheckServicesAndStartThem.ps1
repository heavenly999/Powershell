$Username = "username"
$Password = ConvertTo-SecureString 'password' -AsPlainText -Force
$Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $Password
$comps=Get-Content -Path "C:\ops\comps.csv"

foreach ($c in $comps){
    Write-Host $c
    Invoke-Command –ComputerName $c -Credential $Credential -ScriptBlock{
        function Get-ServiceLogonAccount {
            [cmdletbinding()]
            param (
                $ComputerName = $env:computername,
                $LogonAccount
            )            

            if($logonAccount){
                $stopped = Get-WmiObject -Class Win32_Service -ComputerName $ComputerName | ? { $_.StartName -match $LogonAccount } | Where-Object {$_.State -eq "Stopped"} | select DisplayName, StartName | Format-Table
                $stopped
                Start-Service -DisplayName "servicename1", "servicename2"
            }
            else{
                Get-WmiObject -Class Win32_Service -ComputerName $ComputerName | select DisplayName, StartName, State
            } 
        }
        Get-ServiceLogonAccount -LogonAccount accountname
    }
}
