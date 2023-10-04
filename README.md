# SD-Core_DPDK_SR-IOV
## Pre-requisite:
-  As a pre-requisite please make sure sriov, virtualization and VT-d parameters are enabled in BIOS.

- make sure enough hugepage memory allocated, iommu enabled. These changes can be made by updating
  below parameter in /etc/default/grub as follows,
```bash
GRUB_CMDLINE_LINUX="intel_iommu=on iommu=pt default_hugepagesz=1G hugepagesz=1G hugepages=32 transparent_hugepage=never"
```
Once it is updated apply the changes by running below command,
```bash
sudo update-grub
sudo reboot
```
You can verify the allocated hugepages using below command,
```bash
cat /proc/meminfo | grep HugePages
```

## Network-Architecture Info:
- Two different routers are used. One is used for the `DATA_IFACE` and RAN and does not hav internet connection.
- The other router is used for `Node IP` and has internet connection.
- Server-1 us used in this deployment
- Virtual Functions are only made at `DATA_IFACE` and attached to both access and core interface.
![net](./images/SDCore-sriov%2Bdpdk.png)


## Deployment
Firstly clone this repo:
```bash
git clone https://github.com/NgKore47/SD-Core-DPDK.git
```
Then make the cord directory & clone the sd-core-helm-charts:
```bash
cd ~/
git clone https://github.com/NgKore47/sdcore-helm-charts.git
tar -xvzf ~/sdcore-helm-charts/cord.tar

```
### **To see the changes we did in the previous deployment, [click here](#in-sd-core-with-dpdk-and-sr-iov-we-did-these-changes).**

- To setup SR-IOV Virtual Functions, refer [here](https://github.com/NgKore47/Documentation/raw/main/SD-Core_DPDK_SR-IOV/SetupSR_IOV.sh) or you can also make temporary virtual functions using the below command:
```bash
echo 4 > /sys/class/net/ens1f0/device/sriov_numvfs
```


- To setup DPDK, refer [here](./dpdk-install/SetupDPDK.sh) or directory run the script
```bash
sudo bash ./dpdk-install/SetupDPDK.sh
```

- Bind the VF devices to the vfio-pci driver as follows,
```bash
./dpdk-install/dpdk.py -b vfio-pci <pci-id of vf0>
./dpdk-install/dpdk.py -b vfio-pci <pci-id of vf1>
./dpdk-install/dpdk.py -b vfio-pci <pci-id of vf2>
./dpdk-install/dpdk.py -b vfio-pci <pci-id of vf3>
```
For eg: `./dpdk-install/dpdk.py -b vfio-pci 0000:b1:01.0`
> NOTE: You can also use `./dpdk-install/dpdk.py -s` cmd to check binded VF 

- Sriov plugin installation
Before sriov plugin install let's create the cluster
```bash
make node-prep
```
Now sriov plugin:
```bash
kubectl apply -f ./sriov/sriov-device-plugin.yaml
```
Change the `./sriov/sriov-device-plugin-config.yaml` according to the pci id of the virtual functions.
After that:
```bash
kubectl apply -f ./sriov/sriov-device-plugin-config.yaml
```
- Make sure that there are more than 2 intel_sriov_vfio resources available
```bash
kubectl get nodes -o json | jq '.items[].status.allocatable'
```

- Pull Ngkore private docker images using
```bash
kubectl create secret docker-registry regcred --docker-server=https://index.docker.io/v1/ --docker-username=ngkore --docker-password=dckr_pat_3aEGHh5fOR7GYqCc9gB0_rvt5aw --docker-email=ngkore47@gmail.com
kubectl create -f ~/sdcore-helm-charts/private-docker-images.yml
```
> **Note:** After this step, wait for a few minutes to pull the private images

- Now deply the 5G-Core using the Makefile
```bash
ENABLE_GNBSIM=false DATA_IFACE=enp101s0f1 CHARTS=local make 5g-core
```

After all the pods are up and running, run the following command:
```bash
sudo iptables -t nat -A POSTROUTING -o eno1 -j MASQUERADE
```
Here, `eno1 = Node IP`

###  In SD-Core with `DPDK` and `SR-IOV`, we did these changes:

- `~/Aether/sd-core-5g-values.yaml`

	- use external IP for `AMF` --> same as `Node_IP`
	- ***In the `plmn`, change the `mcc`, `mnc`*** as shown below, this part is very important.
	- Enable `SR-IOV` and `hugepages`
	- Change `access` and `core` interface IPs according to core
	- Change mode to `DPDK`


> NOTE: Here is the list of all the changes that needs to be done on fresh SD-Core with DPDK and SR-IOV
```patch
diff --git a/sd-core-5g-values.yaml b/sd-core-5g-values.yaml
index 2dccc4f..0784b7f 100644
--- a/sd-core-5g-values.yaml
+++ b/sd-core-5g-values.yaml
@@ -67,9 +67,9 @@ omec-control-plane:
     amf:
       # use externalIP if you need to access your AMF from remote setup and you don't
       # want setup NodePort Service Type
-      #ngapp:
-        #externalIp: "128.110.219.37"
-        #port: 38412
+      ngapp:
+        externalIp: "192.168.2.61"
+        port: 38412
       cfgFiles:
         amfcfg.conf:
           configuration:
@@ -230,8 +230,8 @@ omec-sub-provision:
                 - name: "aiab-gnb2"
                   tac: 2
                 plmn:
-                  mcc: "208"
-                  mnc: "93"
+                  mcc: "001"
+                  mnc: "01"
                 site-name: "aiab"
                 upf:
                   upf-name: "upf"  # associated UPF for this slice. One UPF per Slice. Provide fully qualified name
@@ -254,11 +254,11 @@ omec-user-plane:
     upf:
       name: "oaisim"
       sriov:
-        enabled: false #default sriov is disabled in AIAB setup
+        enabled: true #default sriov is disabled in AIAB setup
       hugepage:
-        enabled: false #should be enabled if dpdk is enabled
+        enabled: true #should be enabled if dpdk is enabled
       #can be any other plugin as well, remember this plugin dictates how IP address are assigned.
-      cniPlugin: macvlan
+      cniPlugin: vfioveth
       ipam: static
       routes:
         - to: ${NODE_IP}
@@ -266,15 +266,21 @@ omec-user-plane:
       enb:
         subnet: ${RAN_SUBNET} #this is your gNB network
       access:
-        iface: ${DATA_IFACE}
+        resourceName: "intel.com/intel_sriov_vfio_access"
+        ip: "192.168.252.3/24"
+        gateway: "192.168.252.1"
       core:
-        iface: ${DATA_IFACE}
+        resourceName: "intel.com/intel_sriov_vfio_core"
+        ip: "192.168.250.3/24"
+        gateway: "192.168.250.1"
       cfgFiles:
         upf.json:
-          mode: af_packet  #this mode means no dpdk
+          mode: dpdk  #this mode means dpdk
           hwcksum: true
           log_level: "trace"
           gtppsc: true #extension header is enabled in 5G. Sending QFI in pdu session extension header
+          measure_upf: false
+          workers: 1
           cpiface:
             dnn: "internet" #keep it matching with Slice dnn
             hostname: "upf"
@@ -300,7 +306,7 @@ omec-user-plane:
       execInParallel: false #run all profiles in parallel
       goProfile:
         enable: false #enable/disable golang profile in gnbsim
-        port: 5000
+      #   port: 5000
       httpServer:
         enable: false #enable httpServer in gnbsim
         port: 6000
(END)
-      cniPlugin: macvlan
+      cniPlugin: vfioveth
       ipam: static
       routes:
         - to: ${NODE_IP}
```
