Function Get-AzRAAccessToken{
<#
	.SYNOPSIS
		Gets the bearer token needed for REST API calls.

	.DESCRIPTION
		Gets the bearer token needed for REST API calls.

	.EXAMPLE
		$TenantId = "c123456f-a1cd-6fv7-bh73-123r5t6y7u8i9"
		$ClientId = '1a2s3d4d4-dfhg-4567-d5f6-h4f6g7k933ae'
		$ClientSecret = '36._ERF567.6FB.XFGY75D-35TGasdrvk467'

		Get-AzRAAccessToken -TenantID $TenantID -ClientID $ClientId -ClientSecret $ClientSecret

	.PARAMETER TenantID
		This is the tenant ID of your Azure subscription.

	.PARAMETER ClientID
		This is the ClientID of the Service Principal

	.PARAMETER ClientSecret
		This is the Client secret that was generated when you secured the Service Principal

	.INPUTS
		Input is from command line or called from a script.

	.OUTPUTS
		This will output a bearer token that can be used in future API calls.

	.NOTES
		Author:				Lars Panzerbjørn
		Creation Date:		2021.07.30
#>
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)][string]$TenantID,
		[Parameter(Mandatory)][string]$ClientID,
		[Parameter(Mandatory)][string]$ClientSecret
	)

	BEGIN{
		$TokenEndpoint = "https://login.windows.net/$TenantID/oauth2/token"
		$ARMResource = "https://management.core.windows.net/"
	}
	PROCESS{
		$Body = @{
			Grant_Type = "client_credentials"
			resource = $ARMResource
			client_id = $ClientID
			client_secret = $ClientSecret
		}

		$InvokeRestMethodSplat = @{
			ContentType = 'application/x-www-form-urlencoded'
			Headers = @{'accept'='application/json'}
			Body = $Body
			Method = 'Post'
			URI = $TokenEndpoint
		}

		$Token = Invoke-RestMethod @InvokeRestMethodSplat
	}
	END{
		Return "Bearer " + ($Token.access_token).ToString()
	}
}

