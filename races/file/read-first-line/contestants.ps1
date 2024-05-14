return @{
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