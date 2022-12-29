Param([parameter(Mandatory=$true,
   HelpMessage="-appProjectFolder -propertyName -vsoOutputVariableName")]
   [string]$appProjectFolder = "Application",
   [string]$propertyName,
   [string]$vsoOutputVariableName)

$appJsonFile = Join-Path $appProjectFolder "app.json"
$json = Get-Content $appJsonFile | ConvertFrom-Json
$propertyValue = $json.$propertyName

Write-Host "::debug::$propertyName = $propertyValue"

"$vsoOutputVariableName=$propertyValue" >> $env:GITHUB_ENV
