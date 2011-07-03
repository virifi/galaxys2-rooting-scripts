#!/bin/sh

echo "creating odin img"
tar -cf FACTORYFS_SC02COMKF2.tar factoryfs.img
wait
md5sum -t FACTORYFS_SC02COMKF2.tar >> FACTORYFS_SC02COMKF2.tar
wait
mv FACTORYFS_SC02COMKF2.tar FACTORYFS_SC02COMKF2.tar.md5
wait
echo "created odin img : FACTORYFS_SC02COMKF2.tar.md5"
echo "Complete : 3.5_creat_odin_img.sh" 
