<# 
Author: Navid Rastegani 
Email: navid.rastegani@optus.com.au 
Description: Automates daily NAS cloning, NDMP backup configuration, and deletion of a PowerStore NAS server clone with a 35-day retention policy.
Includes error handling, wait for completion, and sends alerts via SNMP (optional) and SMTP in case of failures.
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
$MaxWaitTime = 600                                # Max wait time for completion (seconds)

# SNMP Alert Configuration (Set to $null to disable SNMP)
$SNMPServer = $null                               # Set to SNMP server IP to enable, or $null to disable
$CommunityString = "public"                       # SNMP community string

# SMTP Email Alert Configuration
$SMTPServer = "<SMTP_Server_IP>"                  # SMTP server IP
$SMTPFrom = "alerts@example.com"                  # From address for alert emails
$SMTPTo = "admin@example.com"                     # To address for alert emails
$SMTPSubject = "PowerStore NAS Backup Script Error"

# Encode credentials for PowerStore API authentication
$authInfo = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$User:$Password"))

# Function: Send SNMP Alert (optional)
function Send-SNMPAlert {
    param (
        [string]$ErrorMessage
    )
    if ($SNMPServer) {
        Write-Output "Sending SNMP alert for error: $ErrorMessage"
        snmptrap -v 2c -c $CommunityString $SNMPServer '' .1.3.6.1.4.1.5000 "s" "$ErrorMessage"
    } else {
        Write-Output "SNMP alert skipped as SNMPServer is not set."
    }
}

# Function: Send Email Alert
function Send-EmailAlert {
    param (
        [string]$ErrorMessage
    )
    Write-Output "Sending email alert for error: $ErrorMessage"
    Send-MailMessage -SmtpServer $SMTPServer -From $SMTPFrom -To $SMTPTo -Subject $SMTPSubject -Body $ErrorMessage
}

# Function: Create a daily clone of the DR NAS server
function New-NASClone {
    param ($nasServerID, $cloneName)
    try {
        $uri = "$PowerStoreAPI/nas_server/$nasServerID/clone"
        $body = @{
            name = $cloneName
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{Authorization = "Basic $authInfo"} -Body $body -ContentType "application/json"
        return $response.id # Returns the Clone ID for further steps
    } catch {
        $ErrorMessage = "Failed to create NAS clone: $($_.Exception.Message)"
        Write-Output $ErrorMessage
        Send-SNMPAlert -ErrorMessage $ErrorMessage
        Send-EmailAlert -ErrorMessage $ErrorMessage
        throw
    }
}

# Function: Check Clone Completion
function WaitForCloneCompletion {
    param ($cloneID, $maxWaitTime)
    $uri = "$PowerStoreAPI/nas_server/$cloneID"
    $elapsedTime = 0
    $checkInterval = 15 # Check every 15 seconds

    while ($elapsedTime -lt $maxWaitTime) {
        try {
            $status = Invoke-RestMethod -Uri $uri -Method Get -Headers @{Authorization = "Basic $authInfo"}
            if ($status.state -eq "ready") {
                Write-Output "Clone is ready for backup."
                return $true
            } else {
                Write-Output "Waiting for clone to be ready... (Status: $($status.state))"
                Start-Sleep -Seconds $checkInterval
                $elapsedTime += $checkInterval
            }
        } catch {
            $ErrorMessage = "Failed to check clone status: $($_.Exception.Message)"
            Write-Output $ErrorMessage
            Send-SNMPAlert -ErrorMessage $ErrorMessage
            Send-EmailAlert -ErrorMessage $ErrorMessage
            throw
        }
    }

    # Timeout reached
    $ErrorMessage = "Clone did not complete within the allowed wait time ($maxWaitTime seconds)."
    Write-Output $ErrorMessage
    Send-SNMPAlert -ErrorMessage $ErrorMessage
    Send-EmailAlert -ErrorMessage $ErrorMessage
    throw $ErrorMessage
}

# Function: Configure NDMP for Backup
function Configure-NDMP {
    param ($cloneID, $username, $password)
    try {
        $uri = "$PowerStoreAPI/file_ndmp/create"
        $body = @{
            nas_server_id = $cloneID
            user_name = $username
            password = $password
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{Authorization = "Basic $authInfo"} -Body $body -ContentType "application/json"
        return $response
    } catch {
        $ErrorMessage = "Failed to configure NDMP: $($_.Exception.Message)"
        Write-Output $ErrorMessage
        Send-SNMPAlert -ErrorMessage $ErrorMessage
        Send-EmailAlert -ErrorMessage $ErrorMessage
        throw
    }
}

# Function: Delete Clones Older Than Retention Period
function Delete-OldClones {
    param ($nasServerID, $retentionDays)
    try {
        $uri = "$PowerStoreAPI/nas_server"
        $clones = Invoke-RestMethod -Uri $uri -Method Get -Headers @{Authorization = "Basic $authInfo"}
        
        $expiryDate = (Get-Date).AddDays(-$retentionDays)
        $oldClones = $clones | Where-Object { $_.creation_timestamp -lt $expiryDate }

        foreach ($clone in $oldClones) {
            $cloneUri = "$PowerStoreAPI/nas_server/$($clone.id)"
            Write-Output "Deleting clone with ID: $($clone.id)"
            Invoke-RestMethod -Uri $cloneUri -Method Delete -Headers @{Authorization = "Basic $authInfo"}
        }
    } catch {
        $ErrorMessage = "Failed to delete old clones: $($_.Exception.Message)"
        Write-Output $ErrorMessage
        Send-SNMPAlert -ErrorMessage $ErrorMessage
        Send-EmailAlert -ErrorMessage $ErrorMessage
        throw
    }
}

# Main Workflow
try {
    # Step 1: Clone the NAS server at DR site
    Write-Output "Creating a clone of the DR NAS server for backup..."
    $cloneID = New-NASClone -nasServerID $DR_NAS_Server_ID -cloneName $CloneName
    Write-Output "Clone created successfully with ID: $cloneID"

    # Step 2: Wait for clone to be ready before configuring NDMP and starting backup
    Write-Output "Checking if the clone is ready for backup..."
    WaitForCloneCompletion -cloneID $cloneID -maxWaitTime $MaxWaitTime

    # Step 3: Configure NDMP on the clone for backup purposes
    Write-Output "Configuring NDMP on the cloned NAS server..."
    $ndmpConfigResponse = Configure-NDMP -cloneID $cloneID -username $NDMP_User -password $NDMP_Password
    Write-Output "NDMP configuration completed successfully for clone."

    # Perform your backup operations here (assuming your NDMP client initiates the backup using the clone ID)

    # Step 4: Apply retention policy for clones older than $RetentionDays days
    Write-Output "Applying retention policy for clones older than $RetentionDays days..."
    Delete-OldClones -nasServerID $DR_NAS_Server_ID -retentionDays $RetentionDays
    Write-Output "Old clones deleted according to retention policy."

    Write-Output "Daily NAS cloning, backup, and cleanup completed successfully."

} catch {
    $ErrorMessage = "An error occurred during the main workflow: $($_.Exception.Message)"
    Write-Output $ErrorMessage
    Send-SNMPAlert -ErrorMessage $ErrorMessage
    Send-EmailAlert -ErrorMessage $ErrorMessage
}
