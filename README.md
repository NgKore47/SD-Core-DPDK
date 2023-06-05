# SD-Core_DPDK_SR-IOV

####  In SD-Core with `DPDK` and `SR-IOV`, we have to configure the following:

- `~/Aether/sd-core-5g-values.yaml`

	- use external IP for `AMF` --> same as `Data_Iface`
	- ***In the `plmn`, change the `mcc`, `mnc`*** as shown below, this part is very important.
	- Enable `SR-IOV` and `hugepages`
	- Change `access` and `core` interface IPs according to core
	- Change mode to `DPDK`
#### To setup DPDK, refer [here](https://github.com/NgKore47/Documentation/raw/main/SD-Core_DPDK_SR-IOV/SetupDPDK.sh)

#### To setup SR-IOV, refer [here](https://github.com/NgKore47/Documentation/raw/main/SD-Core_DPDK_SR-IOV/SetupSR_IOV.sh)

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
