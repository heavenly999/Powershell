function GetInfoByInstanceID(){
    param($InstanceID,$Region)
    $Instances=(Get-EC2Instance -InstanceId $InstanceID -Region $Region).Instances
    foreach($Instance in $Instances){
            New-Object -TypeName psobject -Property @{
            Name = $Instance.Tag | Where-Object {$_.Key -eq "Name"} | select -ExpandProperty  Value
            PrivateIP = $Instance.PrivateIpAddress
            PublicIP = $Instance.PublicIpAddress
        } | Sort-Object
    }
}


function GetInfoByPrivateIPAddress(){
    param($Region)

    return $Instances
}


function GetInfoByPublicIPAddress(){
    param($Region)

    return $Instances
}


function GetInfoByName(){
    param($Region)

    return $Instances
}


function GetInfoByHostname(){
    param($Region)

    return $Instances
}


function GetInfoByFQDN(){
    param($Region)

    return $Instances
}


function GetInfoByCustomerID(){
    param($Region)

    return $Instances
}







function Menu(){
    $Region="us-east-1"
    $Start={
        $Prompt="What info snippet you have:`n1. Instance ID`n2. Private IP Address`n3. Public IP Address`n4. Name snippet`n5. Hostname`n6. FQDN`n7. Customer ID`n8. Change region`n9. Exit"
        Write-Host "Current region is $Region"
        Write-Host $Prompt
        $Choice=Read-Host -Prompt "Enter your selection"        

        if($Choice -eq '1'){
            cls
            $Input=Read-Host -Prompt "Enter your string"
            GetInfoByInstanceID -InstanceID $Input -Region $Region
            .$Start
        }
        elseif($Choice -eq '2'){
            cls
            $Input=Read-Host -Prompt "Enter your string"
            GetInfoByPrivateIPAddress -PrivateIPAddress $Input -Region $Region
            .$Start
        }
        elseif($Choice -eq '3'){
            cls
            $Input=Read-Host -Prompt "Enter your string"
            GetInfoByPublicIPAddress -PublicIPAddress $Input -Region $Region
            .$Start
        }
        elseif($Choice -eq '4'){
            cls
            $Input=Read-Host -Prompt "Enter your string"
            GetInfoByName -Name $Input -Region $Region
            .$Start
        }
        elseif($Choice -eq '5'){
            cls
            $Input=Read-Host -Prompt "Enter your string"
            GetInfoByHostname -Hostname $Input -Region $Region
            .$Start
        }
        elseif($Choice -eq '6'){
            cls
            $Input=Read-Host -Prompt "Enter your string"
            GetInfoByFQDN -FQDN $Input -Region $Region
            .$Start
        }
        elseif($Choice -eq '7'){
            cls
            $Input=Read-Host -Prompt "Enter your string"
            GetInfoByCustomerID -CustomerID $Input -Region $Region
            .$Start
        }
        elseif($Choice -eq '7'){
            cls
            $Region=Read-Host -Prompt "Enter a region (eu-west-1, us-east-1, ap-southeast-2)"
            .$Start
        }
        elseif($Choice -eq '9'){
            $exit=$true
        }

        else {
            cls
            Write-Host "`nEnter a number from the options`n" -ForegroundColor Yellow
            .$Start
        }
    }
    &$Start
}

Menu