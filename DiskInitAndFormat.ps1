$Username = "username"
$Password = ConvertTo-SecureString 'password' -AsPlainText -Force
$Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $Password
$comps=Get-Content -Path "C:\ops\comps.csv"


foreach ($c in $comps){
    Invoke-Command –ComputerName $c -Credential $Credential -ScriptBlock{
    $drives = gwmi Win32_diskdrive
    $scriptdisk = $Null
    $script = $Null
    foreach ($disk in $drives){
        if ($disk.Partitions -eq "0"){
            $drivenumber = $disk.DeviceID -replace '[\\\\\.\\physicaldrive]',''        

$script = @"
select disk $drivenumber
online disk noerr
attributes disk clear readonly noerr
create partition primary noerr
format quick fs=ntfs
assign letter="L"
"@
        }
        $drivenumber = $Null
        $scriptdisk += $script + "`n"
    }
    $scriptdisk | diskpart
    }
}