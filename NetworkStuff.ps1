$Username = "username"
$Password = ConvertTo-SecureString 'password' -AsPlainText -Force
$Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $Password

$comps=Get-Content -Path "C:\ops\comps.csv"

foreach ($c in $comps){
    $c | Out-File C:\ops\MTUlogs2.csv -Append

    Invoke-Command –ComputerName $c -Credential $Credential -ScriptBlock{
        netsh interface ipv4 show subinterface 
    } | Out-File C:\ops\MTUlogs2.csv -Append 
}



 