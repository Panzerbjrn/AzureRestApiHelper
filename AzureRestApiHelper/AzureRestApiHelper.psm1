#region Script Header
#	Thought for the day:
#	NAME: AzureRestApiHelper.psm1
#	AUTHOR: Lars Panzerbjørn
#	CONTACT: GitHub: Panzerbjrn / Twitter: Panzerbjrn
#	DATE: 2021.07.17
#	VERSION: 0.1 - 2021.07.17 - Module Created with Create-NewModuleStructure by Lars Panzerbjørn
#
#	SYNOPSIS:
#
#
#	DESCRIPTION:
#	A module for helping with Azure REST API calls
#
#	REQUIREMENTS:
#
#endregion Script Header

#Requires -Version 4.0

[cmdletbinding()]
param()

Write-Verbose $PSScriptRoot

#Get public and private function definition files.
$Functions  = @( Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 -ErrorAction SilentlyContinue )
$Helpers = @( Get-ChildItem -Path $PSScriptRoot\Helpers\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach ($Import in @($Functions + $Helpers))
{
	Try
	{
		Write-Verbose "Processing $($Import.Fullname)"
		. $Import.Fullname
	}
	Catch
	{
		Write-Error -Message "Failed to Import function $($Import.Fullname): $_"
	}
}

Export-ModuleMember -Function $Functions.Basename
