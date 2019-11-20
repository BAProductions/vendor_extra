# Vendor Extra

1.  ***Q:** "Is Vendor Extra a replacement learn the various command for building Android rom, Debubuging & working devices etc.?"*

    ***A:** "Well no not relly."*

2. ***Q:** "What is vendor_extra?"*

   ***A:** "really Vendor Extra is a tool with useful command to speed up your build process & is in no way a replacement learn the various command for building Android rom, Debubuging & working devices etc, witch highly recommend you learn anyways."*
 
 3.  ***Q:** "What does vendor_extra allow to do?"*

	   ***A:** "Well I'm glad you asked, vendor_extra if a repo that Contains useful command for pulling logs dmesg & kmsg, Making a full build, making bootimage,
systemimage, recoveryimage & kernel plus taking screenshot & fixing
sepolicy error etc."*

4.  ***Q:** "Why are the benefits of using vendor_extra? in your device tree"*

    ***A:** "The benefits of using a vendor_extra in your device tree being able apply patch a rom to make work with your devices witch out having to fork or maintain the repo at all & allow you developer to add useful commands to speed your build process."*

5.  ***Q:** "That can you do with base version vendor_extra"*

    ***A:** "Well simple you add you'er devices room service files & use as it or fork and ajust it to fit your needs, devices & you'er build process."*

5.  ***Q:** "Where do I add in my roomseves files?"*

    ***A:** "Well simple at the end of the file before the closing <\/manifest>."*
    
    ### Code
    ~~~
    <!-- Lineage Depdence For All Samsung Devices  -->
    <project name="BAProductions/vendor_extra" path="vendor/extra" remote="github" revision="lineage-16.0"/>
    ~~~
  
# List Of Command Built Into  The Tool 
INIT
--------------------------------
| # | Commend |  Description |
|--|--|--|
|| init | Run this commit once to make the debug folder |

repo sync
--------------------------------
| # | Commend |  Description |
|--|--|--|
|| rs | Trigger sync repo |

Common Build Commands
--------------------------------
| # | Commend |  Description |
|--|--|--|
|| mb | Make flashable zip |
|| msi | build new system image & flashable zip |
|| mbi | build new bootimage |
|| mri | build new recoveryimage |
|| mk | build new kernel |
|| mop | Make flashable OTA zip |

Debug Commands
--------------------------------
| # | Commend |  Description |
|--|--|--|
|| tlc | Displays logcat |
|| tlcf | Reboot the device & writes locgat output to a .log file with timestamp & boot infomation |
|| rkmsg | Displays kmsg |
|| rkmsgf | Reboot the device & writes kmsg output to a .log file with timestamp & boot infomation |
|| rdmesg | Displays dmesg |
|| rdmesgf | Reboot the device & writes dmesg output to a .log file with timestamp & boot infomation |
|| dw | Disable WiFi (run if device reboot after connecting to Wifi network) |
|| ew | Enable WiFi |
|| rdmesgf | Reboot the device & writes dmesg output to a .log file with timestamp & boot infomation |

Sepolicy Commands
--------------------------------
| # | Commend |  Description |
|--|--|--|
|| fsep | Useful fo fixing sepolicy denials |

Other Commands
--------------------------------
| # | Commend |  Discriptoon |
|--|--|--|
|| tss | Allow you to take screenshots fo the rom with timestamp just incase you want upload them to XDA or alaskalinuxuser wants too see what camera error is a UI lavel |
|| rb | Reboots your device |
|| rbir | Reboots your device tnto recovery mode |
|| rbid | Reboots your device tnto downloade mode/fastboot mode & Odin mode for all Samsung devices |


Most of the file have been taking form [sub77](https://github.com/sub77/)  & rewitten for my needs
