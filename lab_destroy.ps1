write-host "Burninator."

$numVM = read-host "Enter the Number of VM's you wish me to destroy"
$prefixVM = read-host "Enter the lab prefix"
$vmNameTemplate = $prefixVM + "-{0:D3}"
$reverseName = "230.21.10.in-addr.arpa"
$fwdName = "yourdomain.local"
#$clusterName = read-host "Enter the cluster name, Lab or Demo"
#$cluster = Get-Cluster $clusterName
#$csvName = Read-Host "Enter the name of the ip list you used - megalab.csv, kubernetes.csv"
#$template = Get-Template ubtk8stemplate
#$staticIpList = Import-CSV $csvName
# Create the VMs

$vmList = @()

for ($i = 1; $i -le $numVM; $i++) {
    $vmName = $vmNameTemplate -f $i
    $ip = Get-VM -Name $vmName | Select-Object  @{N="IP Address";E={@($_.guest.IPAddress[0])}}
    write-host $ip."IP Address"
    #$newip = $ip."IP Address".Substring
    $newip = $ip."IP Address".Substring($ip.Length - 3, 3)
    write-host $newip
    $vmList += stop-vm -VM $vmName -Confirm:$false -RunAsync
    $vmList += remove-vm -VM $vmName -DeletePermanently -Confirm:$false -RunAsync
    Remove-DnsServerResourceRecord -ZoneName $fwdName -ComputerName dc01 -Name $vmName -RRType A -Force
    #Remove-DnsServerResourceRecord -ZoneName $reverseName  -ComputerName dc01 -Name $newip -RRType Ptr -Force
    write-host $vmName + "Burninated"
}