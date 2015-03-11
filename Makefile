# Set these to the desired locations
url_bootsect = http://dl.cubieboard.org/software/a20-cubietruck/lubuntu/ct-lubuntu-card0-v1.00/u-boot-sunxi-with-spl-ct-20131102.bin
url_bootfs = http://geekdome.net/x2go/trusty/trusty-boot.tar.bz2
url_rootfs = http://geekdome.net/x2go/trusty/trusty-root.tar.bz2

# Desired FS size (G) 
img_size = 10
img_fn = hda.img


# Where to do temporary mounts
mounts_dir = mnt

	
.PHONY: all clean do_populate get_loop_info do_unmount

all: do_populate do_unmount

img_bootsect = $(notdir $(url_bootsect))
$(img_bootsect):
	wget -N $(url_bootsect)
	

img_bootfs = $(notdir $(url_bootfs))
$(img_bootfs):
	wget -N $(url_bootfs)
	

img_rootfs = $(notdir $(url_rootfs))
$(img_rootfs):
	wget -N $(url_rootfs)
	

$(img_fn): 
	# Start a disk image file
	dd if=/dev/zero of=$(img_fn) bs=1024 count=10
	
	# Apply the bootloader
	dd if=$(img_bootsect) of=$(img_fn) bs=1024 seek=8
	
	# Previous dd reduces the image size.
	# This zeros it out to the desired size
	truncate -s $(img_size)G $(img_fn)
	
	# Partition and Make File Systems on Partitions
	parted $(img_fn) mklabel msdos
	parted -s $(img_fn) mkpart primary 0.0 64M
	parted -s $(img_fn) mkpart primary 64M $(img_size)G
	

/sbin/kpartx:
	apt-get install -y kpartx

# First dependency on $fs_devs will redefine it as the
# actual devices mapped to the boot and root partitions
fs_devs = $(img_fn) get_loop_devs
get_loop_devs: /sbin/kpartx
	# Get the loopback device associated with this file, 
	# or associate it with one if necessary. Store in 'dev' var
	$(eval loop = $(shell \
		DEV=$$(sudo losetup -j $(img_fn) | tail -n 1 | cut -d: -f1 | awk -F/ '{print $$(NF)}') ; \
		[ -z "$$DEV" ] && \
		DEV=$$(sudo losetup -vf $(img_fn) | awk -F/ '{print $$(NF)}') ; \
		echo "$$DEV" ; \
	))
	$(eval loop_dev = /dev/$(loop))
	
	sudo kpartx -va $(loop_dev)
	$(eval bootfs_dev = /dev/mapper/$(loop)p1)
	$(eval rootfs_dev = /dev/mapper/$(loop)p2)
	$(eval fs_devs = $(bootfs_dev) $(rootfs_dev))
	
	
bootfs_mountpoint = $(mounts_dir)/boot	
bootfs_mount: $(fs_devs)
	[ -e $(bootfs_mountpoint) ] || mkdir -p $(bootfs_mountpoint)
	if ! mount | grep $(bootfs_mountpoint) ; \
	then \
		blkid | grep $(bootfs_dev) || sudo mkfs.ext2 $(bootfs_dev) ; \
		sudo mount -o loop $(bootfs_dev) $(bootfs_mountpoint) ;\
	fi
	
bootfs_populate: bootfs_mount
	[ $$(ls -l $(bootfs_mountpoint) | grep -v 'lost+found' | wc -l) -gt 0 ] &&  \
		sudo tar -C $(bootfs_mountpoint) -zxf $(img_bootfs)
	
	
rootfs_mountpoint = $(mounts_dir)/root	
rootfs_mount: $(fs_devs)
	[ -e $(rootfs_mountpoint) ] || mkdir -p $(rootfs_mountpoint)
	if ! mount | grep $(rootfs_mountpoint) ; \
	then \
		blkid | grep $(rootfs_dev) || sudo mkfs.ext4 $(rootfs_dev) ; \
		sudo mount -o loop $(rootfs_dev) $(rootfs_mountpoint) ;\
	fi
	
rootfs_populate: rootfs_mount
	[ $$(ls -l $(rootfs_mountpoint) | grep -v 'lost+found' | wc -l) -gt 0 ] &&  \
		sudo tar -C $(rootfs_mountpoint) -zxf $(img_rootfs)
	
	
do_populate: $(img_bootsect) $(img_bootfs) bootfs_populate rootfs_populate

do_unmount: get_loop_devs
	sudo umount $(rootfs_mountpoint) || true
	sudo umount $(bootfs_mountpoint) || true
	sudo kpartx -d $(loop_dev)
	for d in $$(sudo losetup -j $(img_fn) | tail -n 1 | cut -d: -f1) ; \
		do sudo losetup -d $$d ; done
	

clean:
	rm -f $(img_fn) || true
	
