#!/bin/bash

# Please confiure:
defaultGpgID=""
defaultImageSize=5
keyName=luks-secret.gpg
cryptimg=luks-secret.img


keyfifo=/tmp/"luksfifo"$(cat < /dev/urandom | tr -dc "[:lower:]"  | head -c 8)
workingDir=$PWD
keyFile=$workingDir/$keyName
cryptimg=luks-secret.img
script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
dmdev="luksdev"$(cat < /dev/urandom | tr -dc "[:lower:]"  | head -c 8)
mountpoint=${workingDir}/mnt

# colors for errors and warnings	
red=$(tput setab 0; tput setaf 1)
yellow=$(tput setab 0; tput setaf 3)
none=$(tput sgr0)

# colors for messages
green="\033[32m"
blue="\033[34m"
normal="\033[0m"


# Print out intro banner
function intro(){
echo -e "$yellow =========================================================$none"
echo -e "$green \tLUKS-Mounts for mounting LUKS containers in Linux. $normal"
echo -e "$green \tIt can create, mount, unmount LUKS formatted disk $normal"
echo -e "$green \timages encrypted with gpg-encrypted key file $normal"
echo -e "$green \t"
echo -e "$green \tCreates key-file and volume in working directory."
echo -e "$green \tMountpoint will be Working_Directory/mnt."
echo -e "$yellow =========================================================$none"
}


function testmount() {
if ! test -f $cryptimg; then
    echo "Crypto-Imgae $cryptimg existiert nicht."
    echo "Breche ab"
    exit 0
fi
if ! test -d $mountpoint; then
    mkdir $mountpoint
fi
if mount |grep $mountpoint > /dev/null 2>&1; then
    echo "Image scheint bereits gemountet oder Mountpoint anderweitig in Verwendung."
    echo "Breche ab"
    exit 0
fi
if ls -l $mountpoint/* > /dev/null 2>&1; then
    echo "Mountpoint nicht leer"
    echo "Breche ab"
    exit 0
fi
    }

function luksopen() {
	gpg -dq $keyFile | sudo cryptsetup luksOpen --key-file - $cryptimg $dmdev
	}

function imgmount() {
	sudo mount /dev/mapper/$dmdev $mountpoint
	}

function imgumount() {
    # get actual dm-device
    if mount |grep $mountpoint; then 
        dmdev=$(mount |grep $mountpoint | cut -d' ' -f1 |sed -e 's|^/dev/mapper/||')
        sudo umount $mountpoint
        sudo cryptsetup luksClose $dmdev
    else
        echo "Image not mounted??"
    fi
	}

function imgchown() {
    # workaround fuer unterschiedliche Nutzer
    sudo chown -R $USER $mountpoint
    }

function imageCreate() {

if test -e $cryptimg; then
    echo "Image with this name already exists. Operation canceled"
    exit 0
fi

if test -e $keyFile; then
    echo "Key file with this name already exists. Operation canceled"
    exit 0
fi


# Get Size of the volume to create . Default is 512 MB
read -p "Enter size (MB) of the virtual volume to create [default $defaultImageSize] :  " size
while [[ -z  $size  ]]; do
    size=$defaultImageSize
done

# Get gpg-IDs
read -p "Enter gpg-ID: " gpgID
while [[ -z  $gpgID ]]; do
    read -p "You must enter a gpg-ID: " gpgID
done

# generate gpg encrypted secret key
dd if=/dev/urandom bs=1 count=256 | gpg -e -o $keyFile -r $gpgID

# generate volume
dd if=/dev/zero of=$cryptimg bs=1M count=$size

# keyfifo erstellen - hier kommt dann der entschlüsselte key rein.
mkfifo -m 700 $keyfifo
gpg -d $keyFile >$keyfifo &

# device erstellen 
sudo cryptsetup luksFormat $cryptimg $keyfifo

# device öffnen
gpg -dq $keyFile | sudo cryptsetup luksOpen --key-file - $cryptimg $dmdev

# Filesystem erstellen
sudo mkfs.ext4 /dev/mapper/$dmdev

# luks schließen
sudo cryptsetup luksClose $dmdev

# aufräumen
rm $keyfifo

    }

### Help Function 

function usage(){
echo -e "$yellow\t++++++++++++++++++++++++++++++++++++++ $none"
echo -e "$green\tHow to use luks-mount (optional) $normal"
echo -e "$yellow\t++++++++++++++++++++++++++++++++++++++ $none"
echo -e "$blue luks-mount.sh menu $normal"
echo -e "$blue luks-mount.sh create $normal"
echo -e "$blue luks-mount.sh mount $normal"
echo -e "$blue luks-mount.sh umount $normal \n"
exit 1;
}

### Run Function

function run() {
case $1 in
	mount)
		# Checken, ob der Key überhaupt zu entschlüsseln ist ...
        testmount
		luksopen
		imgmount
        imgchown
	;;
	umount)
		imgumount
	;;
    create)
        imageCreate
    ;;
    *)
        usage
    ;;

esac
}

# Here operation starts

if [ $# -eq 0 ]; then
    intro
    echo -e "$green Select an option to use. \n $normal"

    a="Create an LUKS Encrypted Disk Image"
    b="Mount an LUKS Encrypted Image"
    c="Unmount a LUKS Encrypted Image"
    d="Quit"
     

    select option in  "$a" "$b" "$c" "$d"
    do
        case "$option" in 
            "$a") run create
            ;;
            "$b") run mount
            ;;
            "$c") run umount
            ;;
            "$d") exit 1;
            ;;
            *) echo -e "$red  Option not found! What did you do there? $none";;
        esac
    done

else run $1
fi
