<#
.NOTES
    ## CUSTOM PANE SCRIPT REQUIREMENTS
    - Script must be placed in the CustomScripts folder of the PSDResources module
    - Script must be named PSDWizard_<CustomPaneName>.ps1
    - Script must contain a $PageLoadScriptBlock and $PreloadScriptBlock
    - Script can contain other functions and variables as needed

    NOTE: Script is processed twice, once in the Preload phase and once in the PageLoad phase

    ### Custom Pane criptblocks
    - $PreloadScriptBlock - Used to define functions and variables that will be process BEFPORE the Wizard is loaded
        - Useful for defining event handlers and other functions that need to be defined before the Wizard is loaded
        - Useful to process large amounts of data that will be used in the Wizard

    - $PageLoadScriptBlock - Used to define the actions that will be taken AFTER the Wizard is loaded and each time the Pane ise displayed
        - Useful for setting the initial state of the Wizard elements
        - Useful for setting the initial values of the Wizard elements
        - Useful for setting the initial visibility of the Wizard elements
        - Useful for checking logic of the Wizard elements

    ### Recommended Functions to use to interact with the Wizard
    - **Write-PSDLog** - Used to write log messages to the PSD log
    - **Get-PSDWizardElement** - Used to get a reference to a wizard element
    - **Set-PSDWizardElement** - Used to set properties of a wizard element
    - **Add-PSDWizardComboList** - Used to add a list of items to a ComboBox
    - **Add-PSDWizardList** - Used to add a list of items to a ListBox
    - **Get-PSDWizardTSEnvVar** - Used to get a Task Sequence variable

    STEPS:
    1. Build the Pages in xaml format
    2. Add page to the Theme definitions page
    3. Add context to the PSDwizard Definitions page
    4. Create scripts for each page and place them in the CustomScripts. Use this script as a template
    5. Use the PreloadScriptBlock to set pre coollect data and event handlers of the new elements
    6. Use the PageLoadScriptBlock to perform additional action when the page loads


.EXAMPLE
    This is an example of a script that will be used to populate a ComboBox with a list of roles from customsettings.ini
    [Settings]
    Priority=Default
    Properties=DeviceRole(*)

    [Default]    
    DeviceRole001=SG-AZ-DTO-MDM-WUFB-EUDRingBroad-Devices
    DeviceRole002=SG-AZ-DTO-MDM-WUFB-EUDRingFast-Devices
    DeviceRole003=SG-AZ-DTO-MDM-WUFB-TestRing-Devices
    DeviceRole004=Windows Autopatch Device Registration

.EXAMPLE
    This is the list of roles in a array
    $DeviceRoleList=@(
        "SG-AZ-DTO-MDM-WUFB-EUDRingBroad-Devices",
        "SG-AZ-DTO-MDM-WUFB-EUDRingFast-Devices",
        "SG-AZ-DTO-MDM-WUFB-TestRing-Devices",
        "Windows Autopatch Device Registration"
    )
#>


$PreloadScriptBlock = {
    #get list from customsettings.ini
    #make the list global so it can be used in the page load script block
    $Global:DeviceRoleList = Get-PSDWizardTSEnvVar -Name "DeviceRole" -WildCard -ValueOnly
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








