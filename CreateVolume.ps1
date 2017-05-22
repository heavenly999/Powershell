#VolumeTypes: gp2;io1;sc1;st1;standard
#Regions:
#ap-northeast-1 Asia Pacific (Tokyo)
#ap-northeast-2 Asia Pacific (Seoul)
#ap-south-1     Asia Pacific (Mumbai)
#ap-southeast-1 Asia Pacific (Singapore)
#ap-southeast-2 Asia Pacific (Sydney)
#ca-central-1   Canada (Central)
#eu-central-1   EU Central (Frankfurt)
#eu-west-1      EU West (Ireland)
#eu-west-2      EU West (London)
#sa-east-1      South America (Sao Paulo)
#us-east-1      US East (Virginia)
#us-east-2      US East (Ohio)
#us-west-1      US West (N. California)
#us-west-2      US West (Oregon)


function CreateVolume($region,$type,$size,$count){
    $date=$(get-date -format "MMddyyyy-hhmmtt").ToString()
    $reg=$region.ToString()
    $FilePath="C:\ops\logs\Volumes_"+$region+"-"+$date+".csv"
    $FilePath=$FilePath.ToString()

    Start-Transcript -Path $FilePath -Append
    for($i=1; $i -le $count; $i++){
        New-EC2Volume -AvailabilityZone $region -VolumeType $type -Size $size
    }
    Stop-Transcript
}

CreateVolume -region "ap-southeast-2" -type "standard" -size "30" -count "1"