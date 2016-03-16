#Requires -version 3.0

<#
**************************************************
* Private members
**************************************************
#>


<#
**************************************************
* Public members
**************************************************
#>
function Get-Publications
{
    <#
    .Synopsis
    Gets a list of Publications present in Tridion Content Manager.

    .Description
    Gets a list of PublicationData objects containing information about all Publications present in Tridion Content Manager.

    .Notes
    Example of properties available: Id, Title, Key, PublicationPath, PublicationUrl, MultimediaUrl, etc.
    
    For a full list, consult the Content Manager Core Service API Reference Guide documentation 
    (Tridion.ContentManager.Data.CommunicationManagement.PublicationData object)

    .Inputs
    None.

    .Outputs
    Returns a list of objects of type [Tridion.ContentManager.CoreService.Client.PublicationData].

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Get-TridionPublications
	Returns a list of all Publications within Tridion.
	
	.Example
	Get-TridionPublications -PublicationType Web
	Returns a list of all 'Web' Publications within Tridion.

    .Example
    Get-TridionPublications | Select-Object Title, Id, Key
	Returns a list of the Title, Id, and Key of all Publications within Tridion.
    
    #>
    [CmdletBinding()]
	Param(
		# The type of Publications to include in the list. Examples include 'Web', 'Content', and 'Mobile'. Omit to retrieve all Publications.
		[string] $PublicationType
	)
	
	Begin
	{
        $client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        if ($client -ne $null)
        {
			Write-Verbose "Loading list of Publications...";
			$filter = New-Object Tridion.ContentManager.CoreService.Client.PublicationsFilterData;
			if ($PublicationType)
			{
				$filter.PublicationTypeName = $PublicationType;
			}
			return $client.GetSystemWideList($filter);
        }
    }
	
	End
	{
		Close-CoreServiceClient $client;
	}
}


Function Get-Item
{
    <#
    .Synopsis
    Reads the item with the given ID.

    .Notes
    Example of properties available: Id, Title, etc.
    
    For a full list, consult the Content Manager Core Service API Reference Guide documentation 
    (Tridion.ContentManager.Data.CommunicationManagement.IdentifiableObject object)

    .Inputs
    None.

    .Outputs
    Returns a list of objects of type [Tridion.ContentManager.CoreService.Client.IdentifiableObject].

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Get-TridionItem -Id "tcm:2-44"
	Reads a Component.

    .Example
    Get-TridionItem -Id "tcm:2-55-8"
	Reads a Schema.

    .Example
    Get-TridionItem -Id "tcm:2-44" | Select-Object Id, Title
	Reads a Component and outputs just the ID and Title of it.
	
	.Example
	Get-TridionPublications | Get-TridionItem
	Reads every Publication within Tridion and returns the full data for each.
    
    #>
    [CmdletBinding()]
    Param
    (
		# The TCM URI or WebDAV URL of the item to retrieve.
        [Parameter(Mandatory=$true, ValueFromPipelineByPropertyName=$true)]
		[ValidateNotNullOrEmpty()]
        [string]$Id
    )
	
	Begin
	{
		$client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        if ($client -ne $null)
        {
			if ($client.IsExistingObject($Id))
			{
				return $client.Read($Id, (New-Object Tridion.ContentManager.CoreService.Client.ReadOptions));
			}
			else
			{
				Write-Error "There is no item with ID '$Id'.";
			}
		}
    }
	
	End
	{
		Close-CoreServiceClient $client;
	}
}

function New-Publication
{
    <#
    .Synopsis
    Adds a new publication to Tridion Content Manager.

    .Description
    Adds a new publication to Tridion Content Manager with the given title, description, parrents and other parameters.  

    .Notes
    Example of properties available: Title, PublicationKey, PublicationPath, PublicationUrl, MultimediaUrl, ParrentPublications, etc.
    
    For a full list, consult the Content Manager Core Service API Reference Guide documentation 
    (Tridion.ContentManager.Data.CommunicationManagement.PublicationData object)

    .Inputs
    [string] title: the title of publication.
    [string] publicationKey: the publication Publication key.
    [string] publicationPath: the publication Publication path.
    [string] publicationURL: the publication Publication URL.
    [string] multimediaPath: the publication Multimedia path.
    [string] multimediaUrl: the publication Multimedia URL.
    [string] businessProcessType: the publications Business Process Type.
    [string[]] ParrentPublications: the parrents of publication.
    
    .Outputs
    Returns an object of type [Tridion.ContentManager.CoreService.Client.PublicationData], representing the newly created publication.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    New-Publication -Title "TestPub"
    Adds publication with title "TestPub" and publication key "TestPub" to the Content Manager.
	
	.Example
    New-Publication -Title "TestPub" -ParrentPublications "Pub1", "tcm:0-209-1"
    Adds "TestPub" publication to the Content Manager with 2 parent publications. Publication with title "Pub1" and publication with id "tcm:0-209-1".

	.Example
    New-Publication -Title "TestPub" -PublicationKey "SomeKey"
    Adds publication with title "TestPub" and key "SomeKey" to the Content Manager.
    
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    Param(
			# The Title of publication.
            [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
			[ValidateNotNullOrEmpty()]
            [string]$Title,
			
            # The PublicationKey of publication.
            [Parameter()]
            [string]$PublicationKey,
			
			# The PublicationPath of publication.
            [Parameter()]
            [string]$PublicationPath,
			
            # The PublicationURL of publication.
            [Parameter()]
            [string]$PublicationURL,
            
			# The MultimediaPath of publication.
            [Parameter()]
            [string]$MultimediaPath,
            
			# The MultimediaUrl of publication.
            [Parameter()]
            [string]$MultimediaUrl,
            
			# The Business Process Type of publication.
            [Parameter()]
            [string]$BusinessProcessType,

			# The parrents of publication.
            [Parameter()]
            [string[]]$ParrentPublications
    )
	
	Begin
	{
		$settings = Get-TridionCoreServiceSettings
		if ($BusinessProcessType -and $settings.Version -ne "Web-8.1"){
			Write-Error "BusinessProcessType can be only set in Core service 8.1+. Use Set-TridionCoreServiceSettings -Version Web-8.1 to use new core service."
		}

        $client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}

    Process
    {
        if ($client -ne $null)
        {
			$readOptions = New-Object Tridion.ContentManager.CoreService.Client.ReadOptions;
			$readOptions.LoadFlags = [Tridion.ContentManager.CoreService.Client.LoadFlags]::None;
			
			if ($client.GetDefaultData.OverloadDefinitions[0].IndexOf('ReadOptions readOptions') -gt 0)
			{
				$pub = $client.GetDefaultData("Publication", $null, $readOptions);
			}
			else
			{
				$pub = $client.GetDefaultData("Publication", $null);
			}
			
			SetPublicationProperties $pub  $Title  $PublicationKey  $PublicationPath  $PublicationURL  $MultimediaPath  $MultimediaUrl  $BusinessProcessType  $ParrentPublications

			if ($PSCmdLet.ShouldProcess("Publication { Title: '$($pub.Title)' }", "Create")) 
			{
				$client.Create($pub, $readOptions);
				Write-Verbose ("Publication '{0}' has been created." -f $pub.Title);
			}
        }
    }
	
	End
	{
		Close-CoreServiceClient $client;
	}	
}

function Set-Publication
{
    <#
    .Synopsis
    Update publication.

    .Description
    Update publication with the given title, description, parrents and other parameters.  

    .Notes
    Example of properties available: Title, PublicationKey, PublicationPath, PublicationUrl, MultimediaUrl, ParrentPublications, etc.
    
    For a full list, consult the Content Manager Core Service API Reference Guide documentation 
    (Tridion.ContentManager.Data.CommunicationManagement.PublicationData object)

    .Inputs
    [string] title: the title of publication.
    [string] publicationKey: the publication Publication key.
    [string] publicationPath: the publication Publication path.
    [string] publicationURL: the publication Publication URL.
    [string] multimediaPath: the publication Multimedia path.
    [string] multimediaUrl: the publication Multimedia URL.
    [string] businessProcessType: the publications Business Process Type.
    [string[]] ParrentPublications: the parrents of publication. Note that by setting ParrentPublications you override existing paretns
    
    .Outputs
    Returns an object of type [Tridion.ContentManager.CoreService.Client.PublicationData], representing the newly created publication.

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Set-Publication -Id "tcm:0-1-1" -Title "TestPub"
    Set title of publication to "TestPub".
	
	.Example
    Set-Publication -Title "TestPub" -ParrentPublications "Pub1", "tcm:0-209-1"
    Set title of publication to "TestPub" and override parents. Publication with title "Pub1" and publication with id "tcm:0-209-1".

	.Example
    Set-Publication -Title "TestPub" -PublicationKey "SomeKey"
    Set title of publication to "TestPub" and publication key "SomeKey".
    
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact='Medium')]
    Param(
			# The TcmUri of publication.
            [Parameter(Mandatory=$true, ValueFromPipeline=$true)]
			[ValidateNotNullOrEmpty()]
            [string]$Id,

			# The Title of publication.
            [Parameter()]
            [string]$Title,
			
            # The PublicationKey of publication.
            [Parameter()]
            [string]$PublicationKey,
			
			# The PublicationPath of publication.
            [Parameter()]
            [string]$PublicationPath,
			
            # The PublicationURL of publication.
            [Parameter()]
            [string]$PublicationURL,
            
			# The MultimediaPath of publication.
            [Parameter()]
            [string]$MultimediaPath,
            
			# The MultimediaUrl of publication.
            [Parameter()]
            [string]$MultimediaUrl,
            
			# The Business Process Type of publication.
            [Parameter()]
            [string]$BusinessProcessType,

			# The parrents of publication.
            [Parameter()]
            [string[]]$ParrentPublications
    )
	
	Begin
	{
		$settings = Get-TridionCoreServiceSettings
		if ($BusinessProcessType -and $settings.Version -ne "Web-8.1"){
			Write-Error "BusinessProcessType can be only set in Core service 8.1+. Use Set-TridionCoreServiceSettings -Version Web-8.1 to use new core service."
		}

        $client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}

    Process
    {
        if ($client -ne $null)
        {
			$pub = Get-TridionItem -Id $Id

			SetPublicationProperties $pub  $Title  $PublicationKey  $PublicationPath  $PublicationURL  $MultimediaPath  $MultimediaUrl  $BusinessProcessType  $ParrentPublications

			if ($PSCmdLet.ShouldProcess("Publication { Title: '$($pub.Title)' }", "Create")) 
			{
				$client.Update($pub, $readOptions);
				Write-Verbose ("Publication '{0}' has been created." -f $pub.Title);
			}
        }
    }
	
	End
	{
		Close-CoreServiceClient $client;
	}	
}

function SetPublicationProperties ($pub, [string]$Title, [string]$PublicationKey, [string]$PublicationPath, [string]$PublicationURL, [string]$MultimediaPath, [string]$MultimediaUrl, [string]$BusinessProcessType, [string[]]$ParrentPublications)
{
	$tridionPublications = $null;
	$publicationsLoaded = $false;

	if($Title)
	{
		$pub.Title = $Title
	}

	if($PublicationKey)
	{
		$pub.Key = $PublicationKey
	}
	elseif ($Title)
	{
		$pub.Key = $Title
	}

	if($PublicationPath)
	{
	    $pub.PublicationPath = $PublicationPath
	}

	if($PublicationURL)
	{
		$pub.PublicationUrl = $PublicationURL
	}

	if($MultimediaPath)
	{
		$pub.MultimediaPath = $MultimediaPath
	}

	if($MultimediaUrl)
	{
		$pub.MultimediaUrl = $MultimediaUrl
	}

	if ($ParrentPublications)
	{
		#$pub.Parents = $()

		foreach($pubUri in $ParrentPublications)
		{
			if ($pubUri)
			{
				if (-not $pubUri.StartsWith('tcm:'))
				{
					# It's not a URI, it's a name. Look up the group URI by its title.
					if (-not $publicationsLoaded)
					{
						$tridionPublications = Get-Publications
						$publicationsLoaded = $true;
					}
							
					$parentPub = $tridionPublications | ?{$_.Title -eq $pubUri} | Select -First 1
					if (-not $parentPub) 
					{
						Write-Error "Could not find a publication named $pubUri."
						continue
					}
							
					$pubUri = $parentPub.id
				}

				$pubLink = New-Object Tridion.ContentManager.CoreService.Client.LinkToRepositoryData;
				$pubLink.IdRef = $pubUri;
						
				$pub.Parents += $pubLink;
			}

			$pub.Parents
		}
	}

	if($BusinessProcessType)
	{
		$bpt = Get-TridionItem -Id $BusinessProcessType -ErrorAction SilentlyContinue
		if ($bpt)
		{
			$bptLink = New-Object Tridion.ContentManager.CoreService.Client.LinkToBusinessProcessTypeData;
			$bptLink.IdRef = $bpt.Id;
			$pub.BusinessProcessType = $bptLink;
		}
		else
		{
			Write-Error "Could not find a Business Process Type with id $BusinessProcessType."
		}
	}
}

function Get-BusinessProcessTypes
{
    <#
    .Synopsis
    Gets a list of Business Process Types present in Tridion Content Manager.

    .Description
    Gets a list of BusinessProcessTypeData objects containing information about all Business Process Types present in Tridion Content Manager.

    For a full list, consult the Content Manager Core Service API Reference Guide documentation 
    (Tridion.ContentManager.CoreService.Client.LinkToBusinessProcessTypeData object)

    .Inputs
    [string] cdTopologyTypeId: CD Topology Type Id to search BPT for
	 
    .Outputs
    Returns a list of objects of type [Tridion.ContentManager.CoreService.Client.LinkToBusinessProcessTypeData].

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Get-TridionBusinessProcessTypes -CdTopologyTypeId "Live"
	Returns a list of all Business Process Types with CdTopologyTypeId = "Live" Tridion.
    
    #>
    [CmdletBinding()]
	Param(
		# The Id of CD TopologyType
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[ValidateNotNullOrEmpty()]
		[string] $CdTopologyTypeId
	)
	
	Begin
	{
		$settings = Get-TridionCoreServiceSettings
		if ($settings.Version -ne "Web-8.1"){
			Write-Error "Get-BusinessProcessTypes only supported in Core service 8.1+. Use Set-TridionCoreServiceSettings -Version Web-8.1 to use new core service."
		}

        $client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        if ($client -ne $null)
        {
			Write-Verbose "Loading list of Business Process Types with CdTopologyTypeId: '$CdTopologyTypeId' ...";
			return $client.GetBusinessProcessTypes($CdTopologyTypeId);
        }
    }
	
	End
	{
		Close-CoreServiceClient $client;
	}
}

function Get-TcmUriInPublication
{
    <#
    .Synopsis
    Change publication of given TcmUri.

    .Description
    Change publication of given TcmUri to publication from TargetPubUri.

    .Inputs	
	[string] tcmUri: tcmUri to convert 
	[string] targetPubUri: target publication TcmUri or integer that represent publication id
	[string] version: optional version for versioned items

    .Outputs
    Returns string that represent converted TcmUri

    .Link
    Get the latest version of this script from the following URL:
    https://github.com/pkjaer/tridion-powershell-modules

    .Example
    Get-TridionTcmUriInPublication -TcmUri "tcm:2-500-2" -TargetPubUri "tcm:0-123-1"
	Returns "tcm:123-500-2"

    .Example
    Get-TridionTcmUriInPublication -TcmUri "tcm:2-500-2" -TargetPubUri 123
	Returns "tcm:123-500-2"

    .Example
    Get-TridionTcmUriInPublication -TcmUri "tcm:2-500-16" -TargetPubUri "tcm:0-123-1" -Version 3
	Returns "tcm:123-500-v3"
    
    #>
    [CmdletBinding()]
	Param(
		# The Id of CD TopologyType
		[Parameter(Mandatory=$true, ValueFromPipeline=$true)]
		[ValidateNotNullOrEmpty()]
		[string] $TcmUri, 
		[Parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string] $TargetPubUri,
		[Parameter()]
		[string] $Version = $null
	)
	
	Begin
	{
        $client = Get-CoreServiceClient -Verbose:($PSBoundParameters['Verbose'] -eq $true);
	}
	
    Process
    {
        if ($client -ne $null)
        {
			if (-not $TargetPubUri.StartsWith('tcm:')){
				$TargetPubUri = "tcm:0-$TargetPubUri-1"
			}

			if($Version){
				return $client.GetTcmUri($TcmUri, $TargetPubUri, $Version);
			}
			else
			{
				return $client.GetTcmUri($TcmUri, $TargetPubUri, $null);
			}
        }
    }
	
	End
	{
		Close-CoreServiceClient $client;
	}
}


<#
**************************************************
* Export statements
**************************************************
#>
Export-ModuleMember Get-Item
Export-ModuleMember Get-Publications
Export-ModuleMember New-Publication
Export-ModuleMember Set-Publication
Export-ModuleMember Get-BusinessProcessTypes
Export-ModuleMember Get-TcmUriInPublication