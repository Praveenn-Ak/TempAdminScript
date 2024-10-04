
## **Temporary Admin Rights Script, Removal Using Task Scheduler**

In this blog post, I’ll discuss the **Temp Admin Script**, a powerful tool that temporarily grants users admin rights on a machine and removes those rights automatically after a set period, using a scheduled task. This script is ideal for situations where users need administrative privileges for a limited time without permanent access.

### **How the Temp Admin Script Works**

The script performs a series of steps to ensure that the user is granted temporary admin rights and that those rights are removed after a specified time:

1. **Identifying the Current User:**  
   Like the permanent admin script, the Temp Admin script retrieves the explorer owner to identify the logged-in user who will receive the temporary admin rights.

2. **Granting Temporary Admin Rights:**  
   Once the current user is identified, the script uses `Add-LocalGroupMember` to add the user to the local Administrators group, granting them admin rights.

3. **Setting the Duration for Admin Rights:**  
   The script creates a scheduled task that is set to run after a predefined time (e.g., 48 hours). The task triggers the removal of the user from the local Administrators group once the time expires.

4. **Removing Admin Rights Automatically:**  
   When the scheduled task runs, the user is removed from the Administrators group using `Remove-LocalGroupMember`, thus revoking their admin privileges.

5. **Cleaning Up:**  
   After the task completes, the script deletes the scheduled task and any temporary files used during the process, ensuring no lingering artifacts remain on the system.

### **Key Features of the Script**

- **Dynamic User Identification:**  
  The script dynamically identifies the current explorer owner, ensuring the correct user is granted admin rights.

- **Scheduled Task for Automatic Removal:**  
  A scheduled task is created as part of the script, which ensures admin rights are removed automatically after the defined period, without any manual intervention.

- **Silent SCCM Deployment:**  
  Like the permanent admin script, this Temp Admin script can be packaged and deployed silently via SCCM. Users won’t see any prompts or notifications, and the entire process happens in the background.

- **Extendable Timer:**  
  The script can be customized to extend the admin rights duration if needed (e.g., from 30 minutes up to 6 hours). You can configure this based on the specific needs of your environment.

### **Converting the Script to EXE (Optional)**

Just like with the Permanent Admin script, you can convert this PowerShell script into an EXE using the `ps2exe` module, ensuring smooth and silent deployment via SCCM.

#### **Steps:**
1. **Install the ps2exe Module:**
   ```powershell
   Install-Module -Name ps2exe
   ```

2. **Convert the Script to EXE:**
   ```powershell
   ps2exe -inputFile TempAdmin.ps1 -outputFile TempAdmin.exe
   ```

3. **Silent Deployment via SCCM:**
   You can silently deploy the EXE using SCCM with the following command:
   ```bash
   cmd.exe /c start "" "TempAdmin.exe"
   ```

### **Why Use This Script?**

- **Temporary Privileges:**  
  Users only get admin rights for the time they need it. This enhances security and minimizes risks associated with permanent admin access.

- **Automated Cleanup:**  
  The script ensures that admin rights are removed without any manual effort through a scheduled task, ensuring adherence to security policies.

- **SCCM Compatibility:**  
  Deploying the Temp Admin script via SCCM allows for easy, large-scale deployment, with no user prompts or interruptions.

### **Conclusion**

The Temp Admin Script is a practical solution for temporarily granting admin rights while ensuring that these rights are revoked after a specified time period. Its integration with Task Scheduler and SCCM deployment capabilities makes it a valuable tool for managing administrative access securely and efficiently.

If you’ve tried this approach or have any feedback, feel free to share in the comments!

