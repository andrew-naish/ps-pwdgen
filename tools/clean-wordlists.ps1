## Init
Param(

    # Path to a specific wordlist.
    #[Parameter(Mandatory = $true, HelpMessage="Path to a specific wordlist.")]
    #[ArgumentCompleter( { param($cmd, $param, $wordToComplete) $((Get-ChildItem -Path "..\wordlists\plaintext\").BaseName) -like "$wordToComplete*" } )]
    #[ValidateScript( { $_ -in $((Get-ChildItem -Path "..\wordlists\plaintext\").BaseName) })]
    #[String[]] $Wordlists,

    # Check word length, if less than defined min or more than defined max, remove it.
    #   If this param is used, DynamicParams will be added in the block below.
    [Parameter(Mandatory = $false, HelpMessage="Check word length, if less than defined min or more than defined max, remove it.")]
    [Switch] $ByLength,

    # Requires a sentiment report. Remove all words which are below the sentiment threshold.
    #   If this param is used, DynamicParams will be added in the block below.
    [Parameter(Mandatory = $false, HelpMessage="Requires a sentiment report. Remove all words which are below the sentiment threshold.")]
    [Switch] $BySentiment

)

DynamicParam {

    # all params go here ..
    $param_dictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

    ## ByLength
    if ($ByLength) {
        
        # Define: MinLength
            $bylength_minlen_param_attr = New-Object -Type System.Management.Automation.ParameterAttribute
            $bylength_minlen_param_attr.Mandatory = $false

            $bylength_minlen_param_attrcol = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $bylength_minlen_param_attrcol.Add($bylength_minlen_param_attr)

            # create parameter object
            $bylength_minlen_param = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("MinLength", [Int], $bylength_minlen_param_attrcol)
            $bylength_minlen_param.Value = 4 # default value

            # commit
            $param_dictionary.Add('MinLength', $bylength_minlen_param)

        # Define: MaxLength
            $bylength_maxlen_param_attr = New-Object -Type System.Management.Automation.ParameterAttribute
            $bylength_maxlen_param_attr.Mandatory = $true
            
            $bylength_maxlen_param_attrcol = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $bylength_maxlen_param_attrcol.Add($bylength_maxlen_param_attr)

            # create parameter object
            $bylength_maxlen_param = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("MaxLength", [Int], $bylength_maxlen_param_attrcol)

            # commit
            $param_dictionary.Add('MaxLength', $bylength_maxlen_param)

    }

    ## BySentiment
    if ($BySentiment) {

        # Define: SentimentReport
            $bysentiment_sntthreshold_param_attr = New-Object -Type System.Management.Automation.ParameterAttribute
            $bysentiment_sntthreshold_param_attr.Mandatory = $false

            $bysentiment_sntthreshold_param_attrcol = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $bysentiment_sntthreshold_param_attrcol.Add($bysentiment_sntthreshold_param_attr)

            # create parameter object
            $bysentiment_sntthreshold_param = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("SentimentThreshold", [Int], $bysentiment_sntthreshold_param_attrcol)
            $bysentiment_sntthreshold_param.Value = 1 # default value

            # commit
            $param_dictionary.Add('SentimentThreshold', $bysentiment_sntthreshold_param)
    
    }

    # return params
    return $param_dictionary

}

Begin {

    # import threadjob module
    Import-Module "..\dependancies\ThreadJob\ThreadJob.psd1"

    # funct
    function WriteToLog($Message, $Level = "INFO") {

        $nice_date_with_space = Get-Date -Format 'dd-MM-yyyy HH:mm:ss'

        # write to stream
        $message_to_commit = ("{0} :: {1} :: $Message" -f $nice_date_with_space, $Level)
        $logs_streamwriter.WriteLine($message_to_commit)

    }

    # var
    $nice_date = Get-Date -Format 'ddMMyyyy-HHmmss'
    $wordlists_dir = Resolve-path "..\wordlists"
    $wordlists_backups_dir = "$wordlists_dir\backups"
    $wordlists_backups_fullpath = ("$wordlists_backups_dir\{0}_wordlistbackup.zip" -f $nice_date)
    $logs_dir = Resolve-path ".\logs"
    $logs_fullpath = ("$logs_dir\{0}_log_clean-wordlists.txt" -f $nice_date)

    # initialise log
    $logs_streamwriter = [System.IO.StreamWriter] $logs_fullpath
    WriteToLog -Message "Log started"

    # handle dynamic params
    WriteToLog -Message "Parameters used:"
    if ( $ByLength ) {
        WriteToLog -Message "- ByLength: $true"
        WriteToLog -Message "- MinLength: $($param_dictionary.MinLength.Value)"
        WriteToLog -Message "- MaxLength: $($param_dictionary.MaxLength.Value)"
        $acceptable_range = ($param_dictionary.MinLength.Value)..($param_dictionary.MaxLength.Value)
    }

    if ( $BySentiment ) {
        WriteToLog -Message "- BySentiment: $true"
        WriteToLog -Message "- SentimentThreshold: $($param_dictionary.SentimentThreshold.Value)"
        $sentiment_threshold = $param_dictionary.SentimentThreshold.Value
        $sentiment_map = @{
            "NEGATIVE" = 0
            "MIXED" = 1
            "NEUTRAL" = 2
            "POSITIVE" = 3
        }
    }

} # end: begin

## Main

Process {

    ## backup current wordlists

    # create dir if does not exist
    if ( -not (Test-Path $wordlists_backups_dir)) 
    { New-Item -Path $wordlists_backups_dir -ItemType Directory -Force | Out-Null }

    # backup to zip file
    Compress-Archive -Path "$wordlists_dir\*.*" -DestinationPath "$wordlists_backups_fullpath" | Out-Null
    WriteToLog -Message "Wordlist backup created: $wordlists_backups_fullpath"

    ## itterate wordlists
    WriteToLog -Message "Processing wordlists"
    $wordlists = Get-ChildItem -Path $wordlists_dir -Filter "*.txt"
    foreach ($wordlist in $wordlists ) {

        $wordlist_fullname = $wordlist.FullName
        WriteToLog -Message "On wordlist: $wordlist_fullname"

        # import existing wordlist and remove
        $wordlist_content = Get-Content "$($wordlist_fullname)"
        Remove-Item -Path "$($wordlist_fullname)" -Force
        WriteToLog -Message "Imported and deleted original"

        # prepare output stream
        $wordlist_streamwriter = [System.IO.StreamWriter] $wordlist_fullname
        WriteToLog -Message "Created new wordlist file"

        # if $BySentiment was used, check if there's a sentiment report present
        if ( $BySentiment ) {
            WriteToLog -Message "Checking for sentiment report:"
            $sentiment_report_path = "$wordlists_dir\$($wordlist.BaseName)_sentimentreport.csv"
            $sentiment_report_present = $false

            # check if there's a sentiment report
            if ( Test-Path "$sentiment_report_path" ) {
                WriteToLog -Message "- Sentiment report present"
                $sentiment_report_present = $true
                $sentiment_report = Import-Csv $sentiment_report_path
            }
            else {
                WriteToLog -Level "WARN" -Message "- Sentiment report not present"
            }
        }

        # initialise counters
        [int]$words_counter = 0
        [int]$words_included_counter = 0
        [int]$words_excluded_counter = 0
        $wordlist_total_lines = ($wordlist_content | Measure-Object).Count

        ## itterate words in wordlist
        WriteToLog -Message "Processing words"
        foreach ( $word in ($wordlist_content | Sort-Object) ) {

            # pre-emptively increment, will derement if we reach then end!
            $words_excluded_counter++
            $words_counter++ # not this one though

            # remove non-alpha chars
            $word = [regex]::replace($word, "[^a-zA-Z]", "")

            # if empty, skip
            if ( [string]::IsNullOrEmpty($word) ) {
                WriteToLog -Message "- Skipped empty line"
                continue
            }

            # by length
            if ( $ByLength ) {
                if ($word.Length -notin $acceptable_range) {
                    WriteToLog -Message "- Word excluded: $word, Reason: Length is not in acceptable range"
                    continue
                } 
            }

            # by sentiment
            if ( $BySentiment -AND $sentiment_report_present ) {
                $sentiment = ($sentiment_report | Where-Object {$_.Word -eq $word}).Sentiment
                if ($null -ne $sentiment) {
                    if ($sentiment_map[$sentiment] -lt $sentiment_threshold) {
                        WriteToLog -Message "- Word excluded: $word, Reason: Below sentiment threshold"
                        continue
                    }
                }
            }

            # convert to titlecase
            $word = ((Get-Culture).TextInfo).ToTitleCase($word)

            # if we got to here, the word is ok, write it!
            # just use write if it's the last item (to avoid a blank line at the end)
            if ($words_counter -eq $wordlist_total_lines) {
                $wordlist_streamwriter.Write($word)
            } else {
                $wordlist_streamwriter.WriteLine($word)
            }

            # counters
            $words_excluded_counter--
            $words_included_counter++

        } # end: fe word

        # close the stream!
        $wordlist_streamwriter.Close()
        WriteToLog -Message "Finished processing words:"
        WriteToLog -Message "- Total words: $wordlist_total_lines"
        WriteToLog -Message "- Words included: $words_included_counter"
        WriteToLog -Message "- Words excluded: $words_excluded_counter"

    } # end: fe wordlist
    WriteToLog -Message "Finished processing wordlists"

} # end: process

End {
    # close streams
    $logs_streamwriter.Close()
}