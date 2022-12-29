Param([parameter(Mandatory=$true,
   HelpMessage="-appProjectFolder -alcFolder -apiUserName -apiPassword")]
   [string]$appProjectFolder = "Application",
   [string]$alcFolder,
   [string]$codeAnalyzers = "CodeCop,UICop,AppSourceCop",
   [string]$rulesetFile = $null,
   [bool]$nowarn = $false,
   [string]$assemblyProbingPaths = $null,
   [string]$vsoAppFileOutputVariableName = "AL_APPFILE")

if ([string]::IsNullOrEmpty($rulesetFile)) {
    $rulesetFile = $null
}
if ([string]::IsNullOrEmpty($assemblyProbingPaths)) {
    $assemblyProbingPaths = $null
}

$appSymbolsFolder = "$appProjectFolder\.alpackages"

Set-Location $alcFolder

# Compile Application

$alcParameters = @("/project:$appProjectFolder", "/packagecachepath:$appSymbolsFolder")
if ("$codeAnalyzers".Contains("CodeCop")) {
    $alcParameters += @("/analyzer:$(Join-Path $alcFolder 'Analyzers\Microsoft.Dynamics.Nav.CodeCop.dll')")
}
if ("$codeAnalyzers".Contains("AppSourceCop")) {
    $alcParameters += @("/analyzer:$(Join-Path $alcFolder 'Analyzers\Microsoft.Dynamics.Nav.AppSourceCop.dll')")
}
if ("$codeAnalyzers".Contains("PerTenantExtensionCop")) {
    $alcParameters += @("/analyzer:$(Join-Path $alcFolder 'Analyzers\Microsoft.Dynamics.Nav.PerTenantExtensionCop.dll')")
}
if ("$codeAnalyzers".Contains("UICop")) {
    $alcParameters += @("/analyzer:$(Join-Path $alcFolder 'Analyzers\Microsoft.Dynamics.Nav.UICop.dll')")
}
if ($rulesetFile) {
    $alcParameters += @("/ruleset:$rulesetfile")
}
if ($nowarn) {
    $alcParameters += @("/nowarn:$nowarn")
}
if ($assemblyProbingPaths) {
    $alcParameters += @("/assemblyprobingpaths:$assemblyProbingPaths")
}

Write-Host "##[command]alc.exe $([string]::Join(' ', $alcParameters))"

& .\alc.exe $alcParameters #| Convert-AlcOutputToAzureDevOps

$appFile = (Get-Item "$appProjectFolder/*.app").FullName
"$vsoAppFileOutputVariableName=$appFile" >> $env:GITHUB_ENV
