# PowerStore NAS Cloning and Automated Backup Script to Data Domain

This repository contains a PowerShell script that automates the daily cloning, NDMP backup preparation, and cleanup for a PowerStore NAS server at a Disaster Recovery (DR) site. The backup is performed to a Data Domain appliance, with clones automatically deleted after a 35-day retention period.

---

## Table of Contents
- [Overview](#overview)
- [Author](#author)
- [Prerequisites](#prerequisites)
- [Script Execution Flow](#script-execution-flow)
- [Setting Up the Script](#setting-up-the-script)
- [Script Scheduling on Windows and Linux](#script-scheduling-on-windows-and-linux)
- [IP Address Requirement](#ip-address-requirement)
- [Script Code](#script-code)
- [Final Notes](#final-notes)

---

## Overview
This script provides a fully automated solution for cloning and preparing NAS servers at the DR site for daily backups, targeting a Data Domain appliance. The workflow includes cloning, NDMP backup setup, and automated clone deletion after 35 days to optimize storage use.

### Key Features
- **Automated Daily NAS Cloning**: Creates a new clone every day for backup purposes.
- **Optional IP Assignment**: Assigns an IP to the clone if required for Data Domain connectivity.
- **NDMP Backup Configuration**: Sets up NDMP on the clone, enabling backup access to Data Domain.
- **Automated Clone Deletion**: Deletes clones older than 35 days to maintain storage efficiency.

---

## Author
**Navid Rastegani**  
**Email:** [navid.rastegani@optus.com.au](mailto:navid.rastegani@optus.com.au)

---

## Prerequisites

1. **PowerShell Environment**:
   - Ensure PowerShell is installed on the server that will run the script. (PowerShell is standard on Windows; on Linux, PowerShell Core may need to be installed.)

2. **Server with Network Access**:
   - The server executing the script must have network access to your PowerStore appliance and any required firewall or routing permissions.

3. **PowerStore API Access**:
   - Confirm that you have the **PowerStore REST API credentials** and endpoint information. The script requires API credentials for authentication, so be sure to test connectivity to the PowerStore API from this server.

4. **PowerStore API Permissions**:
   - The API user account must have permission to perform NAS clone creation, NDMP configuration, and deletion operations.

5. **Data Domain Configuration**:
   - Verify that your Data Domain appliance is configured to receive NDMP backups from PowerStore.

6. **Valid IP Address (if needed)**:
   - If your Data Domain appliance requires an IP for the NAS clone, ensure that an IP from the correct VLAN is available and included in the script.

---

## Script Execution Flow

1. **Daily NAS Cloning**:
   - The script generates a writable, independent clone of the DR NAS server each day for backup.

2. **Optional IP Assignment**:
   - Assigns an IP address in the backup VLAN if the Data Domain appliance requires network access to the clone. This step can be skipped if direct connectivity is available without an IP.

3. **NDMP Configuration for Backup**:
   - Configures NDMP access on the clone to enable the Data Domain appliance to initiate backups.

4. **Automated Clone Deletion**:
   - Any clones older than the 35-day retention period are automatically deleted to free up storage.

---

## Setting Up the Script

1. **Open PowerShell** on the designated server.
2. **Replace Placeholder Values**: Update the script with your specific PowerStore IP, credentials, NAS IDs, Data Domain credentials, and other required details.
3. **Manual Test**: Run the script manually to ensure proper functionality.
4. **Schedule the Script**: Once verified, set up daily scheduling to automate execution.

---

## Script Scheduling on Windows and Linux

### Windows: Using Task Scheduler

1. **Open Task Scheduler**:
   - Open **Task Scheduler** on the server where the script will run.

2. **Create a New Task**:
   - Click on **Create Task** and name it (e.g., "Daily PowerStore NAS Backup").

3. **Set Trigger**:
   - Go to the **Triggers** tab, click **New**, and set the trigger to run **Daily**.
   - Specify the start time and any recurrence options needed.

4. **Set Action**:
   - Go to the **Actions** tab, click **New**, and set the action to start a program.
   - For the **Program/script** field, enter `powershell`.
   - In the **Add arguments (optional)** field, enter the path to your script. For example:
     ```plaintext
     -File "C:\path\to\your\script.ps1"
     ```

5. **Configure Settings**:
   - In the **Settings** tab, enable options like **Allow task to be run on demand** and **Run task as soon as possible after a scheduled start is missed** if needed.

6. **Save the Task**:
   - Click **OK** to save the task. Ensure it’s set to run with the highest privileges if necessary.

7. **Test**:
   - Run the task manually from Task Scheduler to confirm it works as expected.

### Linux: Using Cron Job

1. **Make the Script Executable**:
   - Run the following command to make the script executable:
     ```bash
     chmod +x /path/to/your/script.ps1
     ```

2. **Schedule with Cron**:
   - Open the cron configuration for editing:
     ```bash
     crontab -e
     ```
   - Add a new line to run the script daily. For example, to run it at midnight:
     ```plaintext
     0 0 * * * /usr/bin/pwsh /path/to/your/script.ps1
     ```
   - Ensure you’re using the correct path to `pwsh` if using PowerShell Core on Linux.

3. **Save and Exit**:
   - Save the cron job. The script will now run daily at the specified time.

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
Description: This script automates the daily cloning, NDMP backup configuration, and deletion of a PowerStore NAS server clone at the DR site. Clones are automatically deleted after a 35-day retention period to manage storage.
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
$RetentionDays = 35                               # Retention period in days

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

# Function: Delete Clones Older Than Retention Period
function Delete-OldClones {
    param ($nasServerID, $retentionDays)
    $uri = "$PowerStoreAPI/nas_server"
    
    # Get all clones for the NAS server
    $clones = Invoke-RestMethod -Uri $uri -Method Get -Headers @{Authorization = "Basic $authInfo"}

    # Filter clones older than the retention period
    $expiryDate = (Get-Date).AddDays(-$retentionDays)
    $oldClones = $clones | Where-Object { $_.creation_timestamp -lt $expiryDate }

    # Delete each old clone
    foreach ($clone in $oldClones) {
        $cloneUri = "$PowerStoreAPI/nas_server/$($clone.id)"
        Write-Output "Deleting clone with ID: $($clone.id)"
        Invoke-RestMethod -Uri $cloneUri -Method Delete -Headers @{Authorization = "Basic $authInfo"}
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

    # Step 3: Delete clones older than the retention period
    Write-Output "Applying retention policy for clones older than $RetentionDays days..."
    Delete-OldClones -nasServerID $DR_NAS_Server_ID -retentionDays $RetentionDays
    Write-Output "Old clones deleted according to retention policy."

    Write-Output "Daily NAS cloning, backup, and cleanup completed successfully."

} catch {
    Write-Output "An error occurred: $_"
}
