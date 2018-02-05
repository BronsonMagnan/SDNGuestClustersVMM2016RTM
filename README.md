# SDNGuestClustersVMM2016RTM
This script enables configuring a guest cluster in a SDN fabric that is under control of VMM 2016 RTM. The usefulness of the script will diminish with the release of VMM 1801. The script will grab the existing tenant virtual network, virtual subnet information, and virtual machine network adapter information to provide the artifacts needed to configure a floating IP address on a guest cluster. 

You still need to configure a matching probe port, and probe port firewall rules on the guest cluster itself.

This script has to be run on a management console that has both:
1. The VMM console installed
2. The Network controller certificate installed

Notes:
* VMM will write a warning when it live migrates a VM in this cluster because it is detecting the floating IP that it does not know about, the floating ip will continue to work though.
* The VIP address needs to be available in the "load balancer address" space of this tenant subnet's IP pool, and not currently in use.
* SQL Browser service does not work in SDN.
* Client connections and access from sql server management studio need to be "InstanceName,Port" where instance name is resolvable in dns.
* Failover cluster manager access can work if the active node is on the same host as the management console. I have not figured out if how to do this yet as the floating ip address load balancer seems to only be able to forward a single port.

References: https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/guest-clustering


