write-host "Changinator"

$numVM = read-host "Enter the Number of VM's you wish me to change"
$prefixVM = read-host "Enter the lab prefix"
$vmNameTemplate = $prefixVM + "-{0:D3}"


$cluster = Get-Cluster Lab

$template = Get-Template ubtk8stemplate

# Create the VMs

$vmList = @()

for ($i = 1; $i -le $numVM; $i++) {

$vmName = $vmNameTemplate -f $i
$vmList += stop-vm -VM $vmName -Confirm:$false
$vmList += set-vm -VM $vmName -MemoryGB 32 -NumCpu 8 -Confirm:$false
$vmList += start-vm -VM $vmName -Confirm:$false
write-host $vmName + "Chaginated"
}