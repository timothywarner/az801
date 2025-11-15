# Exam AZ-801: Configuring Windows Server Hybrid Advanced Services

This repository supports both:
- **O'Reilly Live Learning** online training courses
- **Microsoft Press Video Training** (2nd Edition)

## Contact information

- [LinkedIn](https://www.linkedin.com/in/timothywarner/)
- [Email](mailto:timothywarner316@gmail.com)
- [Website](https://techtrainertim.com)
- [Bluesky](https://bsky.app/profile/techtrainertim.bsky.social)
- [Mastodon](https://mastodon.social/@techtrainertim)

## About the exam and certification

- [Windows Server Hybrid Administrator Associate certification](https://learn.microsoft.com/en-us/credentials/certifications/windows-server-hybrid-administrator/)
- [Exam AZ-800: Administering Windows Server Hybrid Core Infrastructure](https://learn.microsoft.com/en-us/credentials/certifications/exams/az-800/)
- [Exam AZ-801: Configuring Windows Server Hybrid Advanced Services](https://learn.microsoft.com/en-us/credentials/certifications/exams/az-801/)
- [Microsoft certification policies & FAQs](https://learn.microsoft.com/en-us/credentials/certifications/certification-exam-policies)

## Practice exams

- [MeasureUp Practice Test AZ-801: Configuring Windows Server Hybrid Advanced Services](https://www.measureup.com/microsoft-practice-test-az-801-configuring-windows-server-hybrid-advanced-services.html)
- [Practice Assessment for Exam AZ-801: Configuring Windows Server Hybrid Advanced Services](https://learn.microsoft.com/en-us/credentials/certifications/exams/az-801/practice/assessment?assessment-type=practice&assessmentId=68)
- [Microsoft Learn offers](https://learn.microsoft.com/en-us/credentials/certifications/deals)

## Conceptual learning

- [Windows Server documentation](https://learn.microsoft.com/en-us/windows-server/)
- [Microsoft Azure documentation](https://learn.microsoft.com/en-us/azure/)
- [Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/)
- [Microsoft Cloud Adoption Framework for Azure](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/)
- [Microsoft Azure Well-Architected Framework](https://learn.microsoft.com/en-us/azure/well-architected/)

## Repository Structure

This repository is organized to support both O'Reilly Live Learning sessions and MS Press video training modules:

### MS Press Video Training Modules

The repository contains 26 modules aligned with the MS Press video training course outline (~6 hours total runtime):

#### Security (Modules 1-7)
- [Module 1: Implement Core OS Security](module-01-implement-core-os-security/) (20 min)
- [Module 2: Secure Local Accounts and Passwords](module-02-secure-local-accounts-and-passwords/) (15 min)
- [Module 3: Manage Protected Users and RODCs](module-03-manage-protected-users-and-rodcs/) (15 min)
- [Module 4: Configure Advanced Domain Security](module-04-configure-advanced-domain-security/) (20 min)
- [Module 5: Monitor and Defend with Microsoft Security Tools](module-05-monitor-and-defend-with-microsoft-security-tools/) (20 min)
- [Module 6: Secure Windows Server Networking](module-06-secure-windows-server-networking/) (15 min)
- [Module 7: Secure Storage with Encryption](module-07-secure-storage-with-encryption/) (15 min)

#### High Availability & Disaster Recovery (Modules 8-15)
- [Module 8: Implement Failover Clusters](module-08-implement-failover-clusters/) (20 min)
- [Module 9: Configure Advanced Cluster Features](module-09-configure-advanced-cluster-features/) (15 min)
- [Module 10: Manage and Maintain Clusters](module-10-manage-and-maintain-clusters/) (20 min)
- [Module 11: Implement Storage Spaces Direct](module-11-implement-storage-spaces-direct/) (15 min)
- [Module 12: Protect VMs with Hyper-V Replication](module-12-protect-vms-with-hyper-v-replication/) (15 min)
- [Module 13: Implement Azure Backup](module-13-implement-azure-backup/) (20 min)
- [Module 14: Backup and Recover Azure VMs](module-14-backup-and-recover-azure-vms/) (15 min)
- [Module 15: Implement Azure Site Recovery](module-15-implement-azure-site-recovery/) (20 min)

#### Migration (Modules 16-21)
- [Module 16: Migrate Storage Using SMS](module-16-migrate-storage-using-sms/) (15 min)
- [Module 17: Use Azure Migrate for Server Migration](module-17-use-azure-migrate-for-server-migration/) (15 min)
- [Module 18: Migrate Server Roles](module-18-migrate-server-roles/) (20 min)
- [Module 19: Migrate Infrastructure Services](module-19-migrate-infrastructure-services/) (15 min)
- [Module 20: Migrate IIS Workloads to Azure](module-20-migrate-iis-workloads-to-azure/) (15 min)
- [Module 21: Migrate Active Directory to Windows Server 2025](module-21-migrate-active-directory-to-windows-server-2025/) (20 min)

#### Monitoring & Troubleshooting (Modules 22-26)
- [Module 22: Monitor Windows Server Performance](module-22-monitor-windows-server-performance/) (20 min)
- [Module 23: Monitor with Azure Services](module-23-monitor-with-azure-services/) (15 min)
- [Module 24: Troubleshoot Core Services](module-24-troubleshoot-core-services/) (20 min)
- [Module 25: Troubleshoot Advanced Issues](module-25-troubleshoot-advanced-issues/) (15 min)
- [Module 26: Troubleshoot Active Directory](module-26-troubleshoot-active-directory/) (20 min)

Each module folder contains:
- `README.md` - Learning objectives, topics covered, and supplemental resources
- Hands-on lab exercises (where applicable)
- Scripts and configuration files (where applicable)

### Additional Resources

- **Certification Study Guide**: [az801-cert-study-blueprint.md](az801-cert-study-blueprint.md)
- **Course Table of Contents**: [az801-course-toc.md](az801-course-toc.md)
- **Scripts**: Legacy scripts are in the `/scripts` directory; module-specific scripts are in their respective module folders
- **Slide Deck**: [warner-az-801-slides.pptx](warner-az-801-slides.pptx)
- **Diagrams**: Class topology and architecture diagrams for lab setup
- **RDCMan**: Remote Desktop Connection Manager tool and configuration files

### Lab Environment

The repository includes Infrastructure as Code (IaC) templates for setting up lab environments:
- Bicep templates for Azure VM deployment
- PowerShell scripts for configuration automation
- ARM templates for Active Directory deployment
