describe "Get-StandardDeviation" {
    context "When given a list of numbers" {
        it "Calculates the standard deviation" {
            $List = 1, 2, 3, 4, 5
            $Result = Get-RStandardDeviation -List $List
            "$Result" | Should -BeExactly "1.58113883008419"
        }
    }
}