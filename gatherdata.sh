#!/bin/bash


filename=""             # Servers list for gathering infomation
serverip=""             # IDM server ip or FQDN
usage() {
    echo "Usage: $0 [ -f serverlist ] [ -s IDMserver]" 1>&2
}
exit_abnormal() {   # Function: Exit with error.
    usage
    exit 1
}



while getopts f:s: flag
do
    case "${flag}" in
        f) filename=${OPTARG};;
        s) serverip=${OPTARG};;
    esac
done


IDMserver=$serverip

for i in `cat $filename`
do
    # test local dir exist in bastion host
    data=data
    [ ! -d "$data/$i" ] 
        mkdir $data/$i
        mkdir $data/$i/sudoers.d/
        mkdir $data/$i/sssd/conf.d/
        mkdir $data/$i/sssd/pki
        
        # collect port info from remote server and dump to bastion host
        # list of ports for IDM https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/linux_domain_identity_authentication_and_policy_guide/ports
        declare -a ports=("636" "389" "88" "443" "8443")
        for port in ${ports[@]}
            do
            ssh -o "BatchMode=yes" root@$i "nc -zv -w 5 $IDMserver $port" 2>&1 | tee -a $data/$i/ports.out
        done
        
        
        scp root@$i:/etc/sudoers.d/* $data/$i/sudoers.d/
        scp root@$i:/etc/sssd/conf.d/ $data/$i/sssd/
        scp root@$i:/etc/sssd/pki/ $data/$i/sssd/pki/
        ssh -o "BatchMode=yes" root@$i "cat /etc/passwd" > $data/$i/passwd.out
        ssh -o "BatchMode=yes" root@$i "cat /etc/group" > $data/$i/group.out
        ssh -o "BatchMode=yes" root@$i "cat /etc/resolv.conf" > $data/$i/resolv.out
        ssh -o "BatchMode=yes" root@$i "/etc/nsswitch.conf" > $data/$i/nsswitch.out
        ssh -o "BatchMode=yes" root@$i yum list available idm 2>&1 | tee -a $data/$i/packages.out


done