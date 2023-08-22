#!/bin/bash
# Wait for /dev/nvme1n1 to appear up to 30 seconds
for i in {1..10}; do
    [[ -e /dev/nvme1n1 ]] && break
    echo "Waiting for nvme1n1 ($i/10)"
    sleep 3
done

if [[ -e /dev/nvme1n1 ]]; then
  # Determine the file system
  FSTYPE=$(lsblk /dev/nvme1n1 -no fstype)
  if [[ -z "$FSTYPE" ]]; then
    echo "Formatting /dev/nvme1n1"
    parted -s /dev/nvme1n1 mklabel gpt
    parted -s /dev/nvme1n1 mkpart primary ext4 0% 100%
    mkfs.ext4 /dev/nvme1n1p1
    # Reload partitions
    partprobe /dev/nvme1n1
    udevadm settle
  else
    echo "Disk is already formatted"
  fi

  UUID=$(lsblk /dev/nvme1n1p1 -no UUID)
  if grep -q "$UUID" /etc/fstab; then
    echo "Disk is already in fstab"
  else
    echo "Adding disk to fstab"
    echo "UUID=$UUID /mnt/data ext4 defaults 0 0" >> /etc/fstab
  fi
else # if [[ ! -e /dev/nvme1n1 ]]
  echo "Disk is not present"
fi

mkdir -p /mnt/data
mount -a
