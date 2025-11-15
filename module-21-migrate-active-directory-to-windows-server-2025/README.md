# Module 21: Migrate Active Directory to Windows Server 2025

**Duration:** ~20 minutes

## Learning Objectives

After completing this module, you will be able to:

- Choose an appropriate migration method
- Implement a forest restructure
- Migrate AD DS objects, including users, groups and Group Policies using AD Migration Tool
- Migrate to a new Active Directory forest
- Upgrade an existing forest, including setting functional levels

## Topics Covered

### 21.1. Choose an Appropriate Migration Method
Evaluate in-place upgrade, swing migration, and forest restructure approaches.

### 21.2. Implement a Forest Restructure
Reorganize AD DS by moving objects between forests.

### 21.3. Migrate AD DS Objects, Including Users, Groups and Group Policies Using AD Migration Tool
Use ADMT to migrate users, groups, computers, and GPOs.

### 21.4. Migrate to a New Active Directory Forest
Create a new forest and migrate objects from the old forest.

### 21.5. Upgrade an Existing Forest, Including Setting Functional Levels
Perform in-place upgrades of domain controllers and raise functional levels.

## Topics Covered

## Supplemental Resources

- [Active Directory Migration](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/deploy/upgrade-domain-controllers)
- [ADMT Guide](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc974332(v=ws.10))
- [Functional Levels](https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/active-directory-functional-levels)
- [Forest Restructure](https://learn.microsoft.com/en-us/previous-versions/windows/it-pro/windows-server-2008-R2-and-2008/cc754736(v=ws.10))

## Hands-on Labs

Check the `/labs` subdirectory for hands-on exercises related to this module.

## Scripts

- `install-ad-forest-root.ps1` - Install new AD forest
- `install-ad-child-domain.ps1` - Add child domain
- `create-forest-trust.ps1` - Create forest trust relationship
- `ad-recycle-bin.ps1` - Enable AD Recycle Bin
- `fsmo.ps1` - Manage FSMO roles

## Notes

- In-place upgrade is the simplest but has the highest risk
- ADMT supports cross-forest migrations
- Raise functional levels only after all DCs are upgraded
- Windows Server 2025 domain functional level requires all DCs to be 2025
- Always enable AD Recycle Bin before major migrations
