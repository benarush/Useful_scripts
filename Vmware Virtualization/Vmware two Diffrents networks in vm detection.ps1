$vCenter="<vCenter Address>"
$vCenterUser="<vCenter UserName>"
$vCenterUserPassword="<vCenter Password>"

Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false  
write-host “Connecting to vCenter Server $vCenter” -foreground green
Connect-viserver $vCenter -user $vCenterUser -password $vCenterUserPassword -WarningAction 0 

$VMs = Get-VM -Name * | select-object Name #Get All VM Either
$VSwitchArr=Get-VirtualSwitch -Datacenter <Datacenter Name> | select-object Name

Foreach ($VM in @($VMs.name))
{
    $OSSVlan="False"
    $LanVlan = "False"
    $VM
    $VMNetWrok = Get-NetworkAdapter -VM $VM | select-object NetworkName
    Foreach ($VimNic in @($VMNetWrok.NetworkName))
    {
:VS     Foreach ($VSwitch in @($VSwitchArr.Name))
        {
            $Newtworks = Get-VirtualPortGroup -VirtualSwitch $VSwitch | select-object Name
            foreach ($Network in @($Newtworks.Name))
            {
                if (($VimNic -eq $Network) -and ($VSwitch -eq "vSwitch1"))
                {
                    $LanVlan = "True"
                    break :VS
                       
                }
                elseif (($VimNic -eq $Network) -and ($VSwitch -eq "vSwitch2"))
                {
                    $OSSVlan="True"
                    break :VS
                }
            }
        }
    }
    if (($LanVlan -eq "True") -and ($OSSVlan -eq "True"))
    {
        echo "Have A Two Vmnics!! $VM "
    }
}