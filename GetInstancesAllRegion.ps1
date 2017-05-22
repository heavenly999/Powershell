function CheckPath(){


if((Test-Path C:\ops\logs\instances\) -match 'False'){
        Write-Host "Log folder doesn't exist, creating: C:\ops\logs\instances"
        New-Item -Type directory "C:\ops\logs\instances\" | Out-Null
    }
}


function ClearLogs{
    Write-Host "Clearing log folder"
    Remove-Item "C:\ops\logs\instances\*"
}

function GetInstanceList($region){
Write-Host "Writing to Log folder: C:\ops\logs\instances"
    $instances = (Get-ec2instance -region $region).Instances

    $date=$(get-date -format "MMddyyyy-hhmmtt").ToString()
    $reg=$region.ToString()
    $FilePath="C:\ops\logs\instances\"+$region+"-"+$date+".csv"
    $FilePath=$FilePath.ToString()

    $header="Name,InstanceID,PrivateIP,PublicIP,Status,Volumes" | Out-file -FilePath $FilePath -Append


    foreach ($instance in $instances) {
        $BlockDeviceMappings=$instance.BlockDeviceMappings
        $VolumeID=foreach($volume in $BlockDeviceMappings){$volume.Ebs.VolumeId+";"}
        $InstanceStatus=$instance.State.Name
        $InstanceId=$instance.InstanceId
        $InstancePrivateIP=$instance.PrivateIpAddress
        $InstancePublicIP=$instance.PublicIpAddress
        $tags = $instance | Where-Object {$_.instanceId -eq $InstanceId} |select Tag
        $ServerName = $tags.Tag | Where-Object {$_.Key -eq "Name"} | select -ExpandProperty Value

        $info=$ServerName+","+$InstanceId+","+$InstancePrivateIP+","+$InstancePublicIP+","+$InstanceStatus+","+$VolumeID | Out-File -FilePath $FilePath -Append
        }
}


Checkpath
ClearLogs
GetInstanceList -region "eu-west-1"