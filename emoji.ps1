# ==============================================================================
# Windows 11 Emoji Font Switcher (Fluent GUI)
# ==============================================================================

# 1. Ensure script runs with Administrator privileges
$currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = [Security.Principal.WindowsPrincipal]$currentIdentity
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# 2. Set directory context
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $ScriptDir) { $ScriptDir = Get-Location }
$FontFileName = "AppleColorEmoji-Windows.ttf"
$FontSourcePath = Join-Path $ScriptDir $FontFileName
$FontsFolder = "$env:windir\Fonts"
$FontTargetPath = Join-Path $FontsFolder $FontFileName
$RegPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

# 3. Load WPF Assemblies
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

# 4. Define Windows 11 Modern UI (XAML)
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Emoji Font Manager" Height="580" Width="480"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize"
        Background="#202020" Foreground="#FFFFFF"
        FontFamily="Segoe UI Variable Display, Segoe UI, sans-serif">

    <Window.Resources>
        <!-- Primary Button Style -->
        <Style x:Key="AccentBtn" TargetType="Button">
            <Setter Property="Background" Value="#0078D4"/>
            <Setter Property="Foreground" Value="#FFFFFF"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" CornerRadius="6" Padding="14,10">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#1A86D9"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#006CBE"/>
                            </Trigger>
                            <Trigger Property="IsEnabled" Value="False">
                                <Setter TargetName="border" Property="Background" Value="#333333"/>
                                <Setter Property="Foreground" Value="#777777"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>

        <!-- Secondary Button Style -->
        <Style x:Key="SecondaryBtn" TargetType="Button">
            <Setter Property="Background" Value="#2D2D2D"/>
            <Setter Property="Foreground" Value="#EDEDED"/>
            <Setter Property="BorderBrush" Value="#3D3D3D"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="border" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="6" Padding="14,10">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#383838"/>
                            </Trigger>
                            <Trigger Property="IsPressed" Value="True">
                                <Setter TargetName="border" Property="Background" Value="#252525"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>

    <Grid Margin="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <!-- Header -->
        <StackPanel Grid.Row="0" Margin="0,0,0,18">
            <TextBlock Text="Apple Color Emoji Switcher" FontSize="20" FontWeight="Bold" Foreground="#FFFFFF"/>
            <TextBlock Text="Change or revert your system-wide Windows 11 emoji font" FontSize="12" Foreground="#9E9E9E" Margin="0,3,0,0"/>
        </StackPanel>

        <!-- Status Card -->
        <Border Grid.Row="1" Background="#2A2A2A" BorderBrush="#383838" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,12">
            <Grid>
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="Auto"/>
                </Grid.ColumnDefinitions>
                <StackPanel Grid.Column="0">
                    <TextBlock Text="ACTIVE SYSTEM EMOJI" FontSize="10" FontWeight="Bold" Foreground="#888888"/>
                    <TextBlock x:Name="CurrentStatusText" Text="Detecting..." FontSize="15" FontWeight="SemiBold" Foreground="#60CDFF" Margin="0,3,0,0"/>
                </StackPanel>
                <Border x:Name="StatusBadge" Grid.Column="1" Background="#1C3829" CornerRadius="12" Padding="10,4" VerticalAlignment="Center">
                    <TextBlock x:Name="StatusBadgeText" Text="ACTIVE" FontSize="11" FontWeight="Bold" Foreground="#57D38C"/>
                </Border>
            </Grid>
        </Border>

        <!-- File Check Card -->
        <Border Grid.Row="2" Background="#2A2A2A" BorderBrush="#383838" BorderThickness="1" CornerRadius="8" Padding="16" Margin="0,0,0,18">
            <StackPanel>
                <TextBlock Text="LOCAL FONT ASSET" FontSize="10" FontWeight="Bold" Foreground="#888888"/>
                <TextBlock x:Name="FontFileStatusText" Text="Checking..." FontSize="13" Foreground="#D0D0D0" Margin="0,4,0,0"/>
            </StackPanel>
        </Border>

        <!-- Actions -->
        <StackPanel Grid.Row="3" VerticalAlignment="Top">
            <Button x:Name="BtnApply" Style="{StaticResource AccentBtn}" Content="Apply Apple Color Emoji" Height="42" Margin="0,0,0,10"/>
            <Button x:Name="BtnRevert" Style="{StaticResource SecondaryBtn}" Content="Revert to Default Windows Emoji" Height="42" Margin="0,0,0,10"/>
        </StackPanel>

        <!-- Notification Bar & Restart Button -->
        <StackPanel Grid.Row="4" Margin="0,10,0,0">
            <Border x:Name="MessageBanner" Background="#262626" BorderBrush="#3D3D3D" BorderThickness="1" CornerRadius="6" Padding="12,8" Visibility="Collapsed" Margin="0,0,0,10">
                <TextBlock x:Name="MessageText" Text="" FontSize="12" Foreground="#FFD580" TextWrapping="Wrap"/>
            </Border>
            <Button x:Name="BtnRestart" Style="{StaticResource SecondaryBtn}" Content="Restart PC Now" Height="36" Visibility="Collapsed"/>
        </StackPanel>
    </Grid>
</Window>
"@

# 5. Build Window
$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

# Get Controls
$CurrentStatusText = $window.FindName("CurrentStatusText")
$StatusBadge = $window.FindName("StatusBadge")
$StatusBadgeText = $window.FindName("StatusBadgeText")
$FontFileStatusText = $window.FindName("FontFileStatusText")
$BtnApply = $window.FindName("BtnApply")
$BtnRevert = $window.FindName("BtnRevert")
$BtnRestart = $window.FindName("BtnRestart")
$MessageBanner = $window.FindName("MessageBanner")
$MessageText = $window.FindName("MessageText")

# 6. Helper Functions
function Refresh-UIState {
    # Check current registry mapping
    $currentFont = (Get-ItemProperty -Path $RegPath -Name "Segoe UI Emoji (TrueType)" -ErrorAction SilentlyContinue)."Segoe UI Emoji (TrueType)"
    
    if ($currentFont -eq $FontFileName) {
        $CurrentStatusText.Text = "Apple Color Emoji"
        $CurrentStatusText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#60CDFF")
        $StatusBadge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#183B2B")
        $StatusBadgeText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#57D38C")
        $StatusBadgeText.Text = "APPLIED"
    } elseif ($currentFont -eq "seguiemj.ttf") {
        $CurrentStatusText.Text = "Windows Default (Segoe UI)"
        $CurrentStatusText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFFFFF")
        $StatusBadge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#332A15")
        $StatusBadgeText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FFD580")
        $StatusBadgeText.Text = "DEFAULT"
    } else {
        $CurrentStatusText.Text = "Custom ($currentFont)"
        $CurrentStatusText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FF9999")
        $StatusBadge.Background = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#3B1B1B")
        $StatusBadgeText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FF8080")
        $StatusBadgeText.Text = "CUSTOM"
    }

    # Verify font existence
    if (Test-Path $FontSourcePath) {
        $FontFileStatusText.Text = "[Ready] Found: $FontFileName in folder"
        $FontFileStatusText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#57D38C")
        $BtnApply.IsEnabled = $true
    } else {
        $FontFileStatusText.Text = "[Missing] Put '$FontFileName' next to this script!"
        $FontFileStatusText.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString("#FF6B6B")
        $BtnApply.IsEnabled = $false
    }
}

# 7. Button Handlers
$BtnApply.Add_Click({
    try {
        # Copy to C:\Windows\Fonts
        Copy-Item -Path $FontSourcePath -Destination $FontTargetPath -Force -ErrorAction Stop
        
        # Configure Registry
        Set-ItemProperty -Path $RegPath -Name "Segoe UI Emoji (TrueType)" -Value $FontFileName -Type String
        Set-ItemProperty -Path $RegPath -Name "Apple Color Emoji (TrueType)" -Value $FontFileName -Type String
        
        Refresh-UIState
        $MessageText.Text = "Applied successfully! A full restart is required to reload the system emoji cache."
        $MessageBanner.Visibility = "Visible"
        $BtnRestart.Visibility = "Visible"
    }
    catch {
        $MessageText.Text = "Error applying font: $_"
        $MessageBanner.Visibility = "Visible"
    }
})

$BtnRevert.Add_Click({
    try {
        # Reset Registry back to standard Windows emoji
        Set-ItemProperty -Path $RegPath -Name "Segoe UI Emoji (TrueType)" -Value "seguiemj.ttf" -Type String
        Remove-ItemProperty -Path $RegPath -Name "Apple Color Emoji (TrueType)" -ErrorAction SilentlyContinue
        
        Refresh-UIState
        $MessageText.Text = "Reverted to default! Please restart your PC to refresh all running apps."
        $MessageBanner.Visibility = "Visible"
        $BtnRestart.Visibility = "Visible"
    }
    catch {
        $MessageText.Text = "Error reverting font: $_"
        $MessageBanner.Visibility = "Visible"
    }
})

$BtnRestart.Add_Click({
    $promptMsg = "Your PC will restart in 5 seconds. Save all open work!`n`nDo you want to proceed?"
    $result = [System.Windows.MessageBox]::Show(
        $promptMsg,
        "Restart Required",
        [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )

    if ($result -eq [System.Windows.MessageBoxResult]::Yes) {
        shutdown.exe /r /t 5 /c "Restarting to apply font updates..."
        $window.Close()
    }
})

# Initial render
Refresh-UIState

# Show UI
$window.ShowDialog() | Out-Null