# Install from Media (IFM)
# Reference: https://4sysops.com/archives/install-a-secondary-domain-controller-using-install-from-media-ifm/

# Create IFM folder
New-Item -Path C:\ -Name ifm -ItemType directory -Force

# Create the media with ntdsutil
ntdsutil
activate instance ntds
ifm
help
Create Sysvol RODC c:\ifm
quit
quit