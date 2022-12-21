#region iPosh History
Add-iPoshHistory 22.12.4.0 @'
Added:
    Get-EnviVariable
    - Use to easily retrive environment varibele that store on AzureAutomation Variable dbo.
    - Work in both environment.
    - Easy to use and imploment in exsiting automation.

    Convert-DFSPathToRealDFSPath
    - Help-Function as part of DFS functions
    - Convert old DFPS path to real DFS Path basid on the folder location.
    -

    Get-DFSFolderTarget
    - Function for FLS team.
    - basic operations can be performed on the server without the need for a local DFS module.
    - The function gets all target shared folders of a DFS namespace folder.

'@


Function Get-EnviVariable {
    <#
    .SYNOPSIS
        Return an hashtable obeject with the enviermnet variable details that stored in AzureAutomation Variable dbo.

    .DESCRIPTION
        The variable name is received, and the variable details are returned as hashtable obeject.

    .PARAMETER Environment
       The environment to which the variable belongs.

    .PARAMETER VariableName
       The Variable name to look for.

    .PARAMETER ListAll
       Boolean flag, called all variables will return

    .EXAMPLE
        PS C:\>   Get-EnviVariable -VariableName 'Server-EOL-Instance'

    .EXAMPLE
        PS C:\>  $result =  Get-EnviVariable -VariableName 'Server-EOL-Instance' -ListAll

         #Use $result."All Variables" to get the all variable

        #Output:

        $result

        Name                           Value
        ----                           -----
        All Variables                  {Automation-AzureAutomation-LongRunningRunbookExcludeList, Automation-Cobbler-Instance, Automation-DefaultAutomationAccount, Automation-Cobbler-DBName...}
        Server-EOL-Instance            System.Data.DataRow

    .EXAMPLE

        $result = Get-EnviVariable -VariableName 'Server-EOL-Instance'

        #Use $result.Values to get the variable data

        $result.Values

        #Output:

        Name             : Server-EOL-Instance
        Value            : orchestrator-mysql.intel.com
        Encrypted        : False
        CreationTime     : 4/18/2022 4:13:33 PM
        LastModifiedTime : 6/8/2022 3:05:07 PM
        Description      : Server EOL MySQL Instance

    .NOTES
        Additional information about the function.
#>
    [cmdletbinding()]
    Param (
        #By defualt the env' is Production
        [ValidateSet('Production', 'Integration')]
        [string] $Environment = 'Production',
        [parameter(Mandatory, Position = 0)]
        [String]$VariableName,
        [switch]$ListAll
    )

    #Crate hasTable object for the query results
    $results = @{}

    #Set the relevet connection string prod/int
    if ($Environment -eq 'Production') {
        $ConnectionString = 'server=orchestratorpdb-prod.intel.com,3184;database=Orchestrator_PDB;integrated security=true'
    }
    else {
        $ConnectionString = 'server=orchestratorpdb-int.intel.com,3180;database=Orchestrator_PDB;integrated security=true'
    }

    #Set the query for the reqested varible/s
    $ReqVarQuery = "SELECT *
	Added:
    Get-EnviVariable
    - Use to easily retrive environment varibele that store on AzureAutomation Variable dbo.
    - Work in both environment.
    - Easy to use and imploment in exsiting automation


    FROM [AzureAutomation_Variable]
    WHERE [Name] like '$($VariableName)'"

    if ($listAll) {
        #Set the query to retrieve all variables
        $AllVarsQuery = "SELECT *
        FROM [AzureAutomation_Variable]"
    }

    try {
        #Retrieve the value of the requested variable
        $QueryData = Get-DatabaseData -connectionString $ConnectionString -query $ReqVarQuery

        #If the QueryData is empty -> the Variable are not exsit in the db
        if($null -ne $QueryData)
        {
            #Adding requested variable data
            $results.Add($VariableName , $QueryData.value)
        }
        else
        {
             #Adding null for the data
            write-warning "Variable are not exsist, check for typo."
            #trhow?!

            $results.Add($VariableName , $null)
        }

        if ($AllVarsQuery) {
            #Retrieve all variables in table
            $QueryData = Get-DatabaseData -connectionString $ConnectionString -query $AllVarsQuery

            #Add last data (all variables)
            $results.Add("All Variables" , $QueryData)
        }
    }
    catch {
        Write-Warning "Colud not retrive data"
        Write-Warning $_.Exception
    }

    return $results
}

function Convert-DFSPathToRealDFSPath {
    <#
	.SYNOPSIS
	Convert old path to real DFS Path.

	.DESCRIPTION
	This function will find the real dfs path using domain area and regex.

	.PARAMETER Path
	Path of the DFS namespace folder

	.EXAMPLE
	> Get-DFSFolderTarget -Path \\ger\ec\proj\ha\computing\nts

Path                               TargetPath                           State  ReferralPriorityClass ReferralPriorityRank
----                               ----------                           -----  --------------------- --------------------
\\ger\ec-iec\ha\proj\computing\nts \\havfsgen014.ger.corp.intel.com\nts Online sitecost-normal       0

	.NOTES
	Author: Ofir Eyal
	#>
    param (
        [Parameter(Position = 0, ValueFromPipeline)]
        [string[]] $Path
    )
    begin {
        #Define Regex
        $regEx = [regex] '(?i)^\\\\(?<Domain>[^\.]+)(?<DomainSuffix>\.corp\.intel\.com)?\\ec\\proj\\(?<Site>DPGEC|gk|ha|ir|is|jr|ka|kt|ls|pt|si|tl|tm|ul|ba|my|pg)(?:\\.+)?\\?$'
    }
    process {
        #Take the recived path and identify the relevant Domain, then change it(by replacing part in the path) with the correct path
        $Path | . {
            process {
                #Remove all the '\' in the end of the path
                [string] $dfsPath = $_.Trim().TrimEnd('\')
                if ($dfsPath -ne '') {
                    #Check if regex match to the path
                    $match = $regEx.Match($dfsPath)
                    if ($match.Success) {
                        #If the Domain is ger:
                        if ($match.Groups["Domain"].Value -ieq 'ger') {
                            #Replace \ec\ with \ec-iec\, and \SiteName\ with \Proj\
                            $dfsPath = $dfsPath -replace "\\\\$($match.Groups["Domain"].Value)$($match.Groups["DomainSuffix"].Value)\\ec\\proj\\$($match.Groups["Site"].Value)", "\\$($match.Groups["Domain"].Value)$($match.Groups["DomainSuffix"].Value)\ec-iec\$($match.Groups["Site"].Value)\proj"


                        }#If the Domain in gar
                        elseif ($match.Groups["Domain"].Value -ieq 'gar') {
                            #Replace \ec\ with \EC-ASEC\
                            $dfsPath = $dfsPath -replace "\\\\$($match.Groups["Domain"].Value)$($match.Groups["DomainSuffix"].Value)\\ec\\proj\\$($match.Groups["Site"].Value)", "\\$($match.Groups["Domain"].Value)$($match.Groups["DomainSuffix"].Value)\EC-ASEC\proj\$($match.Groups["Site"].Value)"
                        }
                        #If the Domain is #! ??
                    }
                    else {
                        if (($match = [regex]::Match($dfsPath, '(?i)^\\\\(?<Domain>[^\.]+)(?<DomainSuffix>\.corp\.intel\.com)?\\ec\\Users\\(?<Rest>.+?)\\?$')).Success) {
                            #Replace \ec\users\ with \EC-Users\
                            $dfsPath = $dfsPath -ireplace "\\\\$($match.Groups["Domain"].Value)$($match.Groups["DomainSuffix"].Value)\\ec\\Users\\$($match.Groups["Rest"].Value)", "\\$($match.Groups["Domain"].Value)$($match.Groups["DomainSuffix"].Value)\EC-Users\$($match.Groups["Rest"].Value)"
                        }
                    }
                    $dfsPath
                }
            }
        }
    }
}

function Get-DFSFolderTarget {
    <#
	.SYNOPSIS
	Gets All target shared folders of a DFS namespace folder.

	.DESCRIPTION
	This function is wrapper for Get-DfsnFolderTarget. The function will convert the DFS path to a local path if needed use that path with Get-DfsnFolderTarget.

	.PARAMETER Path
	Path of the DFS namespace folder

	.PARAMETER WhatIf
	Display the  Get-DfsnFolderTarget command with parameters that would have been executed.

	.EXAMPLE
	> Get-DFSFolderTarget -Path \\ger\ec\proj\ha\computing\nts

Path                               TargetPath                           State  ReferralPriorityClass ReferralPriorityRank
----                               ----------                           -----  --------------------- --------------------
\\ger\ec-iec\ha\proj\computing\nts \\havfsgen014.ger.corp.intel.com\nts Online sitecost-normal       0

	.NOTES
	Author: Ofir Eyal
	#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [string[]] $Path

        , [Parameter()]
        [Alias('WI')]
        [switch] $WhatIf
    )
    process {
        $Path | . {
            process {
                #Get the real path
                [string] $dfsPath = Convert-DFSPathToRealDFSPath -Path $_

                #Display the Get-DfsnFolderTarget command with parameters that would have been executed.
                if ($WhatIf) {
                    "WhatIf: Get-DfsnFolderTarget -Path $dfsPath"
                }
                else {
                    if ($VerbosePreference -ne 'SilentlyContinue') {
                        Write-Verbose "$([DateTime]::Now.ToString("yyyy-MM-dd HH:mm:ss")) Executing: Get-DfsnFolderTarget -Path $dfsPath"
                    }
                    $err = $null
                    #Get the dfsn folder from the real path
                    Get-DfsnFolderTarget -Path $dfsPath -ErrorAction SilentlyContinue -ErrorVariable err
                    #print err
                    if ($err -ne $null) {
                        "Error: $(($err.Exception.Message.Trim()) -join "`r`n")"
                    }
                }
            }
        }
    }
}

get-DfsFolderTarget \\ger\ec\proj\ha\computing\adaskal