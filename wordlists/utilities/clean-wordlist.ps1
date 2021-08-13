## Init

param(

    # Path to a specific wordlist.
    [Parameter(Mandatory = $true, HelpMessage="Path to a specific wordlist.")]
    [String] $Wordlist,

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
            $bysentiment_sentimentrpt_param_attr = New-Object -Type System.Management.Automation.ParameterAttribute
            $bysentiment_sentimentrpt_param_attr.Mandatory = $true

            $bysentiment_sentimentrpt_param_attrcol = New-Object -Type System.Collections.ObjectModel.Collection[System.Attribute]
            $bysentiment_sentimentrpt_param_attrcol.Add($bysentiment_sentimentrpt_param_attr)

            # create parameter object
            $bysentiment_sentimentrpt_param = New-Object -Type System.Management.Automation.RuntimeDefinedParameter("SentimentReport", [String], $bysentiment_sentimentrpt_param_attrcol)

            # commit
            $param_dictionary.Add('SentimentReport', $bysentiment_sentimentrpt_param)
    
    }

    # return params
    return $param_dictionary

}

Begin {

    Read-Host "PAUSE"

}

Process {


    ## TODO: Backup current wordlists

    ## TODO: Do the basic stuff 
    #    - Convert to TitleCase
    #    - Remove chars which are not [a-zA-Z]

    ## TODO: If ByLength
    #    - Do stuff

    ## TODO: If BySentiment
    #    - Do stuff

    Read-Host "PAUSE - Before Old Code"
    ### Old code below ##

    # define backup dir
    $backup_dir_path = ".\wordlist_backups\backup_$(Get-Date -Format "yyyyMMdd-HHmmss")" 

    # create dir
    if ( -not (Test-Path "$backup_dir_path")) {
        New-Item -ItemType Directory -Name "$bkDirName" -Force | Out-Null
    }

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

}