Param([parameter(Mandatory=$true,
  HelpMessage="-appProjectFolder -nugetFolder")]
  [string]$appProjectFolder = "Application",
  [string]$dependencyVersion = 'Highest')

$nugetpackagesPath = Join-Path $appProjectFolder ".nugetpackages"
$alpackagesPath = Join-Path $appProjectFolder ".alpackages"
$nugetExePath = "nuget"

if (!(Test-Path -Path $nugetpackagesPath -PathType Container)) {
  New-Item -ItemType Directory -Force -Path $nugetpackagesPath | Out-Null
}
if (!(Test-Path -Path $alpackagesPath -PathType Container)) {
    New-Item -ItemType Directory -Force -Path $alpackagesPath | Out-Null
}

$packages = [xml] (Get-Content (Join-Path $appProjectFolder "packages.config"))
$packages.packages.package | ForEach-Object {
    Write-Host("::debug::Installing NuGet package $_")
    . "$nugetExePath" install $_.id -OutputDirectory $nugetpackagesPath -DependencyVersion $dependencyVersion
}

Get-ChildItem -Path $nugetpackagesPath -Filter *.app -Recurse -File | ForEach-Object {
    Write-Host("::debug::Copying $_ to $alpackagesPath")
    Move-Item -Path $_.FullName -Destination (Join-Path $alpackagesPath $_.Name) -Force
}
