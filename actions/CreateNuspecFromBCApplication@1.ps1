Param([parameter(Mandatory=$true,
  HelpMessage="-appProjectFolder")]
  [string]$appProjectFolder = "Application",
  [string]$nuspecOutputFolder = ".")


if (Test-Path (Join-Path $appProjectFolder "app.json")) {
    Write-Host "::debug::app.json found"
    $json = Get-Content (Join-Path $appProjectFolder "app.json") | ConvertFrom-Json
} else {
    Write-Host "::debug::app.json not found, looking for a package..."

    $appFile = (Get-ChildItem -Path $appProjectFolder -Filter '*.app' -File | Select-Object -First 1).FullName
    Write-Host "::debug::Package $appFile found."

    . (Join-Path (Split-Path $MyInvocation.MyCommand.Path) "Expand7ZipArchive@1.ps1") -Path $appFile -DestinationPath $appProjectFolder

    $xmlManifest = New-Object -TypeName System.Xml.XmlDocument
    $xmlManifest.LoadXml((Get-Content (Join-Path $appProjectFolder "NavxManifest.xml")))

    $json = @{
        publisher = $xmlManifest.Package.App.Publisher;
        name = $xmlManifest.Package.App.Name;
        version = $xmlManifest.Package.App.Version;
        description = $xmlManifest.Package.App.Description
        dependencies = @($xmlManifest.Package.Dependencies.Dependency | ForEach-Object {
            @{ 
                id = $_.Id;
                publisher = $_.Publisher;
                name = $_.Name;
                version = $_.MinVersion;
            }
        })
    }
}

function GetApplicationId {
    param(
        [string]$Publisher = '',
        [string]$Name = ''
    )
  return $Publisher.Replace(' ', '') + '.' + $Name.Replace(' ', '')
}

$nuspec = New-Object -TypeName System.Xml.XmlDocument
$nuspec.LoadXml(@"
<?xml version=`"1.0`" encoding=`"utf-8`"?>
<package xmlns=`"http://schemas.microsoft.com/packaging/2010/07/nuspec.xsd`">
    <metadata>
        <id></id>
        <version></version>
        <description></description>
        <authors></authors>

        <dependencies>
        </dependencies>
    </metadata>
    <files>
        <file src=`"*.app`" target=`".`" />
    </files>
</package>
"@)
$nuspec.package.metadata.id = GetApplicationId -Publisher $json.publisher -Name $json.name
$nuspec.package.metadata.version = $json.version
$nuspec.package.metadata.description = $json.description
$nuspec.package.metadata.authors = $json.publisher

$packages = New-Object -TypeName System.Xml.XmlDocument
$packages.LoadXml(@"
<?xml version=`"1.0`" encoding=`"utf-8`"?>
<packages>
</packages>
"@)


$ns = New-Object System.Xml.XmlNamespaceManager($nuspec.NameTable)
$ns.AddNamespace("ns", $nuspec.DocumentElement.NamespaceURI)

ForEach ($dependency in $json.dependencies) {
    if (($dependency.publisher -eq 'Microsoft') -or [string]::IsNullOrEmpty($dependency.publisher)) {
        continue
    }

    $DependencyAppId = GetApplicationId -Publisher $dependency.publisher -Name $dependency.name
    
    $xDependency = $nuspec.CreateElement('dependency', $nuspec.DocumentElement.NamespaceURI)
    $xAttr = $nuspec.CreateAttribute('id')
    $xAttr.Value = $DependencyAppId
    $xDependency.Attributes.Append($xAttr)

    $xAttr = $nuspec.CreateAttribute('version')
    $xAttr.Value = $dependency.version
    $xDependency.Attributes.Append($xAttr)

    $nuspec.SelectSingleNode('/ns:package/ns:metadata/ns:dependencies', $ns).AppendChild($xDependency)


    $xPackage = $packages.CreateElement('package')
    $xAttr = $packages.CreateAttribute('id')
    $xAttr.Value = $DependencyAppId
    $xPackage.Attributes.Append($xAttr)

    $xAttr = $packages.CreateAttribute('version')
    $xAttr.Value = $dependency.version
    $xPackage.Attributes.Append($xAttr)

    $packages.SelectSingleNode('/packages').AppendChild($xPackage)

}

$nuspec.Save((Join-Path $nuspecOutputFolder ".nuspec"))
$packages.Save((Join-Path $nuspecOutputFolder "packages.config"))


Write-Host "::debug::.nuspec"
Get-Content (Join-Path $nuspecOutputFolder ".nuspec")

Write-Host "::debug::packages.config"
Get-Content (Join-Path $nuspecOutputFolder "packages.config")
