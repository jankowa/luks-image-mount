luks-image-mount
========

### What is Luks-Image-Mount? 
A bash script to create, mount and unmount LUKS encrypted 
containers files with gnupg encrypted key files.

### How it work's

During creation there will be added a new disk-image and a 
gpg-encrypted key-file. The disk image will be formatted as
a LUKS Container using the gpg-encrypted key-file with a ext4 
file system.

During initial creation the script asks for a gnupg-ID. To 
encrypt with multiple gpg-IDs use gnupg group-IDs.

After creating and formatting the disk image can be mounted on a 
mountpoint inside the working directory.

### Basic Usage 

To create a disk file in the current working directory:
```bash
luks-image-mount.sh create
```

To mount disk file in the current working directory:
```bash
luks-image-mount.sh mount
```

To unmount disk file in the current working directory:
```bash
luks-image-mount.sh umount
```

There is an option for a menu:
```bash
luks-image-mount.sh menu
```

### Advanced Usage

The most secure way to use this is together with gnupg-smartcards.


### Dependencies (Install applications:)
1. **dmsetup** -- low level logical volume management
2. **cryptsetup** -- manage plain dm-crypt and LUKS encrypted volumes
3. **gnupg2** -- manage gpg-encrypted key files

#### But make sure you read the man pages and other online Doc about LUKS and gnupg
* man cryptsetup (or cryptsetup --help)
* man dmsetup
* man gpg

#### Thanks:

This script was inspired from https://github.com/JohnTroony/LUKS-OPs
