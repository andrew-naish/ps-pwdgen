## Init

param (

    [Parameter(Mandatory=$true)]
    [String] $WordlistPath,

    [Parameter(Mandatory=$true)]
    [String] $AWSCredentialProfile,

    [Parameter(Mandatory=$false)]
    [Int] $BatchRequests = 10,

    [Parameter(Mandatory=$false)]
    [String] $AWSLanguageCode = 'en'

)

try {

    # import wordlist
    Write-Output "Importing Wordlist"
    $wordlist = Get-Content $WordlistPath -ErrorAction Stop
    $wordlist_count = ($wordlist | Measure-Object).Count
    Write-Output ""

    # prepare stack
    $wordlist_stack = New-Object System.Collections.Stack
    $wordlist | ForEach-Object {
        $wordlist_stack.Push($_)
    }

}

catch {
    Write-Output "ERROR: $($error[0].exception.message)"
    throw "Error Importing Wordlist"
    Exit
}

## Main

# calculate itterations
$itterations = [System.Math]::Ceiling($wordlist_count/$BatchRequests)
[int]$modulo = $wordlist_count % $BatchRequests

if ($itterations -eq 0) {
    Write-Output "ERROR: No batches to process"
    Exit
}

Write-Output "Sending Batches to AWS"
$results = @()
for( $i=1; $i -le $itterations; $i++)
{

    # if it's the last item there may be a remainder
    $max_items = if ($i -eq $itterations -AND $modulo -gt 0) 
    { Write-Output $modulo } 
    else 
    { Write-Output $BatchRequests }

    # add words to the batch
    $word_batch =  @()
    1 .. $max_items | ForEach-Object {
        $word_batch += $wordlist_stack.Pop()
    }

    # send the query to AWS
    Write-Output "  Batch #$i of $itterations"
    $aws_results = Find-COMPSentimentBatch -TextList $word_batch -LanguageCode "$AWSLanguageCode" -ProfileName "$AWSCredentialProfile"

    if (($aws_results.ErrorList | Measure-Object).Count -gt 0 ) {
        Write-Output "  ERRORS:"
        $aws_results.ErrorList 
    }    

    # process results
    $aws_results.ResultList | ForEach-Object {

        $index = $_.Index
        $score = $_.SentimentScore

        $result_row = New-Object PSObject -Property @{
            "Word" = $word_batch[$index]
            "Sentiment" = $($_.Sentiment)
            "ScoreNegative" = "$($score.Negative)"
            "ScoreMixed" = "$($score.Mixed)"
            "ScoreNeutral" = "$($score.Neutral)"
            "ScorePositive" = "$($score.Positive)"
        }

        # commit row
        $results += $result_row

    }

    # sleep to prevent throttling
    Start-Sleep -Seconds 2

}; Write-Output ""

## Output

Write-Output "Generating Output CSV"

$output_dir = ".\Output"
$output_filename = "$((Get-Item $WordlistPath).BaseName)-SentimentReport.csv"
$output_fullpath = Join-Path $output_dir $output_filename

# Create output if it does not exist
if ( -not (Test-Path $output_dir)) {
    New-Item -ItemType Directory -Path $output_dir | Out-Null
}

# If existing report, remove
if (Test-Path $output_fullpath) {
    Remove-Item -Path $output_fullpath -Force | Out-Null
}

# order properties then sort
$property_order = "Word", "Sentiment", "ScoreMixed", "ScoreNegative", "ScoreNeutral", "ScorePositive"
$results = $results | Select-Object -Property $property_order | Sort-Object -Property "Word"

# export
$results | Export-Csv -NoClobber -NoTypeInformation -Path $output_fullpath

Write-Output "$output_fullpath"
Write-Output ""