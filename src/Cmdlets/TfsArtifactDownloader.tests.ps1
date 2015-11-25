# This is a PowerShell Unit Test file.
# You need a unit test framework such as Pester to run PowerShell Unit tests. 
# You can download Pester from http://go.microsoft.com/fwlink/?LinkID=534084
#

$modulePath = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) 'TfsArtifactDownloader.psd1'
Get-Module TfsArtifactDownloader | Remove-Module
Import-Module $modulePath

# Download build artifacts
Invoke-TfsArtifactDownload -collection "https://tfs.bouvet.no/tfs/DefaultCollection" -project "Eramet" -buildDefinitionID 48