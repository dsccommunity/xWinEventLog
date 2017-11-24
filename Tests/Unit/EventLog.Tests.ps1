    <#
    .NOTES

#>

Import-Module $PSScriptRoot\..\..\DSCResources\MSFT_xEventLog\MSFT_xEventLog.psm1 -Prefix EventLog -Force

Describe 'EventLog Get-TargetResource'{

    Mock -CommandName Write-Verbose -MockWith {}

    Mock Get-EventLog -ModuleName MSFT_xEventLog {
        $properties = @{
            Source = 'Application1'
        }

        Write-Output (New-Object -TypeName PSObject -Property $properties)
    }

    $results = Get-EventLogTargetResource 'Application'

    It 'Should return an hashtable'{
        $results.GetType().Name | Should Be 'HashTable'
    }

    It 'Should return a Hashtable LogName is Pester'{
        $results.LogName = 'Pester'
    }

    It 'Should return a Hashatable with the Source is Application1'{
        $results.Source | Should Be 'Application1'
    }
}

Describe 'EventLog Test-TargetResource'{

    Mock -CommandName Write-Verbose -MockWith {}

    Mock -CommandName Get-TargetResource -ModuleName MSFT_xEventLog -MockWith {
        $properties = @{
            Source = 'Application1'
        }

        Write-Output (New-Object -TypeName PSObject -Property $properties)
    } -ParameterFilter {$LogName -eq 'Pester'}

    Mock -CommandName Get-TargetResource -ModuleName MSFT_xEventLog -MockWith {
        $properties = @{
            Source = @('Application1','Application2')
        }

        Write-Output (New-Object -TypeName PSObject -Property $properties)
    } -ParameterFilter {$LogName -eq 'ArrayOfSources'}

    Mock -CommandName Get-TargetResource -ModuleName MSFT_xEventLog -MockWith {
        Throw "Event Log $LogName doesn't exist"
    } -ParameterFilter {$LogName -eq 'NotExisting'}

    $params = @{
        LogName = 'Pester'
        Source = 'Application1'
    }


    It 'should return true when all properties match'{
        $testResults = Test-EventLogTargetResource @params
        $testResults | Should Be $True
    }

    It 'should return false when Source does not match'{
        $testResults = Test-EventLogTargetResource -LogName 'Pester' -Source 'Application2'
        $testResults | Should Be $False
    }

    It 'should return false when an array of Sources does not match'{
        $testResults = Test-EventLogTargetResource -LogName 'ArrayOfSources' -Source @('Application2','Application3')
        $testResults | Should Be $False
    }

    It 'should return false when LogName does not exist'{
        $testResults = Test-EventLogTargetResource -LogName 'NotExisting' -Source 'Application2'
        $testResults | Should Be $False
    }

    It 'Should call Get-TargetResource' {
        Assert-MockCalled Get-TargetResource -ModuleName MSFT_xEventLog -Exactly -Times 4
    }
}

Describe 'EventLog Set-TargetResource'{
    Mock -CommandName Write-EventLog -MockWith {}
    Mock -CommandName Write-Verbose -MockWith {}

    Context 'When set is called and event log does not exist' {
        Mock -CommandName New-EventLog -MockWith { $true }
        Mock -CommandName Get-TargetResource -ModuleName MSFT_xEventLog -MockWith { Throw }

        It 'Should create the event log' {
            Set-EventLogTargetResource -LogName 'Pester' -Source 'SetTargetResource'
            Assert-MockCalled -CommandName New-EventLog -Exactly -Times 1
            Assert-MockCalled -CommandName Get-TargetResource -Exactly -Times 1
        }

        It 'Should throw an error if it fails to create the new event log'{
            Mock -CommandName New-EventLog -MockWith {Throw}
            { Set-EventLogTargetResource -LogName 'Pester' -Source 'SetTargetResource' } | Should Throw
        }
    }

    Context "When EventLog exists but Sources don't match"{
        Mock -CommandName Get-TargetResource -ModuleName MSFT_xEventLog -MockWith {
            [psobject]@{
                LogName = 'Pester'
                Source = @('SetTargetResource')
            }
        }

        It 'Should create 2 new sources when passed 3 with 1 already existing' {
            Mock -CommandName New-EventLog -MockWith {}
            $Source = @('SetTargetResource','TestTargetResource','GetTargetResource')
            Set-EventLogTargetResource -LogName 'Pester' -Source $Source
            Assert-MockCalled -CommandName New-EventLog -Exactly -Times 1
            Assert-MockCalled -CommandName Write-EventLog -Exactly -Times 2
        }

    }

}
