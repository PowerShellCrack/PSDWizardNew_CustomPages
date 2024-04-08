

#region: This section is process when PSDWizard loads
$PreloadScriptBlock = {   
    
    Get-PSDWizardElement -Name "_btnADCheck" | Set-PSDWizardElement -Enable:$false
    Get-PSDWizardElement -Name "_cmbTabArea" | Set-PSDWizardElement -Enable:$false
    #Get-PSDWizardElement -Name "_cmbDomainOUs" | Set-PSDWizardElement -Enable:$false

    #getthe region and area list
    $Global:DeviceNameRegionList = Get-PSDWizardTSEnvProperty 'DeviceNameRegions' -WildCard -ValueOnly
    $Global:NYAreaList = Get-PSDWizardTSEnvProperty 'DeviceNameNYAreas' -WildCard -ValueOnly
    $Global:NCAreaList = Get-PSDWizardTSEnvProperty 'DeviceNameNCAreas' -WildCard -ValueOnly
    $Global:SCAreaList = Get-PSDWizardTSEnvProperty 'DeviceNameSCAreas' -WildCard -ValueOnly

    Add-PSDWizardComboList -Array $Global:DeviceNameRegionList -ListObject $_cmbTabRegion
    #Set event for region selection
    $_cmbTabRegion.Add_SelectionChanged( {
        switch($this.SelectedItem){
            'NY'{
                Add-PSDWizardComboList -Array $Global:NYAreaList -ListObject $_cmbTabArea
            }
            'NC'{
                Add-PSDWizardComboList -Array $Global:NCAreaList -ListObject $_cmbTabArea
            }
            'SC'{
                Add-PSDWizardComboList -Array $Global:SCAreaList -ListObject $_cmbTabArea
            }
        }
        Get-PSDWizardElement -Name "_cmbTabArea" | Set-PSDWizardElement -Enable:$true
    })
    #Event for region selection
    
    

    #Event for computer name validation
    $TS_OSDComputerName.AddHandler(
        [System.Windows.Controls.Primitives.TextBoxBase]::TextChangedEvent,
        [System.Windows.RoutedEventHandler] {
            $_btnADCheck.IsEnabled = (Confirm-PSDWizardComputerName -ComputerNameObject $TS_OSDComputerName -OutputObject $_cusTabValidation1 -Passthru)
            If( $_btnADCheck.IsEnabled -eq $false){
                Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$false
            }
        }
    )


    #change the text for domain join OU to combo box if DomainOUs* values are found
    If((Get-PSDWizardTSEnvProperty 'DomainOUs' -WildCard -ValueOnly).count -gt 0){
        Get-PSDWizardElement -Name "TS_MachineObjectOU" | Set-PSDWizardElement -Visible:$false
        Get-PSDWizardElement -Name "_cmbDomainOUs" | Set-PSDWizardElement -Visible:$true

        $OUList = Get-PSDWizardTSEnvProperty 'DomainOUs' -WildCard -ValueOnly

        If($DefaultOU = Get-PSDWizardTSEnvProperty 'MachineObjectOU' -ValueOnly){
            Add-PSDWizardComboList -Array $OUList -ListObject $_cmbDomainOUs -PreSelect $DefaultOU
        }Else{
            Add-PSDWizardComboList -Array $OUList -ListObject $_cmbDomainOUs
        }
    }

    $_btnADCheck.Add_Click( {

        Function Get-ADComputerInfo {
            <#
            .SYNOPSIS
                Get Active directory Computer Info
        
            .DESCRIPTION
                Get Active directory Computer properties using adsisearcher
        
            .PARAMETER Name
                Specify a Name instead of all Computers
        
            .PARAMETER Credential
                Use alternate credentials when pulling AD objects
        
            .NOTES
                Author		: Dick Tracy II <richard.tracy@microsoft.com>
                Source	    : https://www.DOMAIN-Apps.com/
                Version		: 1.0.0
            #>
            [CmdletBinding()]
            param(
                [parameter(Mandatory = $false)]
                [String]$Name,
                [parameter(Mandatory = $false)]
                [System.Management.Automation.PSCredential]$Credential
            )
        
            #Define the Credential
            #$Credential = Get-Credential -Credential $Credential
        
            # Create an ADSI Search
            $Searcher = New-Object -TypeName System.DirectoryServices.DirectorySearcher
        
            # Get only the User objects
            If($Name){
                $Searcher.Filter = "(&(objectClass=computer)(objectCategory=computer)(name=$Name))"
            }Else{
                $Searcher.Filter = "(&(objectClass=computer)(objectCategory=computer))"
            }
        
            # Limit the output to 50 objects
            $Searcher.SizeLimit = 0
            $Searcher.PageSize = 10000
        
            # Get the current domain
            $DomainDN = $(([adsisearcher]"").Searchroot.path)
        
            If($Credential){
                # Create an object "DirectoryEntry" and specify the domain, username and password
                $Domain = New-Object -TypeName System.DirectoryServices.DirectoryEntry -ArgumentList $DomainDN,$($Credential.UserName),$($Credential.GetNetworkCredential().password)
            }
        
            # Add the Domain to the search
            #$Searcher.SearchRoot = $Domain
        
            #set the properties to parse
            $props=@('name','operatingsystem','distinguishedname','dnshostname','samaccountname','objectsid')
            [void]$Searcher.PropertiesToLoad.AddRange($props)
        
            $Results = @()
            # Execute the Search; build object with properties
            Try{
            $Searcher.FindAll() | %{
        
                    $Object = New-Object PSObject -Property @{
                        ComputerName = $($_.Properties.name)
                        SamAccountName = $($_.Properties.samaccountname)
                        OperatingSystem = $($_.Properties.operatingsystem)
                        Distinguishedname = $($_.Properties.distinguishedname)
                        DNS = $($_.Properties.dnshostname)
                        SID=(new-object System.Security.Principal.SecurityIdentifier $_.Properties.objectsid[0],0).Value
                        LDAP=$_.Path
                    }
                    $Results += $Object
                }
            }
            Catch{
                #unable to grab attributes
            }
        
            #return user and properties
            $Results
        }
        

        $ADUser = Get-PSDWizardTSEnvProperty 'DomainAdmin' -ValueOnly
        $ADDomain = Get-PSDWizardTSEnvProperty 'DomainAdminDomain' -ValueOnly
        $SecurePass = ConvertTo-SecureString -String (Get-PSDWizardTSEnvProperty 'DomainAdminPassword' -ValueOnly) -AsPlainText -Force
        $PSDComputerCredential = New-Object System.Management.Automation.PsCredential("$ADDomain\$ADUser", $SecurePass)
        Try{
            $ADObject = Get-ADComputerInfo -Name $TS_OSDComputerName.Text -Credential $PSDComputerCredential
            If($ADObject){
                Invoke-PSDWizardNotification -Message 'Device name already exits' -OutputObject $_cusTabValidation1 -Type Error
                Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$false
            }Else{
                Invoke-PSDWizardNotification -Message 'Device name is available' -OutputObject $_cusTabValidation1 -Type Info
                Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$true
            }
        }Catch{
            Invoke-PSDWizardNotification -Message ('Error: {0}' -f $_.exception.message) -OutputObject $_cusTabValidation1 -Type Error
            Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$false
        }
        
    })

}

#endregion

#region: This section is processed after the Wizard is loaded but only during the pane its assigned to (based on name of script)
$PageLoadScriptBlock = {

    

    If ($_cmbTabRegion.SelectedItem -in $Global:DeviceNameRegionList) {            
        Get-PSDWizardElement -Name "_cmbTabArea" | Set-PSDWizardElement -Enable:$true
    }Else{
        Get-PSDWizardElement -Name "_cmbTabArea" | Set-PSDWizardElement -Enable:$false
    }

    $_cmbTabRegion.Add_SelectionChanged( {
        switch($this.SelectedItem){
            'NY'{
                Add-PSDWizardComboList -Array $Global:NYAreaList -ListObject $_cmbTabArea
                $Global:AreaList = $Global:NYAreaList
            }
            'NC'{
                Add-PSDWizardComboList -Array $Global:NCAreaList -ListObject $_cmbTabArea
                $Global:AreaList = $Global:NYAreaList
            }
            'SC'{
                Add-PSDWizardComboList -Array $Global:SCAreaList -ListObject $_cmbTabArea
                $Global:AreaList = $Global:NYAreaList
            }
        }
        Get-PSDWizardElement -Name "TS_OSDComputerName" | Set-PSDWizardElement -Text ($this.SelectedItem)    
    })

    $Global:CurrentName = $TS_OSDComputerName.Text

    #Event for area selection
    $_cmbTabArea.Add_SelectionChanged( {
        If($Global:CurrentName.length -eq 2){
            $Global:CurrentName = $Global:CurrentName + $this.SelectedItem
        }Else{
            $Global:CurrentName = $Global:CurrentName -replace $Global:CurrentName.Substring(2,3),$this.SelectedItem
        }
        Get-PSDWizardElement -Name "TS_OSDComputerName" | Set-PSDWizardElement -Text $Global:CurrentName
        Get-PSDWizardElement -Name "_txtTabDigits" | Set-PSDWizardElement -Enable:$true
    })
    

    $_txtTabDigits.AddHandler(
        [System.Windows.Controls.Primitives.TextBoxBase]::TextChangedEvent,
        [System.Windows.RoutedEventHandler] {
            #update the computer name with the digits
            Get-PSDWizardElement -Name "TS_OSDComputerName" | Set-PSDWizardElement -Text ( ($Global:CurrentName -replace '\d+$') + $this.Text)

            If($TS_OSDComputerName.text -match '\d{4}$'){
                #Get-PSDWizardElement -Name "TS_OSDComputerName" | Set-PSDWizardElement -Text $Global:CurrentName
                Invoke-PSDWizardNotification -Message ('{0} is valid. Check availability' -f $TS_OSDComputerName.Text) -OutputObject $_cusTabValidation1 -Type Warning
                #Get-PSDWizardElement -Name "_btnADCheck" | Set-PSDWizardElement -Enable:$true
            }Else{
                Invoke-PSDWizardNotification -Message 'Device name must end with 4 digits!' -OutputObject $_cusTabValidation1 -Type Error
                Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$false
            }
            
        }
    )
    
}