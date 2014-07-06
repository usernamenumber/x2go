x2go
====

##################################################################################
# Procedure for Installing the EDX Platform on Cubietruck Using a Booting SD Card
##################################################################################

On a Linux or Ubuntu machine connected to the Internet and which have access
to a SD card Slot (You can also access a SD card through a USB):

- Put the contents of the EDX Platform Installation files for Cubietruck on an empty folder.

- Change the current directory to this folder.

- Insert an empty SD card on the corresponding slot.

- Replacing ${card} with the SD card device you are using (eg. /dev/sdc, please be sure of this
  before proceeding, so not damage happens), run:
  
      python execute sd ${card}

- When finished, it will be safe to take out the SD card, and it will contain Lubuntu (as specified
  on the Cubietruck web site) and the EDX installation files for Cubietruck, I created, on the
  folder  "/home/linaro/EDX"

- Insert the created SD card on the Cubietruck SD card slot, turn on the Cubietruck,
  and Lubuntu will load.

- Change directory and run the first part of the script ("update" file).
  Note: The initial installation of Lubuntu on Cubietruck has Python3
  
      cd /home/linaro/EDX
      python3 execute update

- When finished Cubietruck will reboot, so change directory and run the second part of the script
  which consists of the EDX installation previous steps ("edxPRE") and the main one ("edx").
  You can see the files "edxPRE" and "edx" for better understanding.
  
      cd /home/linaro/EDX
      python3 execute edxPRE edx

- At this point the installation will fail when running "edx", trying to make sure NGINX is started.
  A reboot will fix this, so reboot and re-run "edx".
  
      sudo reboot
      cd /home/linaro/EDX
      python3 execute edx

- At this point, one more failure will hapend when the installation runs "apparmor_parser" on the
  "loading code sandbox profile" task, because of an issue with warnings. My fix for this is
  explained in the file "apparmorFIX" which has to be run next. You also have to re-run the
  unfinished "edx".
  
      sudo reboot
      cd /home/linaro/EDX
      python3 execute apparmorFIX edx

- At this point, the EDX Installation will complete successfully here, but because of continous
  development, new issues may appear. In this case, the only thing left to do is for now: rebooting
  and trying to run "edx" again. Similarly, you can do this after cancelling the running of "edx", if
  it delays too long in a specific task (which normaly runs faster) as if it appears to never finish.
  That happened to me some times at different points, maybe becuause of a bad internet connection,
  not too sure.
