<#
    .NOTES
        TODO: Add Tests to validate that only the properties that don't match are updated in the set
#>

Import-Module 'C:\Program Files\WindowsPowerShell\Modules\xWinEventLog\DSCResources\MSFT_xWinEventLog\MSFT_xWinEventLog.psm1' -Prefix WinEventLog

Describe 'WinEventLog Get-TargetResource'{
    
    Mock Get-WinEvent -ModuleName MSFT_xWinEventLog {
        $properties = @{
            MaximumSizeInBytes = '999'
            IsEnabled = $true
            LogMode = 'Test'
            SecurityDescriptor = 'TestDescriptor'
        }
        
        Write-Output (New-Object -TypeName PSObject -Property $properties)   
    }

    $results = Get-WinEventLogTargetResource 'Application'

    It 'Should return an hashtable'{
        $results.GetType().Name | Should Be 'HashTable'
    }

    It 'Should return a Hashtable name is Application'{
        $results.LogName = 'Application'
    }

    It 'Should return a Hashatable with the MaximumSizeInBytes is 999'{
        $results.MaximumSizeInBytes | Should Be '999'
    }

    It 'Should return a Hashtable where IsEnabled is true'{
        $results.IsEnabled | should Be $true
    }

    It 'Should return a HashTable where LogMode is Test' {
        $results.LogMode | Should Be 'Test'
    }

    It 'Should return a HashTable where SecurityDescriptor is TestDescriptor'{
        $results.SecurityDescriptor | Should Be 'TestDescriptor'
    }
}

Describe 'WinEventLog Test-TargetResource'{
    
    Mock Get-WinEvent -ModuleName MSFT_xWinEventLog {
        $properties = @{
            MaximumSizeInBytes = '5111808'
            IsEnabled = $true
            LogMode = 'Circular'
            SecurityDescriptor = 'TestDescriptor'
        }
        
        Write-Output (New-Object -TypeName PSObject -Property $properties)   
    }

    $params = @{
        LogName = 'Application'
        MaximumSizeInBytes = '5111808'
        LogMode = 'Circular'
        IsEnabled = $true
        SecurityDescriptor = 'TestDescriptor'
    }
    
   
    It 'should return true when all properties match does not match'{
        $testResults = Test-WinEventLogTargetResource @params
        $testResults | Should Be $True
    }
    
    It 'should return false when MaximumSizeInBytes does not match'{
        $testResults = Test-WinEventLogTargetResource -LogName 'Application' -MaximumSizeInBytes '1' -IsEnabled $true -SecurityDescriptor 'TestDescriptor' -LogMode 'AutoBackup'
        $testResults | Should Be $False
    }

    It 'should return false when LogMode does not match'{
        $testResults = Test-WinEventLogTargetResource -LogName 'Application' -MaximumSizeInBytes '5111808' -IsEnabled $true -SecurityDescriptor 'TestDescriptor' -LogMode 'AutoBackup'
        $testResults | Should Be $false
    }

    It 'should return false when IsEnabled does not match'{
        $testResults = Test-WinEventLogTargetResource -LogName 'Application' -MaximumSizeInBytes '5111808' -IsEnabled $false -SecurityDescriptor 'TestDescriptor' -LogMode 'Circular'
        $testResults | Should Be $false
    }

    It 'Should return false when SecurityDescriptor does not match'{
        $testResults = Test-WinEventLogTargetResource -LogName 'Application' -MaximumSizeInBytes '5111808' -IsEnabled $true -SecurityDescriptor 'TestDescriptorFail' -LogMode 'Circular'
        $testResults | Should Be $false    
    }

    It 'Should call Get-WinEventLog' {
        Assert-MockCalled Get-WinEvent -ModuleName MSFT_xWinEventLog -Exactly 5
    }
}

Describe 'WinEventLog Set-TargetResource'{
    BeforeAll {
        New-EventLog -LogName 'Pester' -Source 'PesterTest'
        $Log = Get-WinEvent -ListLog 'Pester'
        $Log.LogMode = 'Circular'
        $Log.SaveChanges()
    }
    
    It 'Should update the LogMode'{
        Set-WinEventLogTargetResource -LogName 'Pester' -LogMode 'AutoBackup'
        (Get-WinEvent -ListLog 'Pester').LogMode | Should Be 'AutoBackup'        
    }

    It 'Should update MaximumSizeInBytes' {
        Set-WinEventLogTargetResource -LogName 'Pester' -MaximumSizeInBytes '5111800'
        (Get-WinEvent -ListLog 'Pester').MaximumSizeInBytes | Should Be '5111800'  
    }

    It 'Should update IsEnabled to false' {
        Set-WinEventLogTargetResource -LogName 'Pester' -IsEnabled $false
        (Get-WinEvent -ListLog 'Pester').IsEnabled | Should Be $false
    }

    It 'Should update SecurityDescriptor' {
        Set-WinEventLogTargetResource -LogName 'Pester' -SecurityDescriptor 'O:BAG:SYD:(A;;0x7;;;BA)(A;;0x7;;;SO)(A;;0x3;;;IU)(A;;0x3;;;SU)(A;;0x3;;;S-1-5-3)(A;;0x3;;;S-1-5-33)(A;;0x1;;;S-1-5-32-573)' 
        (Get-WinEvent -ListLog 'Pester').SecurityDescriptor = 'O:BAG:SYD:(A;;0x7;;;BA)(A;;0x7;;;SO)(A;;0x3;;;IU)(A;;0x3;;;SU)(A;;0x3;;;S-1-5-3)(A;;0x3;;;S-1-5-33)(A;;0x1;;;S-1-5-32-573)' 
    }

    AfterAll {
        Remove-EventLog -LogName 'Pester'
    }
}