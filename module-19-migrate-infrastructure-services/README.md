# Module 19: Migrate Infrastructure Services

**Duration:** ~15 minutes

## Learning Objectives

After completing this module, you will be able to:

- Migrate Dynamic Host Configuration Protocol (DHCP) servers
- Migrate print servers
- Migrate by using an in-place upgrade

## Topics Covered

### 19.1. Migrate Dynamic Host Configuration Protocol (DHCP) Servers
Export and import DHCP scopes, reservations, and settings.

### 19.2. Migrate Print Servers
Move print servers while preserving printers, drivers, and configurations.

### 19.3. Migrate by Using an In-Place Upgrade
Upgrade Windows Server in-place to a newer version.

## Supplemental Resources

- [Migrate DHCP](https://learn.microsoft.com/en-us/windows-server/networking/technologies/dhcp/dhcp-deploy-wps)
- [Print Server Migration](https://learn.microsoft.com/en-us/windows-server/administration/windows-server-migration-tools)
- [In-Place Upgrade](https://learn.microsoft.com/en-us/windows-server/get-started/perform-in-place-upgrade)
- [Windows Server Migration Tools](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2012-R2-and-2012/jj134202(v=ws.11))

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Notes

- DHCP migration includes server options, scope options, and reservations
- Print Management console simplifies printer migration
- In-place upgrades are faster but have higher risk than clean installs
- Always backup before performing in-place upgrades
- Consider cluster-aware updating for clustered services
