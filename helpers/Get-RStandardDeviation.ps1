function Get-RStandardDeviation {
    [CmdletBinding()]
    param (
        [int[]]$List
    )
    
    begin {


    }
    
    process {
        # Calculate the average of the list
        $Avg = ($List | Measure-Object -Average).Average
        # Initialize the sum of squared deviations
        $SumOfDerivation = 0
        # Iterate through each number in the list
        for ($i = 0; $i -lt $List.Count; $i++) {
            $number = $List[$i]
            # Calculate the squared deviation and add it to the sum
            $SumOfDerivation += ($number - $avg) * ($number - $avg)
        }
        # Calculate the average of the sum of squared deviations
        # $SumOfDerivationAvg = $SumOfDerivation / ($List.Count - 1)
        # Calculate the standard deviation using the formula: sqrt(SumOfDerivationAvg - Avg^2)
    }
    
    end {
        return [math]::Sqrt($SumOfDerivation / ($List.Count - 1))
        # return [math]::Sqrt($SumOfDerivationAvg - ($Avg * $Avg))
    }
}