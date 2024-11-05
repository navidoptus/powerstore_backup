Project Overview
This project is an automation script designed to manage daily cloning and backup preparation of a PowerStore NAS server located at a Disaster Recovery (DR) site. The script creates a new NAS clone each day, assigns a static IP address to the clone, and configures it for NDMP backup. By automating these tasks, the script provides an efficient, hands-free approach to ensure data consistency and backup readiness.

Author
Navid Rastegani
Email: navid.rastegani@optus.com.au

Prerequisites
PowerStore API Access:

Ensure you have access to PowerStore’s REST API and have your API endpoint and credentials (username and password).
Server for Script Execution:

A Windows server with PowerShell installed, or a Linux server (script requires adaptation to Bash for Linux).
The server must have network connectivity to the PowerStore management IP.
NDMP-Compatible Backup Solution:

Ensure your backup solution can connect via NDMP to the PowerStore NAS clone.
IP Address:

Have a static, unused IP address available in the DR network, which will be assigned to each NAS clone.
Script Execution Flow
Daily NAS Cloning:

The script creates a read-write (RW) clone of the NAS server at the DR site, preserving the original NAS configuration and data.
Assign Static IP:

A predefined IP address is assigned to the clone, providing isolated network access for backup purposes without IP conflicts.
Configure NDMP for Backup:

NDMP credentials are set up on the clone to enable backup access.
Automation:

The script can be scheduled using Task Scheduler (Windows) or cron (Linux) for daily execution, ensuring that backups are continuously automated.
Setting Up the Script
Open PowerShell on the server where you’ll run the script.
Replace Placeholder Values in the script (e.g., PowerStore IP, credentials, NAS IDs).
Test the Script Manually for initial verification before scheduling it.
Schedule the Script to run daily if verified as working correctly.
Script Scheduling
Windows: Use Task Scheduler to create a new task, specifying the PowerShell script and setting the frequency to daily.
Linux: Use cron to schedule the script after adapting it to Bash (if running on Linux)
