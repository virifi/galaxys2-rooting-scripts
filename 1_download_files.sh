#!/bin/sh

adb_path=`which adb`
if [ ! -x $adb_path ]; then
    echo "cannot find adb"
    exit 1
else
    echo $adb_path > ./adb_path
fi
if [ ! -x `which curl` ]; then
    echo "cannot find curl"
    exit 1
fi
if [ ! -x `which gcc` ]; then
    echo "cannot find gcc"
    exit 1
fi
if [ ! -x `which make` ]; then
    echo "cannot find make"
    exit 1
fi

echo "Downloading ext4_utils.zip"
curl -#Lo ext4_utils.zip 'http://forum.xda-developers.com/attachment.php?attachmentid=597848&d=1305554016'
wait
echo "Building ext4_utils"
unzip ext4_utils.zip >/dev/null
wait
rm -f ./ext4_utils.zip
cd ext4_utils
wait
make
wait
if [ ! -e ./make_ext4fs ]; then
    echo "failed building ext4_utils"
    exit 1
fi
cd ..
echo "Downloading bluetooth conf files"
curl -#L -o bluetooth-596d8ca.tgz --connect-timeout 10 'http://android.git.kernel.org/?p=platform/system/bluetooth.git;a=snapshot;h=596d8cae44844161b5b182d3defa681e1200dd46;sf=tgz'
wait
tar xzvf bluetooth-596d8ca.tgz >/dev/null
wait
rm -f ./bluetooth-596d8ca.tgz
mv bluetooth-596d8ca/data ./rooting_files
wait
rm -rf ./bluetooth-596d8ca
curl -#L -o dbus.conf --connect-timeout 10 'http://android.git.kernel.org/?p=platform/system/core.git;a=blob_plain;f=rootdir/etc/dbus.conf;hb=dd7bc3319deb2b77c5d07a51b7d6cd7e11b5beb0'
wait
mv dbus.conf ./rooting_files
echo "Downloading su and Superuser.apk"
curl -#Lo su-2.3.6.1-ef-signed.zip --connect-timeout 10 'http://api.viglink.com/api/click?format=go&drKey=1359&loc=http%3A%2F%2Fforum.xda-developers.com%2Fshowthread.php%3Ft%3D682828&v=1&libid=1309666857489&out=http%3A%2F%2Fbit.ly%2Fsu2361ef&ref=http%3A%2F%2Fforum.xda-developers.com%2Fshowpost.php%3Fp%3D6976975%26postcount%3D2&title=%5BAPP%5D%20Superuser%202.3.6.1%20-%20Now%20on%20the%20Market%20%5B2010-09-05%5D%20-%20xda-developers&txt=su-2.3.6.1-ef-signed.zip'
wait
unzip su-2.3.6.1-ef-signed.zip -d ./su_files
wait
rm -f ./su-2.3.6.1-ef-signed.zip
mv ./su_files/system/bin/su ./rooting_files
mv ./su_files/system/app/Superuser.apk ./rooting_files
wait
rm -rf ./su_files
wait
cd ./rooting_files
patch < ../auto_pairing.conf.patch
wait
cd ..
echo "Complete : 1_download_files.sh"