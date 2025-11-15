# Module 18: Migrate Server Roles

**Duration:** ~20 minutes

## Learning Objectives

After completing this module, you will be able to:

- Choose an appropriate migration method
- Migrate IIS workloads and configurations
- Migrate Hyper-V hosts
- Migrate Remote Desktop Services (RDS) host servers

## Topics Covered

### 18.1. Choose an Appropriate Migration Method
Evaluate migration strategies including lift-and-shift, replatform, and refactor.

### 18.2. Migrate IIS Workloads and Configurations
Move IIS web servers and their configurations.

### 18.3. Migrate Hyper-V Hosts
Migrate Hyper-V infrastructure to new hardware or Azure.

### 18.4. Migrate Remote Desktop Services (RDS) Host Servers
Move RDS infrastructure while maintaining user sessions and settings.

## Supplemental Resources

- [Server Role Migration](https://learn.microsoft.com/en-us/windows-server/get-started/migrate-roles-and-features)
- [Migrate IIS](https://learn.microsoft.com/en-us/iis/manage/managing-your-configuration-settings/shared-configuration_264)
- [Migrate Hyper-V](https://learn.microsoft.com/en-us/windows-server/virtualization/hyper-v/manage/choose-between-standard-or-production-checkpoints-in-hyper-v)
- [Remote Desktop Services](https://learn.microsoft.com/en-us/windows-server/remote/remote-desktop-services/welcome-to-rds)

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- IIS Manager can export/import server and site configurations
- Live migration allows moving VMs between Hyper-V hosts with zero downtime
- RDS can use User Profile Disks for state management
- Consider Azure Virtual Desktop as an alternative to RDS
