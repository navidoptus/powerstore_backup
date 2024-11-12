<#
Author: Navid Rastegani
Email: navid.rastegani@optus.com.au
Description: Automates daily NAS cloning, NDMP backup configuration, and deletion of a PowerStore NAS server clone with a 35-day retention policy.
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
