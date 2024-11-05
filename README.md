## Script Code

Below is the full PowerShell script that automates NAS cloning and NDMP backup configuration. Replace all placeholder values as instructed in the script comments.

```powershell
<#
Author: Navid Rastegani
Email: navid.rastegani@optus.com.au
Description: This script automates the daily cloning, IP assignment, and NDMP backup configuration for a PowerStore NAS server at the DR site. The clone is used for automated NDMP backups, providing a hands-free solution for consistent, isolated backup preparation.
#>

# PowerStore API Endpoint and Credentials
$PowerStoreAPI = "https://<PowerStore_IP>/api/rest" # Replace with PowerStore API IP
$User = "<username>"                              # PowerStore API username
$Password = "<password>"                          # PowerStore API password

# NAS and NDMP Configuration
$DR_NAS_Server_ID = "<DR_NAS_Server_ID>"          # Replace with NAS server ID at DR site
$CloneName = "Daily_Clone_$(Get-Date -Format 'yyyyMMdd')" # Clone name includes the date for easy identification
$Clone_IP = "<Clone_IP_Address>"                  # Static IP address for the cloned NAS
$Clone_Gateway = "<Gateway_IP>"                   # Gateway IP in the DR network
$NDMP_User = "<NDMP_User>"                        # NDMP username for backup access
$NDMP_Password = "<NDMP_Password>"                # NDMP password for backup access

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

# Function: Assign a static IP to the cloned NAS server
function Assign-IPToClone {
    param ($cloneID, $ipAddress, $gateway)
    $uri = "$PowerStoreAPI/file_interface/create"
    $body = @{
        nas_server_id = $cloneID
        ip_address = $ipAddress
        gateway = $gateway
        role = "Backup"
        is_disabled = $false
    } | ConvertTo-Json

    # Send request to PowerStore API to assign the IP to the clone
    $response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{Authorization = "Basic $authInfo"} -Body $body -ContentType "application/json"
    return $response
}

# Function: Set up NDMP credentials on the cloned NAS server
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

# Main Workflow
try {
    # Step 1: Clone the NAS server at DR site
    Write-Output "Creating a clone of the DR NAS server..."
    $cloneID = New-NASClone -nasServerID $DR_NAS_Server_ID -cloneName $CloneName
    Write-Output "Clone created successfully with ID: $cloneID"

    # Step 2: Assign a static IP to the cloned NAS server
    Write-Output "Assigning static IP to the cloned NAS server..."
    $ipAssignResponse = Assign-IPToClone -cloneID $cloneID -ipAddress $Clone_IP -gateway $Clone_Gateway
    Write-Output "IP assignment completed for the clone."

    # Step 3: Configure NDMP on the clone for backup purposes
    Write-Output "Configuring NDMP on the cloned NAS server..."
    $ndmpConfigResponse = Configure-NDMP -cloneID $cloneID -username $NDMP_User -password $NDMP_Password
    Write-Output "NDMP configuration completed successfully for clone."

    Write-Output "Daily NAS cloning and backup preparation completed successfully."

} catch {
    Write-Output "An error occurred: $_"
}
