#!/bin/bash

if [ ! -d "video" ]
then
mkdir video 
fi

if [ ! -d "audio" ]
then
mkdir audio
fi

if [ ! -d "merged" ]
then
mkdir merged
fi

echo ============================================================
echo Welcome to the Maths Authoring Aid
echo ============================================================

function contToMenu(){
read -n 1 -s -r -p "Press any key to continue to menu:"
echo ""
menu
}

fontFilePath=/usr/share/fonts/truetype/freefont/FreeMonoBold.ttf

function numberOfCreations(){
creationNum=$(ls merged/*.mp4 2>/dev/null | wc -l)
}


function listCreations(){
ls -1 merged | nl | sed 's/....$//'
}


function list(){
numberOfCreations
if [ "$creationNum" -eq 0 ]
then
    echo "No creations available"
    contToMenu
elif [ "$creationNum" -eq 1 ]
then 
    echo There is 1 creation:
else
    echo There are $creationNum creations:
fi
listCreations
contToMenu
}


function delete(){
yn=""
numberOfCreations
if [ "$creationNum" -gt 0 ]
then
        listCreations
	echo -n "Enter a number to delete a creation:"
	read nthCreation
	if [ "$nthCreation" -ge 1 -a "$nthCreation" -le "$creationNum" &> /dev/null ]
	then
                delete=$(ls merged | sed -n ${nthCreation}p | sed 's/....$//')
		while [[ "$yn" != "y" && "$yn" != "n" ]]
		do    
                    echo -n Are you sure you want to delete "$delete"\? " "\(y/n\):
                    read yn
		
		done
		
		if [ "$yn" == "y" ]
		then 
                    rm video/"$delete.mp4"
                    rm audio/"$delete.wav"
                    rm merged/"$delete.mp4"
                    echo "$delete deleted"
                else
                    echo "$delete not deleted"
		fi
		
		yn=""
		while [[ "$yn" != "y" && "$yn" != "n" ]]
		do 
			echo -n Continue with delete\? " "\(y/n\):
			read yn
		done
	else	
		while [[ "$yn" != "y" && "$yn" != "n" ]]
		do 
                    echo -n \""$nthCreation"\" is not a valid number, try again\? \(y/n\) :
                    read yn
		done
	fi
	if [ "$yn" == "y" ]
	then
		yn=""
		delete
	else
		yn=""
		menu
	fi
else
	echo No creations are available to delete.
	contToMenu
fi
}

function quit(){
echo ......................exiting program.......................
	exit 0
}
 

function create(){ 
creation=""
while [[ "$creation" == "" ]]
do
        echo -n "Enter name for new creation : "
        read creation
done
y=""
if [ -a "merged/${creation}.mp4" ]
then
	while [[ "$yn" != "y" && "$yn" != "n" ]]
	do
            yn=""    
            echo -n "$creation" already exists, choose another name\?  \(y/n\):
	read "yn"
	done
else
        # create video
	ffmpeg -f lavfi -i color=c=white:s=320x240:d=3 -vf "drawtext=fontfile=${fontFilePath}:fontsize=30: fontcolor=black:x=(w-text_w)/2:y=(h-text_h)/2:text='$creation'" "video/${creation}.mp4" &> /dev/null
	
	echo You must record audio for the creation.

	keepOrRedo=""
	while [[ "$keepOrRedo" != k ]]
	do
		read -n 1 -s -r -p "Press any key to begin recording."
		echo -en '\n'Recording..........
		ffmpeg -f alsa -i hw:0 -t 3 -acodec pcm_s16le -ar 16000 -ac 1 -y "audio/${creation}.wav" &> /dev/null
		echo done
		read -n 1 -s -r -p "Press any key to listen to recording."
		echo -en '\n'Audio playing......
		ffplay -autoexit "audio/${creation}.wav" &> /dev/null
		echo done
		
		keepOrRedo=""
		while [[ "$keepOrRedo" != "k" && "$keepOrRedo" != "r" ]]
		do
                    echo -n Would you like to \(k\)eep or \(r\)edo the audio?:
                    read "keepOrRedo"
		done
                if [ "$keepOrRedo" == "r" ]
                then
                    rm "audio/${creation}.wav" &> /dev/null
                fi
	done
	
	#merge audio and video
	ffmpeg -i "video/${creation}.mp4" -i "audio/${creation}.wav" -c:v copy -c:a aac -strict experimental "merged/${creation}.mp4" &> /dev/null
	
	echo $creation created
	while [[ $yn != "y" && $yn != "n" ]]
	do
		echo -n Make another\?  \(y/n\):
	read yn
	done
fi
if [ "$yn" == "y" ]
then
	yn=""
	create
else
	yn=""
	menu
fi
}

function play(){
yn=""
numberOfCreations
if [ "$creationNum" -gt 0 ]
then
        listCreations
	echo -n "Enter a number to play a creation:"
	read nthCreation
	if [ "$nthCreation" -ge 1 -a "$nthCreation" -le "$creationNum" &> /dev/null ]
	then
                playVid=(merged/*.mp4)
                ffplay -autoexit "${playVid[$((nthCreation - 1))]}" &> /dev/null
		yn=""
		while [[ "$yn" != "y" && "$yn" != "n" ]]
		do 
			echo -n Play another\? " "\(y/n\):
			read yn
		done
	else	
		while [[ "$yn" != "y" && "$yn" != "n" ]]
		do 
                    echo -n \""$nthCreation"\" is not a valid number, try again\? \(y/n\) :
                    read yn
		done
	fi
	if [ "$yn" == "y" ]
	then
		yn=""
		play
	else
		yn=""
		menu
	fi
else
	echo No creations are available to play.
	contToMenu
fi
}

function menu() {
echo Please select from one of the following options:
echo '   ' \(l\)ist existing creations
echo '   ' \(p\)lay an existing creation
echo '   ' \(d\)elete an existing creation
echo '   ' \(c\)reate a new creation
echo '   ' \(q\)uit authoring tool
echo -n "Enter a selection [l/p/d/c/q] : "
read selection
		

if [ "$selection" == l ]
then 
	list
elif [ "$selection" == p ]
then 
	play
elif [ "$selection" == d ]
then
	delete
elif [ "$selection" == c ]
then 
	create
elif [ "$selection" == q ]
then
	quit
else
	echo ""
	echo Invalid selection, try again
	menu
fi

}

contToMenu
