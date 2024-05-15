# Powershell-Racer
Discover optimal PowerShell techniques in this repository! Compare and test various tasks, from file handling to data manipulation, to find the most efficient solutions for your needs.

its just read-first-line for now.. more will come! 
if you have suggestions or code changes please do a pr or create an issue. 

how to run:
just start race.ps1 all the parameters are set to default:
create a file of 200 MB at env:temp/testfile, run 15000 laps. measurement in ticks
```powershell
HELP: race.ps1 [[-FileName] <string>] [[-CreateFile] <bool>] [[-SizeMB] <int>] [[-Laps] <int>] [[-Measurement] <string>]
.\race.ps1 -Laps 1000
```