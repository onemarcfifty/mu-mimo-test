#!/usr/bin/python3

# #############################################
# grbl_contrl.py
# reads in a gcode file and feeds it to an
# attached grbl controller running on an 
# Arduino
# #############################################
import argparse
import serial
import sys
import time

# Parse command line arguments
parser = argparse.ArgumentParser()
parser.add_argument('-f', '--filename', required=True, help='Name of G-code file')
parser.add_argument('-p', '--port', required=True, help='Serial port of Grbl Arduino')
args = parser.parse_args()

# Open serial port to connect to Grbl Arduino
try:
    ser = serial.Serial(args.port, 115200, timeout=1)
except serial.SerialException as e:
    print(f'Error: {e}')
    sys.exit(1)

# Open G-code file and read contents
try:
    with open(args.filename, 'r') as file:
        gcode = file.readlines()
except FileNotFoundError as e:
    print(f'Error: {e}')
    sys.exit(2)

for i in range(0,2):
    # GRBL will send initial lines
    response = ser.readline().decode().strip()
    print (f'**** {response}')

# Iterate through each line of G-code
for line in gcode:
    # Remove any whitespace and newline characters from the line
    line = line.strip()
    # If the line is not empty and does not start with a comment character (;), send it to the Arduino
    if line and not line.startswith(';'):
        # Add a newline character to the end of the line to signal the end of the command
        print (f'Sending Line: {line}')
        line += '\n'
        # Encode the line as bytes and send it to the Arduino
        ser.write(line.encode())
        # Wait for Grbl to respond with an "ok" status code
        while True:
            response = ser.readline().decode().strip()
            print (f'**** {response}')
            if response == 'ok':
                while True:
                    ser.write('?'.encode())
                    response = ser.readline().decode().strip()
                    if ('Run' in response):
                        print (f'{response}',end="\r")
                        time.sleep(1)
                    else:
                        print (f'{response}')
                        break         
                break
            elif response.startswith('error:'):
                # Handle any errors from Grbl
                print(f'Error from Grbl: {response}')
                ser.close()
                sys.exit(3)
# Close the serial port
ser.close()
sys.exit(0)
