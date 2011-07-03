#!/usr/bin/perl

use strict;
use warnings;

print "copying rooting files\n";
`cp ./rooting_files/main.conf ./system/etc/bluetooth/`;
`cp ./rooting_files/audio.conf ./system/etc/bluetooth/`;
`cp ./rooting_files/input.conf ./system/etc/bluetooth/`;
`cp ./rooting_files/auto_pairing.conf ./system/etc/bluetooth/`;
`cp ./rooting_files/dbus.conf ./system/etc/`;
unless (-e "./system/bin/su") {
    `cp ./rooting_files/su ./system/bin/`;
}
unless (-e "./system/app/Superuser.apk") {
    `cp ./rooting_files/Superuser.apk ./system/app`;
}

print "setting permissions\n";
chown "1002", "1002", "./system/etc/bluetooth";
chmod oct("0440"), "./system/etc/bluetooth";
chown "1002", "1002", "./system/etc/bluetooth/audio.conf";
chmod oct("0440"), "./system/etc/bluetooth/audio.conf";
chown "1000", "1000", "./system/etc/bluetooth/auto_pairing.conf";
chmod oct("0640"), "./system/etc/bluetooth/auto_pairing.conf";
chown "1002", "1002", "./system/etc/bluetooth/input.conf";
chmod oct("0440"), "./system/etc/bluetooth/input.conf";
chown "1002", "1002", "./system/etc/bluetooth/main.conf";
chmod oct("0440"), "./system/etc/bluetooth/main.conf";
chown "1002", "1002", "./system/etc/dbus.conf";
chmod oct("0440"), "./system/etc/dbus.conf";
chown "0", "0", "./system/app/Superuser.apk";
chmod oct("0644"), "./system/app/Superuser.apk";

my $result = `ls -l ./system/bin/su`;
wait;
if ($result !~ /^-rwsr-xr-x/ || $result !~ /\s+root\s+root/) {
    chown "0", "0", "./system/bin/su";
    chmod oct("4755"), "./system/bin/su";
}
$result = `ls -l ./system/bin/su`;
wait;
if ($result !~ /^-rwsr-xr-x/) {
    print "Please manually set permission by following command\n"
	. "# chmod 4755 ./system/bin/su\n"
	. "# chmod 6750 ./system/bin/run-as\n";
    exit(1);
}

print "packing_img\n";
my $cur_dir = `pwd`;
chomp($cur_dir);
my $system_dir = $cur_dir . "/system";
chdir "./ext4_utils" or die "error : $!";
wait;
`./mkuserimg.sh -s $system_dir ../factoryfs.img ext4 ./temp 612M`;
wait;
chdir ".." or die "error : $!";
wait;
print "packed files to ./factoryfs.img\n";
`rm -f ./adb_path`;
`rm -rf ./ext4_utils`;
print "Complete : 3_packing_img.pl\n";
