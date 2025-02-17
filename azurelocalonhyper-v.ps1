#Notes: This will create two Azure local vms with boot disk + 14 data disks + 6 network adapters (2 management, 2 VMSwitch, 2 Storage)

#1.	You need to download Azure Local ISO
#2.	Open ISO on hyper-V host and note the drive letter, change drive letter accordingly on $isopath parameter
#3.	Change the drive letter on $path parameter accordingly.
#4.	Change the “ethernet” name on new-vmswitch accordingly. 






$vmlist= "azlocaln1","azlocaln2"
$path= "x:\vms"


install-module -Name convert-windowsimage -AllowClobber

Convert-WindowsImage -SourcePath f:\sources\install.wim -VhdPath $path -SizeBytes 70GB -VhdFormat VHDX -VhdType Dynamic -DiskLayout UEFI -RemoteDesktopEnable -Edition 2


New-VMSwitch -AllowManagementOS $true -NetAdapterName "ethernet" -EnableEmbeddedTeaming $true -Name SETSW

New-VMSwitch -SwitchType Private -Name SMB






foreach ($vm in $vmlist)

{

New-item -ItemType directory -Path $path -Name $vm -ErrorAction SilentlyContinue
New-item -ItemType directory -Path $path -Name $vm\"Virtual Hard Disks" -ErrorAction SilentlyContinue



Copy-Item -Path $path\hciroot.vhdx -Destination $path\$vm\"Virtual Hard Disks"\hciroot.vhdx


 

  for ($i = 1; $i -lt 12; $i++)

  {

      new-vhd -Path $path\$vm\"Virtual Hard Disks"\$i.vhdx -SizeBytes 4TB -Dynamic

  }



new-vm -Name $vm -MemoryStartupBytes 256GB -SwitchName SETSW -Path $path -VHDPath $path\$vm\"Virtual Hard Disks"\hciroot.vhdx -Generation 2



for ($j = 1; $j -lt 12 ; $j++)

{

Add-VMHardDiskDrive -VMName $vm -Path $path\$vm\"Virtual Hard Disks"\$j.vhdx

}

 

for ($k = 1; $k -lt 4; $k++)

{

Add-VMNetworkAdapter -VMName $vm -SwitchName "SETSW" 

}


for ($k = 1; $k -lt 2; $k++)

{

Add-VMNetworkAdapter -VMName $vm -SwitchName "SMB" 

}

 

Set-VM -Name $vm -ProcessorCount 24 -AutomaticCheckpointsEnabled $false -StaticMemory
Set-VMProcessor -VMName $vm -ExposeVirtualizationExtensions $true

get-vm $vm | Get-VMNetworkAdapter| Set-VMNetworkAdapter -AllowTeaming On -MacAddressSpoofing On -DeviceNaming On -VrssEnabled $true -FixSpeed10G On 

get-vm $vm | Get-VMNetworkAdapter| Set-VMNetworkAdapterVlan -trunk -AllowedVlanIdList 0-999 -NativeVlanId 0 

Set-VMKeyProtector -VMName $vm -NewLocalKeyProtector
Enable-VMTPM -VMName $vm 


#checkpoint-vm -Name $vm -SnapshotName 1

}