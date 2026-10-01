Function Get-AzRATableEntities {
<#
	.SYNOPSIS
		Reads entities from an Azure Storage Table using the Table REST API.

	.DESCRIPTION
		Reads entities from an Azure Storage Table using the Table REST API.
		Results are fetched in pages of up to 1000 entities and streamed to the pipeline as they arrive,
		so very large tables can be processed without holding everything in memory.

		Authentication can be done with an Entra ID token (requires the "Storage Table Data Reader" role or higher)
		or with a SAS token. If neither is provided, a token is acquired from the current Az context and refreshed
		automatically during long-running reads.

	.EXAMPLE
		Connect-AzAccount
		Get-AzRATableEntities -StorageAccountName mystorage -TableName Logs

		Reads every entity in the table using the current Az context.

	.EXAMPLE
		Get-AzRATableEntities -StorageAccountName mystorage -TableName Logs -Filter "PartitionKey eq '2026-10'" -Select RowKey,Message

		Reads only the RowKey and Message properties of entities in a single partition.

	.EXAMPLE
		Get-AzRATableEntities -StorageAccountName mystorage -TableName Logs -SasToken $Sas | Export-Csv .\Logs.csv -NoTypeInformation

		Streams the whole table to a CSV file using a SAS token.

	.PARAMETER StorageAccountName
		The name of the storage account.

	.PARAMETER TableName
		The name of the table.

	.PARAMETER Filter
		An OData filter, e.g. "PartitionKey eq 'abc' and Timestamp ge datetime'2026-01-01T00:00:00Z'".
		Filtering on PartitionKey (and RowKey) is by far the fastest.

	.PARAMETER Select
		The properties to return. Returning fewer properties reduces the amount of data transferred.

	.PARAMETER MaxResults
		The maximum number of entities to return. If omitted, all matching entities are returned.

	.PARAMETER AccessToken
		An access token for https://storage.azure.com/, either as a token object (with access_token) or a string.

	.PARAMETER SasToken
		A SAS token with read and list permissions on the table.

	.INPUTS
		None. You cannot pipe input to this function.

	.OUTPUTS
		The table entities as PSCustomObjects. Int64 and DateTime properties are returned as strings.

	.NOTES
		Author:				Lars Panzerbjørn
		Creation Date:		2026.10.01
#>
	[CmdletBinding(PositionalBinding=$False)]
	param(
		[Parameter(Mandatory)][string]$StorageAccountName,
		[Parameter(Mandatory)][string]$TableName,
		[Parameter()][string]$Filter,
		[Parameter()][string[]]$Select,
		[Parameter()][ValidateRange(1, [int]::MaxValue)][int]$MaxResults,
		[Parameter()][psobject]$AccessToken,
		[Parameter()][string]$SasToken
	)

	BEGIN{
		# Progress bars make Invoke-WebRequest very slow in Windows PowerShell
		$ProgressPreference = 'SilentlyContinue'

		$Uri = "https://$StorageAccountName.table.core.windows.net/$TableName()"
		$Headers = @{
			'x-ms-version' = '2019-02-02'
			'Accept' = 'application/json;odata=nometadata'
		}

		$AutoToken = $False
		IF($SasToken){
			$SasToken = $SasToken.TrimStart('?')
		}ELSEIF($AccessToken){
			$TokenString = IF($AccessToken -is [string]){$AccessToken}ELSE{$AccessToken.access_token}
			$Headers.Authorization = "Bearer $TokenString"
		}ELSE{
			$AutoToken = $True
		}

		# Keep the module's ARM token intact when acquiring a storage token
		$GetStorageToken = {
			$SavedToken = $Script:TokenResponse
			Get-AzRAAccessTokenFromAz -ResourceUrl 'https://storage.azure.com/'
			$Script:TokenResponse = $SavedToken
		}
	}

	PROCESS{
		$Returned = 0
		$NextPartitionKey = $null
		$NextRowKey = $null

		DO{
			$PageSize = 1000
			IF($MaxResults){ $PageSize = [Math]::Min(1000, $MaxResults - $Returned) }

			$Query = @("`$top=$PageSize")
			IF($Filter){ $Query += "`$filter=$([uri]::EscapeDataString($Filter))" }
			IF($Select){ $Query += "`$select=$([uri]::EscapeDataString($Select -join ','))" }
			IF($NextPartitionKey){ $Query += "NextPartitionKey=$([uri]::EscapeDataString($NextPartitionKey))" }
			IF($NextRowKey){ $Query += "NextRowKey=$([uri]::EscapeDataString($NextRowKey))" }
			IF($SasToken){ $Query += $SasToken }

			IF($AutoToken -and (-not $Token -or $Token.ExpiresOn -lt (Get-Date).AddMinutes(5))){
				$Token = & $GetStorageToken
				$Headers.Authorization = "Bearer $($Token.access_token)"
			}

			$Attempt = 0
			WHILE($True){
				TRY{
					$Response = Invoke-WebRequest -Uri "$($Uri)?$($Query -join '&')" -Headers $Headers -Method Get -UseBasicParsing -ErrorAction Stop
					break
				}CATCH{
					$Status = [int]$_.Exception.Response.StatusCode
					$Attempt++
					IF($Status -notin 429, 500, 503 -or $Attempt -ge 5){ throw }
					Write-Verbose "Request throttled or failed with status $Status. Retrying (attempt $Attempt)"
					Start-Sleep -Seconds ([Math]::Pow(2, $Attempt))
				}
			}

			$Entities = ($Response.Content | ConvertFrom-Json).value
			IF($Entities){
				$Returned += $Entities.Count
				$Entities
			}

			$NextPartitionKey = $Response.Headers['x-ms-continuation-NextPartitionKey'] | Select-Object -First 1
			$NextRowKey = $Response.Headers['x-ms-continuation-NextRowKey'] | Select-Object -First 1
			Write-Verbose "Retrieved $Returned entities so far"
		}WHILE($NextPartitionKey -and (-not $MaxResults -or $Returned -lt $MaxResults))
	}
}
