# AZ-801 Lesson 20: IIS Migration Demo Runbook (10 min)

## Setup (Pre-record)
```powershell
# On your demo VM - create simple IIS site
New-Item C:\DemoApp -ItemType Directory
"<h1>Legacy HR Portal</h1><p>Running on IIS 10</p>" | Out-File C:\DemoApp\default.html
New-IISSite -Name "HRPortal" -PhysicalPath C:\DemoApp -Port 8080
```

## Demo Flow

### 1. Azure Migrate Discovery (3 min)
```powershell
# Show in Portal - DON'T ACTUALLY DEPLOY
# portal.azure.com > Azure Migrate > Servers, databases, web apps
```
- Click "Discover" 
- Show appliance download (don't download)
- **SAY:** "Appliance discovers IIS sites via WMI and IIS metabase"
- Show assessment output (use pre-made screenshot)

### 2. Web App Migration Assistant (4 min)
```powershell
# Download but DON'T run full migration
Start-Process https://aka.ms/webappmigrationassistant
```
- Launch tool
- Show it detecting local IIS sites
- Walk through readiness checks
- **STOP at "Create Azure Resources"**
- **SAY:** "Creates App Service, migrates content, preserves bindings"

### 3. Container Quick Demo (2 min)
```dockerfile
# Show this Dockerfile - don't build
FROM mcr.microsoft.com/windows/servercore/iis:windowsservercore-ltsc2022
COPY DemoApp /inetpub/wwwroot
```
**SAY:** "For apps needing Windows auth or COM components"

### 4. Portal Walkthrough (1 min)
- Show App Service plans (Basic, Standard, Premium)
- Show Container Instances 
- Show AKS Windows node pool option
- **SAY:** "Pick based on requirements - PaaS for simple, containers for complex"

## Exam Points to Hit

1. **Azure Migrate = Assessment only** (doesn't migrate)
2. **Web App Assistant = Actual migration tool**
3. **App Service tiers:**
   - Basic: No autoscale
   - Standard: Autoscale + slots
   - Premium: Zone redundancy
4. **Container requirements:**
   - Windows Server Core (not Nano)
   - Process isolation default in 2022
5. **AKS limitations:**
   - Azure CNI required
   - No host networking

## Wrap Statement
"Three paths to modernize IIS: Web Apps for simplicity, containers for compatibility, AKS for scale. The exam tests when to use each."

---

**DONE IN 10 MINUTES. NO FLUFF.**
