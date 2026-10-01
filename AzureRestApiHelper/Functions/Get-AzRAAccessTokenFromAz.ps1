Function Get-AzRAAccessTokenFromAz {
<#
	.SYNOPSIS
		Gets the bearer token needed for Azure REST API calls using Az module authentication.

	.DESCRIPTION
		Gets the bearer token needed for Azure Resource Manager REST API calls using the currently
		logged in Azure context from the Az module. This eliminates the need for
		TenantID, ClientID, and ClientSecret.

		The context can be a user (Connect-AzAccount), a managed identity (Connect-AzAccount -Identity),
		or a service principal using a certificate or federated credential.

	.EXAMPLE
		Connect-AzAccount
		$Token = Get-AzRAAccessTokenFromAz
		Get-AzRASubscriptions -AccessToken $Token

		This example logs in as the current user, gets a token and lists subscriptions.

	.PARAMETER ResourceUrl
		The resource URL for which to get an access token. Defaults to "https://management.azure.com/".

	.INPUTS
		None. You cannot pipe input to this function.

	.OUTPUTS
		A token response object compatible with the other AzRA* functions in this module.

	.NOTES
		Author:				Lars Panzerbjørn
		Creation Date:		2026.10.01

		Requires the Az.Accounts module to be installed and an active Az login context.
		The returned token is also stored in module scope for use by other functions in this module.
#>
	[CmdletBinding(PositionalBinding=$False)]
	param(
		[Parameter()][string]$ResourceUrl = "https://management.azure.com/"
	)

	BEGIN{
		IF(-not (Get-Module -ListAvailable -Name Az.Accounts)) {
			throw "Az.Accounts module is not installed. Please install it using: Install-Module -Name Az.Accounts"
		}

		$Context = Get-AzContext -ErrorAction SilentlyContinue
		IF(-not $Context) {
			throw "Not logged into Azure. Please run Connect-AzAccount first."
		}
	}

	PROCESS{
		TRY{
			$AzToken = Get-AzAccessToken -ResourceUrl $ResourceUrl -ErrorAction Stop

			# Az.Accounts 5+ returns a SecureString, older versions a plain string
			IF($AzToken.Token -is [SecureString]) {
				$BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($AzToken.Token)
				$TokenString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
				[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
			}ELSE {
				$TokenString = $AzToken.Token.ToString()
			}

			$ExpiresOn = [DateTimeOffset]$AzToken.ExpiresOn

			$TokenResponse = [PSCustomObject]@{
				token_type = "Bearer"
				expires_in = [int]($ExpiresOn - [DateTimeOffset]::UtcNow).TotalSeconds
				expires_on = $ExpiresOn.ToUnixTimeSeconds()
				resource = $ResourceUrl
				access_token = $TokenString
				ExpiresOn = $ExpiresOn.LocalDateTime
			}

			$Script:TenantID = $Context.Tenant.Id
			$Script:TokenResponse = $TokenResponse

			Write-Verbose "Acquired token for $($Context.Account.Id). Expires at: $($TokenResponse.ExpiresOn.ToString('yyyy-MM-dd HH:mm:ss'))"
		}CATCH{
			throw "Failed to acquire access token: $_"
		}
	}

	END{
		Return $TokenResponse
	}
}
