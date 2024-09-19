#!/usr/bin/env bash
#-----------------------------------------------------------------------------------
# Enable Expansion Units in Synology NAS that don't officially support them.
#
# Allows using your Synology expansion unit
# in Synology NAS models that aren't on their supported model list.
#
# Github: https://github.com/007revad/Synology_enable_eunit
# Script verified at https://www.shellcheck.net/
#
# To run in a shell (replace /volume1/scripts/ with path to script):
# sudo -i /volume1/scripts/syno_enable_eunit.sh
#-----------------------------------------------------------------------------------

scriptver="v3.0.18"
script=Synology_enable_eunit
repo="007revad/Synology_enable_eunit"
scriptname=syno_enable_eunit

# Check BASH variable is bash
if [ ! "$(basename "$BASH")" = bash ]; then
    echo "This is a bash script. Do not run it with $(basename "$BASH")"
    printf \\a
    exit 1  # Not running in bash
fi

# Check script is running on a Synology NAS
if ! /usr/bin/uname -a | grep -q -i synology; then
    echo "This script is NOT running on a Synology NAS!"
    echo "Copy the script to a folder on the Synology"
    echo "and run it from there."
    exit 1  # Not Synology NAS
fi


ding(){ 
    printf \\a
}

usage(){ 
    cat <<EOF
$script $scriptver - by 007revad

Usage: $(basename "$0") [options]

Options:
  -c, --check           Check expansion units status
  -r, --restore         Restore from backups to undo changes
      --unit=EUNIT      Automatically enable specified expansion unit
                          Only needed when script is scheduled
                          EUNIT is dx517, dx513, dx213, dx510, rx418, rx415,
                          rx410, rx1217rp, rx1217, rx1214r, rx1214, rxX1211rp,
                          rx1211, dx1215ii, dx1215 or dx1211
  -e, --email           Disable colored text in output scheduler emails
      --autoupdate=AGE  Auto update script (useful when script is scheduled)
                          AGE is how many days old a release must be before
                          auto-updating. AGE must be a number: 0 or greater
  -h, --help            Show this help message
  -v, --version         Show the script version

EOF
    exit 0
}


scriptversion(){ 
    cat <<EOF
$script $scriptver - by 007revad

See https://github.com/$repo
EOF
    exit 0
}


# Save options used for getopts
args=("$@")

autoupdate=""

# Check for flags with getopt
if options="$(getopt -o abcdefghijklmnopqrstuvwxyz0123456789 -l \
    check,restore,unit:,help,version,email,autoupdate:,log,debug -- "${args[@]}")"; then
    eval set -- "$options"
    while true; do
        case "${1,,}" in
            -h|--help)          # Show usage options
                usage
                ;;
            -v|--version)       # Show script version
                scriptversion
                ;;
            -l|--log)           # Log
                #log=yes
                ;;
            -d|--debug)         # Show and log debug info
                debug=yes
                ;;
            -c|--check)         # Check current settings
                check=yes
                break
                ;;
            -r|--restore)       # Restore original settings
                restore=yes
                break
                ;;
            --unit)             # Specify eunit to enable for task scheduler
                if [[ ${2,,} =~ ^(d|r)x[0-9]+(rp|ii)?$ ]]; then
                    if [[ ${2:(-2)} == "rp" ]]; then
                        # Convert to upper case except rp at end
                        unit="$(b=${2:0:-2} && echo -n "${b^^}")rp"
                    else
                        # Convert to upper case
                        unit="${2^^}"
                    fi
                else
                    echo -e "Invalid argument '$2'\n"
                    exit 2  # Invalid argument
                fi
                break
                ;;
            -e|--email)         # Disable colour text in task scheduler emails
                color=no
                ;;
            --autoupdate)       # Auto update script
                autoupdate=yes
                if [[ $2 =~ ^[0-9]+$ ]]; then
                    delay="$2"
                    shift
                else
                    delay="0"
                fi
                ;;
            --)
                shift
                break
                ;;
            *)                  # Show usage options
                echo -e "Invalid option '$1'\n"
                usage "$1"
                ;;
        esac
        shift
    done
else
    echo
    usage
fi


if [[ $debug == "yes" ]]; then
    set -x
    export PS4='`[[ $? == 0 ]] || echo "\e[1;31;40m($?)\e[m\n "`:.$LINENO:'
fi


# Shell Colors
if [[ $color != "no" ]]; then
    #Black='\e[0;30m'   # ${Black}
    #Red='\e[0;31m'     # ${Red}
    #Green='\e[0;32m'   # ${Green}
    Yellow='\e[0;33m'   # ${Yellow}
    #Blue='\e[0;34m'    # ${Blue}
    #Purple='\e[0;35m'  # ${Purple}
    Cyan='\e[0;36m'     # ${Cyan}
    #White='\e[0;37m'   # ${White}
    Error='\e[41m'      # ${Error}
    Off='\e[0m'         # ${Off}
else
    echo ""  # For task scheduler email readability
fi


# Check script is running as root
if [[ $( whoami ) != "root" ]]; then
    ding
    echo -e "${Error}ERROR${Off} This script must be run as sudo or root!"
    exit 1  #  running as sudo or root
fi

# Get DSM major and minor versions
#dsm=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/VERSION majorversion)
#dsminor=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/VERSION minorversion)
#if [[ $dsm -gt "6" ]] && [[ $dsminor -gt "1" ]]; then
#    dsm72="yes"
#fi
#if [[ $dsm -gt "6" ]] && [[ $dsminor -gt "0" ]]; then
#    dsm71="yes"
#fi

# Get NAS model
model=$(cat /proc/sys/kernel/syno_hw_version)
#modelname="$model"


# Show script version
#echo -e "$script $scriptver\ngithub.com/$repo\n"
echo "$script $scriptver"

# Get DSM full version
productversion=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/VERSION productversion)
buildphase=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/VERSION buildphase)
buildnumber=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/VERSION buildnumber)
smallfixnumber=$(/usr/syno/bin/synogetkeyvalue /etc.defaults/VERSION smallfixnumber)

# Show DSM full version and model
if [[ $buildphase == GM ]]; then buildphase=""; fi
if [[ $smallfixnumber -gt "0" ]]; then smallfix="-$smallfixnumber"; fi
echo -e "$model DSM $productversion-$buildnumber$smallfix $buildphase\n"


# Get StorageManager version
storagemgrver=$(/usr/syno/bin/synopkg version StorageManager)
# Show StorageManager version
if [[ $storagemgrver ]]; then echo -e "StorageManager $storagemgrver\n"; fi


# Show options used
if [[ ${#args[@]} -gt "0" ]]; then
    echo "Using options: ${args[*]}"
fi

# Check Synology has a expansion port
# eSATA and InfiniBand ports both appear in syno_slot_mapping as:
# Esata port count: 1
# Eunit port 1 - RX1214
if which syno_slot_mapping >/dev/null; then
    esata_ports=$(syno_slot_mapping | grep 'Esata port count' | awk '{print $4}')
    if [[ $esata_ports -lt "1" ]]; then
        echo -e "${Error}ERROR${Off} Synology NAS has no expansion port(s)!"
        exit 1  # No expansion port(s)
    fi
else
    echo -e "${Error}ERROR${Off} Unsupported Synology NAS model. No syno_slot_mapping command!"
    exit 1  # No syno_slot_mapping file
fi


#------------------------------------------------------------------------------
# Check latest release with GitHub API

syslog_set(){ 
    if [[ ${1,,} == "info" ]] || [[ ${1,,} == "warn" ]] || [[ ${1,,} == "err" ]]; then
        if [[ $autoupdate == "yes" ]]; then
            # Add entry to Synology system log
            /usr/syno/bin/synologset1 sys "$1" 0x11100000 "$2"
        fi
    fi
}


# Get latest release info
# Curl timeout options:
# https://unix.stackexchange.com/questions/94604/does-curl-have-a-timeout
release=$(curl --silent -m 10 --connect-timeout 5 \
    "https://api.github.com/repos/$repo/releases/latest")

# Release version
tag=$(echo "$release" | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
shorttag="${tag:1}"

# Release published date
published=$(echo "$release" | grep '"published_at":' | sed -E 's/.*"([^"]+)".*/\1/')
published="${published:0:10}"
published=$(date -d "$published" '+%s')

# Today's date
now=$(date '+%s')

# Days since release published
age=$(((now - published)/(60*60*24)))


# Get script location
# https://stackoverflow.com/questions/59895/
source=${BASH_SOURCE[0]}
while [ -L "$source" ]; do # Resolve $source until the file is no longer a symlink
    scriptpath=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )
    source=$(readlink "$source")
    # If $source was a relative symlink, we need to resolve it
    # relative to the path where the symlink file was located
    [[ $source != /* ]] && source=$scriptpath/$source
done
scriptpath=$( cd -P "$( dirname "$source" )" >/dev/null 2>&1 && pwd )
scriptfile=$( basename -- "$source" )
echo -e "Running from: ${scriptpath}/$scriptfile\n"

# Warn if script located on M.2 drive
scriptvol=$(echo "$scriptpath" | cut -d"/" -f2)
vg=$(lvdisplay | grep /volume_"${scriptvol#volume}" | cut -d"/" -f3)
md=$(pvdisplay | grep -B 1 -E '[ ]'"$vg" | grep /dev/ | cut -d"/" -f3)
if grep "$md" /proc/mdstat | grep -q nvme; then
    echo -e "${Yellow}WARNING${Off} Don't store this script on an NVMe volume!"
fi


cleanup_tmp(){ 
    cleanup_err=

    # Delete downloaded .tar.gz file
    if [[ -f "/tmp/$script-$shorttag.tar.gz" ]]; then
        if ! rm "/tmp/$script-$shorttag.tar.gz"; then
            echo -e "${Error}ERROR${Off} Failed to delete"\
                "downloaded /tmp/$script-$shorttag.tar.gz!" >&2
            cleanup_err=1
        fi
    fi

    # Delete extracted tmp files
    if [[ -d "/tmp/$script-$shorttag" ]]; then
        if ! rm -r "/tmp/$script-$shorttag"; then
            echo -e "${Error}ERROR${Off} Failed to delete"\
                "downloaded /tmp/$script-$shorttag!" >&2
            cleanup_err=1
        fi
    fi

    # Add warning to DSM log
    if [[ $cleanup_err ]]; then
        syslog_set warn "$script update failed to delete tmp files"
    fi
}


if ! printf "%s\n%s\n" "$tag" "$scriptver" |
        sort --check=quiet --version-sort >/dev/null ; then
    echo -e "\n${Cyan}There is a newer version of this script available.${Off}"
    echo -e "Current version: ${scriptver}\nLatest version:  $tag"
    scriptdl="$scriptpath/$script-$shorttag"
    if [[ -f ${scriptdl}.tar.gz ]] || [[ -f ${scriptdl}.zip ]]; then
        # They have the latest version tar.gz downloaded but are using older version
        echo "You have the latest version downloaded but are using an older version"
        sleep 10
    elif [[ -d $scriptdl ]]; then
        # They have the latest version extracted but are using older version
        echo "You have the latest version extracted but are using an older version"
        sleep 10
    else
        if [[ $autoupdate == "yes" ]]; then
            if [[ $age -gt "$delay" ]] || [[ $age -eq "$delay" ]]; then
                echo "Downloading $tag"
                reply=y
            else
                echo "Skipping as $tag is less than $delay days old."
            fi
        else
            echo -e "${Cyan}Do you want to download $tag now?${Off} [y/n]"
            read -r -t 30 reply
        fi

        if [[ ${reply,,} == "y" ]]; then
            # Delete previously downloaded .tar.gz file and extracted tmp files
            cleanup_tmp

            if cd /tmp; then
                url="https://github.com/$repo/archive/refs/tags/$tag.tar.gz"
                if ! curl -JLO -m 30 --connect-timeout 5 "$url"; then
                    echo -e "${Error}ERROR${Off} Failed to download"\
                        "$script-$shorttag.tar.gz!"
                    syslog_set warn "$script $tag failed to download"
                else
                    if [[ -f /tmp/$script-$shorttag.tar.gz ]]; then
                        # Extract tar file to /tmp/<script-name>
                        if ! tar -xf "/tmp/$script-$shorttag.tar.gz" -C "/tmp"; then
                            echo -e "${Error}ERROR${Off} Failed to"\
                                "extract $script-$shorttag.tar.gz!"
                            syslog_set warn "$script failed to extract $script-$shorttag.tar.gz!"
                        else
                            # Set script sh files as executable
                            if ! chmod a+x "/tmp/$script-$shorttag/"*.sh ; then
                                permerr=1
                                echo -e "${Error}ERROR${Off} Failed to set executable permissions"
                                syslog_set warn "$script failed to set permissions on $tag"
                            fi

                            # Copy new script sh file to script location
                            if ! cp -p "/tmp/$script-$shorttag/${scriptname}.sh" "${scriptpath}/${scriptfile}";
                            then
                                copyerr=1
                                echo -e "${Error}ERROR${Off} Failed to copy"\
                                    "$script-$shorttag sh file(s) to:\n $scriptpath/${scriptfile}"
                                syslog_set warn "$script failed to copy $tag to script location"
                            fi

                            # Copy new CHANGES.txt file to script location (if script on a volume)
                            if [[ $scriptpath =~ /volume* ]]; then
                                # Set permissions on CHANGES.txt
                                if ! chmod 664 "/tmp/$script-$shorttag/CHANGES.txt"; then
                                    permerr=1
                                    echo -e "${Error}ERROR${Off} Failed to set permissions on:"
                                    echo "$scriptpath/CHANGES.txt"
                                fi

                                # Copy new CHANGES.txt file to script location
                                if ! cp -p "/tmp/$script-$shorttag/CHANGES.txt"\
                                    "${scriptpath}/${scriptname}_CHANGES.txt";
                                then
                                    if [[ $autoupdate != "yes" ]]; then copyerr=1; fi
                                    echo -e "${Error}ERROR${Off} Failed to copy"\
                                        "$script-$shorttag/CHANGES.txt to:\n $scriptpath"
                                else
                                    changestxt=" and changes.txt"
                                fi
                            fi

                            # Delete downloaded tmp files
                            cleanup_tmp

                            # Notify of success (if there were no errors)
                            if [[ $copyerr != 1 ]] && [[ $permerr != 1 ]]; then
                                echo -e "\n$tag ${scriptfile}$changestxt downloaded to: ${scriptpath}\n"
                                syslog_set info "$script successfully updated to $tag"

                                # Reload script
                                printf -- '-%.0s' {1..79}; echo  # print 79 -
                                exec "${scriptpath}/$scriptfile" "${args[@]}"
                            else
                                syslog_set warn "$script update to $tag had errors"
                            fi
                        fi
                    else
                        echo -e "${Error}ERROR${Off}"\
                            "/tmp/$script-$shorttag.tar.gz not found!"
                        syslog_set warn "/tmp/$script-$shorttag.tar.gz not found"
                    fi
                fi
                cd "$scriptpath" || echo -e "${Error}ERROR${Off} Failed to cd to script location!"
            else
                echo -e "${Error}ERROR${Off} Failed to cd to /tmp!"
                syslog_set warn "$script update failed to cd to /tmp"
            fi
        fi
    fi
fi


#------------------------------------------------------------------------------
# Show connected expansion units

#found_eunits=($(syno_slot_mapping | grep 'Eunit port' | awk '{print $NF}'))
read -r -a found_eunits <<< "$(syno_slot_mapping | grep 'Eunit port' | awk '{print $NF}')"
echo "Connected Expansion Units:"
if [[ ${#found_eunits[@]} -gt "0" ]]; then
    for e in "${found_eunits[@]}"; do
        echo -e "${Cyan}$e${Off}"
    done
else
    echo -e "${Cyan}None${Off}"
fi
#echo ""


#------------------------------------------------------------------------------
# Set file variables

if [[ -f /etc.defaults/model.dtb ]]; then  # Is device tree model
    # Get syn_hw_revision, r1 or r2 etc (or just a linefeed if not a revision)
    hwrevision=$(cat /proc/sys/kernel/syno_hw_revision)

    # If syno_hw_revision is r1 or r2 it's a real Synology,
    # and I need to edit model_rN.dtb instead of model.dtb
    if [[ $hwrevision =~ r[0-9] ]]; then
        hwrev="_$hwrevision"
    fi

    dtb_file="/etc.defaults/model${hwrev}.dtb"
    dtb2_file="/etc/model${hwrev}.dtb"
    #dts_file="/etc.defaults/model${hwrev}.dts"
    dts_file="/tmp/model${hwrev}.dts"
else
    echo -e "${Error}ERROR${Off} Unsupported Synology NAS model. No model.dtb file!"
    exit 1  # No model.dtb file
fi

synoinfo="/etc.defaults/synoinfo.conf"
synoinfo2="/etc/synoinfo.conf"
scemd="/usr/syno/bin/scemd"

rebootmsg(){ 
    # Ensure newly connected ebox is in /var/log/diskprediction log.
    # Otherwise the new /var/log/diskprediction log is only created a midnight.
    /usr/syno/bin/syno_disk_data_collector record

    # Reboot prompt
    echo -e "\n${Cyan}The Synology needs to restart.${Off}"
    echo -e "Type ${Cyan}yes${Off} to reboot now."
    echo -e "Type anything else to quit (if you will restart it yourself)."
    read -r -t 10 answer
    if [[ ${answer,,} != "yes" ]]; then
        echo ""
        exit
    fi

#    # Reboot in the background so user can see DSM's "going down" message
#    reboot &
    if [[ -x /usr/syno/sbin/synopoweroff ]]; then
        /usr/syno/sbin/synopoweroff -r || reboot
    else
        reboot
    fi
}


#------------------------------------------------------------------------------
# Restore changes from backups

compare_md5(){ 
    # $1 is file 1
    # $2 is file 2
    if [[ -f "$1" ]] && [[ -f "$2" ]]; then
        if [[ $(md5sum -b "$1" | awk '{print $1}') == $(md5sum -b "$2" | awk '{print $1}') ]];
        then
            return 0
        else
            return 1
        fi
    else
        restoreerr=$((restoreerr+1))
        return 2
    fi
}

restore_orig(){ 
    restoreerr="0"
    if [[ -f ${dtb_file}.bak ]] || [[ -f ${synoinfo}.bak ]] || [[ -f ${scemd}.bak ]] ; 
    then
        # Restore synoinfo.conf from backup
        # /usr/syno/etc.defaults/synoinfo.conf
        if [[ -f ${synoinfo}.bak ]]; then
            setting="$(/usr/syno/bin/synogetkeyvalue "${synoinfo}.bak" support_ew_20_eunit)"
            setting2="$(/usr/syno/bin/synogetkeyvalue "${synoinfo}" support_ew_20_eunit)"
            if [[ $setting != "$setting2" ]]; then
                if /usr/syno/bin/synosetkeyvalue "$synoinfo" support_ew_20_eunit "$setting"; then
                    /usr/syno/bin/synosetkeyvalue "$synoinfo2" support_ew_20_eunit "$setting"
                    echo -e "Restored ${synoinfo}"
                else
                    restoreerr=$((restoreerr+1))
                    echo -e "${Error}ERROR${Off} Failed to restore ${synoinfo}!\n"
                fi
            fi
        else
            restoreerr=$((restoreerr+1))
            echo -e "${Error}ERROR${Off} No backup to restore ${synoinfo} from!\n"
        fi

        # Restore scemd from backup
        if [[ -f ${scemd}.bak ]]; then
            if compare_md5 "${scemd}".bak "${scemd}"; then
                echo -e "${Cyan}OK${Off} ${scemd}"
            else
                /usr/bin/systemctl stop scemd.service
                if cp -p --force "${scemd}.bak" "${scemd}"; then
                    echo -e "Restored ${scemd}"
                else
                    restoreerr=$((restoreerr+1))
                    echo -e "${Error}ERROR${Off} Failed to restore ${scemd}!\n"
                fi
                /usr/bin/systemctl start scemd.service
            fi
        #else
        #    restoreerr=$((restoreerr+1))
        #    echo -e "${Error}ERROR${Off} No backup to restore ${scemd} from!\n"
        fi

        # Restore model.dtb from backup
        if [[ -f ${dtb_file}.bak ]]; then
            # /etc.default/model.dtb
            if compare_md5 "${dtb_file}.bak" "${dtb_file}"; then
                echo -e "${Cyan}OK${Off} ${dtb_file}"
            else
                if cp -p --force "${dtb_file}.bak" "${dtb_file}"; then
                    echo -e "Restored ${dtb_file}"
                    reboot=yes
                else
                    restoreerr=$((restoreerr+1))
                    echo -e "${Error}ERROR${Off} Failed to restore ${dtb_file}!\n"
                fi
            fi
            # Restore /etc/model.dtb from /etc.default/model.dtb
            if compare_md5 "${dtb_file}.bak" "${dtb2_file}"; then
                echo -e "${Cyan}OK${Off} ${dtb2_file}"
            else
                if cp -p --force "${dtb_file}.bak" "${dtb2_file}"; then
                    echo -e "Restored ${dtb2_file}"
                else
                    restoreerr=$((restoreerr+1))
                    echo -e "${Error}ERROR${Off} Failed to restore ${dtb2_file}!\n"
                fi
            fi
        else
            restoreerr=$((restoreerr+1))
            echo -e "${Error}ERROR${Off} No backup to restore ${dtb2_file} from!\n"
        fi

        if [[ -z $restoreerr ]] || [[ $restoreerr -lt "1" ]]; then
            echo -e "\nRestore successful."
            rebootmsg
        elif [[ $restoreerr == "1" ]]; then
            echo -e "\nThere was $restoreerr restore error!"
        else
            echo -e "\nThere were $restoreerr restore errors!"
        fi
    else
        echo -e "Nothing to restore."
    fi
}

if [[ $restore == "yes" ]]; then
    echo ""
    restore_orig
    echo ""
    exit
fi


#----------------------------------------------------------
# Check currently enabled expansion units

supported_eunits=("DX517" "DX513" "DX213" "DX510" "RX418" "RX415" "RX410" \
"RX1217rp" "RX1217" "RX1214rp" "RX1214" "RX1211rp" "RX1211" \
"DX1215II" "DX1215" "DX1211")

check_modeldtb(){ 
    # $1 is DX517 or RX418 etc
    if [[ -f "${dtb2_file}" ]]; then
        if grep -q "$1"'\b' "${dtb2_file}"; then
            echo -e "${Cyan}$1${Off} is enabled in ${Yellow}${dtb2_file}${Off}" >& 2
        else
            echo -e "${Cyan}$1${Off} is ${Cyan}not${Off} enabled in ${Yellow}${dtb2_file}${Off}" >& 2
        fi
    fi
    if [[ -f "${dtb_file}" ]]; then
        if grep -q "$1"'\b' "${dtb_file}"; then
            echo -e "${Cyan}$1${Off} is enabled in ${Yellow}${dtb_file}${Off}" >& 2
        else
            echo -e "${Cyan}$1${Off} is ${Cyan}not${Off} enabled in ${Yellow}${dtb_file}${Off}" >& 2
        fi
    fi
}

check_enabled(){ 
    echo ""
    for e in "${supported_eunits[@]}"; do
        if grep -q "$e"'\b' "${dtb_file}"; then
            check_modeldtb "${e#Synology-}"
        fi
    done
    echo ""
}

if [[ $check == "yes" ]]; then
    #echo ""
    check_enabled
    exit
fi


#------------------------------------------------------------------------------
# Enable unsupported Synology expansion units

backupdb(){ 
    # Backup file if needed
    if [[ -f "$1" ]]; then
        if [[ ! -f "$1.bak" ]]; then
            if [[ $(basename "$1") == "synoinfo.conf" ]]; then
                echo "" >&2  # Formatting for stdout
            fi
            if [[ $2 == "long" ]]; then
                fname="$1"
            else
                fname=$(basename -- "${1}")
            fi
            if cp -p "$1" "$1.bak"; then
                echo -e "Backed up ${fname}" >&2
            else
                echo -e "${Error}ERROR 5${Off} Failed to backup ${fname}!" >&2
                return 1
            fi
        fi
        # Fix permissions if needed
        octal=$(stat -c "%a %n" "$1" | cut -d" " -f1)
        if [[ ! $octal -eq 644 ]]; then
            chmod 644 "$1"
        fi
    else
        echo -e "${Error}ERROR 5${Off} File not found: ${1}!" >&2
        return 1
    fi
    return 0
}

dts_ebox(){ 
    # $1 is the ebox model
    # $2 is the dts file

    # Remove last }; so we can append to dts file
    sed -i '/^};/d' "$2"

    # Append expansion unit node to dts file
    if [[ $1 == DX517 ]] || [[ $1 == DX513 ]] || [[ $1 == DX510 ]]; then
    cat >> "$2" <<EODX5bay

	$1 {
		compatible = "Synology";
		model = "synology_${1,,}";

		pmp_slot@1 {

			libata {
				EMID = <0x00>;
				pmp_link = <0x00>;
			};
		};

		pmp_slot@2 {

			libata {
				EMID = <0x00>;
				pmp_link = <0x01>;
			};
		};

		pmp_slot@3 {

			libata {
				EMID = <0x00>;
				pmp_link = <0x02>;
			};
		};

		pmp_slot@4 {

			libata {
				EMID = <0x00>;
				pmp_link = <0x03>;
			};
		};

		pmp_slot@5 {

			libata {
				EMID = <0x00>;
				pmp_link = <0x04>;
			};
		};
	};
};
EODX5bay

elif [[ $1 == DX213 ]]; then
    cat >> "$2" <<EODX213

	$1 {
		compatible = "Synology";
		model = "synology_${1,,}";

		pmp_slot@1 {

			libata {
				EMID = <0x00>;
				pmp_link = <0x00>;
			};
		};

		pmp_slot@2 {

			libata {
				EMID = <0x00>;
				pmp_link = <0x01>;
			};
		};
	};
};
EODX213

elif [[ $1 == RX418 ]] || [[ $1 == RX415 ]] || [[ $1 == RX410 ]]; then
    cat >> "$2" <<EORX4bay

	$1 {
		compatible = "Synology";
		model = "synology_${1,,}";

		pmp_slot@1 {

			libata {
				EMID = <0x00>;
				pmp_link = <0x00>;
			};
		};

		pmp_slot@2 {

			libata {
				EMID = <0x00>;
				pmp_link = <0x01>;
			};
		};

		pmp_slot@3 {

			libata {
				EMID = <0x00>;
				pmp_link = <0x02>;
			};
		};

		pmp_slot@4 {

			libata {
				EMID = <0x00>;
				pmp_link = <0x03>;
			};
		};
	};
};
EORX4bay

elif [[ ${_12bays[*]} =~ $1 ]]; then
    cat >> "$2" <<EORX12bay

	$1 {
		compatible = "Synology";
		model = "synology_rx1217rp";

		pmp_slot@1 {

			libata {
				EMID = <0x00>;
				pmp_link = <0x00>;
			};
		};

		pmp_slot@2 {

			libata {
				EMID = <0x00>;
				pmp_link = <0x01>;
			};
		};

		pmp_slot@3 {

			libata {
				EMID = <0x00>;
				pmp_link = <0x02>;
			};
		};

		pmp_slot@4 {

			libata {
				EMID = <0x01>;
				pmp_link = <0x00>;
			};
		};

		pmp_slot@5 {

			libata {
				EMID = <0x01>;
				pmp_link = <0x01>;
			};
		};

		pmp_slot@6 {

			libata {
				EMID = <0x01>;
				pmp_link = <0x02>;
			};
		};

		pmp_slot@7 {

			libata {
				EMID = <0x02>;
				pmp_link = <0x00>;
			};
		};

		pmp_slot@8 {

			libata {
				EMID = <0x02>;
				pmp_link = <0x01>;
			};
		};

		pmp_slot@9 {

			libata {
				EMID = <0x02>;
				pmp_link = <0x02>;
			};
		};

		pmp_slot@10 {

			libata {
				EMID = <0x03>;
				pmp_link = <0x00>;
			};
		};

		pmp_slot@11 {

			libata {
				EMID = <0x03>;
				pmp_link = <0x01>;
			};
		};

		pmp_slot@12 {

			libata {
				EMID = <0x03>;
				pmp_link = <0x02>;
			};
		};
	};
};
EORX12bay

fi
}

install_binfile(){ 
    # install_binfile <file> <file-url> <destination> <chmod> <bundled-path> <hash>
    # example:
    #  file_url="https://raw.githubusercontent.com/${repo}/main/bin/dtc"
    #  install_binfile dtc "$file_url" /usr/bin/dtc a+x bin/dtc

    if [[ -f "${scriptpath}/$5" ]]; then
        binfile="${scriptpath}/$5"
        echo -e "\nInstalling ${1}"
    elif [[ -f "${scriptpath}/$(basename -- "$5")" ]]; then
        binfile="${scriptpath}/$(basename -- "$5")"
        echo -e "\nInstalling ${1}"
    else
        # Download binfile
        if [[ $autoupdate == "yes" ]]; then
            reply=y
        else
            echo -e "\nNeed to download ${1}"
            echo -e "${Cyan}Do you want to download ${1}?${Off} [y/n]"
            read -r -t 30 reply
        fi
        if [[ ${reply,,} == "y" ]]; then
            echo -e "\nDownloading ${1}"
            if ! curl -kL -m 30 --connect-timeout 5 "$2" -o "/tmp/$1"; then
                echo -e "${Error}ERROR${Off} Failed to download ${1}!"
                #return
                exit 1  # Failed to download  binfile
            fi
            binfile="/tmp/${1}"

            printf "Downloaded md5: "
            md5sum -b "$binfile" | awk '{print $1}'

            md5=$(md5sum -b "$binfile" | awk '{print $1}')
            if [[ $md5 != "$6" ]]; then
                echo "Expected md5:   $6"
                echo -e "${Error}ERROR${Off} Downloaded $1 md5 hash does not match!"
                exit 1  # Downloaded $1 md5 hash does not match
            fi
        else
            echo -e "${Error}ERROR${Off} Cannot add expansion unit without ${1}!"
            exit 1  # User answered no
        fi
    fi

    # Set binfile executable
    chmod "$4" "$binfile"

    # Copy binfile to destination
    cp -p "$binfile" "$3"
}

edit_modeldtb(){ 
    # $1 is ebox model
    if [[ -f /etc.defaults/model.dtb ]]; then  # Is device tree model
        # Check if dtc exists and is executable
        if [[ ! -x $(which dtc) ]]; then
            md5hash="01381dabbe86e13a2f4a8017b5552918"
            branch="main"
            file_url="https://raw.githubusercontent.com/${repo}/${branch}/bin/dtc"
            # install_binfile <file> <file-url> <destination> <chmod> <bundled-path> <hash>
            install_binfile dtc "$file_url" /usr/sbin/dtc "a+x" bin/dtc "$md5hash"
        fi

        # Check again if dtc exists and is executable
        if [[ -x /usr/sbin/dtc ]]; then

            # Backup model.dtb
            backupdb "$dtb_file" || exit 1  # Failed to backup model.dtb

            # Output model.dtb to model.dts
            dtc -q -I dtb -O dts -o "$dts_file" "$dtb_file"  # -q Suppress warnings
            chmod 644 "$dts_file"

            # Edit model.dts
            for c in "${eboxes[@]}"; do
                # Edit model.dts if needed
                if ! grep -q "$c"'\b' "$dtb_file"; then
                    dts_ebox "$c" "$dts_file"
                    echo -e "Added ${Cyan}$c${Off} to ${Yellow}model${hwrev}.dtb${Off}" >&2
                    reboot=yes
                else
                    echo -e "${Cyan}$c${Off} already enabled in ${Yellow}model${hwrev}.dtb${Off}" >&2
                fi
            done

            # Compile model.dts to model.dtb
            dtc -q -I dts -O dtb -o "$dtb_file" "$dts_file"  # -q Suppress warnings

            # Set owner and permissions for model.dtb
            chmod a+r "$dtb_file"
            chown root:root "$dtb_file"
            cp -pu "$dtb_file" "$dtb2_file"  # Copy dtb file to /etc
        else
            echo -e "${Error}ERROR${Off} Missing /usr/sbin/dtc or not executable!" >&2
            exit
        fi
    fi
}


#------------------------------------------------------------------------------
# Select expansion unit to enable
 
# Show currently enabled eunit(s)
check_enabled

enable_eunit(){ 
    case "$choice" in
        DX517|DX513|DX510)
            eboxes=("$choice") && edit_modeldtb
            return
        ;;
        DX213)
            eboxes=("$choice") && edit_modeldtb
            return
        ;;
        RX418|RX415|RX410)
            eboxes=("$choice") && edit_modeldtb
            return
        ;;
        RX1217rp|RX1214rp|RX1211rp)
            eboxes=("$choice")
            eboxes+=("${choice//rp}")  # Also add non-RP model
            edit_modeldtb
            return
        ;;
        RX1217|RX1214|RX1211)
            eboxes=("$choice") && edit_modeldtb
            return
        ;;
        DX1215II|DX1215|DX1211)
            eboxes=("$choice") && edit_modeldtb
            return
        ;;
        Check)
            check_enabled
            exit
        ;;
        Restore)
            restore_orig
            return
        ;;
        Quit) exit ;;
        "") echo "Invalid Choice!" ;;
        *)
            echo -e "$choice not supported yet"
            exit
        ;;
    esac
}

_12bays=("RX1217rp" "RX1217" "RX1214rp" "RX1214" "RX1211rp" "RX1211" \
"DX1215II" "DX1215" "DX1211")

eunits=("DX517" "DX513" "DX213" "DX510" "RX418" "RX415" "RX410" \
"RX1217rp" "RX1217" "RX1214rp" "RX1214" "RX1211rp" "RX1211" \
"DX1215II" "DX1215" "DX1211" \
"Restore" "Quit")

if [[ -n $unit ]]; then
    # Expansion Unit supplied as argument
    if [[ ${eunits[*]} =~ ${unit} ]]; then
        choice="${unit}"
        echo -e "$choice selected\n"
        enable_eunit
    else
        echo -e "Unsupported expansion unit argument: $unit\n"
        exit 2  # Unsupported expansion unit argument
    fi
else
    PS3="Select your Expansion Unit: "
    select choice in "${eunits[@]}"; do
        echo -e "You selected $choice \n"
        enable_eunit
        break
    done
fi
#echo ""


#------------------------------------------------------------------------------
# Finished

if [[ $reboot == "yes" ]]; then
    rebootmsg
else
    echo -e "\nFinished"
fi

