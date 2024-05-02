#region: This section is process when PSDWizard loads
$PreloadScriptBlock = {
    
    #populate data on start
    $Global:Disks = Get-Disk
    $Global:PhysicalDisks = Get-PhysicalDisk
    $Global:Volumes = $Global:Disks | Get-Partition | Get-Volume
    $Global:Partitions = $Global:Disks | Get-Partition
    $Global:OSDDiskIndex = Get-PSDWizardTSEnvProperty -Name "OSDDiskIndex" -ValueOnly
    #$Global:WmiVolumes = Get-WMIObject Win32_LogicalDisk | Foreach-Object { Get-WmiObject -Query "Associators of {Win32_LogicalDisk.DeviceID='$($_.DeviceID)'} WHERE ResultRole=Antecedent" | Select *}
    
    #populate the list boxes for the disks and volumes
    $_lstDisks.ItemsSource = @($Global:Disks | Sort DiskNumber | Select Number,FriendlyName,PartitionStyle,
                                    @{Name="Model";Expression={($Global:PhysicalDisks | Where-Object DeviceID -eq $_.Number).Model}},
                                    @{Name="Bus";Expression={($Global:PhysicalDisks | Where-Object DeviceID -eq $_.Number).BusType}},
                                    @{Name="Media";Expression={($Global:PhysicalDisks | Where-Object DeviceID -eq $_.Number).MediaType}},
                                    @{Name="Size";Expression={([math]::round($_.Size /1Gb, 2)).ToString() + ' GB'}})

    $_lstVolumes.ItemsSource = @($Global:Volumes | Sort DriveLetter |
                                Select-Object DriveLetter,FileSystemLabel,FileSystem,DriveType,
                                    @{Name="Disk";Expression={($Global:Partitions | Where-Object AccessPaths -contains "$($_.DriveLetter):\").DiskNumber}},
                                    @{Name="Size";Expression={([math]::round($_.Size /1Gb, 2)).ToString() + ' GB'}},
                                    @{Name="SizeRemaining";Expression={([math]::round($_.SizeRemaining /1Gb, 2)).ToString() + ' GB'}})

    [System.Windows.RoutedEventHandler]$Script:OnVolumeListChanged = {         
        # Create a hash table to store values
        $VolDataSet = @{}
        # Get local Volume usage from WMI
        $Vol = $Global:Volumes | Where-Object{$_.DriveLetter -eq ($this.SelectedItem).DriveLetter}
        # Add Free Volume to a hash table
        $VolDataSet.FreeVol = @{}
        $VolDataSet.FreeVol.Header = "Free Space"
        $VolDataSet.FreeVol.Value = [math]::Round(($Vol.SizeRemaining / 1Gb),2)
        # Add used Volume to a hash table
        $VolDataSet.UsedVol = @{}
        $VolDataSet.UsedVol.Header = "Used Space"
        $VolDataSet.UsedVol.Value = [math]::Round(($Vol.Size / 1Gb - $Vol.SizeRemaining / 1Gb),2)
        # Create the Chart
        Write-PSDLog -Message ("Selected Volume from list: " + ($this.SelectedItem).DriveLetter)
        # Set the image source
        Add-Type -AssemblyName System.Windows.Forms,System.Windows.Forms.DataVisualization
    
        #Create our chart object
        $Chart = New-object System.Windows.Forms.DataVisualization.Charting.Chart
        $Chart.Width = 200
        $Chart.Height = 160
        $Chart.Left = 0
        $Chart.Top = 0

        #Create a chartarea to draw on and add this to the chart
        $ChartArea = New-Object System.Windows.Forms.DataVisualization.Charting.ChartArea
        $Chart.ChartAreas.Add($ChartArea)
        [void]$Chart.Series.Add("Data")

        #Add a datapoint for each value specified in the parameter hash table
        $VolDataSet.GetEnumerator() | foreach {
            $datapoint = new-object System.Windows.Forms.DataVisualization.Charting.DataPoint(0, $_.Value.Value)
            $datapoint.AxisLabel = "$($_.Value.Header)" + "(" + $($_.Value.Value) + " GB)"
            $Chart.Series["Data"].Points.Add($datapoint)
        }

        $Chart.Series["Data"].ChartType = [System.Windows.Forms.DataVisualization.Charting.SeriesChartType]::Pie
        $Chart.Series["Data"]["PieLabelStyle"] = "Outside"
        $Chart.Series["Data"]["PieLineColor"] = "Black"
        $Chart.Series["Data"]["PieDrawingStyle"] = "Concave"
        ($Chart.Series["Data"].Points.FindMaxByValue())["Exploded"] = $true

        #Set the title of the Chart
        $Title = new-object System.Windows.Forms.DataVisualization.Charting.Title
        $Chart.Titles.Add($Title)
        $Chart.Titles[0].Text = ('Volume Usage for: {0}' -f ($this.SelectedItem).DriveLetter)
        
        $File = ($env:Temp + '\' + ($this.SelectedItem).DriveLetter + '_' + $(Get-Date -format "yyyyMMdd_hhmmsstt") + '.png')
        $Chart.SaveImage($File, "PNG")
        Write-PSDLog -Message ("Pie chart image path is now: " + $File)
       
        $_imgPieChart.Source = $File
        
        $Chart.Dispose()
    }

    [System.Windows.RoutedEventHandler]$Script:OnDiskListChanged = {  
        #set the text box to the selected disk number
        $TS_OSDDiskIndex.Text = ($this.SelectedItem).Number
        $_cmbTargetDisk.SelectedItem = ($this.SelectedItem).Number
        #Clear the volume list box and pie chart
        $_lstVolumes.SelectedItem = $null
        $_imgPieChart.Source = $null
        Write-PSDLog -Message ("Target Disk Index selected: " + $TS_OSDDiskIndex.Text)
    }

    $_lstVolumes.AddHandler([System.Windows.Controls.ListView]::SelectionChangedEvent, $OnVolumeListChanged)
    $_lstDisks.AddHandler([System.Windows.Controls.ListView]::SelectionChangedEvent, $OnDiskListChanged)

    #Add an event to the text box to enable the next button if text if populated
    [System.Windows.RoutedEventHandler]$Script:OnTargetDiskTextChanged = {
        Write-PSDLog -Message ("OSDDiskIndex value is now: " + $TS_OSDDiskIndex.Text)
        If ( $TS_OSDDiskIndex.Text -in $Global:Disks.Number) {            
            Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$True
        }Else{
            Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$False
        }
    }

    [System.Windows.RoutedEventHandler]$Script:OnTargetDiskChanged = {  
        $TS_OSDDiskIndex.Text = $this.SelectedItem
        Write-PSDLog -Message ("Target Disk Index selected: " + $TS_OSDDiskIndex.Text)
    }

    #Add the event to the combo box
    If ( $_cmbTargetDisk.GetType().Name -eq 'ComboBox') {
        $_cmbTargetDisk.AddHandler([System.Windows.Controls.ComboBox]::SelectionChangedEvent, $OnTargetDiskChanged)
        #Add the list to the combo box
        Add-PSDWizardComboList -InputObject $Global:Disks -ListObject $_cmbTargetDisk -Identifier 'Number' -PreSelect 0
    }

    #Add the event to the list box
    If ( $_cmbTargetDisk.GetType().Name -eq 'ListBox') {
        $_cmbTargetDisk.AddHandler([System.Windows.Controls.ListBox]::SelectionChangedEvent, $OnTargetDiskChanged)
        #Add the list to the list box
        Add-PSDWizardList -InputObject $Global:Disks -ListObject $_cmbTargetDisk -Identifier 'Number' -PreSelect 0
    }
    
    #Add the event to the text box
    $TS_OSDDiskIndex.AddHandler([System.Windows.Controls.Primitives.TextBoxBase]::TextChangedEvent, $OnTargetDiskTextChanged)
}

$PageLoadScriptBlock = {

    #hide the text box if not in debug mode
    Get-PSDWizardElement -Name "TS_OSDDiskIndex" | Set-PSDWizardElement -Visible:$PSDDeBug

    <#
    If($TS_OSDDiskIndex.Text -ne $Global:OSDDiskIndex){
        $TS_OSDDiskIndex.Text = $Global:OSDDiskIndex
    }
    #>

    #set the next button to disabled until a selection is made
    Write-PSDLog -Message ("OSDDiskIndex value is now: " + $TS_OSDDiskIndex.Text)
    If ( $TS_OSDDiskIndex.Text -in $Global:Disks.Number) {            
        Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$True
    }Else{
        Get-PSDWizardElement -Name "_wizNext" | Set-PSDWizardElement -Enable:$False
    }
}