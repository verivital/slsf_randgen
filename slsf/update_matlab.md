# Updating Matlab in the VM

The VM has R2015a version of Matlab. If you want to use a newer version (e.g. R2017a), use the following steps.

Terminologies: *Guest machine/OS* means the Ubuntu operating system running in the VM.

## Unzip newer Matlab

Unzip to get a `.vmdk` image of the newer Matlab

## Install the VM image in VMware

 - Shut down the Ubuntu guest operating system. Then go to VMware Workstation Player, select the VM, and 
click "Edit virtual machine settings" [screenshot](https://www.dropbox.com/s/a0muq3zjd2qdnoa/1.PNG?dl=0) . 
 - In the Hardware section, click "Add" [screenshot](https://www.dropbox.com/s/uhahbom0x0jveii/2.PNG?dl=0)
 - Select "Hard Disc" and click "next" [screenshot](https://www.dropbox.com/s/g4cmtt92y38yza5/3.PNG?dl=0)
 - Select SCSI
 - Select "Use an existing virtual disk"
 - Browse the `.vmdk` file
 - Click Finish/Ok.

## Configure host machine to use the new Matlab

Open terminal and enter following commands:

    sudo su # Will ask for password
    mkdir /media/mlnew
    echo "/dev/sdb /media/mlnew auto auto,user,exec 0 0" >> /etc/fstab
    exit

Next:

- Make sure you entered exit so that you are no logner superuser.
- Open `~/.zshrc` file in some text editor (e.g. `gedit ~/.zshrc`)

Then, Comment-out this line: (i.e. by putting `#` before it)

    # export PATH=$PATH:/$CSMITH_PATH/src:/home/cyfuzz/installations/matlab/bin

Enter this line:

    export PATH=$PATH:/$CSMITH_PATH/src:/media/mlnew/r2017a/bin

In the line above, use the correct version. E.g., I'm using r2017a so this line works for me.

## Restart the guest machine.

 - After restarting, if you type `matlab &` in a terminal, it should ask you to log in. 
