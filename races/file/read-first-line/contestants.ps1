# i gotta figure out how input object works with measure-command.. right now its inputting the "racer" object, while im defining path..
return @{
    #administrator.. easier to have it in the same object as the rest
    _                                    = @{
        #what to expect of execution. This is used to verify that the output is correct, before measuring
        expect = Get-Content $FileName -TotalCount 1
    }
    #tests
    "Switch -file"                       = @{
        summary = "switch -file"
        run     = {
            # $FileName = $_
            switch -file ($FileName) { Default { $_; break } }
            # Write-Output $FirstLine
        }
    }
    "get content -TotalCount"            = @{
        summary = "get content -totalcount"
        run     = {
            # $FileName = $_
            return (Get-Content $FileName -TotalCount 1)
        }
    }
    "IO.File readlines|select"           = @{
        summary = "IO.File Read, Pipe select"
        run     = {
            # $FileName = $_
            return ([system.io.file]::ReadLines($FileName) | Select-Object -first 1)
        }
    }
    "IO.File readlines,movenext,current" = @{
        summary = "IO.File Read, movenext, current"
        run     = {
            # $FileName = $_
            $lines = [system.io.file]::ReadLines($FileName)
            [void]$lines.movenext()
            return $lines.current
        }
    }
    "StreamReader readline"              = @{
        summary = "StreamReader"
        run     = {
            # $global:test = $_
            # $FileName = $_
            $reader = [System.IO.StreamReader]::new($FileName)
            return $reader.ReadLine()
        }
    }
    # "StreamReader Linq"                  = @{
    #     summary = "StreamReader"
    #     run     = {
    #         # $FileName = $_
    #         $reader = [System.IO.StreamReader]::new($FileName)
    #         $delegate = [Func[string, bool]] { $true }
    #         Write-Output [Linq.Enumerable]::First($reader, $delegate)[0]
    #         $reader.Close()
    #     }
    # }
    "StreamReader readline w/encoding"   = @{
        summary = "StreamReader with encoding"
        run     = {
            # $FileName = $_
            $reader = [System.IO.StreamReader]::new($FileName, [System.Text.Encoding]::UTF8)
            Write-output $reader.ReadLine()
            $reader.Close()
        }
    }
    "FileStream StreamReader readline"   = @{
        summary = "FileStream StreamReader"
        run     = {
            # $FileName = $_
            $stream = [System.IO.File]::OpenRead($FileName)
            $reader = [System.IO.StreamReader]::new($stream)
            Write-Output $reader.ReadLine()
            $stream.Close()
        }
    }
    "get-content|select"                 = @{
        summary = "get-content pipe"
        run     = {
            # $reader.ReadLine()
            return (Get-Content $FileName | select -first 1)
        }
        
    }
}