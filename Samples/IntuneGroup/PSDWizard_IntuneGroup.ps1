

#region: This section is process when PSDWizard loads
$PreloadScriptBlock = {

    #get list from customsettings.ini
    #make the list global so it can be used in the page load script block
    $Global:IntuneGroupList = Get-PSDWizardTSEnvProperty -Name "IntuneGroup" -WildCard -ValueOnly
    
    #Add an event to the text box to enable the next button if text if populated
    [System.Windows.RoutedEventHandler]$Script:OnIntuneGroupTextChanged = {
        Write-PSDLog -Message ("IntuneGroup value is now: " + $TS_IntuneGroup.Text)
        If ( $TS_IntuneGroup.Text -in $Global:IntuneGroupList) {            
            Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$True
        }Else{
            Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$False
        }
    }

    [System.Windows.RoutedEventHandler]$Script:OnIntuneGroupChanged = {  
        $TS_IntuneGroup.Text = $this.SelectedItem
        Write-PSDLog -Message ("Intune Group selected: " + $TS_IntuneGroup.Text)
    }
    

    If ( $_cmbIntuneGroup.GetType().Name -eq 'ComboBox') {
        $_cmbIntuneGroup.AddHandler([System.Windows.Controls.ComboBox]::SelectionChangedEvent, $OnIntuneGroupChanged) 
    }

    #Add the event to the list box
    If ( $_cmbIntuneGroup.GetType().Name -eq 'ListBox') {
        $_cmbIntuneGroup.AddHandler([System.Windows.Controls.ListBox]::SelectionChangedEvent, $OnIntuneGroupChanged)
    }

    #Add the event to the combo box
    If ( $_cmbIntuneGroup.GetType().Name -eq 'ComboBox') {
        $_cmbIntuneGroup.AddHandler([System.Windows.Controls.ComboBox]::SelectionChangedEvent, $OnIntuneGroupChanged)
        #Add the list to the combo box
        Add-PSDWizardComboList -InputObject $Global:IntuneGroupList -ListObject $_cmbIntuneGroup
    }

    #Add the event to the list box
    If ( $_cmbIntuneGroup.GetType().Name -eq 'ListBox') {
        $_cmbIntuneGroup.AddHandler([System.Windows.Controls.ListBox]::SelectionChangedEvent, $OnIntuneGroupChanged)
        #Add the list to the list box
        Add-PSDWizardList -InputObject $Global:IntuneGroupList -ListObject $_cmbIntuneGroup
    }

    
    #Add the event to the text box
    $TS_IntuneGroup.AddHandler([System.Windows.Controls.Primitives.TextBoxBase]::TextChangedEvent, $OnIntuneGroupTextChanged)
    
}
#endregion

#region: This section is processed after the Wizard is loaded but only during the pane its assigned to (based on name of script)
$PageLoadScriptBlock = {
    
    #hide the text box if not in debug mode
    Get-PSDWizardElement -Name "TS_IntuneGroup" | Set-PSDWizardElement -Visible:$PSDDeBug

    #set the next button to disabled until a selection is made
    Write-PSDLog -Message ("IntuneGroup value is now: " + $TS_IntuneGroup.Text)
    If ( $TS_IntuneGroup.Text -in $Global:IntuneGroupList) {            
        Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$True
    }Else{
        Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$False
    }
}
#endregion








