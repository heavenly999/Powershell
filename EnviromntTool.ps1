$Username = "username"
$Password = ConvertTo-SecureString 'password' -AsPlainText -Force
$Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $Password
$comps=Get-Content -Path "C:\ops\comps.csv"

foreach ($c in $comps){
    Invoke-Command –ComputerName $c -Credential $Credential -ScriptBlock{
        New-Item -Path C:\Ops\logs -ItemType directory
        [Environment]::SetEnvironmentVariable("ENVNAME", “VALUE”, "MACHINE")
    }
}