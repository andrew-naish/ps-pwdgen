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
            $bylength_minlen_param.Value = 3 # default value

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

    # TODO: import sqllite3.dll

    # funct
    function MessageAndContinue($Word, $Message) {
        Write-Output "Removing word: $word, Reason: $Message"
        continue
    }

    # var
    $wordlists_dir = "..\wordlists"
    $wordlists_plaintext_dir = "$wordlists_dir\plaintext"
    $wordlists_plaintext_backups_dir = "$wordlists_plaintext_dir\backups"

    # handle dynamic params
    if ( $ByLength ) {
        $acceptable_range = ($param_dictionary.MinLength.Value)..($param_dictionary.MaxLength.Value)
    }
    if ( $BySentiment ) {
        $sentiment_threshold = $param_dictionary.SentimentThreshold.Value
        $sentiment_map = @{
            "NEGATIVE" = 0
            "MIXED" = 1
            "NEUTRAL" = 2
            "POSITIVE" = 3
        }
    }

}

## Main

Process {

    ## backup current wordlists
    Write-Output "Backing up current wordlists"

    # create dir if does not exist
    if ( -not (Test-Path $wordlists_plaintext_backups_dir)) 
    { New-Item -Path $wordlists_plaintext_backups_dir -ItemType Directory -Force | Out-Null }

    # do the thing
    Compress-Archive -Path "$wordlists_plaintext_dir\*.txt" -DestinationPath "$wordlists_plaintext_backups_dir\$(Get-Date -Format 'ddMMyyyy-HHmmss')_wordlistbackup.zip" | Out-Null

    ## itterate wordlists
    Get-ChildItem -Path $wordlists_plaintext_dir -Filter "*.txt" | ForEach-Object {

        $wordlist_current_name = $_.BaseName
        Write-Output "On Wordlist: $wordlist_current_name"

        # import wordlist
        $wordlist_current_content = Get-Content $_.FullName

        # remove current
        #$_ | Remove-Item -Force

        # prepare
        $wordlist_new = New-Object -Type Collections.Generic.List[String]

        # check if can sentiment
        if ( $BySentiment ) {

            $sentiment_report_path = "$wordlists_plaintext_dir\$($wordlist_current_name)_sentimentreport.csv"
            $sentiment_report_present = $false

            if ( Test-Path "$sentiment_report_path" ) {
                $sentiment_report_present = $true
                $sentiment_report = Import-Csv $sentiment_report_path
            }

        }

        foreach ( $word in $wordlist_current_content ) {

            # if empty, skip
            if ( [string]::IsNullOrEmpty($word) ) {
                continue
            }

            # by length
            if ( $ByLength ) {
                if ($word.Length -notin $acceptable_range) {
                    MessageAndContinue $word "Length is not in acceptable range"
                } 
            }

            # by sentiment
            if ( $BySentiment -AND $sentiment_report_present ) {
                $sentiment = ($sentiment_report | Where-Object {$_.Word -eq $word}).Sentiment
                if ($sentiment_map[$sentiment] -lt $sentiment_threshold) {
                    MessageAndContinue $word "Word is below sentiment threshold"
                }
            }

            # TODO: convert to titlecase

            # TODO: remove non a-z chars

            # word is ok
            #Write-Output "Word ok: $word"
            $wordlist_new.Add($word)

        }

        # TODO: sort

        # TODO: dump as text

        # TODO: dump as .bin ?

        Write-Output ""
    }


    <#
    $titlecaseConverter = (Get-Culture).TextInfo
    $bkDirName = "wordlist_backup"

    $wordlists = Get-ChildItem ".\" -Filter "*.txt"
    foreach ($wl in $wordlists) {
        # Import file, Backup then Delete original
        [array]$content = $wl | Get-Content
        Copy-Item -Path $wl -Destination .\$bkDirName -Force
        Remove-Item $wl -Force

        # Build new wordlist
        $newContent = @(); foreach ($word in $content) {
            $nw = [regex]::replace($word, "[^a-zA-Z]", "")
            $nw = $titlecaseConverter.ToTitleCase($nw)

            $newContent += $nw
        }

        $stream = [System.IO.StreamWriter] $($wl.FullName)
            $ar = $newContent | Sort-Object
            for ($i = 0; $i -lt [int]$ar.Length; $i++)
            { 
                $stream.WriteLine($ar[$i])
            }
            $stream.Close()
    }

    #>

}