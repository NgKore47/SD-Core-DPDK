### If you face any issue in UPF like:

```text
upf-0                         0/5     Init:0/1 
```

Then the issue may related to:

- Make sure VFs are created, check using 

```bash
ip link show ens2f1
```

If not, create VFs using:

```bash
sudo su
echo 4 > /sys/class/net/ens2f1/device/sriov_numvfs
```

- `MAC` of `VFs` --> If `MAC` is by default set to `00:00:00:00:00:00` --> then, set `MAC` manually using:
    ```bash
    sudo ip link set ens2f1 vf 0 mac 00:11:22:33:44:66
    sudo ip link set ens2f1 vf 1 mac 00:11:22:33:44:77
    sudo ip link set ens2f1 vf 2 mac 00:11:22:33:44:88
    sudo ip link set ens2f1 vf 3 mac 00:11:22:33:44:99
    ```

- Make sure your `VFs` are binded to `DPDK`, to check use:

```bash
dpdk-devbind.py -s
```

if not binded then bind them using:
```bash
./dpdk-install/dpdk.py -b vfio-pci 0000:65:10.1 #<pci-id of vf0>
./dpdk-install/dpdk.py -b vfio-pci 0000:65:10.5 #<pci-id of vf1>
./dpdk-install/dpdk.py -b vfio-pci 0000:65:11.1 #<pci-id of vf2>
./dpdk-install/dpdk.py -b vfio-pci 0000:65:11.5 #<pci-id of vf3>
```