#!/usr/bin/perl

use strict;
use warnings;
use File::Basename;

my $reset_flag = 0;
if (@ARGV == 1 && $ARGV[0] eq "reset_permission") {
    $reset_flag = 1;
}

my $adb_path_file = "./adb_path";
my $adb_fh;
open $adb_fh, "<", $adb_path_file or die "$adb_path_file:$!";
my $adb_path;
if ($adb_path = <$adb_fh>) {
    chomp($adb_path);
    unless (-e $adb_path) {
	die "$adb_path : not found\n";
    }
} else {
    die "can't read $adb_path_file\n";
}
close $adb_fh;

my %userid_hash = (
    "root" => 0,
    "system" => 1000,
    "radio" => 1001,
    "bluetooth" => 1002,
    "graphics" => 1003,
    "input" => 1004,
    "audio" => 1005,
    "camera" => 1006,
    "log" => 1007,
    "compass" => 1008,
    "mount" => 1009,
    "wifi" => 1010,
    "adb" => 1011,
    "install" => 1012,
    "media" => 1013,
    "dhcp" => 1014,
    "sdcard_rw" => 1015,
    "vpn" => 1016,
    "keystore" => 1017,
    "usb" => 1018,
    "drm" => 1019,
    "drmio" => 1020,
    "gps" => 1021,
    "unused1" => 1022,
    "rfu1" => 1023,
    "rfu2" => 1024,
    "nfc" => 1025,
    "shell" => 2000,
    "cache" => 2001,
    "diag" => 2002,
    "net_bt_admin" => 3001,
    "net_bt" => 3002,
    "inet" => 3003,
    "net_raw" => 3004,
    "net_admin" => 3005,
    "misc" => 9998,
    "nobody" => 9999,
    "app" => 10000
);

my $exec_dir = `pwd`;
chomp($exec_dir);

my $file_infos;
get_permissions("/system", \$file_infos);

print "\n";

foreach my $file_info (@{$file_infos->{"d"}}) {
    unless (-e $file_info->{"filepath"}) {
	print "creating directory : " . $file_info->{"filepath"} . "\n";
	`mkdir -p $file_info->{"filepath"}`;
    }
    print "setting permission, userid, groupid: " . $file_info->{"filepath"} . "\n\n";
    set_permission_and_ugid($file_info);
}
foreach my $file_info (@{$file_infos->{"r"}}) {
    unless ($reset_flag) {
	print "pulling file : " . $file_info->{"android_filepath"} . "\n";
	pull_file($file_info);
	wait;
    }
    print "setting permission, userid, groupid: " . $file_info->{"filepath"} . "\n\n";
    set_permission_and_ugid($file_info);
}
foreach my $file_info (@{$file_infos->{"l"}}) {
    unless ($reset_flag) {
	print "making symlink : " . $file_info->{"filepath"} . "\n";
	make_symlink($file_info);
    }
}

if ($reset_flag) {
    print "Complete : 2.5_reset_permissions.pl\n";
} else {
    print "Complete : 2_pull_system_files.pl\n";
}

sub get_permissions {
    my ($cur_dir, $file_infos_ref) = @_;
    
    my $cur_dir_permission = `$adb_path shell ls -l -d $cur_dir`;
    my $file_info = get_file_info($cur_dir_permission, $cur_dir);
    push(@{$$file_infos_ref->{$file_info->{"filetype"}}}, $file_info);
    
    my @file_list = `$adb_path shell ls -l $cur_dir`;
    foreach my $line (@file_list) {
	chomp($line);
	$line =~ /\d\d:\d\d\s+(\S+)/;
	my $filename = $1;
	if ($line =~ /^d/) {
	    get_permissions($cur_dir . "/" . $filename, $file_infos_ref);
	} else {
	    $file_info = get_file_info($line, $cur_dir . "/" . $filename);
	    push(@{$$file_infos_ref->{$file_info->{"filetype"}}}, $file_info);
	}
    }
}

sub set_permission_and_ugid {
    my $file_info = shift;
    chdir $file_info->{"dirname"} or die "error : $!";
    chown $file_info->{"userid"}, $file_info->{"groupid"}, $file_info->{"basename"};
    chmod oct($file_info->{"permission"}), $file_info->{"basename"};
}

sub make_symlink {
    my $file_info = shift;
    chdir $file_info->{"dirname"} or die "error : $!";
    system("ln -sf " . $file_info->{"sym_dest_file"} . " " . $file_info->{"basename"});
}

sub pull_file {
    my $file_info = shift;
    system("$adb_path pull " . $file_info->{"android_filepath"} . " " . $file_info->{"filepath"});
}

sub get_file_info {
    my ($permission_str, $filepath) = @_;

    print "getting permission, userid , groupid : $filepath\n";
    
    $permission_str =~ /(\S+)\s+(\S+)\s+(\S+)\s+(.+)/;
    my $permission = $1;
    my $user = $2;
    while (my ($android_user, $android_id) = each(%userid_hash)) {
	if ($user eq $android_user) {$user = $android_id}
    }
    my $group = $3;
    while (my ($android_user, $android_id) = each(%userid_hash)) {
	if ($group eq $android_user) {$group = $android_id}
    }
    my $others = $4;
    
    $permission =~ /(.)(.)(.)(.)(.)(.)(.)(.)(.)(.)/;
    my $is_symlink = 0;
    my $is_dir = 0;
    if ($1 eq 'l') {
	$is_symlink = 1;

    } elsif ($1 eq 'd') {
	$is_dir = 1;
    }
    my $sym_dest_file;
    if ($is_symlink) {
	$others =~ /->\s+(\S+)/;
	$sym_dest_file = $1;
    }
    my ($set_ug_num, $u_num, $g_num, $o_num) = (0, 0, 0, 0);
    if ($2 eq 'r') {$u_num += 4}
    if ($3 eq 'w') {$u_num += 2}
    if ($4 eq 'x') {$u_num += 1}
    elsif ($4 eq 's') {
	$set_ug_num += 4;
	$u_num += 1;
    }
    if ($5 eq 'r') {$g_num += 4}
    if ($6 eq 'w') {$g_num += 2}
    if ($7 eq 'x') {$g_num += 1}
    elsif ($4 eq 's') {
	$set_ug_num += 2;
	$g_num += 1;
    }
    if ($8 eq 'r') {$o_num += 4}
    if ($9 eq 'w') {$o_num += 2}
    if ($10 eq 'x') {$o_num += 1}
    my $permission_num =  $set_ug_num . $u_num . $g_num . $o_num;

    my $file_info;
    $file_info->{"android_filepath"} = $filepath;
    $file_info->{"filepath"} = $exec_dir . $filepath;
    $file_info->{"basename"} = basename($filepath);
    $file_info->{"dirname"} = dirname($file_info->{"filepath"});
    $file_info->{"permission"} = $permission_num;
    $file_info->{"userid"} = $user;
    $file_info->{"groupid"} = $group;
    if ($is_symlink) {
	$file_info->{"filetype"} = "l";
	$file_info->{"sym_dest_file"} = $sym_dest_file;
    } elsif ($is_dir) {
	$file_info->{"filetype"} = "d";
    } else {
	$file_info->{"filetype"} = "r";
    }
    
    return $file_info;
}
