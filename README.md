# SoftwareDefinedNetworking
This script enables configuring a guest cluster in a SDN fabric that is under control of VMM 2016 RTM. The usefulness of the script will diminish with the release of VMM 1801. The script will grab the existing tenant virtual network, virtual subnet information, and virtual machine network adapter information to provide the artifacts needed to configure a floating IP address on a guest cluster. You still need to configure a matching probe port, and probe port firewall rules on the guest cluster itself.

