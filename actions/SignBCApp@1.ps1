Param([parameter(Mandatory=$true,
  HelpMessage="-appFile -pfxFile -pfxPassword")]
  [string]$appFile,
  [string]$pfxFile,
  [string]$pfxPassword,
  [string]$digestAlgorithm = "SHA256",
  [string]$timeStampServer = "http://timestamp.digicert.com")

#if ($importCertificate) {
#    Import-PfxCertificate -FilePath $pfxFile -Password $pfxPassword -CertStoreLocation "cert:\localMachine\root" | Out-Null
#}

if ($pfxFile -like "https://*" -or $pfxFile -like "http://*") {
    $localPfxFile = Join-Path (Get-Location) "my.pfx"
    Write-Host "Downloading certificate file to $localPfxFile"
    (New-Object System.Net.WebClient).DownloadFile($pfxFile, $localPfxFile)
    $pfxFile = $localPfxFile
}

if (!(Test-Path "C:\Windows\System32\msvcr120.dll")) {
    Write-Host "Downloading vcredist_x86"
    (New-Object System.Net.WebClient).DownloadFile('https://bcartifacts.azureedge.net/prerequisites/vcredist_x86.exe','c:\run\install\vcredist_x86.exe')
    Write-Host "Installing vcredist_x86"
    start-process -Wait -FilePath c:\run\install\vcredist_x86.exe -ArgumentList /q, /norestart
    Write-Host "Downloading vcredist_x64"
    (New-Object System.Net.WebClient).DownloadFile('https://bcartifacts.azureedge.net/prerequisites/vcredist_x64.exe','c:\run\install\vcredist_x64.exe')
    Write-Host "Installing vcredist_x64"
    start-process -Wait -FilePath c:\run\install\vcredist_x64.exe -ArgumentList /q, /norestart
}

if (Test-Path "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\SignTool.exe") {
    $signToolExe = (get-item "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\SignTool.exe").FullName
} else {
    Write-Host "Downloading Signing Tools"
    $winSdkSetupExe = "c:\run\install\winsdksetup.exe"
    $winSdkSetupUrl = "https://go.microsoft.com/fwlink/p/?LinkID=2023014"
    (New-Object System.Net.WebClient).DownloadFile($winSdkSetupUrl, $winSdkSetupExe)
    Write-Host "Installing Signing Tools"
    Start-Process $winSdkSetupExe -ArgumentList "/features OptionId.SigningTools /q" -Wait
    if (!(Test-Path "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\SignTool.exe")) {
        throw "Cannot locate signtool.exe after installation"
    }
    $signToolExe = (get-item "C:\Program Files (x86)\Windows Kits\10\bin\*\x64\SignTool.exe").FullName
}

if ($signToolExe.GetType().FullName -eq "System.Object[]") {
    $signToolExe = $signToolExe[0]
}

Write-Host "Signing $appFile"
$unsecurepassword = $pfxPassword
$attempt = 1
$maxAttempts = 5
do {
    try {
        if ($digestAlgorithm) {
            & "$signtoolexe" @("sign", "/f", "$pfxFile", "/p","$unsecurepassword", "/fd", $digestAlgorithm, "/td", $digestAlgorithm, "/tr", "$timeStampServer", "$appFile") | Write-Host
        }
        else {
            & "$signtoolexe" @("sign", "/f", "$pfxFile", "/p","$unsecurepassword", "/t", "$timeStampServer", "$appFile") | Write-Host
        }
        break
    } catch {
        if ($attempt -ge $maxAttempts) {
            throw
        }
        else {
            $seconds = [Math]::Pow(4,$attempt)
            Write-Host "Signing failed, retrying in $seconds seconds"
            $attempt++
            Start-Sleep -Seconds $seconds
        }
    }
} while ($attempt -le $maxAttempts)