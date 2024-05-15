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
    [ValidateSet("ticks", "milliseconds", "seconds", "nanoseconds")]
    [string]$Measurement = "ticks"
)

gci "$PSScriptRoot/helpers" | ? { $_.basename -notlike "*.tests" } | % { . $_.FullName }

if ($CreateFile) {
    New-RtestFile -Path $FileName -SizeMB $SizeMB | Out-Null
}
elseif (!(Test-Path $FileName)) {
    Throw "Cannot run test. cannot find file $FileName"
}

Write-host "$FileName is $((get-item $FileName).length / 1mb) Mb long"
Write-host "Race is $laps laps long, measured in $Measurement"

#RUNNING THE COMMANDS
$results = @{}

$Contestants = & "$PSScriptRoot/races/file/read-first-line/contestants.ps1"

#for each item in $race where the name is not "_" (this is used for administrating the tests)..
foreach ($Contestant in $Contestants.GetEnumerator().Where{ $_.Key -ne "_" }) {
    $Name = $Contestant.Key
    $ScriptBlock = $Contestant.Value.run

    #testing that the output is as expected
    $RaceOutput = $ScriptBlock.Invoke()
    if ($RaceOutput -ne $Contestants._.expect) {
        Write-Warning "Output for $Name is not as expected, skipping. expeceted '$($Contestants._.expect)', got '$RaceOutput'"
        continue
    }

    #Creating result object for this test
    $results[$Name] = @{
        Laptimes = [int[]]::new($laps)
        Fastest  = [int]::MaxValue
        Slowest  = [int]::MinValue
    }

    Write-Host "Running '$($Name)'"
    $global:Path = $FileName
    for ($i = 0; $i -lt $Laps; $i++) {
        #run the scriptblock with measure command
        $Result = $FileName | Measure-Command -Expression $ScriptBlock
        if ($i -lt 20) {
            continue
        }

        #figuring out what kind of measurement to use, based on the selected measurement in param
        $res = switch ($Measurement) {
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
    $LapTimes = $Result.Laptimes | sort -Descending

    # $stats = ($LapTimes | Measure-Object -AllStats)

    #count of 5% and 1% of laps
    $5percentOfLaps = [int]$laps * 0.05
    $1percentOfLaps = [int]$laps * 0.01
    $k = [math]::Round(($LapTimes | select-object -Skip $1percentOfLaps | Measure-Object -Average).Average, 2)
    #result object
    [pscustomobject]@{
        Name        = $Name
        Measurement = $Measurement
        #average of all runs
        Avg         = [math]::Round(($LapTimes | Measure-Object -Average).average, 2)
        #average of the 99% fastest runs
        p99         = [math]::Round(($LapTimes | select-object -Skip $1percentOfLaps | Measure-Object -Average).Average, 2)
        #average of the 95% fastest runs
        p95         = [math]::Round(($LapTimes | select-object -Skip $5percentOfLaps | Measure-Object -Average).Average, 2)
        #average of the 50% fastest runs. if this is same as Avg, it means that the runs are very consistent
        p50         = [math]::Round(($LapTimes | select-object -Skip ($5percentOfLaps * 10) | Measure-Object -Average).Average, 2)

        #fastest and slowest lap
        Fastest     = $Result.Fastest
        Slowest     = $Result.Slowest

        Deviation   = [math]::Round((Get-RStandardDeviation -List $LapTimes), 2)

        Total       = [math]::Round(($LapTimes | Measure-Object -sum).Sum, 2)
    }
} | sort avg | ft -a 