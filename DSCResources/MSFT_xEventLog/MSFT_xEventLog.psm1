function New-TerminatingError
{
    param
    (
        [Parameter(Mandatory)]
        [String]$errorId,

        [Parameter(Mandatory)]
        [String]$errorMessage,

        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorCategory]$errorCategory
    )

    $exception   = New-Object System.InvalidOperationException $errorMessage
    $errorRecord = New-Object System.Management.Automation.ErrorRecord $exception, $errorId, $errorCategory, $null
    throw $errorRecord
}

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Collections.Hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $LogName
    )

    try
    {
        $log = Get-EventLog -LogName $LogName
        $returnValue = @{
            LogName = [System.String]$LogName
            Source = @($log.Source)
        }

        return $returnValue
    }catch
    {
        write-Debug "ERROR: $($_ | Format-List * -force | Out-String)"
        New-TerminatingError -errorId 'GetEventLogFailed' -errorMessage $_.Exception -errorCategory InvalidOperation
    }
}


function Set-TargetResource
{
    [CmdletBinding()]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $LogName,

        [System.String[]]
        $Source
    )


    try
    {
        $currentEventLog = Get-TargetResource -LogName $LogName
    }
    catch
    {
        try
        {
            Write-Verbose -Message "Creating $LogName with sources specified: $Source"
            New-EventLog -LogName $LogName -Source $Source -ErrorAction Stop
        }
        catch
        {
            Write-Debug "ERROR: $($_ | Format-List * -force | Out-String)"
            New-TerminatingError -errorId 'SetEventLogFailed' -errorMessage $_.Exception -errorCategory InvalidOperation
        }
    }

    if ($currentEventLog)
    {
        $missingSource = Compare-Object -ReferenceObject $currentEventLog.Source -DifferenceObject $Source | Where-Object {$_.SideIndicator -eq '=>'}

        try
        {
            Write-Verbose -Message "Updating $LogName with sources specified: $Source"
            New-EventLog -LogName $LogName -Source $missingSource.InputObject -ErrorAction Stop
            $Source = $missingSource
        }
        catch
        {
            Write-Debug "ERROR: $($_ | Format-List * -force | Out-String)"
            New-TerminatingError -errorId 'SetEventLogFailed' -errorMessage $_.Exception -errorCategory InvalidOperation
        }
    }

    Foreach ($eventSource in $Source)
    {
        Write-Verbose -Message "Adding an event log entry for $eventSource to $LogName to populate it for future checks."

        $writeEventLogParams = @{
            LogName = $LogName
            Source = $eventSource
            EntryType = "Information"
            EventId = 0
            Message = "Populating $LogName using $eventSource to ensure future DSC consistency checks don't attempt to recreate this."
        }

        Write-EventLog @writeEventLogParams
    }

}


function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([System.Boolean])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $LogName,

        [System.String[]]
        $Source
    )

    try
    {
        Write-Verbose -Message "Checking for $LogName."
        $log = Get-TargetResource -LogName $LogName
        If ($Log.Source -ne $Source) {
            Write-Verbose -Message "$LogName found but sources do not match."
            return $false
        }
        Write-Verbose -Message "$LogName found."
        return $true
    }
    catch
    {
        Write-Verbose -Message "$LogName not found."
        return $false
    }

}

Export-ModuleMember -Function *-TargetResource



