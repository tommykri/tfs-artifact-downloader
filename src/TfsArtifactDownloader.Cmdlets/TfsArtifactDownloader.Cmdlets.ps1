<#
	TFS Artifact Download
#>

$Script:credential = $null

function Get-TfsBuildLatest
{
	# Enable -Verbose option
	[CmdletBinding()]

	Param(
		[Parameter(Mandatory=$true)]
		[string]$collectionURL,

		[Parameter(Mandatory=$true)]
		[string]$projectName,

		[Parameter(Mandatory=$true)]
		[string]$buildDefinitionID
	)

	# Gets latest build
	$uri = "$collectionURL/$projectName" + '/_apis/build/builds?definitions=' + $buildDefinitionID + '&$top=1&api-version=2.0'
	$builds = Invoke-RestMethod -Uri $uri -Credential $credential

	if($builds.count -eq 0)
	{
		return $null
	}

	return $builds.Value[0]
}

#function Get-TfsBuildArtifacts
#{
#	# Enable -Verbose option
#	[CmdletBinding()]

#	Param(
#		[Parameter(Mandatory=$true)]
#  		[object]$build,

#		[Parameter(Mandatory=$false)]
#		[System.Management.Automation.PSCredential]$cred
#	)

#	$buildUri = $build.Url
#	$buildArtifactsUrl = "$buildUri/artifacts"

#	# Get build artifacts
#	$artifacts = Invoke-RestMethod -Uri $buildArtifactsUrl -Credential $cred

#	Write-Host "Getting artifacts for build '$buildDefinitionName'"

#	return $artifacts
#}


#function Connect-TfsTeamProject {

#	[CmdletBinding()]

#	Param
#	(
#		[Parameter(Mandatory=$true)]
#		$collection,

#		[Parameter(Mandatory=$false)]
#		$project,

#		[Parameter(Mandatory=$true)]
#		[System.Management.Automation.PSCredential]
#		$credential
#	)

#	$Script:credential = $credential
#	$Script:collection = $collection
#	$Script:project = $project
#}

function Invoke-TfsArtifactDownload {

	# Enable -Verbose option
	[CmdletBinding()]

	Param(
		[Parameter(Mandatory=$true)]
		[ValidateNotNull()]
		[string]$collection,

		[Parameter(Mandatory=$true)]
		[ValidateNotNull()]
		[string]$projectName,

		[Parameter(Mandatory=$true)]
		[ValidateNotNull()]
  		[string]$buildDefinitionID,
	
		[string]$directoryName,

		[Parameter(Mandatory=$true)]
		[System.Management.Automation.PSCredential]
		$credential
	)

	try
	{
		$Script:credential = $credential

		# Get build
		$build = Get-TfsBuildLatest -collectionURL $collection -projectName $projectName -buildDefinitionID $buildDefinitionID

		$buildUri = $build.Url
		$buildNumber = $build.BuildNumber
		$buildDefinitionName = $build.Definition.Name
		$buildArtifactsUrl = "$buildUri/artifacts"

		if(!$directoryName)
		{
			$directoryName = "$PSScriptRoot\$($buildDefinitionName)_$buildNumber"
		}

		# Delete drop folder
		If (Test-Path $directoryName){
			Write-Host " - Clearing drop folder..." -NoNewline
			Remove-Item "$directoryName/*" -Recurse
			Write-Host "Completed" -ForegroundColor Green
		}
				
		Add-Type -assembly 'system.io.compression.filesystem'

		$artifacts = Invoke-RestMethod -Uri $buildArtifactsUrl -Credential $credential

		foreach($artifact in $artifacts.Value)  {

			$artifactDownloadURL = $artifact.Resource.downloadUrl
			$artifactName = $artifact.Name
			$artifactTempFile = "$env:TEMP\artifacttemp.zip"

			# Download artifact
			Write-Host " - Downloading '$artifactName'..." -NoNewline
			Invoke-WebRequest -uri $artifactDownloadURL -Credential $credential -OutFile $artifactTempFile
			Write-Host "Completed" -ForegroundColor Green
		
			# Unzip artifact
			Write-Host " - Unzipping '$artifactName'..." -NoNewline
			[io.compression.zipfile]::ExtractToDirectory($artifactTempFile, $directoryName)
			Write-Host "Completed" -ForegroundColor Green	
		}

		Write-Host "Operation is completed!"
	}
	catch
	{
		Write-Host "Exception: " $_.Exception.Message
	}
	finally
	{
		Write-Host "Completed"
	}
}