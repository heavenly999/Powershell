function ClearLogs{
    Remove-Item "C:\ops\logs\*"
}


function GetSecurityGroups($region){
    $groups=(Get-EC2SecurityGroup -Region $region)
    $date=$(get-date -format "MMddyyyy-hhmmtt").ToString()
    $FilePath="C:\ops\logs\"+$region+"-"+$date+".csv"
    $FilePath=$FilePath.ToString()
    $header="Group ID,Group Name,Group Description" | Out-file -FilePath $FilePath -Append

    foreach($group in $groups){
        $GroupDescription=$group.Description
        $GroupID=$group.GroupId
        $GroupName=$group.GroupName

        $info=$GroupID+","+$GroupName+","+$GroupDescription |  Out-File -FilePath $FilePath -Append
    }
}


GetSecurityGroups -region "eu-west-1"