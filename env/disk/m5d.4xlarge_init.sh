# m5d.4xlarge 磁盘初始化 :
#
# 主盘 :            /dev/nvme0n1  -> root
# /mnt1             /dev/nvme1n1
# 自带两块 SSD 盘 :  /dev/nvme2n1  /dev/nvme3n1

mkdir /mnt1

# /mnt
mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/nvme2n1 /dev/nvme3n1

mkfs.ext4 /dev/md0

tune2fs -o journal_data_writeback /dev/md0
tune2fs -O ^has_journal /dev/md0

mount -o noatime /dev/md0 /mnt
chmod 0777 /mnt


# /mnt1

mkfs.ext4 /dev/nvme1n1

tune2fs -o journal_data_writeback /dev/nvme1n1
tune2fs -O ^has_journal /dev/nvme1n1

mount -o noatime /dev/nvme1n1 /mnt1
chmod 0777 /mnt1