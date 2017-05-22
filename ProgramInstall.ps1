$Username = "username"
$Password = ConvertTo-SecureString 'password' -AsPlainText -Force
$Global:Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $Password
$Global:LogPath="C:\ops\logs\ProgramInstall\"
$Global:LogFileName="WorkingIPs.csv"
$Global:FullLogPath=$LogPath+$LogFileName
$Global:Tempo=$LogPath+"Tempo\"

Function GetRemoteProgram {
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(ValueFromPipeline              =$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0
        )]
        [string[]]
            $ComputerName = $env:COMPUTERNAME,
        [Parameter(Position=0)]
        [string[]]
            $Property,
        [switch]
            $ExcludeSimilar,
        [int]
            $SimilarWord
    )

    begin {
        $RegistryLocation = 'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\',
                            'SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\'
        $HashProperty = @{}
        $SelectProperty = @('ProgramName','ComputerName')
        if ($Property) {
            $SelectProperty += $Property
        }
    }

    process {
        foreach ($Computer in $ComputerName) {
            $RegBase = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::LocalMachine,$Computer)
            $RegistryLocation | ForEach-Object {
                $CurrentReg = $_
                if ($RegBase) {
                    $CurrentRegKey = $RegBase.OpenSubKey($CurrentReg)
                    if ($CurrentRegKey) {
                        $CurrentRegKey.GetSubKeyNames() | ForEach-Object {
                            if ($Property) {
                                foreach ($CurrentProperty in $Property) {
                                    $HashProperty.$CurrentProperty = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue($CurrentProperty)
                                }
                            }
                            $HashProperty.ComputerName = $Computer
                            $HashProperty.ProgramName = ($DisplayName = ($RegBase.OpenSubKey("$CurrentReg$_")).GetValue('DisplayName'))
                            if ($DisplayName) {
                                New-Object -TypeName PSCustomObject -Property $HashProperty |
                                Select-Object -Property $SelectProperty
                            } 
                        }
                    }
                }
            } | ForEach-Object -Begin {
                if ($SimilarWord) {
                    $Regex = [regex]"(^(.+?\s){$SimilarWord}).*$|(.*)"
                } else {
                    $Regex = [regex]"(^(.+?\s){3}).*$|(.*)"
                }
                [System.Collections.ArrayList]$Array = @()
            } -Process {
                if ($ExcludeSimilar) {
                    $null = $Array.Add($_)
                } else {
                    $_
                }
            } -End {
                if ($ExcludeSimilar) {
                    $Array | Select-Object -Property *,@{
                        name       = 'GroupedName'
                        expression = {
                            ($_.ProgramName -split $Regex)[1]
                        }
                    } |
                    Group-Object -Property 'GroupedName' | ForEach-Object {
                        $_.Group[0] | Select-Object -Property * -ExcludeProperty GroupedName
                    }
                }
            }
        }
    }
}

function CheckLogDir(){
    if ((Test-Path $LogPath) -ne $true){New-Item -ItemType directory -Path $LogPath}
    if ((Test-Path $Tempo) -ne $true){New-Item -ItemType directory -Path $Tempo}
}

function ClearLogDir(){
    $FullLogPath | ForEach-Object {$null | Out-File $_.ToString()}
}

function ClearTempo(){
    $Remove=$Tempo+"*"
    Remove-Item -Path $Remove    
}

function GetAllInstances(){
    $AllInstances= $null
    $AllInstances= (Get-ec2instance -region "us-east-1" -Filter @( @{name='instance-state-name';values="running"})).Instances
    $AllInstances+= (Get-ec2instance -region "eu-west-1" -Filter @( @{name='instance-state-name';values="running"})).Instances
    return $AllInstances
}

function GetAllInstancesIP(){
    $header='IP' | Out-File $FullLogPath
    $InstancesIP=$null
    Write-Host "Writing the IPs to "$FullLogPath

    foreach($Instance in (GetAllInstances)){
        $Instance.PrivateIPAddress | Out-File $FullLogPath -Append
    }
}

function GetWorkingIPs(){
    Write-Host "Reading the IPs from "$FullLogPath
    $WorkingIPs=Import-Csv $FullLogPath

    return $WorkingIPs
}

function GetProgramDetailsLocal(){
    param(
            [Parameter(mandatory=$true)]
            [string]$ProgramName
    )
    $Programs=GetRemoteProgram -Property Uninstallstring
    foreach($Program in $Programs){
        if($Program.ProgramName -like "*$ProgramName*"){
            $UninstallString=$Program.Uninstallstring
            $ProgramName=$Program.ProgramName
        }
    } 
    return $ProgramName,$UninstallString
}

function GetProgramDetails(){
    param(
            [Parameter(mandatory=$true)]
            $CollectedIP,
            $ProgramNameLocal
    )
    $function1 = "function GetProgramDetailsLocal { ${function:GetProgramDetailsLocal} }"
    $function2 = "function GetRemoteProgram { ${function:GetRemoteProgram} }"
        Invoke-Command -ComputerName $CollectedIP -Credential $Credential -ArgumentList $function1,$function2,$programNameLocal -ScriptBlock{
            param($function1,$function2,$programNameLocal)

            . ([ScriptBlock]::Create($function1))
            . ([ScriptBlock]::Create($function2))

            $Program=GetProgramDetailsLocal -ProgramName $programNameLocal
            return $Program[0],$Program[1]            
        }
}

function GetFilesFromServer(){
    param(
            [Parameter(mandatory=$true)]
            $URLs
    )
    $Remove=($URLs.Count)-1
    $URLs=$URLs | Where-Object { $_ -ne $URLs[$Remove]}

    foreach($FileURL in $URLs){
        Write-Host "Pulling the file from $FileURL to $Tempo"
        $FileName=$FileURL.Split('/')
        $OutFile=$Tempo+$FileName[($FileName.Count)-1]
        Invoke-WebRequest -Uri $FileURL -OutFile $OutFile
    }
}

function main1(){    
    ClearLogDir

    if(($Choice=Read-Host -Prompt "Enter 'y' if you want to proceed with all instances or enter an IP for one instance") -eq "y"){
        GetAllInstancesIP
        cls
    }else{
        $header='IP' | Out-File $FullLogPath
        $Choice | Out-File $FullLogPath -Append
        cls
    }

}

function main2(){
    $MainStart={
        $CurrentIPBlock=Import-csv $FullLogPath

        $Prompt="Please select what dou you want to do:`n1. Uninstall a program for all machines from the collected Instance IPs`n2. Install a program for all machines from the collected Instance IPs`n3. Exit"
        Write-Host $Prompt
        $Choice=Read-Host -Prompt "Enter your selection"
        if($Choice -eq '1'){
            cls            
            $ProgramNameRead=Read-Host "Please enter the program name (or a part of it) which you want to uninstall"
            $IP=$null            
                foreach($InstanceIP in $CurrentIPBlock){
                    $IP+=$InstanceIP.IP.ToString()+"`n"
                }                        
            Write-Host "The $ProgramNameRead details will be gathered from the following machines:`n$IP"  
            $AllMachines=$null      
            Start-Transcript -Path "$LogPath\UninstallTranscript.txt"                
            foreach($IP in $CurrentIPBlock){
                $IP=$IP.IP.ToString()
                Write-Host "On machine $IP" -ForegroundColor Yellow
                $AppNameAndUninstallString=GetProgramDetails -CollectedIP $IP -ProgramNameLocal $ProgramNameRead
                if($AppNameAndUninstallString[1] -ne $null){  
                    if($AllMachines -ne 'y'){                  
                        [string]$Prompt="Please enter any additional arguments you would like to add to the uninstall string ("+$AppNameAndUninstallString[1]+" <your arguments>) or hit Enter to continue"
                        $Argument=Read-Host -Prompt $Prompt
                        $AllMachines=Read-Host "If you want to use this argument for all following machines, please enter 'y', otherwise hit Enter" 
                    }                
                    $Prompt2=$AppNameAndUninstallString[0]+" will be uninstalled with this string: "+$AppNameAndUninstallString[1]+" "+$Argument
                    Write-Host $Prompt2
                    Invoke-Command -ComputerName $IP -Credential $Credential -ArgumentList $AppNameAndUninstallString,$Argument,$Credential -ScriptBlock{
                        param($AppNameAndUninstallString,$Argument,$Credential)
                        $AppNameAndUninstallString=$AppNameAndUninstallString[1].ToString()
                        if((Test-Path $AppNameAndUninstallString) -eq $true){
                            Invoke-Command -ComputerName localhost -Credential $Credential -ScriptBlock {param($AppNameAndUninstallString,$Argument) cmd /c "$AppNameAndUninstallString $Argument"} -ArgumentList $AppNameAndUninstallString,$Argument
                        }else{Write-Host "The file $AppNameAndUninstallString couldn't be found" -ForegroundColor Cyan}
                    }                    
                }else{Write-Host "Couldn't find $ProgramNameRead on the machine"}
            }
            Stop-Transcript    
        .$MainStart
        } 
        elseif($Choice -eq '2'){
            cls
            $CurrentIPBlock=Import-csv $FullLogPath
            ClearTempo                    
            $IP=$null
            $function1 = "function GetFilesFromServer { ${function:GetFilesFromServer} }"
            $function2 = "function CheckLogDir { ${function:CheckLogDir} }"
            $function3 = "function ClearTempo { ${function:ClearTempo} }"
            $URLs=@()
            do{    
                $Input=Read-Host -Prompt "Please enter the URLs of the files one by one, then enter 's' to continue"                            
                $URLs+=$Input
            }while($Input -ne 's')

            $Script=Read-Host -Prompt "Now please enter a string you want to run on local cmd (cmd /c '<yourstring>').The working directory is $Tempo"
            foreach($IP in $CurrentIPBlock){
                $IP=$IP.IP.ToString()
                Write-Host "On machine $IP" -ForegroundColor Yellow
                Invoke-Command -ComputerName $IP -Credential $Credential -ArgumentList $function1,$function2,$function3,$LogPath,$Tempo,$URLs,$Script -ScriptBlock{
                    param($function1,$function2,$function3,$LogPath,$Tempo,$URLs,$Script)

                    . ([ScriptBlock]::Create($function1))
                    . ([ScriptBlock]::Create($function2))
                    . ([ScriptBlock]::Create($function3))

                    CheckLogDir
                    ClearTempo
                    GetFilesFromServer -URLs $URLs
                    cd $Tempo
                    cmd /c "$Script"

                    pause
                }                                   
            }                
        .$MainStart
        }

        elseif($Choice -eq '3'){
            cls
            $exit=$true
        }
        else{
            cls
            Write-Host "`nEnter a number from the options`n" -ForegroundColor Yellow
            .$MainStart
        }
        
    }
    &$MainStart
}

function main(){
    $MainMainStart={
        CheckLogDir
        $Prompt="What do you want to do:`n1. Get running instances IP address`n2. Install/Uninstall a program`n3. Exit"
        Write-Host $Prompt
        $Choice=Read-Host -Prompt "Enter your selection"
        
            if($Choice -eq '1'){
                cls
                main1
                .$MainMainstart
            }

            elseif($Choice -eq '2'){
                cls
                main2
                .$MainMainstart
            }

            elseif($Choice -eq '3'){
                $exit=$true
            }

            else {
                cls
                Write-Host "`nEnter a number from the options`n" -ForegroundColor Yellow
                .$MainMainstart
            }      
    }
    &$MainMainStart
}

main

