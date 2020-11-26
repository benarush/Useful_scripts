# Disks 

function SendTrap($DataStore,$strMessage,$oid)
{
    $strMessage = 'C:\SnmpTrap\TrapGen.exe -d <Destenation ip> -o '+$oid+' -s 1 -g 6 -v '+ $oid +'.1 s "' + $strMessage + '" -v ' + $oid + '.2 s ' + $DataStore 
    $Time =Get-Date -Format "HH:mm:ss"
    $Time + ":> " + $strMessage |Out-File $logFile -Verbose -Append
    cmd.exe /c $strMessage
}

$Date=Get-Date -Format "MM/dd/yyyy"
$Time =Get-Date -Format "HH:mm:ss"
$logFile = "<Your Log Path>"
$vCenter=”<Your Vcenter HostName>“
$vCenterUser=”<Vcenter User Name>“
$vCenterUserPassword=”<Vcenter Password>“
$oidCritical = "1.3.6.1.4.1.1.4.23" #23 for Critical
$oidMajor = "1.3.6.1.4.1.1.4.24" #24 for Major

"### Monitor Start Run " + $Date + " " + $Time |Out-File $logFile -Verbose -Append 
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false  
#Set Connection 
Connect-viserver $vCenter -user $vCenterUser -password $vCenterUserPassword -WarningAction 0 
$DataStores = Get-Datastore

Foreach ($Datastore_Properties in @($DataStores))
{
    # Calc GB in Use (total - free / total )*100 
    $diskSpaceUsedGB =[int]($Datastore_Properties.CapacityGB - $Datastore_Properties.FreeSpaceGB)
    $diskFreeSpacePrecent = [int](($diskSpaceUsedGB / $Datastore_Properties.CapacityGB)*100)
    if ($diskFreeSpacePrecent -gt 90)
    {
        $strMessage = 'There is ' + $diskFreeSpacePrecent + '%  DatastoreName: ' + $Datastore_Properties.name + ' , TotalGB: ' + $Datastore_Properties.CapacityGB + ' , free Space in GB: ' + $Datastore_Properties.FreeSpaceGB
        SendTrap $Datastore_Properties.Name $strMessage $oidCritical
    }
#	Optional for Major 	
#   elseif ($diskFreeSpacePrecent -gt 85)
#   {
#
#        $strMessage = 'There is ' + $diskFreeSpacePrecent + '%  DatastoreName: ' + $Datastore_Properties.name + ' , TotalGB: ' + $Datastore_Properties.CapacityGB + ' , free Space in GB: ' + $Datastore_Properties.FreeSpaceGB
#        SendTrap $Datastore_Properties.Name $strMessage $oidMajor
#    }
}

<#For Debug
        ("DatastoreName: " + $Datastore_Properties.name + " , TotalGB: " + $Datastore_Properties.CapacityGB + " , free Space in GB: " + $Datastore_Properties.FreeSpaceGB)
        write-host ("Used in GB space: " + $diskSpaceUsedGB + "GB") -foreground green
        write-host ("Used space: " + $diskFreeSpacePrecent) -foreground red
        #>

"### Monitor End "|Out-File $logFile -Verbose -Append