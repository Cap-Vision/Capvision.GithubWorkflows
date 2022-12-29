Param([parameter(Mandatory=$true,
   HelpMessage="-appProjectFolder")]
   [string]$appProjectFolder = "Application")
   
$translationFolder = Join-Path $appProjectFolder "Translations"

$gTransUnitIds = Select-Xml -Path (Join-Path $translationFolder "*.g.xlf") -XPath "//*[@translate = 'yes']/@id"
Write-Host "::debug::$($gTransUnitIds.Length) trans-units found in g.xlf."

$gTargetItems = @(Get-ChildItem -Path (Join-Path $translationFolder "*.g.*.xlf"))
Write-Host "::debug::$($gTargetItems.Length) target files found."

$errorFound = 0

foreach ($gTargetItem in $gTargetItems) {
    Write-Host "::debug::Checking target file $($gTargetItem.Name)..."
    [xml]$TargetXml = Get-Content "$($gTargetItem.FullName)"

    foreach ($gTransUnitId in $gTransUnitIds) {

        $gTargetTransUnits = Select-Xml -Xml $TargetXml -XPath "//*[@id = '$($gTransUnitId.Node."#text")']"

        if (!$gTargetTransUnits) {
            Write-Host "::error::Trans-unit [$gTransUnitId] is missing in $($gTargetItem.Name)"
            $errorFound += 1
        }
    }
}

if ($errorFound -ne 0) {
    Write-Host "::error::$errorFound error(s) found"
} else {
    Write-Host "::notice::Done"
}
