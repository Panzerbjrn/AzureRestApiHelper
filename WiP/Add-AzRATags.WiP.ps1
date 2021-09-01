Function Add-AzRATags{
<#
	.SYNOPSIS
		Adds tags to a resource that can be tagged.

	.DESCRIPTION
		Adds tags to a resource that can be tagged.

	.EXAMPLE
		Add-AzRATags -Tags @{tag1 = "tag1-value";tag2 = "tag2-value"}

	.EXAMPLE
		$Tags = @{tag1 = "tag1-value";tag2 = "tag2-value"}
		Add-AzRATags -Tags $Tags

	.EXAMPLE
		$Tags = @{
            tag1 = "tag1-value"
            tag2 = "tag2-value"
        }
		Add-AzRATags -Tags $Tags

	.PARAMETER Tags
		This is a hashtable collection of tags to add. These must be in a KeyValue pair collection.
		
	.INPUTS
		Input is from command line or called from a script.

	.OUTPUTS
		A list of Subscriptions

	.NOTES
		Author:				Lars Panzerbjørn
		Creation Date:		2021.09.01
#>
	[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Medium')]
	param
	(
		[Parameter(mandatory)][hashtable]$Tags,
		
		[Parameter(Mandatory,HelpMessage='What Subscription ID would you like to target?')]
		[string]$SubscriptionID,

		[Parameter(HelpMessage='Which Resource Group would you like to target?')]
		[string]$ResourceGroup,

		[Parameter(HelpMessage='Which Storage Account would you like to target?')]
		[string]$StorageAccount,

		[Parameter(HelpMessage='Which Container would you like to target?')]
		[string]$Container,

	)

	BEGIN{
		$BaseUri = 'https://management.azure.com'
		$API = '/providers/Microsoft.Resources/tags/default?api-version=2021-04-01'
		
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

