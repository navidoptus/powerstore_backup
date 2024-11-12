# PowerStore NAS Backup Installation Guide

## Table of Contents
- [Prerequisites](#prerequisites)
- [Installation Steps](#installation-steps)
  - [PowerShell Setup](#powershell-setup)
  - [Network Configuration](#network-configuration)
  - [PowerStore Configuration](#powerstore-configuration)
  - [Data Domain Setup](#data-domain-setup)
- [Script Configuration](#script-configuration)
- [Scheduling](#scheduling)
  - [Windows Task Scheduler](#windows-task-scheduler)
  - [Linux Cron](#linux-cron)
- [Testing](#testing)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements
- Windows Server 2016 or later / Linux with PowerShell Core 7.0+
- Minimum 4GB RAM
- 50GB available disk space
- Network connectivity to PowerStore and Data Domain systems

### Required Permissions
1. **PowerStore Access**:
   - Administrator role or custom role with the following permissions:
     - NAS Server management
     - Snapshot management
     - Clone operations
     - NDMP configuration

2. **Data Domain Access**:
   - NDMP administrator privileges
   - Backup operator role

### Software Dependencies
1. **PowerShell Modules**:
   ```powershell
   # Install required PowerShell modules
   Install-Module -Name DellPowerStore -Force
   Install-Module -Name PSScheduledJob -Force
   ```

## Installation Steps

### PowerShell Setup

1. **Enable PowerShell Execution**:
   ```powershell
   # Run as Administrator
   Set-ExecutionPolicy RemoteSigned
   ```

2. **Verify PowerShell Version**:
   ```powershell
   $PSVersionTable.PSVersion
   # Should be 5.1 or higher for Windows PowerShell
   # Or 7.0+ for PowerShell Core
   ```

### Network Configuration

1. **Firewall Rules**:
   - Enable the following ports:
     - PowerStore Management: TCP 443
     - NDMP: TCP 10000
     - REST API: TCP 8443

2. **Network Connectivity Test**:
   ```powershell
   # Test PowerStore connectivity
   Test-NetConnection -ComputerName <powerstore_ip> -Port 443
   
   # Test Data Domain connectivity
   Test-NetConnection -ComputerName <datadomain_ip> -Port 10000
   ```

### PowerStore Configuration

1. **API Access Setup**:
   - Log into PowerStore management interface
   - Navigate to Settings → Users
   - Create a service account for automation
   - Generate and save API credentials

2. **NDMP Configuration**:
   ```powershell
   # Example PowerStore NDMP setup
   $PowerStoreAuth = @{
       Username = "service_account"
       Password = "your_password"
       Server = "powerstore.example.com"
   }
   
   # Configure NDMP
   Connect-PowerStore @PowerStoreAuth
   Set-PowerStoreNDMP -Enabled $true -AuthType SIMPLE
   ```

### Data Domain Setup

1. **NDMP Configuration**:
   - Access Data Domain management interface
   - Enable NDMP daemon
   - Configure NDMP user credentials
   - Set up backup paths

## Script Configuration

1. **Clone Repository**:
   ```bash
   git clone https://github.com/navidoptus/powerstore_backup.git
   cd powerstore_backup
   ```

2. **Configure Credentials**:
   - Create a credentials file:
   ```powershell
   # Create encrypted credentials file
   $CredPath = ".\config\credentials.xml"
   
   # PowerStore credentials
   Get-Credential -Message "Enter PowerStore credentials" | 
       Export-Clixml -Path $CredPath
   
   # Data Domain credentials
   Get-Credential -Message "Enter Data Domain credentials" |
       Export-Clixml -Path ".\config\dd_credentials.xml"
   ```

3. **Update Configuration**:
   Edit `scripts/config.ps1`:
   ```powershell
   # Configuration parameters
   $Config = @{
       PowerStoreHost = "powerstore.example.com"
       DataDomainHost = "datadomain.example.com"
       NASServer = "nas_server_name"
       RetentionDays = 35
       BackupType = "Clone"  # or "Snapshot"
   }
   ```

## Scheduling

### Windows Task Scheduler

1. **Create Task**:
   ```powershell
   # Create scheduled task
   $Action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
       -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$PWD\scripts\Clone_Backup_Script.ps1`""
   
   $Trigger = New-ScheduledTaskTrigger -Daily -At 2AM
   
   Register-ScheduledTask -TaskName "PowerStore Backup" -Action $Action `
       -Trigger $Trigger -RunLevel Highest -Description "Daily PowerStore NAS backup"
   ```

2. **Verify Task**:
   - Open Task Scheduler
   - Locate "PowerStore Backup" task
   - Check Last Run Result
   - Review History

### Linux Cron

1. **Create Cron Job**:
   ```bash
   # Edit crontab
   crontab -e
   
   # Add backup job (runs at 2 AM daily)
   0 2 * * * pwsh /path/to/scripts/Clone_Backup_Script.ps1
   ```

2. **Verify Cron Job**:
   ```bash
   # List cron jobs
   crontab -l
   
   # Check cron logs
   grep CRON /var/log/syslog
   ```

## Testing

1. **Initial Test**:
   ```powershell
   # Test clone backup
   .\scripts\Clone_Backup_Script.ps1 -TestMode
   
   # Test snapshot backup
   .\scripts\Snapshot_Backup_Script.ps1 -TestMode
   ```

2. **Verify Backup**:
   - Check PowerStore for clone/snapshot creation
   - Verify NDMP backup job on Data Domain
   - Check logs for any errors

## Troubleshooting

### Common Issues

1. **Authentication Failures**:
   - Verify credentials in config files
   - Check service account permissions
   - Ensure network connectivity

2. **Backup Failures**:
   ```powershell
   # Check PowerStore connection
   Test-PowerStoreConnection -Server $Config.PowerStoreHost
   
   # Review logs
   Get-Content -Path ".\logs\backup_$(Get-Date -Format 'yyyyMMdd').log"
   ```

3. **NDMP Issues**:
   - Verify NDMP service status
   - Check firewall rules
   - Review Data Domain logs

### Support

For technical support:
- Open an issue on GitHub
- Contact Optus Storage Engineering Team
- Review PowerStore and Data Domain documentation

---

*Document maintained by Navid Rastegani, Optus Storage Engineering Team*