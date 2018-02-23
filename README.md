# SDNGuestClustersVMM2016RTM
This script enables configuring a guest cluster in a SDN fabric that is under control of VMM 2016 RTM. The usefulness of the script will diminish with the release of VMM 1801. The script will grab the existing tenant virtual network, virtual subnet information, and virtual machine network adapter information to provide the artifacts needed to configure a floating IP address on a guest cluster. 

On the cluster nodes, you still need to configure a matching probe port on the cluster resource, and probe port firewall rules.

This script has to be run on a management console that has both:
1. The VMM console installed
2. The Network controller certificate installed

Notes:
* VMM will write a warning when it live migrates a VM in this cluster because it is detecting the floating IP that it does not know about, the floating ip will continue to work though. VMM will also issue a "completed with info" warning when it refreshes the VM.
* The VIP address needs to be available in the "load balancer address" space of this tenant's virtual subnet's IP pool, and not currently in use.


* Only the traffic specified in the vip will be forwarded. Some traditional cluster processes do not work. Here is a list so far:
    1. Cluster aware updating
    2. Failover cluster manager RSAT tool can work if the active node is on the same host as the management console virtual machine.
    3. SQL browser service
    4. SMB Witness for continuously available file shares on General Purpose File server clusters (SOFS cluster does work for CA in SDN)
    5. Any other sort of traffic that uses random ports, like RPC.
    6. RD Gateway redirect off of RD Broker, you will get better results from using DNS load balancing for this.
* Client connections and mangement access from sql server management studio need to be in the format "InstanceName,Port" where instance name is resolvable in dns, as sql browser service to the instance dns name will not work
* 

References: https://docs.microsoft.com/en-us/windows-server/networking/sdn/manage/guest-clustering


