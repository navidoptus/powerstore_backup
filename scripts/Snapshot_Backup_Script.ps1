<#
Author: Navid Rastegani
Email: navid.rastegani@optus.com.au
Description: Automates daily creation of file system snapshots, NDMP backup configuration, and deletion of PowerStore NAS server snapshots with a 35-day retention policy.
#>

# PowerStore API Endpoint and Credentials
$PowerStoreAPI = "https://<PowerStore_IP>/api/rest" # Replace with PowerStore API IP
$User = "<username>"                              # PowerStore API username
$Password = "<password>"                          # PowerStore API password

# NAS and NDMP Configuration
$DR_NAS_Server_ID = "<DR_NAS_Server_ID>"          # Replace with NAS server ID at DR site
$FileSystemIDs = @("<FileSystem_ID1>", "<FileSystem_ID2>")  # List of file system IDs to snapshot
$NDMP_User = "<NDMP_User>"                        # NDMP username for backup access
$NDMP_Password = "<NDMP_Password>"                # NDMP password for backup access
$RetentionDays = 35                               # Retention period in days

# Encode credentials for PowerStore API authentication
$authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$User:$Password"))

# Function: Create a snapshot of a file system
function New-FileSystemSnapshot {
    param ($fileSystemID, $snapshotName)
    $uri = "$PowerStoreAPI/file_system/$fileSystemID/snapshot"
    $body = @{
        name = $snapshotName
    } | ConvertTo-Json

    # Send request to PowerStore API to create the snapshot
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{Authorization = "Basic $authInfo"} -Body $body -ContentType "application/json"
    return $response.id # Returns the Snapshot ID for further steps
}

# Function: Configure NDMP for Backup
function Configure-NDMP {
    param ($fileSystemID, $username, $password)
    $uri = "$PowerStoreAPI/file_ndmp/create"
    $body = @{
        nas_server_id = $DR_NAS_Server_ID
        file_system_id = $fileSystemID
        user_name = $username
        password = $password
    } | ConvertTo-Json

    # Send request to PowerStore API to configure NDMP on the file system snapshot
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{Authorization = "Basic $authInfo"} -Body $body -ContentType "application/json"
    return $response
}

# Function: Delete snapshots older than retention period
function Delete-OldSnapshots {
    param ($fileSystemID, $retentionDays)
    $uri = "$PowerStoreAPI/file_system/$fileSystemID/snapshot"

    # Get all snapshots for the file system
    $snapshots = Invoke-RestMethod -Uri $uri -Method Get -Headers @{Authorization = "Basic $authInfo"}

    # Filter snapshots older than the retention period
    $expiryDate = (Get-Date).AddDays(-$retentionDays)
    $oldSnapshots = $snapshots | Where-Object { $_.creation_timestamp -lt $expiryDate }

    # Delete each old snapshot
    foreach ($snapshot in $oldSnapshots) {
        $snapshotUri = "$PowerStoreAPI/file_system/$fileSystemID/snapshot/$($snapshot.id)"
        Write-Output "Deleting snapshot with ID: $($snapshot.id)"
        Invoke-RestMethod -Uri $snapshotUri -Method Delete -Headers @{Authorization = "Basic $authInfo"}
    }
}

# Main Workflow
try {
    foreach ($fileSystemID in $FileSystemIDs) {
        # Step 1: Create a snapshot of each file system for backup
        $snapshotName = "Backup_Snapshot_$(Get-Date -Format 'yyyyMMdd')"
        Write-Output "Creating a snapshot of file system ID: $fileSystemID for backup..."
        $snapshotID = New-FileSystemSnapshot -fileSystemID $fileSystemID -snapshotName $snapshotName
        Write-Output "Snapshot created successfully with ID: $snapshotID"

        # Step 2: Configure NDMP for the file system snapshot for backup purposes
        Write-Output "Configuring NDMP on the file system snapshot..."
        $ndmpConfigResponse = Configure-NDMP -fileSystemID $fileSystemID -username $NDMP_User -password $NDMP_Password
        Write-Output "NDMP configuration completed successfully for snapshot."

        # Step 3: Delete snapshots older than retention period
        Write-Output "Applying retention policy for snapshots older than $RetentionDays days..."
        Delete-OldSnapshots -fileSystemID $fileSystemID -retentionDays $RetentionDays
    }

    Write-Output "Daily file system snapshot creation, backup, and cleanup completed successfully."

} catch {
    Write-Output "An error occurred: $_"
}
