$Username = "username"
$Password = ConvertTo-SecureString 'password' -AsPlainText -Force
$Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $Password

$Comps=Get-Content -Path "C:\ops\comps.csv"
foreach ($c in $Comps){
    if((Test-Connection -ErrorAction SilentlyContinue -ComputerName $c) -ne $null){
        Invoke-Command –ComputerName $c -Credential $Credential -ScriptBlock{
            Write-Host "hello"
        }    
    }else{"[CONERR] "+$c+" Couldn't connect "+"$(get-date -format `"MM/dd/yyyy hh:mm:ss`")" | Out-File "C:\ops\log.txt" -Append}
}



