<# 
Author: Navid Rastegani 
Email: navid.rastegani@optus.com.au 
Description: Automates daily NAS snapshotting, NDMP backup configuration, and deletion of PowerStore NAS snapshots with a 35-day retention policy.
Includes error handling, wait for completion, and sends alerts via SNMP (optional) and SMTP in case of failures.
#>

# PowerStore API Endpoint and Credentials
$PowerStoreAPI = "https://<PowerStore_IP>/api/rest" # Replace with PowerStore API IP
$User = "<username>"                              # PowerStore API username
$Password = "<password>"                          # PowerStore API password

# NAS and NDMP Configuration
$NAS_FileSystem_ID = "<NAS_FileSystem_ID>"         # Replace with NAS FileSystem ID for snapshot
$SnapshotName = "Backup_Snapshot_$(Get-Date -Format 'yyyyMMdd')" # Snapshot name with date for easy identification
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
$SMTPSubject = "PowerStore NAS Snapshot Script Error"

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

# Function: Create a daily snapshot of the NAS FileSystem
function New-NASSnapshot {
    param ($fileSystemID, $snapshotName)
    try {
        $uri = "$PowerStoreAPI/file_system/$fileSystemID/snapshot"
        $body = @{
            name = $snapshotName
        } | ConvertTo-Json

        $response = Invoke-RestMethod -Uri $uri -Method Post -Headers @{Authorization = "Basic $authInfo"} -Body $body -ContentType "application/json"
        return $response.id # Returns the Snapshot ID for further steps
    } catch {
        $ErrorMessage = "Failed to create NAS snapshot: $($_.Exception.Message)"
        Write-Output $ErrorMessage
        Send-SNMPAlert -ErrorMessage $ErrorMessage
        Send-EmailAlert -ErrorMessage $ErrorMessage
        throw
    }
}

# Function: Check Snapshot Completion
function WaitForSnapshotCompletion {
    param ($snapshotID, $maxWaitTime)
    $uri = "$PowerStoreAPI/file_system_snapshot/$snapshotID"
    $elapsedTime = 0
    $checkInterval = 15 # Check every 15 seconds

    while ($elapsedTime -lt $maxWaitTime) {
        try {
            $status = Invoke-RestMethod -Uri $uri -Method Get -Headers @{Authorization = "Basic $authInfo"}
            if ($status.state -eq "ready") {
                Write-Output "Snapshot is ready for backup."
                return $true
            } else {
                Write-Output "Waiting for snapshot to be ready... (Status: $($status.state))"
                Start-Sleep -Seconds $checkInterval
                $elapsedTime += $checkInterval
            }
        } catch {
            $ErrorMessage = "Failed to check snapshot status: $($_.Exception.Message)"
            Write-Output $ErrorMessage
            Send-SNMPAlert -ErrorMessage $ErrorMessage
            Send-EmailAlert -ErrorMessage $ErrorMessage
            throw
        }
    }

    # Timeout reached
    $ErrorMessage = "Snapshot did not complete within the allowed wait time ($maxWaitTime seconds)."
    Write-Output $ErrorMessage
    Send-SNMPAlert -ErrorMessage $ErrorMessage
    Send-EmailAlert -ErrorMessage $ErrorMessage
    throw $ErrorMessage
}

# Function: Configure NDMP for Backup
function Configure-NDMP {
    param ($snapshotID, $username, $password)
    try {
        $uri = "$PowerStoreAPI/file_ndmp/create"
        $body = @{
            file_system_snapshot_id = $snapshotID
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

# Function: Delete Snapshots Older Than Retention Period
function Delete-OldSnapshots {
    param ($fileSystemID, $retentionDays)
    try {
        $uri = "$PowerStoreAPI/file_system/$fileSystemID/snapshot"
        $snapshots = Invoke-RestMethod -Uri $uri -Method Get -Headers @{Authorization = "Basic $authInfo"}

        $expiryDate = (Get-Date).AddDays(-$retentionDays)
        $oldSnapshots = $snapshots | Where-Object { $_.creation_timestamp -lt $expiryDate }

        foreach ($snapshot in $oldSnapshots) {
            $snapshotUri = "$PowerStoreAPI/file_system_snapshot/$($snapshot.id)"
            Write-Output "Deleting snapshot with ID: $($snapshot.id)"
            Invoke-RestMethod -Uri $snapshotUri -Method Delete -Headers @{Authorization = "Basic $authInfo"}
        }
    } catch {
        $ErrorMessage = "Failed to delete old snapshots: $($_.Exception.Message)"
        Write-Output $ErrorMessage
        Send-SNMPAlert -ErrorMessage $ErrorMessage
        Send-EmailAlert -ErrorMessage $ErrorMessage
        throw
    }
}

# Main Workflow
try {
    # Step 1: Create a snapshot of the NAS FileSystem
    Write-Output "Creating a snapshot of the NAS FileSystem for backup..."
    $snapshotID = New-NASSnapshot -fileSystemID $NAS_FileSystem_ID -snapshotName $SnapshotName
    Write-Output "Snapshot created successfully with ID: $snapshotID"

    # Step 2: Wait for snapshot to be ready before configuring NDMP and starting backup
    Write-Output "Checking if the snapshot is ready for backup..."
    WaitForSnapshotCompletion -snapshotID $snapshotID -maxWaitTime $MaxWaitTime

    # Step 3: Configure NDMP on the snapshot for backup purposes
    Write-Output "Configuring NDMP on the snapshot..."
    $ndmpConfigResponse = Configure-NDMP -snapshotID $snapshotID -username $NDMP_User -password $NDMP_Password
    Write-Output "NDMP configuration completed successfully for snapshot."

    # Perform your backup operations here (assuming your NDMP client initiates the backup using the snapshot ID)

    # Step 4: Apply retention policy for snapshots older than $RetentionDays days
    Write-Output "Applying retention policy for snapshots older than $RetentionDays days..."
    Delete-OldSnapshots -fileSystemID $NAS_FileSystem_ID -retentionDays $RetentionDays
    Write-Output "Old snapshots deleted according to retention policy."

    Write-Output "Daily NAS snapshot, backup, and cleanup completed successfully."

} catch {
    $ErrorMessage = "An error occurred during the main workflow: $($_.Exception.Message)"
    Write-Output $ErrorMessage
    Send-SNMPAlert -ErrorMessage $ErrorMessage
    Send-EmailAlert -ErrorMessage $ErrorMessage
}
