Param([parameter(Mandatory=$true,
  HelpMessage="-platformArtifact")]
  [string]$platformArtifact)
  
$navSipArtifact = (Get-Item (Join-Path "$platformArtifact" "ServiceTier\System64Folder\NavSip.dll")).FullName

#$msvcr120Path = "C:\Windows\System32\msvcr120.dll"
#if (!(Test-Path $msvcr120Path)) {
#    Copy-FileFromBcContainer -containerName $containerName -ContainerPath $msvcr120Path
#}

$navSip64Path = "C:\Windows\SysWow64\NavSip.dll"
# $navSip32Path = "C:\Windows\System32\NavSip.dll"

if (!(Test-Path $navSip64Path)) {

  RegSvr32 /u /s $navSip64Path

  Write-Host "Copy SIP crypto provider from platform artifact $navSipArtifact"
  Copy-Item -Path "$navSipArtifact" -Destination $navSip64Path

  RegSvr32 /s $navSip64Path
}

# if (!(Test-Path $navSip32Path)) {
#   RegSvr32 /u /s $navSip32Path
  
#   Write-Host "Copy SIP crypto provider from platform artifact $navSipArtifact"
#   Copy-Item -Path "$navSipArtifact" -Destination $navSip32Path
#   RegSvr32 /s $navSip32Path
# }
