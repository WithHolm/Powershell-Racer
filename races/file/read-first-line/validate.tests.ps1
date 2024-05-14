param(
    #file to read from. will be created if it does not exist. just let it stay default so you dont delete anything important
    [string]$FileName = "$env:temp/testfile.txt",
    #if i should create the file
    [bool]$CreateFile = $true,
    # size of file if it needs to be created. 200 is good enough.. file creation takes some time
    [int]$SizeMB = 200,
    #number of laps to run. more = better data, but longer run time
    [int]$Laps = 15000,
    #measurement to use. ticks is the most accurate, but also the most verbose
    [ValidateSet("ticks", "milliseconds", "seconds","nanoseconds")]
    [string]$Measurement = "ticks"
)


if($CreateFile){
    $skipFileCreation = $false
    $LineLength = [math]::round(($SizeMB * 1mb) / 100)

    if((test-path $FileName)){
        $MbSize = ($SizeMB * 1mb)
        #if file is within 10% of the size, skip creation
        if((get-item $FileName).length -gt ($MbSize * 0.90) -and (get-item $FileName).length -lt ($MbSize * 1.10)){
            Write-host "File $FileName already exists and is $SizeMB Mb long. Skipping creation"
            $skipFileCreation = $true
        }
        else{
            Write-host "File $FileName already exists (and is $((get-item $FileName).length * 1mb), while we require $Mbsize). removing it"
            get-item $FileName|Remove-Item -ErrorAction SilentlyContinue
        }
    }
    if(!$skipFileCreation)
    {
        Write-host "creating $LineLength lines, or $SizeMB Mb of data for file"
        $Arr = [string[]]::new($LineLength)
        for ($i = 0; $i -lt $LineLength; $i++) {
            $content = "This is line $($i + 1) of the file. It's always fun to count the characters in a long sentence"
            $content += "." * $(98 - $content.length)
            $Arr[$i] = $content
        }
    
        # $Arr.Count
        Write-host "Creating file $FileName"
        [System.IO.File]::WriteAllLines($FileName, $Arr)
    }
}
elseif(!(Test-Path $FileName)){
    Throw "Cannot run test. cannot find file $FileName"

}

Write-host "$FileName is $((get-item $FileName).length / 1mb) Mb long"
Write-host "Rase is $laps laps long, measured in $Measurement"

#DEFINING THE COMMANDS
$Race = @{
    #administrator.. easier to have it in the same object as the rest
    _ = @{
        #what to expect of execution. This is used to verify that the output is correct, before measuring
        expect = Get-Content $FileName -TotalCount 1
    }
    #tests
    "Switch -file" = @{
        summary = "switch -file"
        run = {
             $FirstLine = switch -file ($FileName){Default{$_;break}}
             Write-Output $FirstLine
        }
    }
    "get content -TotalCount" =  @{
        summary = "get content -totalcount"
        run = {
            $FirstLine = Get-Content $FileName -TotalCount 1
            Write-Output $FirstLine
        }
    }
    "IO.File readlines|select" = @{
        summary = "IO.File Read, Pipe select"
        run = {
            $FirstLine = [system.io.file]::ReadLines($FileName)|select -first 1
            Write-Output $FirstLine
        }
    }
    "IO.File readlines,movenext,current" = @{
        summary = "IO.File Read, movenext, current"
        run = {
            $lines = [system.io.file]::ReadLines($FileName)
            [void]$lines.movenext()
            $FirstLine = $lines.current
            Write-Output $FirstLine
        }
    }
    "StreamReader readline" = @{
        summary = "StreamReader"
        run = {
            $reader = [System.IO.StreamReader]::new($FileName)
            $firstLine = $reader.ReadLine()
            Write-Output $firstLine
        }
    }
    "StreamReader readline w/encoding" = @{
        summary = "StreamReader with encoding"
        run = {
            $reader = [System.IO.StreamReader]::new($FileName,[System.Text.Encoding]::UTF8)
            $firstLine = $reader.ReadLine()
            Write-Output $firstLine
            $reader.Close()
        }
    }
    "FileStream StreamReader readline" = @{
        summary = "FileStream StreamReader"
        run = {
            $stream = [System.IO.File]::OpenRead($FileName)
            $reader = [System.IO.StreamReader]::new($stream)
            $firstLine = $reader.ReadLine()
            Write-Output $firstLine
            $stream.Close()
        }
    }
    "get-content|select" = @{
        summary = "get-content pipe"
        run = {
            $FirstLine = Get-Content $FileName | select -first 1
            Write-Output $FirstLine
        }
    
    }
}


#RUNNING THE COMMANDS
$results = @{}

#for each item in $race where the name is not "_" (this is used for administrating the tests)..
$Race.GetEnumerator().Where{$_.Key -ne "_"} | % {
    $Name = $_.Key
    $ScriptBlock = $_.Value.run

    #Creating result object for this test
    $results[$Name] = @{
        Laptimes = [int[]]::new($laps)
        Fastest = [int]::MaxValue
        Slowest = [int]::MinValue
    }

    #testing that the output is as expected
    $RaceOutput = $ScriptBlock.Invoke()
    if($RaceOutput -ne $Race._.expect){
        Write-Warning "Output for $Name is not as expected, skipping. expeceted '$($Race._.expect)', got '$RaceOutput'"
        continue
    }

    Write-Host "Running '$($_.Key)'"
    for ($i = 0; $i -lt $Laps; $i++) {
        #run the scriptblock with measure command
        $Result = Measure-Command -Expression $ScriptBlock
        if($i -lt 20){
            continue
        }

        #figuring out what kind of measurement to use, based on the selected measurement in param
        $res = switch($Measurement)
        {
            "ticks" { $Result.Ticks }
            "milliseconds" { $Result.TotalMilliseconds }
            "seconds" { $Result.TotalSeconds }
            "nanoseconds" { $Result.TotalNanoseconds }
        }

        #adding the result to the laptimes arr
        $results[$Name].Laptimes[$i] = $res

        #figuring out if this is the fastest or slowest lap
        $results[$Name].Fastest = [Math]::Min($results[$Name].Fastest, $res)
        $results[$Name].Slowest = [Math]::Max($results[$Name].Slowest, $res)
    }
}

Write-host "------"
Write-host "Results after $laps laps with a file of $((get-item $FileName).length / 1mb) Mb, measured in $Measurement"
Write-host "------"
$results.GetEnumerator() | % {
    $Name = $_.Key
    $Result = $_.Value
    $LapTimes = $Result.Laptimes|sort -Descending

    $stats = ($LapTimes | Measure-Object -AllStats)

    #count of 5% and 1% of laps
    $5percentOfLaps = [int]$laps * 0.05
    $1percentOfLaps = [int]$laps * 0.01

    #result object
    [pscustomobject]@{
        Name = $Name
        Measurement = $Measurement
        #average of all runs
        Avg = [math]::Round($stats.Average,2)
        #average of the 99% fastest runs
        p99 = [math]::Round(($LapTimes|select-object -Skip $1percentOfLaps |Measure-Object -Average).Average,2)
        #average of the 95% fastest runs
        p95 = [math]::Round(($LapTimes|select-object -Skip $5percentOfLaps |Measure-Object -Average).Average,2)
        #average of the 50% fastest runs. if this is same as Avg, it means that the runs are very consistent
        p50 = [math]::Round(($LapTimes|select-object -Skip ($5percentOfLaps * 10) |Measure-Object -Average).Average,2)

        #fastest and slowest lap
        Fastest = $Result.Fastest
        Slowest = $Result.Slowest

        Deviation = [math]::Round($stats.StandardDeviation,2)

        Total = [math]::Round($stats.Sum,2)
    }
}|sort avg|ft -a 
