# Synology enable eunit

<a href="https://github.com/007revad/Synology_enable_eunit/releases"><img src="https://img.shields.io/github/release/007revad/Synology_enable_eunit.svg"></a>
<a href="https://hits.seeyoufarm.com"><img src="https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2F007revad%2FSynology_enable_eunith&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=views&edge_flat=false"/></a>
[![Donate](https://img.shields.io/badge/Donate-PayPal-green.svg)](https://www.paypal.com/paypalme/007revad)
[![](https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86)](https://github.com/sponsors/007revad)
[![committers.top badge](https://user-badge.committers.top/australia/007revad.svg)](https://user-badge.committers.top/australia/007revad)

### Description
Enable unsupported Synology eSATA and InfiniBand Expansion Unit models

This script will enable a choice of DX517, DX513, DX213, DX510, RX418, RX415 or RX410 on Synology NAS that have an eSATA port.

This script will enable a choice of DX517, DX513, DX213, DX510, RX418, RX415 or RX410 on Synology NAS that have an InfiniBand port.

You can enable as many different expansion unit models as you want.

If you have 2 of the same expansion unit model you only need to enable it once for both expansion units to be enabled in DSM.

> **Warning** <br>
> Do ***NOT*** span a storage pool between the NAS and Expansion Unit. After a DSM update the Expansion Unit will be unsupported until you run this script again, which will be hard to do if your only storage pool is offline. Also do ***NOT*** store this script on a volume in the expansion unit.


## Supported Models

This script will work for eSATA expansion units with the following Synology NAS models:

| Model   | Works | Confirmed |
|---------|-------|-----------|
| DS1823xs+ | yes | |
| DS1821+ | yes | DX513, DX213, RX418 |
| DS1621+ | yes | |
| DS1522+ | yes | |
| DS1520+ | yes | |
| DS923+  | yes | |
| DS920+  | yes | |
| DS723+  | yes | |
| DS720+  | yes | DX513, DX213, RX418 |
| RS1221+, RS1221RP+ | yes | DX517 |
| RS822+, RS822RP+ | yes | |

- The DiskStation models above already have DX517 enabled, and RX418 partially enabled.
- The RackStation models above already have RX418 enabled, and DX517 partially enabled.

This script will work for InfiniBand expansion units with the following Synology NAS models:

| Model   | Works | Confirmed |
|---------|-------|-----------|
| RS2421+ | yes | |
| RS2421RP+ | yes | |
| RS2821RP+ | yes | |

## eSATA expansion unit speeds

| Model | eSATA Speed | Notes |
|-------|-------------|-------|
| DX517 | 6 Gbps | 600 MB/s |
|	RX418 | 6 Gbps | 600 MB/s |
| | |
|	DX513 | 3 Gbps | 300 MB/s |
| DX213 | 3 Gbps | 300 MB/s |
|	RX415 | 3 Gbps | 300 MB/s |
| | |
|	DX510 | 1.5 Gbps | 150 MB/s | 
|	RX410 | 1.5 Gbps | 150 MB/s |


## Download the script

1. Download the latest version _Source code (zip)_ from https://github.com/007revad/Synology_enable_eunit/releases
2. Save the download zip file to a folder on the Synology.
3. Unzip the zip file.

> **Warning** <br>
> Do ***NOT*** save the script to a volumes in the expansion unit as the volume won't be available until after the script has run.

## How to run the script

### Scheduling the script in Synology's Task Scheduler

See <a href=how_to_schedule.md/>How to schedule a script in Synology Task Scheduler</a>

### Run the script via SSH

[How to enable SSH and login to DSM via SSH](https://kb.synology.com/en-global/DSM/tutorial/How_to_login_to_DSM_with_root_permission_via_SSH_Telnet)

Run the script then reboot the Synology:

```bash
sudo -s /volume1/scripts/syno_enable_eunit.sh
```

> **Note** <br>
> Replace /volume1/scripts/ with the path to where the script is located.

### Options:
```YAML
  -c, --check           Check expansion units status
  -r, --restore         Restore from backups to undo changes
      --unit=EUNIT      Automatically enable specified expansion unit
                          Only needed when script is scheduled
                          EUNIT is dx517, dx513, dx213, dx510, rx418, rx415 or rx410
  -e, --email           Disable colored text in output scheduler emails
      --autoupdate=AGE  Auto update script (useful when script is scheduled)
                          AGE is how many days old a release must be before
                          auto-updating. AGE must be a number: 0 or greater
  -h, --help            Show this help message
  -v, --version         Show the script version
```

## What about DSM updates?

After any DSM update you will need to run this script again, if you don't have it scheduled to run at boot. 

<br>

## Screenshots

<p align="center">Enable DX513</p>
<p align="center"><img src="/images/esatab.png"></p>

<p align="center">Check option</p>
<p align="center"><img src="/images/enable_dx513b.png"></p>

<p align="center">DS models with eSATA posts only partially have RX418 enabled</p>
<p align="center"><img src="/images/default.png"></p>

<p align="center">Enable RX418</p>
<p align="center"><img src="/images/enable_rx418b.png"></p>

<p align="center">Check option again</p>
<p align="center"><img src="/images/enabled_3b.png"></p>

<p align="center">Restore option</p>
<p align="center"><img src="/images/restore.png"></p>

<p align="center">DS1821+ with a DX213</p>
<p align="center"><img src="/images/1821+dx213-1.png"></p>

<p align="center"><img src="/images/1821+dx213-2.png"></p>
