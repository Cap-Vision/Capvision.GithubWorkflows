Param([parameter(Mandatory = $true,
    HelpMessage = "-publisherName -appName")]
    [string]$publisherName,
    [string]$appName,
    [string]$projectFolder)

$dependenciesFolder = "$projectFolder\.alpackages\"
$files = Get-ChildItem $dependenciesFolder
$pathsToBeArchived = @()

foreach ($i in $files) {
    $i = $i.ToString()
    if (($i -notlike "Microsoft_*") -and ($i -notlike $publisherName + "_" + $appName + "*") -and ($i -notlike "System.app")) {
        $pathsToBeArchived += $dependenciesFolder + $i
    }
}

if ($pathsToBeArchived -ne @()) {
    Write-Host "Compressing $pathsToBeArchived"
    Compress-Archive -Path $pathsToBeArchived -CompressionLevel "Fastest" -DestinationPath "${dependenciesFolder}dependencies.zip"
    "dependenciesExists=True" >> $env:GITHUB_ENV
} else {
    Write-Host "There is no dependencies."
    "dependenciesExists=False" >> $env:GITHUB_ENV
}
