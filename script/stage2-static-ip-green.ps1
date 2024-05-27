# The base octet to start at
$baseOctet = 64
$netsize = 22
# Prompt the user for the last octet of the IP address
$LastOctet = [int] (Read-Host "Enter presclient number (e.g., 1 for 172.29.1.64): ") + ($baseOctet-1)

# Construct the full IP address
$IPAddress = "172.29.1.$LastOctet"

# Define the subnet mask, default gateway, and DNS server(s)
$DefaultGateway = "172.29.0.1"

# Get the default network adapter
$Adapter = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.Name -ne "Loopback" }

# Set the static IP configuration
$Adapter | Set-NetIPInterface -DHCP Disabled
$Adapter | New-NetIPAddress -IPAddress $IPAddress -PrefixLength $netsize -DefaultGateway $DefaultGateway

# Set the DNS server(s)
$DNSServers = "1.1.1.3", "1.0.0.3"  # Cloudflare Family DNS
$Adapter | Set-DnsClientServerAddress -ServerAddresses $DNSServers

sleep 5

ipconfig
Read-Host "Press enter to exit"


# [decimal]$i = Get-Content C:\number.txt # can be just [int] if content is always integer
# $i++
# Set-Content C:\number.txt $i
