$Username = "username"
$Password = ConvertTo-SecureString 'password' -AsPlainText -Force
$Credential = new-object -typename System.Management.Automation.PSCredential -argumentlist $Username, $Password
$Date=$(get-date -format "MM/dd/yyyy-hh:mmtt").ToString()

function LogAndConsole($Message,$Color){
    if($Color -ne $null){
        Write-Host $Message -ForegroundColor $Color
        $Message | Out-File -FilePath C:\ops\logs\RemoveDheldAcc.txt -Append
    }else{
       Write-Host $Message
       $Message | Out-File -FilePath C:\ops\logs\RemoveDheldAcc.txt -Append 
    }
}


function Get-LocalUser
{
    [CmdletBinding()]
    [Alias()]
    [OutputType([int])]
    Param
    (

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string[]]$name,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string[]]$Computername = "$Env:computername"

    )

    Begin
    {
    }
    Process
    {
    if ($name) 
        { 
            $user=[adsi]"WinNT://$($ComputerName[0])/$($name[0]),user" 
            If ($User.Name -eq $NULL) 
                { 
                    $user
                }
        }    
    else 
        {
            $computer = [ADSI]"WinNT://$($ComputerName[0]),computer"
            $user=$computer.psbase.Children | where { $_.psbase.schemaclassname -match 'user' }
        }
            $user | Select-Object -property `
            @{Name='Name';Expression= { $_.name }},`
            @{Name='Fullname';Expression= { $_.Fullname }},`
            @{Name='Description';Expression= { $_.Description }}
      
     }
    End
    {
    }
 }


 function Remove-LocalUser
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [Alias()]
    [OutputType([int])]
    Param
    (
       [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
       [string[]]$Name,
        
       [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                  Position=1)]
       [string[]]$Computername = "$Env:computername"
                
    )

    Begin
    {
    }
    Process
    {
    if ($PSCmdlet.Shouldprocess("$Name Removed from $computername") )
         {
         $computer = [ADSI]"WinNT://$($ComputerName[0]),computer"
         $computer.delete("user",$name[0])
         }
    }
    End
    {
    }
}





function main2{
    param($region,$Credential,$UserAcc)    
    $Instances=(Get-EC2Instance -Region $region -Filter @(@{name='instance-state-name';values="running"})).Instances 
    foreach($Instance in $Instances){
        $function1 = "function Get-LocalUser { ${function:Get-LocalUser}}"
        $IP= $Instance.PrivateIPAddress
        $Users = Invoke-Command -ComputerName $IP -Credential $Credential -ArgumentList $function1 -ScriptBlock{
            param($function1)

            . ([ScriptBlock]::Create($function1))

            $Users = Get-LocalUser
            return $Users
        }
        $User = $Users | Where-Object {$_.Name -like $UserAcc}

        if($User.Name -eq $UserAcc){

            LogAndConsole -Message "[$Date] [DELETED] [$IP] The user account '$UserAcc' exist and is being deleted" 
            $us=$User.Name
            $function2 = "function Remove-LocalUser { ${function:Remove-LocalUser}}"
            Invoke-Command -ComputerName $IP -Credential $Credential -ArgumentList $function2,$us -ScriptBlock{
            param($function2,$us)

            . ([ScriptBlock]::Create($function2))

            Remove-LocalUser -Name $us
        }
        }else{
            LogAndConsole -Message "[$Date] [NOTEXIST] [$IP] The user account '$UserAcc' doesn't exist"
        }
    }
}

function main(){
$UserAcc = Read-Host -Prompt "Please enter the exact user account name you want to delete inevery region for every running instace"
main2 -region "us-east-1" -Credential $Credential -UserAcc $UserAcc
}

main