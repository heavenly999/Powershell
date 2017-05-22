function CheckPath(){
    if((Test-Path C:\ops\logs\volumes\)  -match 'False'){
        Write-Host "Log folder doesn't exist, creating: C:\ops\logs\volumes"
        New-Item -Type directory "C:\ops\logs\volumes\" | Out-Null
    }
}

function ClearLogs{
    Write-Host "Clearing log folder"
    Remove-Item "C:\ops\logs\volumes\*"
}

function Get-VolumeInfo($region){
    Write-Host "Writing to Log folder: C:\ops\logs\volumes"
    $Volumes=(Get-EC2Volume -Region $region)

    $date=$(get-date -format "MMddyyyy-hhmmtt").ToString()
    $FilePath="C:\ops\logs\volumes\"+$region+"-"+$date+".csv"
    $FilePath=$FilePath.ToString()

    $header="VolumeId,Size,VolumeType,Status,InsatnaceID,InstanceName,SnapshotId,AvailabilityZone,CreateTime,Encrypted,Tags" | Out-file -FilePath $FilePath -Append

    foreach($vol in $Volumes){
        $Attachement=$Vol.attachment.instanceid

        #Getting the Instance ID and Instnace Name (if the export is slow and you don't need the instance name and ID, just comment out this section)
        $InstnaceName=(Get-EC2Instance -InstanceId $Attachement -Region $region).Instances
        $InstanceId=$InstnaceName.InstanceId
        $tags = $InstnaceName | Where-Object {$_.instanceId -eq $InstanceId} |select Tag
        $ServerName = $tags.Tag | Where-Object {$_.Key -eq "Name"} | select -ExpandProperty Value

        #Getting the Volume attributes
        $VolumeId=$Vol.VolumeId
        $Size=$Vol.Size
        $VolumeType=$Vol.VolumeType
        $SnapshotId=$Vol.SnapshotId
        $AvailabilityZone=$Vol.AvailabilityZone
        $CreateTime=$Vol.CreateTime
        $Encrypted=$Vol.Encrypted
        $Status=$Vol.Status
        $Tags=$Vol.Tag | Where-Object {$_.Key -eq "Name"} | select -ExpandProperty Value

        #Pushing the collected info to a csv file
        $info=$VolumeId+","+$Size+","+$VolumeType+","+$Status+","+$Attachement+","+$ServerName+","+$SnapshotId+","+$AvailabilityZone+","+$CreateTime+","+$Encrypted+","+$Tags | Out-File -FilePath $FilePath -Append
        }
}

Checkpath
ClearLogs
Get-VolumeInfo -region us-east-1