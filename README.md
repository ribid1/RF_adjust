# RF_adjust
Voice output in Jeti transmitter of Rotorflight Governor state and Rotorflight adjustments  

# Installation:      
Copy the file "RF_adjust.lua" and the folder "Rotorflight" in the "/Apps/" folder of the transmitter   

If you are using a different language than Englisch or German, you have to create new folders in the "/Rotorflight" Directory with the corresponding ending like "_cz", "_fr", "_pt".
There you put your files, but make sure the filename is the same than the englisch ones.  
If you are just using one language you will need just the "adjfunc_" and the "governor_" folder, if you are using more languages you have to copy all folders which you are using.

# Configuration:
![Configuration](help/Configuration.png)  
If voice output always should be one you can also use the logical switch "Log.MAX", than you can spare a switch.

![Optinal Configuration](help/Optional-config.png)  
If you are just using the voice output or the telemetry screen you can ignore the settings of the PID-Profile or the Rate-Profile, but I would recommend it.
Because the app will store every changed function value depending on the active PID-Profile or Rate-Profile in a Global lua Table called "Global_adjTable", and after you shut down the receiver it will convert the table in a json file and save it in the /models folder. Be sure you shut down the rx before the tx!
Of course if you change some settings in the rotorflight app, the json file will not be up to date.

# Telemetry window:
![Telemetry window](help/Telemetrie-screen.png)  
You get two telemtry windows, one for the governor and one for the RF-adjustments

# Example how to setup the Jeti Transmitter:


# Example how to setup Rotorflight:



