# We will name the VMs "VM-001", "VM-002" … "VM-100"
write-host "You ain't the boss of me."

$numVM = read-host "Enter the Number of VM's you wish me to deploy"
$prefixVM = read-host "Enter the lab prefix"
$vmNameTemplate = $prefixVM + "-{0:D3}"
$csvName = read-host "What IP list should I use? (kuberenetes.csv or docker.csv or openshift.csv or megalab.csv"
# e
$clusterName = read-host "Name of the cluster Lab or Demo"
$cluster = Get-Cluster $clusterName

$template = Get-Template ubtk8stemplate

# Create the VMs

$vmList = @()

for ($i = 1; $i -le $numVM; $i++) {

$vmName = $vmNameTemplate -f $i
write-host $vmName

$vmList += New-VM -Name $vmName -ResourcePool $cluster -Template $template

}
# The list of static IPs is stored in "StaticIPs.csv" file

$staticIpList = Import-CSV $csvName

# Create the customization specification . This time we will directly create a non-persistent specification, so we don’t need to specify a name for it

$linuxSpec = New-OSCustomizationSpec -Domain yourdomain.local -DnsServer "10.21.230.6", "10.21.230.7" -NamingScheme VM -OSType Linux -Type NonPersistent

# Now apply the customization specification to each VM

for ($i = 0; $i -lt $vmList.Count; $i++) {

# Acquire a new static IP from the list

$ip = $staticIpList[$i].IP
$ip2 = $staticIpList[$i].IP2
# Remove any NIC mappings from the specification

$nicMapping = Get-OSCustomizationNicMapping -OSCustomizationSpec $linuxSpec

Remove-OSCustomizationNicMapping -OSCustomizationNicMapping $nicMapping -Confirm:$false

# Retrieve the VM’s network adapter on the "Public" network

$publicNIC = $vmList[$i] | Get-NetworkAdapter | where-object {$_.NetworkName -eq "VM Network"}

# Retrieve the VM’s network adapter on the "Private" network

$privateNIC = $vmList[$i] | Get-NetworkAdapter | where-object {$_.NetworkName -eq "iscsi"}

# Create a NIC mapping for the "Public" NIC - it will use static IP

$linuxSpec | New-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $ip -SubnetMask "255.255.255.0" -DefaultGateway "10.21.230.1" -NetworkAdapterMac $publicNIC.MacAddress

# Create a NIC mapping for the "Private" NIC - it will use DHCP and we will map it by MAC address

$linuxSpec | New-OSCustomizationNicMapping -IpMode UseStaticIP -IpAddress $ip2  -SubnetMask "255.255.255.0" -DefaultGateway "192.168.230.1" -NetworkAdapterMac $privateNIC.MacAddress

# Apply the customization
Add-DnsServerResourceRecordA -ZoneName yourdomain.local -ComputerName dc01 -Name $vmList[$i] -IPv4Address $ip -CreatePtr
Set-VM -VM $vmList[$i] -OSCustomizationSpec $linuxSpec -Confirm:$false
Start-VM -VM $vmList[$i]
Write-Host $vmList[$i] "is Now powered ON"

}