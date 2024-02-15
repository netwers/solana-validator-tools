echo "Hello!"
echo
deviceName=$(sudo losetup -Pf --show ~/snode/vhd_32mb_keys.img)
mountName="solkeys"

echo "deviceName: $deviceName"
echo "mountName:  $mountName"
sudo cryptsetup luksOpen $deviceName $mountName
sudo mount /dev/mapper/$mountName ~/snode/sol-keys/
echo "See ya!"
echo ""
