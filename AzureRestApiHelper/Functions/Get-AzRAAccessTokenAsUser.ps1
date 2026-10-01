Function Get-AzRAAccessTokenAsUser {
<#
	.SYNOPSIS
		Gets a bearer token for Azure REST API calls as the signed in user, using the device code flow.

	.DESCRIPTION
		Gets a bearer token for Azure Resource Manager REST API calls under your own user context.
		No client secret or Az module is required. A code is displayed which you enter at
		https://microsoft.com/devicelogin, after which you sign in normally (MFA is supported).

		By default the well-known public client ID for Azure PowerShell is used, so no app registration is needed.

	.EXAMPLE
		$Token = Get-AzRAAccessTokenAsUser
		Get-AzRASubscriptions -AccessToken $Token

		Signs in as the user in their home tenant and lists subscriptions.

	.EXAMPLE
		$Token = Get-AzRAAccessTokenAsUser -TenantID "c123456f-a1cd-6fv7-bh73-123r5t6y7u8i9"

		Signs in as the user against a specific tenant.

	.PARAMETER TenantID
		The tenant ID or domain to sign in to. Defaults to "organizations" (the user's home tenant).

	.PARAMETER ClientID
		The public client application ID. Defaults to the Azure PowerShell public client.

	.PARAMETER Scope
		The scope requested. Defaults to "https://management.azure.com/.default".

	.INPUTS
		None. You cannot pipe input to this function.

	.OUTPUTS
		A token response object compatible with the other AzRA* functions in this module.

	.NOTES
		Author:				Lars Panzerbjørn
		Creation Date:		2026.10.01
		The returned token is also stored in module scope for use by other functions in this module.
#>
	[CmdletBinding(PositionalBinding=$False)]
	param(
		[Parameter()][string]$TenantID = "organizations",
		[Parameter()][string]$ClientID = "1950a258-227b-4e31-a9cf-717495945fc2",
		[Parameter()][string]$Scope = "https://management.azure.com/.default"
	)

	BEGIN{
		$AuthorityUri = "https://login.microsoftonline.com/$TenantID/oauth2/v2.0"
	}

	PROCESS{
		$DeviceCode = Invoke-RestMethod -Method Post -Uri "$AuthorityUri/devicecode" -ContentType 'application/x-www-form-urlencoded' -Body @{
			client_id = $ClientID
			scope = $Scope
		}

		Write-Host $DeviceCode.message -ForegroundColor Yellow

		$TokenBody = @{
			grant_type = "urn:ietf:params:oauth:grant-type:device_code"
			client_id = $ClientID
			device_code = $DeviceCode.device_code
		}
		$Interval = [int]$DeviceCode.interval
		$Deadline = (Get-Date).AddSeconds([int]$DeviceCode.expires_in)
		$TokenResponse = $null

		WHILE(-not $TokenResponse) {
			IF((Get-Date) -gt $Deadline) { throw "Device code expired before sign-in was completed." }
			Start-Sleep -Seconds $Interval

			TRY{
				$TokenResponse = Invoke-RestMethod -Method Post -Uri "$AuthorityUri/token" -ContentType 'application/x-www-form-urlencoded' -Body $TokenBody -ErrorAction Stop
			}CATCH{
				$OAuthError = ($_.ErrorDetails.Message | ConvertFrom-Json -ErrorAction SilentlyContinue).error
				SWITCH($OAuthError) {
					'authorization_pending' { continue }
					'slow_down' { $Interval += 5; continue }
					default { throw "Failed to acquire access token: $_" }
				}
			}
		}

		$TokenResponse | Add-Member -MemberType NoteProperty -Name ExpiresOn -Value (Get-Date).AddSeconds($TokenResponse.expires_in)

		$Script:TenantID = $TenantID
		$Script:TokenResponse = $TokenResponse
	}

	END{
		Return $TokenResponse
	}
}
