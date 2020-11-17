# Shannon Provisioning Instructions

## Download Nvidia Linux
Copy the download links from the Nvidia L4T [Download](https://developer.nvidia.com/l4t-3231-archive) page for the L4T Driver Package (BSP) and the Sample Root Filesystem.  Then use `wget` to download these packages. You may experience errors on decompression if you download using a web browser.  

Change to your home directory, note the full name including version number of the L4T Driver Package, and extract the tarball. _(Note: Do not let the Ubuntu decompress using the Archive Manager app. It's important to extract **both** tarballs using `sudo`.)_

```
sudo tar -jxpf <Name_of_L4T_Driver_Package_you_just_downloaded>
```
 
Now you will install the Sample Root Filesystem into the Linux_for_Tegra directory that was just created. These steps populate binaries and settings into the file system: 
```
cd ~/Linux_for_Tegra/rootfs
sudo tar -jxpf <path/to/sample-rootfs>/Tegra-Linux-Sample-Root-Filesystem_<release_type>.tbz2
cd ..
sudo ./apply_binaries.sh  #See note below
```
(Note: When running the apply_binaries.sh script it may complain you need to install the QEMU library.  If this occurs install the library and re-run the apply_binaries script.)
```
sudo apt-get install qemu-user-static  #only if required
```

## Put the Tegra in flashing mode
Remove the top cover of the Shannon box by removing the screws and navigating the cover up past the Tegra. Plug the micro USBC cable into the Tegra's USBC port. If you are working with a completed Shannon box this port should be extended to the rear panel of the Shannon box. The other side of the cable should be plugged into a Linux computer.

The power buttons on the Tegra from left to right are: POWER, FORCE_RECOVERY, RESET

While holding FORCE_RECOVERY, press POWER, release POWER and then immediately hold RESET for 2 seconds before releasing RESET. Continue to hold FORCE_RECOVERY for an additional second before releasing it. 

After just a few seconds, on the host Linux computer run `lsusb` and you should see something like:

```
$> lsusb
...
Bus 002 Device 004: ID 0955:7019 NVidia Corp.
...
```
This will indicate you have successfully put the Tegra into flashing mode. If you don't see the above line, you may need to repeat the process and vary your button push timing slightly. 

## Flash the device
Connect a keyboard and mouse to the Shannon. There is only one additional USBA port on the Shannon box so you will need to use a USB hub to connect both devices.  Connect a monitor to the HDMI port.  

Run `sudo ./flash.sh jetson-xavier mmcblk0p1`

Once the flashing is completed, the device will boot into a setup screen which will allow you to configure the hostname, user/pass, timezone, language, etc. Go through these screens. You should configure:

- Hostname: ZPU serial number (ZZAA00xx) - Refer to the [Zendar Serial Numbers Page](https://github.com/ZendarInc/ZenCode/wiki/Serial-Numbers) to learn the next serial number.  *Note: Hostnames should always be UPPERCASE.*   
- Name: Zendar
- User/pass: `zen/shannon2020`

At this point, your Jetson will boot into standard Ubuntu. Log in with the username and password you setup before.

> ☝️ Note: If you see a notification that says, "A new version of Ubuntu is available. Would you like to upgrade?" Always choose "Don't Upgrade" . 

## Connecting the Shannon to the network
Plug an RJ-45 cable into the port provided and connect it to the network. By default, the Tegra will not ask for an IP address from the DHCP server. Run these commands to tell the Tegra to ask for an IP address: 

```
sudo dhclient -r eth0
sudo dhclient eth0
```
 
## Installing libraries and services

You will now configure the remaining hardware resources. First, set the power mode:

```
sudo nvpmodel -m 0   # Put the device in max performance mode
sudo nvpmodel -d cool # Turn the fan on high
```
To verify this, run `sudo nvpmodel -q` output will look like:
```
NV Fan Mode:cool
NV Power Mode: MAXN
0
```

Finally, install and deploy ZDMA...
```
sudo apt-get update
sudo apt-get upgrade
sudo apt-get install -y \
    cmake \
    git-lfs \
    dkms \
    debhelper \
    proxychains4 \
    nvidia-docker2
    
cd ~/
git clone https://github.com/ZendarInc/ZDMA
cd ZDMA
./bootstrap.sh
ls # Note the full name of the zdma-dkms file
sudo dpkg -i zdma-dkms_<version>.deb # Use the full name with version 
```

## Load New FPGA Bitstream File
Now you will need to load a new Bitstream File on the FPGA. At the time of this writing, the production bitstream is located at `zen-ffa/fpga/jwong/zendar_flash_doubleA_10_27_2020` on zen-ffa.  

The tool for loading the bitstream on the FPGA is called Vivado and is already installed on Pirsig & Djokovic.  Nyquist has the Vivado Labs tool to load bitstreams on the FPGA.  Use the -x option when connecting to Pirsig/Djokovic so the Vivado GUI can be loaded. The [Vivado Instructions](https://docs.google.com/document/d/1fpW5P4zaQ0zfpHGZjGddd9XyWsCbJWp0RfH5hSCQ5WU/edit) are intended for external customers.  Therefore, you can skip t.o the section titled "GUI Path to Update KCU".  Complete those instructions for installing the bitstream file and then return here.   

>👆 You must completely power-cycle the entire Shannon box at this time to load the new bitstream file. 

## Testing Hardware State

To verify that everything worked, you can do the following:
- Run `sudo lspci -v`. There should be a device called `Processing accelerators: Xilinx Corporation Device`. Under that entry, it should say `Kernel modules: zdma`.


## Setting IP Addresses Configuration

If the Shannon box will be used on a car, you should configure it with a static IP address for connections to ethernet port 0 and via DCHP for connections to ethernet port 1 (using a USB network adapter). To do this, append the following lines to `/etc/network/interfaces`:
```
auto lo

auto eth0
iface eth0 inet static
address 169.254.0.xxx
netmask 255.255.0.0

auto eth1
iface eth1 inet dhcp
```
If the Shannon box will only be used in the office for the time being, append these lines to `/etc/network/interfaces` instead:

```
auto lo

auto eth0
iface eth0 inet dhcp
```
## Update Serial Numbers Wiki Page
Update the [Zendar Serial Numbers Page](https://github.com/ZendarInc/ZenCode/wiki/Serial-Numbers) with the *hostname: ZPU serial number* you assigned to this ZPU. 

## Finish Hardware Setup

Once the above steps are completed, the device hardware is ready to use. Please deploy the device on the rack (if it is an internal system), connect it to the network, and leave it powered on. The remaining IT steps can be performed remotely, so it will be useful to have the device available on the network.

## IT Provisioning

Mounting the SSD:
```
#  Mount the SSD at /storage
sudo mkdir /storage
sudo fdisk /dev/nvme0n1 # See note below for what to enter at prompts. 
sudo mkfs.ext4 /dev/nvme0n1p1
sudo mount /dev/nvme0n1p1 /storage
```
_TODO: document fdisk configuration process_

On the ZPU run:

```
sudo apt install salt-minion
sudo update-rc.d salt-minion defaults
```

Edit `/etc/salt/minion` as root.

Change the line `#master: salt` near the top of the file to `master: confucius.local`, which directs the salt minion to refer to `confucius.local` as the master server.

Find and uncomment the following lines:

```
#pillar_roots:
#  base:
#    - /srv/pillar
```

Restart the daemon and probe the server:

```
sudo systemctl restart salt-minion.service
sudo salt-call state.highstate
```

This will show a denied key error, but that's OK for now.

### Adding the ZPU server side

**NOTE: Salt is configured in the `ZendarInc/ZenAdmin` repositiory and uses the `confucius.local` workstation for provisioning. 
If you don't have access to both, please contact #zendar_support for assistance before proceeding with the following steps.**

On `confucius.local` add the Salt key for the machine you're adding:

```
sudo salt-key -A
```
Type "Y" to accept.

On `confucius.local`, in `/srv/pillar/host_definitions.sls` add the lines (with the correct serial):

```
  ZZAA00xx:                                                                     
    feature_nas: True
    feature_shannon: True
```

In `/srv/pillar/user_mappings.sls` add an entry for the ZPU (again, with the correct serial):

```
ZZAA00xx:
  user_only:
  sudo_only:
```

Add users (see next section), commit and push your changes.

### Adding Users with Salt Stack

If you'd like to add a user that doesn't already exist, first add a stub for their public key:

```
touch /srv/salt/keys/<USER>.pub
```

If you do have you a public key, you can simply append it to the file (multiple keys can exist in that file).  If not, the user can follow the [Setup Instructions](https://github.com/ZendarInc/ZenBook/blob/master/Engineering/Software/Setup/setup.md#setup-instructions) to generate one.  Or, you can just add the key at a later date and proceed.

For a Zendar employee edit the `/srv/pillar/user_definitions.sls` file and at the **end** of the "Zendar Users" section, add en entry in the form:

```
  <USER>:
    uid: <UID>                                                                                                                           
    name: '<FULL NAME>'
    authkey: salt://keys/<USER>.pub
    shell: /bin/bash
    groups:
      - docker
```

The `UID` should be the previous `UID` incremented by 1.  Looking at the other entries, this will be apparent.  

For a **customer**, add them to the "Customer Users" section, and be sure to use the customer UIDs (beginning at 8000) to increment instead of the Zendar UIDs.  

Save and exit the `user_definitions.sls` file.

In `/srv/pillar/user_mappings.sls` add an entry for any users you'd like to add (Including the customer user if you created one).  For example:

```
ZZAA00xx:
  user_only:
    - user1
    - user2
    - customer
  sudo_only:
    - user1
    - customer
```

Commit and push your changes.

### Applying your changes

From `confucius.local`, run:

```
sudo salt ZZAA00xx state.apply
sudo salt ZZAA00xx shadow.gen_password <PASSWORD>
```

If this is a **customer** ZPU, `PASSWORD` should be "shannon" followed by the year (e.g. `shannon2020`), otherwise it should be `radars4all`.  Either way, the output from `shadow.gen_password` will be a password hash.  Copy it, and then for each `USER` run:

```
sudo salt ZZAA00xx shadow.set_password <USER> '<HASH>'
```

Be sure to put the hash in between the single qoutes.

Then on `ZZAA00xx`, for each of the users run:

```
sudo passwd <USER> --expire
```

When the user logs in and uses the `PASSWORD`, they'll be asked to create a new one.

### ZenCode setup

After the user accounts have been added to the ZPU. Follow the [Setup](https://github.com/ZendarInc/ZenBook/blob/master/Engineering/Software/Setup/setup.md) instructions, and in the "Optional" section, only go through the "Docker" and "Setup Docker credentials" portions. Then follow just the [Build ShannonSDK for arm64 (ZPU)](https://github.com/ZendarInc/ZenBook/blob/master/Engineering/Software/Build/build.md#build-shannonsdk-for-arm64-zpu) instructions.

The docker images can be quite large, so move the `/var/lib/docker` directory to `/storage` and create a symlink to it.
```
sudo mv /var/lib/docker /storage
sudo ln -s /storage/docker /var/lib/docker
```

Install `docker-compose`:

```
pip3 install docker-compose
```

Get the latest stable docker image (**This may require admin access, contact #zendar_support if needed**):

```
docker pull gcr.io/shannon-images/shannon:stable
```

Check that the shannon services are running:

```
systemctl status | grep shannon
```

You should see a service from `/usr/bin/shannon_control` and one from `/usr/bin/shannon_bus_relay`.

If you're sending this ZPU to a **customer**, user `secure-delete` to completely wipe the ZenCode directory:

```
srm -rfll ZenCode
```
