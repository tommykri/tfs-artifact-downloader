<#
	TFS Artifact Download
#>

$Script:credential = $null

function Get-TfsBuild
{
	# Enable -Verbose option
	[CmdletBinding()]

	Param(
		[Parameter(Mandatory=$true)]
		[string]$collection,

		[Parameter(Mandatory=$true)]
		[string]$project,

		[Parameter(Mandatory=$true)]
		[string]$buildDefinitionID,

		[Parameter(Mandatory=$false)]
		[string]$buildResult = "Latest",

		[Parameter(Mandatory=$true)]
		[System.Management.Automation.PSCredential]
		$credential
	)

	# Gets latest build
	$uri = "$collection/$project" + '/_apis/build/builds?$top=1&api-version=2.0&definitions=' + $buildDefinitionID

	if($buildResult -ne "Latest")
	{
		$uri += "&resultFilter=$buildResult"
	}

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


function Connect-TfsTeamProject {

	[CmdletBinding()]

	Param
	(
		[Parameter(Mandatory=$true)]
		[ValidateNotNull()]
		$collection,

		[Parameter(Mandatory=$true)]
		[ValidateNotNull()]
		$project,

		[Parameter(Mandatory=$true)]
		[System.Management.Automation.PSCredential]
		$credential
	)

	$Script:credential = $credential
	$Script:collection = $collection
	$Script:project = $project
	$Script:projectURL = "$collection/$project"
}

function Invoke-TfsArtifactDownloader {

	# Enable -Verbose option
	[CmdletBinding()]

	Param(
		[Parameter(Mandatory=$true)]
		[ValidateNotNull()]
		[string]$collection,

		[Parameter(Mandatory=$true)]
		[ValidateNotNull()]
		[string]$project,

		[Parameter(Mandatory=$true)]
		[ValidateNotNull()]
  		[string]$buildDefinitionID,
	
		[ValidateSet("Latest", "Succeeded")] 
        [String] 
        $buildResult = "Latest",

		[Parameter()]
		[string[]]$artifactsToProcess = @(""),

		[Parameter(Mandatory=$false)]
		[string]$branch = "master",

		[string]$directoryName = "",

		[Parameter(Mandatory=$true)]
		[System.Management.Automation.PSCredential]
		$credential
	)
	
	process{
		try
		{
			Connect-TfsTeamProject -collection $collection -project $project -credential $credential

			# Get build
			$build = Get-TfsBuild -collection $collection -project $project -buildDefinitionID $buildDefinitionID -buildResult $buildResult -credential $credential

			$buildUri = $build.Url
			$buildNumber = $build.BuildNumber
			$buildDefinitionName = $build.Definition.Name
			$buildArtifactsUrl = "$buildUri/artifacts"
				
			Write-Output "Downloading TFS artifacts for $buildDefinitionName ($buildNumber)"

			# Set default destination directory
			if(!$directoryName)
			{
				$directoryName = "$($MyInvocation.PSScriptRoot)\$($buildDefinitionName)_$buildNumber"
			}

			# Check if destination directory exists
			If (Test-Path $directoryName){
				Remove-Item "$directoryName/*" -Recurse
				Write-Output " - Removed artifacts"
			}

			$build | ConvertTo-Json | Out-File "$directoryName\buildinfo.json"
			
			# Get artifacts
			$artifacts = Invoke-RestMethod -Uri $buildArtifactsUrl -Credential $credential

			# Loop each artifact
			foreach($artifact in $artifacts.Value)  {

				$artifactDownloadURL = $artifact.Resource.downloadUrl
				$artifactName = $artifact.Name
				$artifactTempFile = "$env:TEMP\artifacttemp.zip"

				# Download artifact
				Invoke-WebRequest -uri $artifactDownloadURL -Credential $credential -OutFile $artifactTempFile
			#	Write-Output "Completed"
		
				# Unzip artifact
			#	Write-Output " - Unzipping '$artifactName'..."
				[io.compression.zipfile]::ExtractToDirectory($artifactTempFile, $directoryName)
				Write-Output " - Downloaded artifact '$artifactName'..."
			}
	
			#Write-Output "Operation is completed!"
		}
		catch
		{
			Write-Output "Exception: " $_.Exception.Message
		}
		finally
		{
			#Write-Output "Completed"
		}
	}
	end{
		#Write-Output "Done"
	}
}