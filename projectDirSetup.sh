#!/bin/bash

#List of subdirectories to be created and possibly copied from
ARRAY=(bin data scripts log adapters data/seqs_raw)

#Check if name argument for the main project directory is given
if [ -z $1 ]
   then
	echo "please specify a name for your project folder."
	exit 0

elif [ -d $1 ]
   then
     echo "This directory name is being used by another directory. Please choose a different name."
     exit 0

else



projectName="$1"
mkdir "$projectName" 


#Create new subdirectories

echo "Creating project directory, $projectName"

for i in ${ARRAY[@]}; do
   
  if [ ! -d $1/$i ]
     then

       mkdir "$projectName/$i"

  fi

done


#Clone from another directory

if [ ! -z $2 ]
   then
    for e in ${ARRAY[@]}; do
      	
	
	echo "Cloning from $2/$e"
	cp -r "$2/$e/"* "$1/$e/" 2>/dev/null
		
    done
fi
fi
