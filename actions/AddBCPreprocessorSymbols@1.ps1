Param([parameter(Mandatory=$true,
   HelpMessage="-appProjectFolder -preprocessorSymbols")]
   [string]$appProjectFolder = "Application",
   [string]$preprocessorSymbols = $null)

$appJsonFile = Join-Path $appProjectFolder "app.json"
$jsonApp = Get-Content $appJsonFile | ConvertFrom-Json

if ([System.Convert]::ToDecimal($jsonApp.runtime, [cultureinfo]::GetCultureInfo('en-US')) -lt 6.0) {
    Write-Host "::debug::Runtime must be greater or equal to 6.0 to support Preprocessor Symbols."
    Exit
}

if (Get-Member -inputobject $jsonApp -name "preprocessorSymbols" -Membertype Properties){
    $appPreprocessorSymbols = $jsonApp.preprocessorSymbols
    Write-Host "::debug::Application preprocessor symbols are $($appPreprocessorSymbols)"
} else {
    $appPreprocessorSymbols = @()
    $jsonApp | Add-Member -Name "preprocessorSymbols" -value $appPreprocessorSymbols -MemberType NoteProperty
    Write-Host "::debug::preprocessorSymbols is missing in app.json. The property is added."
}


$paramSymbols = $preprocessorSymbols.Split(',')

$symbolsArrayList = New-Object System.Collections.ArrayList($null)
$symbolsArrayList.AddRange($appPreprocessorSymbols)

ForEach ($symbol in $paramSymbols) {
    if(!$symbolsArrayList.Contains($symbol)) {
        $symbolsArrayList.Add($symbol)
        Write-Host "::debug::Adding $($symbol)..."
    }
}

$jsonApp.preprocessorSymbols = $symbolsArrayList

Write-Host "::debug::New application preprocessor symbols are $($jsonApp.preprocessorSymbols)"

$jsonApp | ConvertTo-Json >"$appJsonFile"
