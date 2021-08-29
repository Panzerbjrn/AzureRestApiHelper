Function Get-AzRASubscriptions{
<#
	.SYNOPSIS
		Gets a list of subscriptions in the tenancy.

	.DESCRIPTION
		Gets a list of subscriptions in the tenancy. This only works if the Service Principal has been granted this permission in the tenancy.

	.EXAMPLE
		$TenantId = "c123456f-a1cd-6fv7-bh73-123r5t6y7u8i9"
		$ClientId = '1a2s3d4d4-dfhg-4567-d5f6-h4f6g7k933ae'
		$ClientSecret = '36._ERF567.6FB.XFGY75D-35TGasdrvk467'

		$AccessToken = Get-AzRAAccessToken -TenantID $TenantID -ClientID $ClientId -ClientSecret $ClientSecret
		Get-AzRASubscriptions -
		
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

