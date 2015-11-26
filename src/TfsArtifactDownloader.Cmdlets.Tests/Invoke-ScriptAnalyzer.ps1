. "$(Split-Path -Parent $MyInvocation.MyCommand.Path)\_TestSetup.ps1"

#Install-Module -Name PSScriptAnalyzer

Import-Module PSScriptAnalyzer
Invoke-ScriptAnalyzer -path $projectDir