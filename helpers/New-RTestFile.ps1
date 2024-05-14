function New-RTestFile {
    [CmdletBinding()]
    param (
        $Path = "$env:temp/testfile",
        $SizeMB = 200
    )
    
    begin {
        $skipFileCreation = $false
        $LineLength = [math]::round(($SizeMB * 1mb) / 100)        
    }
    
    process {
        if((test-path $Path)){
            $MbSize = ($SizeMB * 1mb)
            #if file is within 10% of the size, skip creation
            if((get-item $Path).length -gt ($MbSize * 0.90) -and (get-item $Path).length -lt ($MbSize * 1.10)){
                Write-host "File $Path already exists and is $SizeMB Mb long. Skipping creation"
                $skipFileCreation = $true
            }
            else{
                Write-host "File $Path already exists (and is $((get-item $Path).length * 1mb), while we require $Mbsize). removing it"
                get-item $Path|Remove-Item -ErrorAction SilentlyContinue
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
            Write-host "Creating file $Path"
            [System.IO.File]::WriteAllLines($Path, $Arr)
        }
    }
    
    end {
        return Get-item $Path
    }
}