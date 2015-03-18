<#
.SYNOPSIS
    Installs the 64-bit Bonjour client for Windows
.DESCRIPTION
    This installs the 64-bit Bonjour client to add mDNS functionality.
.EXAMPLE
    Install-BonjourClient
.LINK
    https://github.com/singlestone/split-puppet-enterprise
#>


msiexec /qn /i C:\vagrant\bin\Bonjour64.msi
