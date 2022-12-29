Param (
    [Parameter(Mandatory=$true)]
    [string] $Path,
    [string] $DestinationPath
)

$7zipPath = "$env:ProgramFiles\7-Zip\7z.exe"

$use7zip = $false
if (Test-Path -Path $7zipPath -PathType Leaf) {
    try {
        $use7zip = [System.Diagnostics.FileVersionInfo]::GetVersionInfo($7zipPath).FileMajorPart -ge 19
    }
    catch {
        $use7zip = $false
    }
}

if ($use7zip) {
    Write-Host "Using 7zip"
    Set-Alias -Name 7z -Value $7zipPath
    $command = '7z x "{0}" -o"{1}" -aoa -r' -f $Path,$DestinationPath
    Invoke-Expression -Command $command | Out-Null
} else {
    Write-Host "Installing 7Zip4Powershell, please install 7zip if you want to get better performances in your pipeline."

    . (Join-Path (Split-Path $MyInvocation.MyCommand.Path) "InstallPSModule@1.ps1") -ModuleName 7Zip4Powershell

    Expand-7Zip -ArchiveFileName $Path -TargetPath $DestinationPath
}
