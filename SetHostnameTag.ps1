$Username = "username"
$Password = ConvertTo-SecureString 'password' -AsPlainText -Force
$Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $Password
$Date=$(get-date -format "MMddyyyy-hhmmtt").ToString()
$LogName = "Hostname_"+$date+".txt"
$LogPath = "C:\ops\logs\AutomatedTags\"
$Log = $LogPath+$LogName

function CheckPath(){
    if((Test-Path $LogPath) -match 'False'){
    Write-Host "Log folder doesn't exist, creating: $LogPath"
    New-Item -Type directory $LogPath
    $null | Out-File "C:\ops\logs\AutomatedTags\ErrorDump.txt"
    }
}

function GetRemoteHostname(){
    param($IP,$Credential)
    if((Test-Connection -Count 1 -Quiet -ComputerName $IP) -eq $true){
        Invoke-Command -ComputerName $IP -Credential $Credential -ScriptBlock {
            return $env:COMPUTERNAME
        }
    }else{        
        return $false
    }
}

function LogAndConsole($Message,$Color){
    if($Color -ne $null){
        Write-Host $Message -ForegroundColor $Color
        $Message | Out-File -FilePath $Log.ToString() -Append
    }else{
       Write-Host $Message
       $Message | Out-File -FilePath $Log.ToString() -Append 
    }
}

function AddHostnameTag (){
    param($Region)  
    $NoIP=$null
    $Tag = "Hostname"
    $Instances=(Get-EC2Instance -Region $region -Filter @(@{name='instance-state-name';values="running"})).Instances 
    foreach($Instance in $Instances){  
        $Error.Clear()
        $IP = $Instance.PrivateIpAddress
        if($IP -eq $null){
            LogAndConsole -Message "The Instance $InstanceID doesn't have a Private IP (most probably stopped)" -Color yellow
        }else{
            $Hostname=GetRemoteHostname -IP $IP -Credential $Credential

            if($Hostname -ne $false){

                $OldValue= $Instance.Tags | Where-Object {$_.Key -eq "$Tag"}

                if($OldValue.Value -eq $Hostname){
                    if($Error){
                        LogAndConsole -Message "$IP There was an error during the connection. no data retrieved (Check C:\ops\logs\AutomatedTags\ErrorDump.txt)" -Color red
                        foreach($Err in $Error){
                        $Err | Out-File "C:\ops\logs\AutomatedTags\ErrorDump.txt" -Append
                        }
                    }else{
                    LogAndConsole -Message "$IP The Hostname is up to date"}
                                
                }else{
                    if($Hostname -eq $null -or $false -or ""){
                        LogAndConsole -Message "$IP Couldn't retrieve hostname"
                    }else{
                        $Old=$OldValue.Value
                        LogAndConsole -Message "$IP Changing from $Old to $Hostname"
                        New-EC2Tag -Tag (New-Object -TypeName Amazon.EC2.Model.Tag -ArgumentList @("$Tag", "$Hostname")) -Resource $Instance.InstanceId -Region $Region
                    }
                }
            }else{
               LogAndConsole -Message "Couldn't reach $IP"
            }
        }
    }
    LogAndConsole -Message "Tags added/changed" -Color yellow
}

function main(){
    CheckPath  
    AddHostnameTag -Region us-east-1
}

main