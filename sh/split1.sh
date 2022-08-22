#!/bin/bash

#Define the string value
text="Welcome to LinuxHint"

# Set space as the delimiter
IFS=' '

#Read the split words into an array based on space delimiter
read -a strarr <<< "$text"

#Count the total words
echo "There are ${#strarr[*]} words in the text."

# Print each value of the array by using the loop
for val in "${strarr[@]}";
do
  printf "$val\n"
done
