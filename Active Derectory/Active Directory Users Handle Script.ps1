<#
							Written By Tomer Ben Harush:
                                      Locked Users And Password Expire Finder From Active Directory .
                                      This Script Find Users Thats Locked and in Stat Enable=TRUE , and also Users that their Password
                                      Gonna be expire . The Defult trashold date for password reminder is two weeks .                                              
#>

$Mode =$args[0] # There Are two parrams for the script : UserLockedOutCheck , & ExpireTimeCheck
$Date=(Get-Date).ToString("dd_MM_yyyy")
$Time = (Get-Date).ToString("HH:mm:ss")
$log= "<Your Log Path>" + $Date + ".log"
$Time + "- Start Running with Mode: " + $Mode | Out-File $log -Verbose -Append

function WriteLog($Text)
{
    $Time + " @Alert@: " + $Text + "." | Out-File $log -Verbose -Append #-Force to clear 
}

function SendTrap($User,$Type,$strMessage)
{
    WriteLog $strMessage
    $strMessage = 'C:\gogo\Active_Derectory_App_Users\TrapGen.exe -d <Destination Ip> -c public -o 1.3.6.1.4.1.270504 -s 913 -g 6 -v .1.3.6.1.4.1.270504.913.1 s ' + $User + ' -v .1.3.6.1.4.1.27004.913.2 s "' + $strMessage + '" -v .1.3.6.1.4.1.27004.913.3 s "' + $Type +'"' 
    cmd.exe /c $strMessage
    $strMessage
}

import-module activedirectory
$AllUsersOfGroup=Get-ADGroupMember -identity “<OU>” 
Foreach ($UserName in @($AllUsersOfGroup))
{
    # Respond to Get ALL users and her Details into A dict Array
    $Detailes = Get-ADUser -filter * -Properties LockedOut , msDS-UserPasswordExpiryTimeComputed , Enabled , PasswordNeverExpires -SearchBase $UserName 
    if (( $Detailes.LockedOut -eq 1) -and ($Detailes.Enabled -eq 1) -and ($Mode -eq "UserLockedOutCheck"))
    {
        $strMessage = "User:" + $Detailes.UserPrincipalName +" Is LockedOut !!!!"
        SendTrap $Detailes.UserPrincipalName $Mode $strMessage
    }
    if ((-NOT $Detailes.PasswordNeverExpires -eq "False") -and ($Mode -eq "ExpireTimeCheck"))
    {
        $begin = [datetime](Get-Date).ToString("yyyy-M-dd") #adddays(-$Days)
        $end = [datetime]([datetime]::FromFileTime($Detailes.'msDS-UserPasswordExpiryTimeComputed').ToString("yyyy-M-dd"))
        $ts = New-TimeSpan -Start $begin -End $end 
        #$ts.Days
        if  (($ts.Days -gt 0) -and ($ts.Days -lt 15))
        {
            $strMessage = "The Password of the application user: " + $Detailes.UserPrincipalName + " is goin to be Expire at: " + [datetime]::FromFileTime($Detailes.'msDS-UserPasswordExpiryTimeComputed').ToString("dd-MM-yyyy")
            SendTrap $Detailes.UserPrincipalName $Mode $strMessage
        }
    }
}
$Time + "- End Of Running with Mode: " + $Mode | Out-File $log -Verbose -Append
"-------------------------------------------------------------------------" | Out-File $log -Verbose -Append
