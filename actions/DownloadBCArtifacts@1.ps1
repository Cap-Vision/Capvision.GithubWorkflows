Param([parameter(Mandatory=$true,
   HelpMessage="-artifact")]
   [string]$artifact = "bcartifacts/sandbox//fr/Latest",
   [string]$cachePath = "C:\.artifacts",
   [string]$sasToken = $null,
   [string]$vsoArtifactsFolderVariableName = "AL_ARTIFACTSFOLDER",
   [string]$vsoPlatformArtifactsFolderVariableName = "AL_PLATFORMARTIFACTSFOLDER",
   [string]$vsoALCompilerFolderVariableName = "AL_ALCFOLDER")

$segments = "$artifact////".Split('/')
if ((![string]::IsNullOrEmpty($sasToken)) -And (($segments[0] -eq "bcinsider") -or ($segments[0] -eq ""))) {
  Write-Host "::debug::Looking for $segments with sasToken enabled"
  $artifactUrl = Get-BCArtifactUrl -storageAccount $segments[0] -type $segments[1] -version $segments[2] -country $segments[3] -select $segments[4] -sasToken $sasToken | Select-Object -First 1
} else {
  Write-Host "::debug::Looking for $segments"
  $artifactUrl = Get-BCArtifactUrl -storageAccount $segments[0] -type $segments[1] -version $segments[2] -country $segments[3] -select $segments[4] | Select-Object -First 1
}
if (-not ($artifactUrl)) {
    Write-Host "::error::Unable to locate artifactUrl from $artifact."
    Exit
}

Write-Host "::debug::Artifact found at $artifactUrl" 


$Paths = Download-Artifacts -artifactUrl $artifactUrl -includePlatform -basePath $cachePath
$artifactCacheFolder = $Paths[0]
$platformArtifactCacheFolder = $Paths[1]

"$vsoArtifactsFolderVariableName=$artifactCacheFolder" >> $env:GITHUB_ENV
"$vsoPlatformArtifactsFolderVariableName=$platformArtifactCacheFolder" >> $env:GITHUB_ENV


$alCompilerFolder = (Join-Path $artifactCacheFolder "ALLanguage/extension/bin")

if (!(Test-Path -Path $alCompilerFolder -PathType Container)) {
    $vsixUrl = Get-LatestAlLanguageExtensionUrl

    Write-Host "::debug::Downloading ALLanguage..."
    (New-Object System.Net.WebClient).DownloadFile($vsixUrl, (Join-Path $artifactCacheFolder "ALLanguage.vsix"))

    Write-Host "::debug::Expanding ALLanguage..."
    . (Join-Path (Split-Path $MyInvocation.MyCommand.Path) "Expand7ZipArchive@1.ps1") -Path (Join-Path $artifactCacheFolder "ALLanguage.vsix") -DestinationPath (Join-Path $artifactCacheFolder "ALLanguage")
}
"$vsoALCompilerFolderVariableName=$alCompilerFolder" >> $env:GITHUB_ENV
