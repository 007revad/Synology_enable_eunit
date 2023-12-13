# Synology enable eunit

<a href="https://github.com/007revad/Synology_enable_eunit/releases"><img src="https://img.shields.io/github/release/007revad/Synology_enable_eunit.svg"></a>
<a href="https://hits.seeyoufarm.com"><img src="https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fgithub.com%2F007revad%2FSynology_enable_eunith&count_bg=%2379C83D&title_bg=%23555555&icon=&icon_color=%23E7E7E7&title=views&edge_flat=false"/></a>
[![](https://img.shields.io/static/v1?label=Sponsor&message=%E2%9D%A4&logo=GitHub&color=%23fe8e86)](https://github.com/sponsors/007revad)
[![committers.top badge](https://user-badge.committers.top/australia/007revad.svg)](https://user-badge.committers.top/australia/007revad)

### Description
Enable an unsupported Synology eSATA Expansion Unit models

This script will enable a choice of DX517, DX513, DX213, RX418, RX415 or RX410 on Synology NAS that have an eSATA port.

You can enable DX517, RX418 and a 3rd model of either DX513, DX213, RX415 or RX410.

**Note:** If you later want to change the 3rd model you need to:
1. Run the script with the --restore option.
2. Run the script to enable your chosen expansion unit.
3. Reboot.

If you have 2 of the same expansion unit model you only need to enable it once for both expansion units to be enabled in DSM.

<br>

**Warning**
    
Do ***NOT*** span a storage pool between the NAS and Expansion Unit. After a DSM update the Expansion Unit will be unsupported until you run this script again, which will be hard to do if your only storage pool is offline. Also do ***NOT*** store this script on a volume in the expansion unit.

<br>

I'm not sure if the RS models would only be able to use 4 of the 5 bays in a DX517 if the total drive number exceded the models' max drive number.

For example:
- An RS822+ may only see 4 drives in a DX517.
- An RS1221+ may only see 8 drives in two DX517.


## Supported Models

I'm 99% certain this script will work for the following Synology NAS models:

| Model | Works | Commment |
|-------|-------|----------|
| DS720+ | ??? | |
| DS723+ | ??? | |
| DS920+ | ??? | |
| DS923+ | ??? | |
| DS1520+ | ??? | |
| DS1522+ | ??? | |
| DS1621+ | ??? | |
| DS1821+ | ??? | |
| DS1823xs+ | ??? | |
| RS822+, RS822RP+ | ??? | |
| RS1221+, RS1221RP+ | ??? | |

- The DiskStation models above already have DX517 enabled, and RX418 partially enabled.
- The RackStation models above already have RX418 enabled, and DX517 partially enabled.


## Download the script

See <a href=images/how_to_download_generic.png/>How to download the script</a> for the easiest way to download the script.

Do ***NOT*** save the script to a volumes in the expansion unit as the volume won't be available until after the script has run.

## How to run the script

### Run the script via SSH

**Note:** Replace /volume1/scripts/ with the path to where the script is located.
Run the script then reboot the Synology:

    sudo -i /volume1/scripts/syno_enable_eunit.sh

**Options:**
```YAML
  -c, --check      Check expansion unit status
  -r, --restore    Restore backup to undo changes
  -h, --help       Show this help message
  -v, --version    Show the script version
```

## What about DSM updates?

After any DSM update you will need to run this script again. 

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

