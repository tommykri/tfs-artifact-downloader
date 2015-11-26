$projectDir = Join-Path (Split-Path $MyInvocation.MyCommand.Path -Parent) '..\TfsArtifactDownloader.Cmdlets' -Resolve
$modulePath = Join-Path $projectDir 'TfsArtifactDownloader.psd1'

Get-Module TfsArtifactDownloader | Remove-Module
Import-Module $modulePath