Function Get-AzRAResourceGroups{
<#
	.SYNOPSIS
		Gets a list of resource groups in a subscriptions.

	.DESCRIPTION
		Gets a list of resource groups in a subscriptions. This only works if the Service Principal has been granted this permission in the tenancy.

	.EXAMPLE
		$AccessToken = Get-AzRAAccessToken -TenantID $TenantID -ClientID $ClientId -ClientSecret $ClientSecret
		Get-AzRAResourceGroups -AccessToken $AccessToken
		
		This command will produce an access token and save it to a variable.

	.EXAMPLE
		$AccessToken = Get-AzRAAccessToken -TenantID $TenantID -ClientID $ClientId -ClientSecret $ClientSecret
		
		Get-AzRASubscriptions

	.PARAMETER AccessToken
		This is the AccessToken that grants you access to Azure

	.INPUTS
		Input is from command line or called from a script.

	.OUTPUTS
		A list of Subscriptions

	.NOTES
		Author:				Lars Panzerbjørn
		Creation Date:		2021.08.30
#>
	[CmdletBinding()]
	param
	(
		[Parameter()][psobject]$AccessToken
	)

	BEGIN{
		IF (($AccessToken) -or ($TokenResponse)){
			IF($AccessToken){$Headers = @{authorization = "Bearer $($AccessToken.access_token)"}}
			IF(!($AccessToken)){$Headers = @{authorization = "Bearer $($TokenResponse.access_token)"}}
		}
		ELSE {THROW "Please provide access token"}
	}

	PROCESS{
		$Headers.host += 'management.azure.com'
		$InvokeRestMethodSplat = @{
			Uri = "https://management.azure.com/subscriptions?api-version=2020-01-01"
			ContentType = 'application/json'
			Method = 'GET'
			Headers = $Headers
		}

		$List = (Invoke-RestMethod @InvokeRestMethodSplat).value
	}
	END{
		Return $List
	}
}

