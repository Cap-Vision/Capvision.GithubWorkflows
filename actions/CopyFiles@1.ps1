Param([parameter(Mandatory=$true,
   HelpMessage="-sourcePath -targetPath")]
   [string]$sourcePath,
   [string]$targetPath,
   [string]$filter = $null)

if (!(Test-Path $targetPath -PathType Container)) {
    New-Item -Path "$targetPath" -ItemType Directory
}

Get-ChildItem -Path $sourcePath -Recurse -Filter $filter | `
    ForEach-Object {
        Write-Host "::debug::Copying $($_.FullName) to $targetPath"
        Copy-Item -Path $_.FullName -Destination "$targetPath\"
    }
