Param([parameter(Mandatory=$true,
  HelpMessage="-containerName")]
  [string]$appName,
  [string]$appPublisher,
  [string]$appProjectFolder = "Application",
  [string]$feedSource = "appsource-stable")

$nugetExePath = "nuget.exe"

$appSourceCopPath = Join-Path $appProjectFolder "AppSourceCop.json"
$alpackagesPath = Join-Path $appProjectFolder ".alpackages"
$appNameWithoutSpace = $appName.Replace(' ', '')
$appPublisherWithoutSpace = $appPublisher.Replace(' ', '')
$nugetpackagesPath = Join-Path $appProjectFolder ".nugetpackages"

Write-Host "::debug::AppSourceCop.json path: $appSourceCopPath"
Write-Host "::debug::.alpackages path: $alpackagesPath"
Write-Host "::debug::Nuget packages path: $nugetpackagesPath"

if (!(Test-Path $appSourceCopPath -PathType Leaf)) {
  Write-Host "::warning::AppSourceCop.json not found."
  Exit
}

if (!(Test-Path $nugetpackagesPath -PathType Container)) {
  New-Item $nugetpackagesPath -itemType Directory -Force
}

if (!(Test-Path $alpackagesPath -PathType Container)) {
  New-Item -Path $alpackagesPath -ItemType Directory -Force
}

. $nugetExePath install "$appPublisherWithoutSpace.$appNameWithoutSpace" -OutputDirectory $nugetpackagesPath  -DependencyVersion ignore -source $feedSource
$Info = . $nugetExePath list "$appPublisherWithoutSpace.$appNameWithoutSpace" -source $nugetpackagesPath -verbosity detailed

if (!$Info) {
  Write-Host "::warning::Unable to get information about the released application version."
  Exit
}

$releasedAppVersion = $Info[2].substring(1)

Write-Host "::debug::Released application version is $releasedAppVersion"

$releasedAppFile = Get-ChildItem -Path (Join-Path $nugetpackagesPath "$appPublisherWithoutSpace.$appNameWithoutSpace.$releasedAppVersion\*.app")

# Termine le numéro de version où NuGet supprime les .0 à la fin
while ($releasedAppVersion.Split(".").Length -le 3) {
    $releasedAppVersion = $releasedAppVersion + ".0"
}

Move-Item $releasedAppFile (Join-Path $alpackagesPath "$($appPublisher)_$($appName)_$releasedAppVersion.app")

$appSourceCopJson = Get-Content $appSourceCopPath | ConvertFrom-Json

if (!$appSourceCopJson.version) {
  $appSourceCopJson | Add-Member -name "version" -value "0.0.0.0" -MemberType NoteProperty
}
$appSourceCopJson.version = $releasedAppVersion
$appSourceCopJson | ConvertTo-Json > $appSourceCopPath 

Get-Content $appSourceCopPath | Write-host 
