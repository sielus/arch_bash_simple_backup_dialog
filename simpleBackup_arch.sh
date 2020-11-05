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
        selectBackuplocation 'Enter your backup location on your USB device' "${newArr[$val - 1]}"/backup/ 60
        rm -r ".data.txt" > /dev/null 2>&1
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
        selectBackuplocation 'Enter your server adress user@adres:/location' 'sielus@192.168.1.16:/mnt/c/Users/sielus/Desktop/testBackup/' 80
    elif [[ "$1" = "local" ]]; then
        selectBackuplocation 'Enter your backup location on your local-PC' '/home/sielus/testBackup/' 60
    elif [[ "$1" = "usb" ]]; then
        checkUsb 
    fi
}   

function selectDirectToBackUp () { 
    OUTPUT=".temp.txt"
    >$OUTPUT;
    dialog --clear --title "What you want to backup?" --checklist "Select:" 10 40 3 /mnt/c/Users/sielus/test1 "" "off" /mnt/c/Users/sielus/test2 "" "off" /mnt/c/Users/sielus/test3  "" "off" 2> $OUTPUT
    BUTTON=$?;
    if [ "$BUTTON" == 0 ];
    then
             rsync -a --progress $(<$OUTPUT) $1 > rsyncLog.txt
             if [ "$?" -eq "0" ]
                then
                    echo rsync -a --progress $(<$OUTPUT) $1 >> rsyncLog.txt
                    alertbox "Rsync" "Backup complete"
                    rm -r ".temp.txt" > /dev/null 2>&1
                    clear
                else
                    echo rsync -a --progress $(<$OUTPUT) $1 >> rsyncLog.txt
                    alertbox "Error while running rsync" "Error code: "$?
                    rm -r ".temp.txt" > /dev/null 2>&1
                    clear
                    mainMeno
                fi
             
    elif [ "BUTTON" == 1 ];
    then
            mainMeno

    else
            mainMeno

    fi
    
}

function mainMeno() {
    cmd=(dialog --keep-tite --backtitle "Sielanczyk_Jakub" --menu "Select options:" 10 30 5)
    options=(1 "Backup on server"
            2 "Backup on local disk"
            3 "Backup on usb")

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

        esac
    done
}

function checkRoot() {
    if [ "$EUID" -ne 0 ]
        then alertbox "Permisions alert!" "Please run as root"
        exit
    else
        mainMeno
    fi
}

checkRoot