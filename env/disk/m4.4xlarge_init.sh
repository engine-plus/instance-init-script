# h1.4xlarge 磁盘初始化 :
#
# 主盘 :            /dev/xvda  -> root
#
# 自带两块 SSD 盘 :
# M4.4xlarge 形式的自带盘盘符是与申请时相关的： 例如 sdb -> xvdb : sdc -> xvdc
# 这里说明指定 ：创建机器时候选择盘必须为 [sdb, sdc 盘符]

mdadm --create /dev/md0 --level=0 --raid-devices=2 /dev/xvdb /dev/xvdc

mkfs.ext4 /dev/md0

tune2fs -o journal_data_writeback /dev/md0
tune2fs -O ^has_journal /dev/md0

mount -o noatime /dev/md0 /mnt

chmod 0777 /mnt