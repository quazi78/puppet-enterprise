<#
.SYNOPSIS
    Installs the Puppet Enterprise agent for Windows
.DESCRIPTION
    This installs the Puppet Enterprise agent for Windows and registers it with the specified Puppet Master.
.PARAMETER PuppetMaster
    The Puppet Master that the agent should register with.
.EXAMPLE
    Install-PuppetEnterpriseAgent -PuppetMaster puppet.local
.LINK
    https://github.com/singlestone/split-puppet-enterprise
#>

# NOTE: Large parts of this script were lifted from https://github.com/hashicorp/puppet-bootstrap/blob/master/windows.ps1

param(
    [Parameter(Mandatory=$true)][string]$PuppetMaster
)

Write-Output "Puppet Master:   $PuppetMaster"
Write-Output "Agent Cert Name: $env:computername"

#cmd.exe /C msiexec /qn /l* C:\vagrant\log\pe-agent-install.txt /i C:\vagrant\bin\puppet-enterprise-3.7.2-x64.msi PUPPET_MASTER_SERVER=$PuppetMaster PUPPET_AGENT_CERTNAME=$env:computername

$PuppetInstalled = $false
try {
  $ErrorActionPreference = "Stop";
  Get-Command puppet | Out-Null
  $PuppetInstalled = $true
  $PuppetVersion=&puppet "--version"
  Write-Host "Puppet $PuppetVersion is installed. This process does not ensure the exact version or at least version specified, but only that puppet is installed. Exiting..."
  Exit 0
} catch {
  Write-Host "Puppet is not installed, continuing..."
}

if (!($PuppetInstalled)) {
  $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  if (! ($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-Host -ForegroundColor Red "You must run this script as an administrator."
    Exit 1
  }

  # Install it - msiexec will download from the url
  $install_args = @("/qn", "/norestart", "/i C:\vagrant\bin\puppet-enterprise-3.7.2-x64.msi", "PUPPET_MASTER_SERVER=$PuppetMaster", "PUPPET_AGENT_CERTNAME=$env:computername")
  Write-Host "Installing Puppet agent. Running msiexec.exe $install_args"
  $process = Start-Process -FilePath msiexec.exe -ArgumentList $install_args -Wait -PassThru
  if ($process.ExitCode -ne 0) {
    Write-Host "Installer failed."
    Exit 1
  }

  Write-Host "Puppet agent successfully installed."
}
