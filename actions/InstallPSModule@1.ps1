param (
    [string]$ModuleName,
    [switch]$AllowPrerelease,
    [switch]$AllowClobber
)

$isInstalled = $false

[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

# On Hosted Agents, Get-InstalledModule is not working and consumes time
if ($env:Agent_Name -ne "Hosted Agent") {
    try {
        if (Get-InstalledModule -Name "$moduleName") {
            Write-Host "::debug::Updating $moduleName..."
            Update-Module "$ModuleName" -Force
        } else {
            Write-Host "::debug::Installing $moduleName..."
            Install-Module "$ModuleName" -Force
        }

        $isInstalled = $true
    } catch {
        Write-Host "##[warning]Failed to install or update..."
    }
}


if (-not $isInstalled) {

    $params = "`"$ModuleName`" -Force"

    if ($AllowClobber) {
        $params += " -AllowClobber"
    }

    if ($AllowPrerelease) {
        $params += " -allowPrerelease"
    }

    Write-Host "::debug::Installing $moduleName..."
    Invoke-Expression "Install-Module $params"
    
}