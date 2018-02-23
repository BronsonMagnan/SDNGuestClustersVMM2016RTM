#This script has to be run on a management console that has both:
#1. The VMM console installed
#2. The Network controller certificate installed
#Note: VMM is write a warning when it live migrates a VM in this cluster because it is detecting the floating IP that it does not know about, it will continue to work though.

#Name of network controller REST API
$uri = "https://NCCluster.fabricdomain.com"

#Names of virtual machines as they appear in VMM.
$node1="sqlnode1.tenantdomain.local"
$node2="sqlnode2.tenantdomain.local"

#Names of tenant virtual network as it appears in VMM.
$VMMNetworkName = "tenantVNETname"
#Name of the tenant subnet as it appears in VMM, this the "site" listed in the properties of the virtual network.
$VMMSubnetName = "tenantSubnetname"

#make sure this name is unique
$ResourceId = "tenantName_InternalVIP_SQLCluster_TCP_10433"

#VIP needs to be available in the "load balancer address" space of this tenant subnet's IP pool, and not in use.
#These should line up with the IP address and PORT of the SQL Instance. SQL Browser does not work in SDN!
#Access from sql server management studio as "InstanceName,Port"
$VIP = "10.9.3.243" 
$VIPProtocol = "TCP"
$VIPPort = "10433"

#The sql instance IP cluster role needs to be configured with this probe port, and each node needs a fire wall rule to permit inbound connections on this tcp port. The source will be the default gateway of the virtual subnet
$ProbePort = "59998" 

#THIS SCRIPT GOES BEHIND VMM 2016 RTM TO CREATE A FLOATING IP FOR A GUEST CLUSTER.
import-module virtualmachinemanager
#Step 1: Translate the Network and Subnet artifacts from VMM into Network Controller Resources.
$scvmNetwork = Get-SCVMNetwork -name $VMMNetworkName
$ncvmNetwork = Get-NetworkControllerVirtualNetwork -ConnectionUri $uri -ResourceId ( $scvmNetwork.ExternalId)
$scvmSubnet = Get-SCVMSubnet -Name $VMMSubnetName -VMNetwork $scvmNetwork
$ncvmSubnet = Get-NetworkControllerVirtualSubnet -connectionuri $uri -VirtualNetworkId $ncvmNetwork.ResourceId | where {$_.properties.AddressPrefix -eq $scvmSubnet.SubnetVLans[0].Subnet}

$VirtualNetwork = $ncvmNetwork.ResourceId
$subnet = $ncvmSubnet.ResourceId

#Step 2: Create the load balancer properties object
$LoadBalancerProperties = new-object Microsoft.Windows.NetworkController.LoadBalancerProperties

#Step 3: Create a front-end IP address
$LoadBalancerProperties.frontendipconfigurations += $FrontEnd = new-object Microsoft.Windows.NetworkController.LoadBalancerFrontendIpConfiguration
$FrontEnd.properties = new-object Microsoft.Windows.NetworkController.LoadBalancerFrontendIpConfigurationProperties
$FrontEnd.resourceId = "Frontend1"
$FrontEnd.resourceRef = "/loadBalancers/$ResourceId/frontendIPConfigurations/$($FrontEnd.resourceId)"
$FrontEnd.properties.subnet = new-object Microsoft.Windows.NetworkController.Subnet
$FrontEnd.properties.subnet.ResourceRef = "/VirtualNetworks/$($VirtualNetwork)/Subnets/$subnet"
$FrontEnd.properties.privateIPAddress = $VIP
$FrontEnd.properties.privateIPAllocationMethod = "Static"

#Step 4: Create a back-end pool to contain the cluster nodes
$BackEnd = new-object Microsoft.Windows.NetworkController.LoadBalancerBackendAddressPool
$BackEnd.properties = new-object Microsoft.Windows.NetworkController.LoadBalancerBackendAddressPoolProperties
$BackEnd.resourceId = "Backend1"
$BackEnd.resourceRef = "/loadBalancers/$ResourceId/backendAddressPools/$($BackEnd.resourceId)"
$LoadBalancerProperties.backendAddressPools += $BackEnd

#Step 5: Add a probe
$LoadBalancerProperties.probes += $lbprobe = new-object Microsoft.Windows.NetworkController.LoadBalancerProbe
$lbprobe.properties = new-object Microsoft.Windows.NetworkController.LoadBalancerProbeProperties
$lbprobe.ResourceId = "Probe1"
$lbprobe.resourceRef = "/loadBalancers/$ResourceId/Probes/$($lbprobe.resourceId)"
$lbprobe.properties.protocol = "TCP"
$lbprobe.properties.port = $ProbePort
$lbprobe.properties.IntervalInSeconds = 5
$lbprobe.properties.NumberOfProbes = 2

#Step 5: Add the load balancing rules
$LoadBalancerProperties.loadbalancingRules += $lbrule = new-object Microsoft.Windows.NetworkController.LoadBalancingRule
$lbrule.properties = new-object Microsoft.Windows.NetworkController.LoadBalancingRuleProperties
$lbrule.ResourceId = "Rules$($VIPProtocol)$($VIPPort)"
$lbrule.properties.frontendipconfigurations += $FrontEnd
$lbrule.properties.backendaddresspool = $BackEnd 
$lbrule.properties.protocol = $VIPProtocol
$lbrule.properties.frontendPort = $lbrule.properties.backendPort = $VIPPort 
$lbrule.properties.IdleTimeoutInMinutes = 4
$lbrule.properties.EnableFloatingIP = $true
$lbrule.properties.Probe = $lbprobe



#Step 5: Create the load balancer in Network Controller
$lb = New-NetworkControllerLoadBalancer -ConnectionUri $URI -ResourceId $ResourceId -Properties $LoadBalancerProperties -Force
#$error[0].Exception.InnerException

#Step 6: Add the cluster nodes to the backend pool
# Cluster Node 1
$vm = Get-SCVirtualMachine -Name $node1
$scvirtualnetworkadapter = Get-SCVirtualNetworkAdapter -VM $vm
$ncnetworkcontrollernetworkinterface = Get-NetworkControllerNetworkInterface -ConnectionUri $uri -ResourceId ($scvirtualnetworkadapter.id)

$nic = $ncnetworkcontrollernetworkinterface
$nic.properties.IpConfigurations[0].properties.LoadBalancerBackendAddressPools += $lb.properties.backendaddresspools[0]
$nic = new-networkcontrollernetworkinterface  -connectionuri $uri -resourceid $nic.resourceid -properties $nic.properties -force

# Cluster Node 2
$vm = Get-SCVirtualMachine -Name $node2
$scvirtualnetworkadapter = Get-SCVirtualNetworkAdapter -VM $vm
$ncnetworkcontrollernetworkinterface = Get-NetworkControllerNetworkInterface -ConnectionUri $uri -ResourceId ($scvirtualnetworkadapter.id)

$nic = $ncnetworkcontrollernetworkinterface
$nic.properties.IpConfigurations[0].properties.LoadBalancerBackendAddressPools += $lb.properties.backendaddresspools[0]
$nic = new-networkcontrollernetworkinterface  -connectionuri $uri -resourceid $nic.resourceid -properties $nic.properties -force

#this code will remove the VIP. Use this after VMM 1801 is released and you want to remove this VIP to redeploy in VMM.
#Load the $resourceID varible from the top
#$lb = Get-NetworkControllerLoadBalancer -ConnectionUri $uri -ResourceId $ResourceId
#Remove-NetworkControllerLoadBalancer -ConnectionUri $uri -ResourceId $lb.ResourceId
