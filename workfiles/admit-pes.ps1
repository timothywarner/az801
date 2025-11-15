# -- Migrate a computer from source domain corp.legacy.com to target domain corp.techtrainertim.com
cd "C:\Program Files (x86)\Active Directory Migration Tool"
admt computer /n:"LegacyPC001$" /sd:corp.legacy.com /td:corp.techtrainertim.com /to:"MigratedComputers" /tss:YES /tup:YES /tur:YES /co:merge

# -- Migrate a service account from source domain corp.legacy.com to target corp.techtrainertim.com
cd "C:\Program Files (x86)\Active Directory Migration Tool"
admt user /n:"SvcAccountSync" /sd:corp.legacy.com /td:corp.techtrainertim.com /to:"ServiceAccounts" /fgm:YES /mss:YES /po:copy

# -- Batch migrate users using an include-file (text list) from source corp.legacy.com to target corp.techtrainertim.com
cd "C:\Program Files (x86)\Active Directory Migration Tool"
admt user /f:"C:\Migration\include_users.txt" /sd:corp.legacy.com /td:corp.techtrainertim.com /to:"MigratedUsers" /ugr:YES /fgm:YES /mss:YES /po:copy

# -- Batch migrate groups using include-file
cd "C:\Program Files (x86)\Active Directory Migration Tool"
admt group /f:"C:\Migration\include_groups.txt" /sd:corp.legacy.com /td:corp.techtrainertim.com /to:"MigratedGroups" /ugr:YES /fgm:YES /mss:YES
