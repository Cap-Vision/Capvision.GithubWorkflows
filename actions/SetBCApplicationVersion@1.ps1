Param([parameter(Mandatory=$true,
   HelpMessage="-appProjectFolder -revisionVersion")]
   [string]$appProjectFolder = "Application",
   [string]$majorVersion = $null,
   [string]$minorVersion = $null,
   [string]$buildVersion = $null,
   [string]$revisionVersion = $null)

$appJsonFile = Join-Path $appProjectFolder "app.json"

$json = Get-Content $appJsonFile | ConvertFrom-Json
$version = $json.version

Write-Host "##[debug]Application version is $($json.version)"

$versions = $version.Split('.')


if (![string]::IsNullOrEmpty($majorVersion)) {
    $versions[0] = $majorVersion
}

if (![string]::IsNullOrEmpty($minorVersion)) {
    $versions[1] = $minorVersion
}

if (![string]::IsNullOrEmpty($buildVersion)) {
    $versions[2] = $buildVersion
}

if (![string]::IsNullOrEmpty($revisionVersion)) {
    $versions[3] = $revisionVersion
}

$json.version = $versions[0] + '.' + $versions[1] + '.' + $versions[2] + '.' + $versions[3]

Write-Host "##[debug]New application version is $($json.version)"

$json | ConvertTo-Json >"$appJsonFile"
