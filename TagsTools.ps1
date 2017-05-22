<#

If a Tag already exists, only the value will be rewritten.


#>


#Create a new tag With a certain value
$NewTag = Read-Host "Please enter the Tag name you want to add"
$Value = Read-Host "Please enter the Value for the tag"
(Get-EC2Instance <#-Filter @{name='tag:Type';values="Clone","clone"}#> -Region eu-west-1).Instances | ForEach-Object -Process {
    $OldTag= $_.Tags
    if($OldTag.Key.Contains("$NewTag")){
    Write-Host "the tag already exists"
    }else{
        Write-Host "doesn't exists"
        New-EC2Tag -Tag (New-Object -TypeName Amazon.EC2.Model.Tag -ArgumentList @("$NewTag", "$Value")) -Resource $PSItem.InstanceId -Region eu-west-1
    }
}
Write-Host "Tags added/changed" -ForegroundColor Yellow






#Clone tag values to a new tag
function CloneTagValues(){
    param($Region,$ToTag,$FromTag)    
    (Get-EC2Instance -Region $Region ).Instances  | ForEach-Object -Process {
        $OldValue= $_.Tags | Where-Object {$_.Key -eq "$FromTag"}
        $NewValue=$OldValue.Value
        Write-Host "Cloning "$OldValue.Value "from $FromTag to $ToTag"
        New-EC2Tag -Tag (New-Object -TypeName Amazon.EC2.Model.Tag -ArgumentList @("$ToTag", "$NewValue")) -Resource $PSItem.InstanceId -Region $Region
    }
}

function main(){
    $ToTag = Read-Host "Please enter the Tag name you want to create and copy to"
    $FromTag = Read-Host "Please enter the Tag name you want to copy from"
    CloneTagValues -Region us-east-1 -ToTag $ToTag -FromTag $FromTag
}

main




#Clone tag values to a new tag with check filter
function CloneTagFilter(){
    param($Region)
    $ToTag = "totag"
    $FromTag = "fromtag"
    $Match = "ifmatches"
    $NewValue="newvalue"
    (Get-EC2Instance -Region $Region).Instances | ForEach-Object -Process {
        $OldValue= $_.Tags | Where-Object {$_.Key -eq "$FromTag"}

        if(($OldValue.Value -eq "$Match")){      
            Write-Host "Cloning "$OldValue.Value "from $FromTag to $ToTag with new value $NewValue"
            New-EC2Tag -Tag (New-Object -TypeName Amazon.EC2.Model.Tag -ArgumentList @("$ToTag", "$NewValue")) -Resource $PSItem.InstanceId -Region $Region
        }else{
            Write-Host $OldValue.Value "is not $Match"
        }
    }
}

CloneTagFilter -Region us-east-1





#Removing tags
function DeleteTag(){
    param($Region,$Tag)
    (Get-EC2Instance -Region $Region).Instances | ForEach-Object -Process {
        Remove-EC2Tag -Tag $Tag -Resource $PSItem.InstanceId -Region $Region -Force
        $InstanceName=$PSItem.tag | Where-Object {$_.key -eq "Name"} | select -ExpandProperty Value
        $Message= "Tag $Tag was removed for $InstanceName "+"("+$PSItem.PrivateIPAddress+")" 
        Write-Host $Message
        $Message | Out-File C:\ops\logs\tags.csv -Append

    }
}

function main2(){
    $Tag = Read-Host "Please enter the Tag name you want to delete"

    DeleteTag -Region us-east-1 -Tag $Tag
}

main2