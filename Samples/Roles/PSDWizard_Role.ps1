
$PreloadScriptBlock = {
    #get list from customsettings.ini
    #make the list global so it can be used in the page load script block
    $Global:DeviceRoleList = Get-PSDWizardTSEnvProperty -Name "DeviceRole" -WildCard -ValueOnly
    Write-PSDLog -Message ("DeviceRoleList: " + ($Global:DeviceRoleList -join ', '))

    #Add an event to the text box to enable the next button if text if populated
    [System.Windows.RoutedEventHandler]$Script:OnDeviceRoleTextChanged = {
        Write-PSDLog -Message ("DeviceRole value is now: " + $TS_DeviceRole.Text)
        If ($TS_DeviceRole.Text -in $Global:DeviceRoleList) {
            Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$True
        }Else{
            Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$False
        }
    }

    [System.Windows.RoutedEventHandler]$Script:OnDeviceRoleChanged = {  
        $TS_DeviceRole.Text = $this.SelectedItem
        Write-PSDLog -Message ("Intune Group selected: " + $TS_DeviceRole.Text)
    }
    
    If ( $_cmbDeviceRole.GetType().Name -eq 'ComboBox') {
        $_cmbDeviceRole.AddHandler([System.Windows.Controls.ComboBox]::SelectionChangedEvent, $OnDeviceRoleChanged) 
    }

    #Add the event to the list box
    If ( $_cmbDeviceRole.GetType().Name -eq 'ListBox') {
        $_cmbDeviceRole.AddHandler([System.Windows.Controls.ListBox]::SelectionChangedEvent, $OnDeviceRoleChanged)
    }

    #Add the event to the combo box
    If ( $_cmbDeviceRole.GetType().Name -eq 'ComboBox') {
        $_cmbDeviceRole.AddHandler([System.Windows.Controls.ComboBox]::SelectionChangedEvent, $OnDeviceRoleChanged)
        #Add the list to the combo box
        Add-PSDWizardComboList -InputObject $Global:DeviceRoleList -ListObject $_cmbDeviceRole
    }

    #Add the event to the list box
    If ( $_cmbDeviceRole.GetType().Name -eq 'ListBox') {
        $_cmbDeviceRole.AddHandler([System.Windows.Controls.ListBox]::SelectionChangedEvent, $OnDeviceRoleChanged)
        #Add the list to the list box
        Add-PSDWizardList -InputObject $Global:DeviceRoleList -ListObject $_cmbDeviceRole
    }

    
    #Add the event to the text box
    $TS_DeviceRole.AddHandler([System.Windows.Controls.Primitives.TextBoxBase]::TextChangedEvent, $OnDeviceRoleTextChanged)
}


$PageLoadScriptBlock = {
    #hide the text box if not in debug mode
    Get-PSDWizardElement -Name "TS_DeviceRole" | Set-PSDWizardElement -Visible:$PSDDeBug

    #set the next button to disabled until a selection is made
    If ($TS_DeviceRole.Text -in $Global:DeviceRoleList) {
        Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$True
    }Else{
        Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$False
    }  
}








