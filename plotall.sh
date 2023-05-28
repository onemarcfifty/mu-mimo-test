#!/bin/bash

function plotB() {
    for TestBSubDir in RouterTests/*/TestB* ; do 
        gnuplot -c tools/gnuplot_TestB.gp "$TestBSubDir"
    done
}

function plotC() {
# Plots for Test C (Wifi Burst)
# We want one plot for each Client and then a combined plot
for TestCSubDir in RouterTests/*/TestC* ; do 
    FileList=()
    for LogFile in ${TestCSubDir}/*.log ; do
        echo $LogFile
        FileList+=("$LogFile.txt")
        cat $LogFile | awk '/MBytes/ && !/sender|receiver/ {print NR-1, $7}' >$LogFile.txt
        gnuplot -c tools/gnuplot_TestC.gp $LogFile.txt
    done
    FileList+=("${TestCSubDir}/plot_all.png")
    gnuplot -c tools/gnuplot_TestC.gp "${FileList[@]}"
done
}

function plotD() {
# Plots for Test D (MU MIMO)
# We want one plot for each of the three tests

for TestDSubDir in RouterTests/*/TestD* ; do 
    echo $TestDSubDir
    # first we need to extract the plotable data from the client iperf logs
    for i in 1 2 3 ; do 
        mkdir -p $TestDSubDir/plot$i
        rm "$TestDSubDir/plot$i/plot-5201.txt"
        rm "$TestDSubDir/plot$i/plot-5202.txt"
        rm "$TestDSubDir/plot$i/plot-5203.txt"
        rm "$TestDSubDir/plot$i/plot-5204.txt"
    done
    # every "Block" starts and ends with "[ ID]"
    toggle_line="[ ID]"
    # we have four distinct log file groups, one for each port
    for port in 5201 5202 5203 5204 ; do
      inside_range=0
      counter=0
      echo "${TestDSubDir}/results-mimo-client-${port}-wifi56-TCP.log"
      # let's read in the file
      while IFS= read -r line; do
        # if we read in toggle semaphore we switch inside range true/false
        # and increase the counter
        if [[ $line == "$toggle_line"* ]]; then
            ((inside_range=!$inside_range))
            # we get back in range - increase counter
            if [ "$inside_range" == 1 ] ; then 
                # we increase the counter for each new block
                ((counter+=1))
                # for port 5204 we increase the counter by 2
                # as it was not included in the second test
                if [[ "$port" == "5204" && "$counter" == 2 ]] ; then ((counter+=1)) ; fi
                output_file="${TestDSubDir}/plot${counter}/plot-${port}.txt"
                echo "$output_file"
                touch "$output_file"
                truncate -s 0 "$output_file"
                line_number=0
                if [[ "$port" == "5202" && "$counter" != 2 ]] ; then line_number=15 ; fi
                if [[ "$port" == "5203" && "$counter" != 2 ]] ; then line_number=31 ; fi
                if [[ "$port" == "5204" && "$counter" != 2 ]] ; then line_number=75 ; fi
            fi
        # if we read in a "normal" line, then we write it into the plot file
        else
            # but only if we are inside the range
            if [ "$inside_range" == 1 ] ; then
                ((line_number+=1))
                result=$(awk '/MBytes/ && !/sender|receiver/ {print $7}' < <(echo "$line")) 
                #echo $result
                echo "$line_number $result" >> "$output_file"
            fi
        fi
      done < "${TestDSubDir}/results-mimo-client-${port}-wifi56-TCP.log"
    done
    gnuplot -c tools/gnuplot_TestD.gp "${TestDSubDir}"
done
}

format_counter() {
    printf "%03d" "$1"  # 3 specifies the minimum width, adjust as needed
}

function prepareE() {
# Plots for Test E (MU MIMO)
# We want one plot for each of the four tests
for TestESubDir in RouterTests/*/TestE* ; do 
    echo $TestESubDir
    # first we need to extract the plotable data from the client iperf logs
    for i in 1 2 3 4; do 
        mkdir -p $TestESubDir/plot$i
        rm "$TestESubDir/plot$i/plot-5201.txt"
        rm "$TestESubDir/plot$i/plot-5202.txt"
        rm "$TestESubDir/plot$i/plot-5203.txt"
    done
    rm $TestESubDir/plot*.png
    # every "Block" starts and ends with "[ ID]"
    toggle_line="[ ID]"
    # we have four distinct log file groups, one for each port
    for port in 5201 5202 5203 ; do
      inside_range=0
      counter=0
      # let's read in the file from th last test which contains all blocks
      while IFS= read -r line; do
        # if we read in toggle semaphore we switch inside range true/false
        # and increase the counter
        if [[ $line == "$toggle_line"* ]]; then
            ((inside_range=!$inside_range))
            # we get back in range - increase counter
            if [ "$inside_range" == 1 ] ; then 
                # we increase the counter for each new block
                ((counter+=1))

                output_file="${TestESubDir}/plot${counter}/plot-${port}.txt"
                echo "$output_file"
                touch "$output_file"
                truncate -s 0 "$output_file"
                line_number=0
                # the first two test had been time-shifted
                if [[ "$port" == "5202" && "$counter" < 3 ]] ; then line_number=20 ; fi
                if [[ "$port" == "5203" && "$counter" < 3 ]] ; then line_number=40 ; fi
            fi
        # if we read in a "normal" line, then we write it into the plot file
        else
            # but only if we are inside the range
            if [ "$inside_range" == 1 ] ; then
                ((line_number+=1))
                result=$(awk '/MBytes/ && !/sender|receiver/ {print $7}' < <(echo "$line")) 
                #echo $result
                formatted_line_number=$(format_counter "$line_number")
                echo "$formatted_line_number $result" >> "$output_file"
            fi
        fi
      done < "${TestESubDir}/moving.tcp/results-${port}.log"
    done
    for i in 1 2 3 4; do 
        join -a 1 -a 2 -e 0 -o 0,1.2,2.2 \
        "${TestESubDir}/plot${i}/plot-5201.txt" \
        "${TestESubDir}/plot${i}/plot-5202.txt" \
        | join -a 1 -a 2 -e 0 -o 0,1.2,1.3,2.2 - \
        "${TestESubDir}/plot${i}/plot-5203.txt" \
        >"${TestESubDir}/plot${i}/join.txt"
    done
done
}

function plotE() {
for TestESubDir in RouterTests/*/TestE* ; do 
    echo $TestESubDir
    if [[ $TestESubDir == *"OWRT"* ]]; then
        TestESubDir2="${TestESubDir//OWRT/STOCK}"
    else
        TestESubDir2="${TestESubDir//STOCK/OWRT}"
    fi    
    echo $TestESubDir2
    gnuplot -c tools/gnuplot_TestE.gp "${TestESubDir}" "${TestESubDir2}"
done
}

#plotB
#plotC
#plotD
prepareE
plotE


