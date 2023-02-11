# NOTES: 
#   This should be put on a flash drive and taken to all the Windows boxes
#   This needs to be executed from an elevated PowerShell prompt
#   The account on the Windows box that ansible connects as needs to have a password
#
# Exit on errors
$ErrorActionPreference='Stop'

# You cannot enable Windows PowerShell Remoting on network connections that are set to Public
# Spin through all the network locations and if they are set to Public, set them to Private

# You cannot change the network location if you are joined to a domain, so abort
if(1,3,4,5 -contains (Get-WmiObject win32_computersystem).DomainRole) { return }

# Get network connections
$networkListManager = [Activator]::CreateInstance([Type]::GetTypeFromCLSID([Guid]"{DCB00C01-570F-4A9B-8D69-199FDBA5723B}"))
$connections = $networkListManager.GetNetworkConnections()

foreach ($net in $connections) {
	Write-Host $net.GetNetwork().GetName()"category was previously set to"$net.GetNetwork().GetCategory()
	$net.GetNetwork().SetCategory(1)
	Write-Host $net.GetNetwork().GetName()"changed to category"$net.GetNetwork().GetCategory()
}

# Set Execution Policy 64 Bit
cmd.exe /c powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"
# Set Execution Policy 32 Bit
C:\Windows\SysWOW64\cmd.exe /c powershell -Command "Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force"

# Disable Network prompt
cmd.exe /c reg add /force "HKLM\System\CurrentControlSet\Control\Network\NewNetworkWindowOff"

# Set quickconfig for winrmm
cmd.exe /c winrm quickconfig -q
# winrm quickconfig# Win RM MaxTimoutms
cmd.exe /c winrm set winrm/config '@{MaxTimeoutms="1800000"}'
# Win RM MaxMemoryPerShellMB
cmd.exe /c winrm set winrm/config/winrs '@{MaxMemoryPerShellMB="800"}'
# Win RM AllowUnencrypted
cmd.exe /c winrm set winrm/config/service '@{AllowUnencrypted="true"}'
# Win RM auth Basic
cmd.exe /c winrm set winrm/config/service/auth '@{Basic="true"}'
# Win RM client auth Basic
cmd.exe /c winrm set winrm/config/client/auth '@e /c w '@{Port="5985"}'
# Stop Win RM Service
cmd.exe /c net stop winrm
# Configure winrm to autostart
cmd.exe /c sc config winrm start= auto
# Start winrm
cmd.exe /c net start winrm

# open port 5985 in the firewall
cmd.exe /c netsh firewall add portopening TCP 5895 "Port 5895"
cmd.exe /c netsh advfirewall firewall set rule group="remote administration" new enable=yes Execution Policy 64 Bit
