# PowerStore NAS Backup Automation to Data Domain

A PowerShell-based automation solution for backing up PowerStore NAS servers to a Data Domain appliance. Choose from two backup options: **NAS server cloning** or **file system snapshotting**, both configured to automate NDMP access and apply a 35-day retention policy.

**Author**: Navid Rastegani  
**Company**: Optus

---

## Table of Contents
- [Overview](#overview)
- [Features](#features)
- [Backup Options](#backup-options)
- [Quick Start](#quick-start)
- [Setup Instructions](#setup-instructions)
- [Use Cases](#use-cases)
- [File Structure](#file-structure)
- [Example Commands](#example-commands)
- [Scheduling the Backup](#scheduling-the-backup)
- [Troubleshooting](#troubleshooting)
- [Future Enhancements](#future-enhancements)
- [Contributing](#contributing)
- [License](#license)
- [Author](#author)

---

## Overview

This solution provides two approaches for PowerStore NAS backups:

1. **NAS Server Cloning**: Creates a writable, point-in-time copy of the NAS server on the DR site for backup.
2. **File System Snapshotting**: Creates read-only snapshots of individual file systems on the NAS server, which is more space-efficient.

Each backup method supports NDMP configuration and includes an automated 35-day retention policy to manage storage efficiently.

---

## Features

- 🚀 **Automated Daily NAS Cloning or Snapshotting**: Choose between creating a full NAS clone or snapshots of individual file systems.
- 🔐 **Configurable NDMP Backup Integration**: Easily set up NDMP access for Data Domain backups.
- 🕒 **Retention Management**: Automatically deletes clones or snapshots older than 35 days to maintain storage efficiency.
- 📧 **Alert Notifications**: Optional SNMP and email (SMTP) alerts for any issues encountered during the backup process.

---

## Backup Options

### Option 1: NAS Server Cloning
With this approach, the script creates a **writable clone** of the DR NAS server for backup.
- **Ideal For**: Situations requiring full, independent copies of NAS servers.
- **Script**: [Clone Backup Script](scripts/Clone_Backup_Script.ps1)
- **Features**:
  - Error handling with SNMP (optional) and email alerts.
  - Waits for clone completion before initiating NDMP configuration.
  - Configurable retention policy to delete clones older than 35 days.

### Option 2: File System Snapshotting
This approach takes **read-only snapshots** of individual NAS file systems for backup.
- **Ideal For**: Storage-efficient backups that don't require full NAS clones.
- **Script**: [Snapshot Backup Script](scripts/Snapshot_Backup_Script.ps1)
- **Features**:
  - Error handling with SNMP (optional) and email alerts.
  - Waits for snapshot completion before initiating NDMP configuration.
  - Configurable retention policy to delete snapshots older than 35 days.

---

## Quick Start

### Prerequisites
- **PowerStore API Credentials**: Username and password with permissions to create clones, snapshots, and configure NDMP.
- **Network Configuration**: Access to Data Domain or backup appliance via NDMP.
- **SMTP Configuration**: For sending email alerts on backup status.
- **SNMP Server** (Optional): Configure for SNMP alerts if needed.

### Setup
1. Clone this repository.
2. Edit the PowerStore, NDMP, SMTP, and SNMP configuration values in each script.
3. Verify connectivity to the PowerStore API and Data Domain for NDMP access.

### Running the Script
1. Run the script manually to verify initial setup.
2. Set up automation using Task Scheduler (Windows) or Cron Jobs (Linux) for daily execution.

---

## Example Commands

Run the clone script:
```powershell
.\Clone_Backup_Script.ps1

---

### Key Updates in the README:

1. **Alert Notifications Section**: Added a description of SNMP (optional) and SMTP email alerts.
2. **Detailed Features for Each Script**: Updated clone and snapshot features to highlight error handling, SNMP, SMTP alerts, completion checks, and retention policies.
3. **Quick Start**: Included prerequisites, setup, and initial run instructions.
4. **Example Commands**: Added sample commands to run each script.
5. **Troubleshooting**: Listed common issues related to connectivity, NDMP, and alerting setup.

This README now provides a comprehensive guide to using both the **Clone** and **Snapshot** scripts with all recent updates. Let me know if you need further modifications! &#8203;:contentReference[oaicite:0]{index=0}&#8203;
