#Script tested on Arch linux



function alertbox () {
    whiptail --title "$1" --msgbox "$2! Click OK to continue!" 8 78
}

function selectBackuplocation () { 
    OUTPUT=".temp.txt"
    >$OUTPUT;
    dialog --clear --title "Backup location" --inputbox "$1" 10 $3 "$2" 2> $OUTPUT

    BUTTON=$?;
    if [ "$BUTTON" == 0 ];
        then
            selectDirectToBackUp $(<$OUTPUT)
            rm -r ".temp.txt" > /dev/null 2>&1
    elif [ "BUTTON" == 1 ];
        then
            rm -r ".temp.txt" > /dev/null 2>&1
            mainMeno 
    else
        rm -r ".temp.txt" > /dev/null 2>&1
        mainMeno
    fi
}

function selectRestoreBackuplocation () { 
    OUTPUT=".temp.txt"
    >$OUTPUT;
    dialog --clear --title "Choose path to save restored files" --inputbox "Default path: /home/$USER/restoredFromBackup" 10 $3 "$2" 2> $OUTPUT

    BUTTON=$?;
    if [ "$BUTTON" == 0 ];
        then
            selectRestoreLocation $(<$OUTPUT)
            rm -r ".temp.txt" > /dev/null 2>&1
    elif [ "BUTTON" == 1 ];
        then
            rm -r ".temp.txt" > /dev/null 2>&1
            mainMeno 
    else
        rm -r ".temp.txt" > /dev/null 2>&1
        mainMeno
    fi
}

function selectRestoreLocation () { 
    OUTPUT=".temp.txt"
    >$OUTPUT;
    dialog --clear --title "Choose path to backup" --inputbox "Backup whill be restored to:$1" 10 $3 "$2" 2> $OUTPUT

    BUTTON=$?;
    if [ "$BUTTON" == 0 ];
        then
            echo rsync -av --progress $(<$OUTPUT) $1 > restoreLog.txt
            rsync -av --progress $(<$OUTPUT) $1 
            rsync -av --progress $(<$OUTPUT) $1 >> restoreLog.txt
            

            path=$1 
           #path="${path}/*"
            echo "Verifying the integrity of a files"

            diff -qr $(<$OUTPUT) $path 
            diff -qr $(<$OUTPUT) $path >> restoreLog.txt  
            echo "Restoring complete"


            rm -r ".temp.txt" > /dev/null 2>&1
    elif [ "BUTTON" == 1 ];
        then
            rm -r ".temp.txt" > /dev/null 2>&1
            mainMeno 
    else
        rm -r ".temp.txt" > /dev/null 2>&1
        mainMeno
    fi
}

function checkUsb () {
    rm -r ".data.txt" > /dev/null 2>&1

       #lsblk -o MOUNTPOINT,NAME | grep sdb | sed s/"sdb"// | sed s/"-1"// | sed s/'`'//  > 'test.txt'

    for letter in {b..z} ; do
         lsblk -o MOUNTPOINT,NAME | grep "sd$letter" | sed s/"sd$letter"// | sed s/"-1"// | sed s/'`'// >> '.data.txt'
    done

    # lsblk -o MOUNTPOINT,NAME | grep sdb | sed s/"sdb"// | sed s/"-1"// | sed s/'`'//  > 'test.txt'
    # lsblk -o MOUNTPOINT,NAME | grep sdc | sed s/"sdc"// | sed s/"-1"// | sed s/'`'//  >> 'test.txt'
    # lsblk -o MOUNTPOINT,NAME | grep sdd | sed s/"sdd"// | sed s/"-1"// | sed s/'`'//  >> 'test.txt'
    
    #sed -i '1d' test.txt
    
    input=".data.txt"
    declare -a arr=()
    let i=0

    if [ -s .data.txt ] 
        then  
            filename=".data.txt"
            while read -r line; do

                if [ "$line" != "" ];   
                then 
                    let i=$i+1
                
                    arr+=( $i $line )
                fi

        done < "$filename"

        val=$(dialog --title "List of USB devices" --menu "Chose your USB target" 24 80 17 "${arr[@]}" 3>&2 2>&1 1>&3) # show dialog and store output
        clear
        val=$val

        declare -a newArr=()

        for i in "${arr[@]}"
            do
                re='^[0-9]+$'
                if  ! [[ $i =~ $re ]] ; then
                newArr+=( $i )
                fi
            done
        #echo  "${newArr[$val - 1]}"



        if [ -z "$val" ]
            then
                mainMeno
                rm -r ".data.txt" > /dev/null 2>&1
            else
                selectBackuplocation 'Enter your backup location on your USB device' "${newArr[$val - 1]}"/backup/ 60
                rm -r ".data.txt" > /dev/null 2>&1
        fi

       # selectBackuplocation 'Enter your backup location on your USB device' "${newArr[$val - 1]}"/backup/ 60
    else
        alertbox "USB devices error" "No USB devices"
        rm -r ".data.txt" > /dev/null 2>&1
        mainMeno
    fi

# while IFS= read -r line
# do
#   echo "$line"
# done < "$input"
}

backupType (){ 
    if [[ "$1" = "server" ]]; then
        selectBackuplocation 'Enter your server adress user@adres:/location' 'user@192.168.1.16:/path/backup/' 80
    elif [[ "$1" = "local" ]]; then
        selectBackuplocation 'Enter your backup location on your local-PC' '/home/'$USER'/backup/' 60
    elif [[ "$1" = "usb" ]]; then
        checkUsb 
    fi
}   

function selectDirectToBackUp () { 
    OUTPUT=".temp.txt"
    >$OUTPUT;
    dialog --clear --title "What you want to backup?" --checklist "Select:" 10 40 3 /home/$USER/test1 "" "off" /home/$USER/test2 "" "off" /home/$USER/test3 "" "off" 2> $OUTPUT
    BUTTON=$?;
    if [ "$BUTTON" == 0 ];
    then
             clear
             rsync -av --progress $(<$OUTPUT) $1 
             if [ "$?" -eq "0" ]
                then
                    echo rsync -av --progress $(<$OUTPUT) $1 > rsyncLog.txt

                    echo "Verifying the integrity of a files"
                    echo rsync --dry-run --checksum --itemize-changes $(<$OUTPUT) $1 > rsyncLog.txt
                    rsync --dry-run --checksum --itemize-changes $(<$OUTPUT) $1 

                    alertbox "Rsync" "Backup complete"
                    echo "Backup complete"
                    # for file in $1*; do
                    #     diff "$file" "$(<$OUTPUT)"
                    #     echo $file
                    # done
                    #echo diff -qr $(<$OUTPUT) $path 

                    rm -r ".temp.txt" > /dev/null 2>&1
                    #clear
                else
                    echo rsync -av --progress $(<$OUTPUT) $1 > rsyncLog.txt
                    alertbox "Error while running rsync" "Error code: "$?
                    rm -r ".temp.txt" > /dev/null 2>&1
                    #clear
                    mainMeno
                fi
             
    elif [ "BUTTON" == 1 ];
    then
            mainMeno

    else
            mainMeno

    fi
    
}


function showHelp() {
    dialog --backtitle "Script tested and used on Arch linux" \
    --title "Help" \
    --msgbox 'Author : Jakub Sielanczyk \nIf you want backup on server chose option "Backup on server" and write correct path with  your server ip addres on start. Something like '$USER'@xxx.xxx.xxx.xxx:/path. On next step select some files to backup.
    \nIf you want backup on local drive or USB device, chose correct option. Option with USB worked fine on Arch Linux... but on debian or ubuntu 5:5' 15 70
    BUTTON=$?;
    if [ "$BUTTON" == 0 ];
        then
            clear
            mainMeno
    fi
}

function mainMeno() {
    cmd=(dialog --keep-tite --backtitle "Sielanczyk_Jakub" --menu "Select options:" 12 30 5)
    options=(1 "Backup on server"
            2 "Backup on local disk"
            3 "Backup on usb"
            4 "Restore backup"
            5 "Help")

    choices=$("${cmd[@]}" "${options[@]}" 2>&1 >/dev/tty)

    for choice in $choices
    
    do
        case $choice in
            1)
                backupType 'server'
                ;;
            2)
                backupType 'local'
                ;;

            3)
                backupType 'usb'
                ;;
            
            4)
                selectRestoreBackuplocation 
                ;;
                           
            5)
                showHelp
                ;;

        esac
    done
}

function checkRoot() {
    if [ "$EUID" -ne 0 ]
        then alertbox "Permisions alert!" "Please run as root"
        exit
    else
        checkInstaller
    fi
}

function checkInstaller() {
    apt=`command -v apt-get`
    pacman=`command -v pacman`

    if [ -n "$apt" ]; then
        if ! which dialog > /dev/null; 
            then
                read -p "Install package Dialog? (y/n): " request
                    if [ "$request" == 'y' ]
                        then
                            apt-get install dialog --yes
                    fi
        fi
        mainMeno
    elif [ -n "$pacman" ]; 
        then
            pacman -Syy dialog
            mainMeno
    else
        echo "Err: no path to apt-get or pacman. Make sure you have installed dialog" >&2;
        exit 1;
    fi
}

checkRoot
