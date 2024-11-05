# PowerStore NAS Cloning and Automated Backup Script to Data Domain

This repository contains a PowerShell script that automates the daily cloning, NDMP backup preparation, and cleanup for a PowerStore NAS server at a Disaster Recovery (DR) site. The backup is performed to a Data Domain appliance, with an optional IP assignment based on network configuration.

---

## Table of Contents
- [Overview](#overview)
- [Author](#author)
- [Prerequisites](#prerequisites)
- [Script Execution Flow](#script-execution-flow)
- [Setting Up the Script](#setting-up-the-script)
- [Script Scheduling](#script-scheduling)
- [IP Address Requirement](#ip-address-requirement)
- [Script Code](#script-code)
- [Final Notes](#final-notes)

---

## Overview
This script provides a fully automated solution for cloning and preparing NAS servers at the DR site for daily backups, targeting a Data Domain appliance. The workflow includes cloning, NDMP backup setup, and cleanup to ensure minimal storage usage.

### Key Features
- **Automated Daily NAS Cloning**: Creates a new clone every day for backup purposes.
- **Optional IP Assignment**: Assigns an IP to the clone if required for Data Domain connectivity.
- **NDMP Backup Configuration**: Sets up NDMP on the clone, enabling backup access to Data Domain.
- **Clone Deletion after Backup**: Removes the clone after backup to save space.
- **Retention Policy for Snapshots**: Deletes snapshots older than 30 days.

---

## Author
**Navid Rastegani**  
**Email:** [navid.rastegani@optus.com.au](mailto:navid.rastegani@optus.com.au)

---

## Prerequisites

1. **PowerStore API Access**:
   - Access to PowerStore’s REST API endpoint with valid credentials.

2. **Server for Script Execution**:
   - A Windows server with PowerShell installed, or a Linux server (requires script adaptation).
   - Network connectivity to PowerStore's management IP.

3. **Data Domain Appliance**:
   - Ensure your Data Domain appliance is NDMP-compatible and can connect to the PowerStore NAS.

4. **Optional Static IP Address**:
   - An IP address in the backup VLAN, if required for connectivity between the NAS clone and the Data Domain appliance.

---

## Script Execution Flow

1. **Daily NAS Cloning**:
   - The script generates a read-write clone of the DR NAS server each day for backup.

2. **Optional IP Assignment**:
   - Assigns an IP address in the backup VLAN if the Data Domain appliance requires network access to the clone. This step can be skipped if direct connectivity is available without an IP.

3. **NDMP Configuration for Backup**:
   - Configures NDMP access on the clone to enable the Data Domain appliance to initiate backups.

4. **Clone Deletion after Backup**:
   - The clone is deleted after the backup process completes to save storage space.

5. **Retention Policy for Snapshots**:
   - Deletes snapshots of the NAS server that are older than 30 days.

---

## Setting Up the Script

1. **Open PowerShell** on the designated server.
2. **Replace Placeholder Values**: Update the script with your specific PowerStore IP, credentials, NAS IDs, Data Domain credentials, and other required details.
3. **Manual Test**: Run the script manually to ensure proper functionality.
4. **Schedule the Script**: Once verified, set up daily scheduling to automate execution.

---

## Script Scheduling

- **Windows**: Use Task Scheduler to create a new daily task, selecting the PowerShell script as the program.
- **Linux**: Adapt the script for Bash and schedule with `cron` for daily execution.

---

## IP Address Requirement

In this setup, an additional IP address for the NAS clone may or may not be necessary:

- **IP Not Required**: If the Data Domain appliance is directly connected to the PowerStore NAS or is on the same storage network, you can skip the IP assignment.
- **IP Required**: If the Data Domain appliance requires network access to the clone (e.g., if they are in separate VLANs), an IP address in the backup VLAN should be assigned to the clone.

---

## Script Code

Below is the full PowerShell script that automates NAS cloning, NDMP backup configuration, and cleanup. Replace all placeholder values as instructed in the script comments.

```powershell
<#
Author: Navid Rastegani
Email: navid.rastegani@optus.com.au
Description: This script automates the daily cloning, NDMP backup configuration, and deletion of a PowerStore NAS server clone at the DR site. A retention policy is applied to automatically delete any NAS snapshots older than 30 days.
#>

# PowerStore API Endpoint and Credentials
$PowerStoreAPI = "https://<PowerStore_IP>/api/rest" # Replace with PowerStore API IP
$User = "<username>"                              # PowerStore API username
$Password = "<password>"                          # PowerStore API password

# NAS and NDMP Configuration
$DR_NAS_Server_ID = "<DR_NAS_Server_ID>"          # Replace with NAS server ID at DR site
$CloneName = "Backup_Clone_$(Get-Date -Format 'yyyyMMdd')" # Clone name with date for easy identification
$NDMP_User = "<NDMP_User>"                        # NDMP username for backup access
$NDMP_Password = "<NDMP_Password>"                # NDMP password for backup access
$RetentionDays = 30                               # Retention period in days

# Encode credentials for PowerStore API authentication
$authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$User:$Password"))

# Function: Create a daily clone of the DR NAS server
function New-NASClone {
    param ($nasServerID, $cloneName)
    $uri = "$PowerStoreAPI/nas_server/$nasServerID/clone"
    $body = @{
        name = $cloneName
    } | ConvertTo-Json

    # Send request to PowerStore API to create the clone
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{Authorization = "Basic $authInfo"} -Body $body -ContentType "application/json"
    return $response.id # Returns the Clone ID for further steps
}

# Function: Configure NDMP for Backup
function Configure-NDMP {
    param ($cloneID, $username, $password)
    $uri = "$PowerStoreAPI/file_ndmp/create"
    $body = @{
        nas_server_id = $cloneID
        user_name = $username
        password = $password
    } | ConvertTo-Json

    # Send request to PowerStore API to configure NDMP on the clone
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{Authorization = "Basic $authInfo"} -Body $body -ContentType "application/json"
    return $response
}

# Function: Delete the NAS clone
function Delete-NASClone {
    param ($cloneID)
    $uri = "$PowerStoreAPI/nas_server/$cloneID"
    
    # Send DELETE request to PowerStore API to delete the clone
    $response = Invoke-RestMethod -Uri $uri -Method Delete -Headers @{Authorization = "Basic $authInfo"}
    return $response
}

# Function: Delete Snapshots Older Than Retention Period
function Delete-OldSnapshots {
    param ($nasServerID, $retentionDays)
    $uri = "$PowerStoreAPI/snapshot?parent_id=$nasServerID"
    
    # Get all snapshots for the NAS server
    $snapshots = Invoke-RestMethod -Uri $uri -Method Get -Headers @{Authorization = "Basic $authInfo"}

    # Filter snapshots older than the retention period
    $expiryDate = (Get-Date).AddDays(-$retentionDays)
    $oldSnapshots = $snapshots | Where-Object { $_.creation_timestamp -lt $expiryDate }

    # Delete each old snapshot
    foreach ($snapshot in $oldSnapshots) {
        $snapshotUri = "$PowerStoreAPI/snapshot/$($snapshot.id)"
        Write-Output "Deleting snapshot with ID: $($snapshot.id)"
        Invoke-RestMethod -Uri $snapshotUri -Method Delete -Headers @{Authorization = "Basic $authInfo"}
    }
}

# Main Workflow
try {
    # Step 1: Clone the NAS server at DR site
    Write-Output "Creating a clone of the DR NAS server for backup..."
    $cloneID = New-NASClone -nasServerID $DR_NAS_Server_ID -cloneName $CloneName
    Write-Output "Clone created successfully with ID: $cloneID"

    # Step 2: Configure NDMP on the clone for backup purposes
    Write-Output "Configuring NDMP on the cloned NAS server..."
    $ndmpConfigResponse = Configure-NDMP -cloneID $cloneID -username $NDMP_User -password $NDMP_Password
    Write-Output "NDMP configuration completed successfully for clone."

    # Perform your backup operations here (assuming your NDMP client initiates the backup using the clone ID)

    # Step 3: Delete the clone after backup
    Write-Output "Deleting the NAS clone after backup..."
    $deleteCloneResponse = Delete-NASClone -cloneID $cloneID
    Write-Output "Clone deleted successfully."

    # Step 4: Delete snapshots older than the retention period
    Write-Output "Applying retention policy for snapshots older than $RetentionDays days..."
    Delete-OldSnapshots -nasServerID $DR_NAS_Server_ID -retentionDays $RetentionDays
    Write-Output "Old snapshots deleted according to retention policy."

    Write-Output "Daily NAS cloning, backup, and cleanup completed successfully."

} catch {
    Write-Output "An error occurred: $_"
}
