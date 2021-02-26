param(
    [switch]$NoInfo,
    $WordlistDirectory=".\wordlists",
    $Count=1,
    $PasswordMask="{wl:colours}{wl:random}#{int}"
)

$formatters = @()
$rtnpwdList = @()

$vowel_upper = @('A', 'E', 'I', 'O', 'U')
$vowel_lower = @('a', 'e', 'i', 'o', 'u')
$consonant_lower = @("b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "w", "x", "y", "z")
$consonant_upper = @('B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Y', 'Z')

# get wordlists
$wordlists_all = Get-ChildItem -Path ($wordlistDirectory | Resolve-Path).Path -Filter "*.txt"
$wordlists_available = {($wordlists_all.BaseName)}.Invoke() # converting it to a System.Collections.ObjectModel.Collection - this allows the use of .Remove()

#  funct
function GetWordFromWordlist($WordlistName) {
    $wl_file = $wordlists_all | Where-Object {$_.basename -eq "$WordlistName"}

    # early ticket home if not found
    if( $null -eq $wl_file ) { 
        throw "404 wordlist not found - Check there's a wordlist named '$WordlistName' in the wordlist directory"
    }

    return $wl_file | Get-Content | Get-Random
}

function ParseExplicitWordlistMask ($ExplicitWordlistMask) {
    $wl_match = [regex]::Match($ExplicitWordlistMask, "{wl:(\w+)}" )
    return $wl_match.Groups[1].Value

    # if the name of the wordlist is invalid
    #   we'll catch it later on when we try to get a word from it 
}

## Main

# parse the password mask
[regex]::Matches($PasswordMask, "{((wl:)?\w)+}|(.)" ) | ForEach-Object {
    
    $new_formatter = New-Object PSObject -Property @{
        "index" = $_.Index
        "value" = $_.Value
        "wordlist" = "" # this will be populated later on for each word-related formatter
    }

    $formatters += $new_formatter

}

$wordy_formatters = $formatters | Where-Object {$_.Value -like "{wl:*}"}

# check if too many wordlists
if ([int]($wordy_formatters| Measure-Object).Count -gt $wordlists_available.Count) {
    throw "Too many formatters which will require a random wordlist. Either add more wordlists or downgrade your formatter game!"
}

# assign a wordlist to wordy formatters
foreach ($formatter in $wordy_formatters) {

    # random wordlist formatter
    if ($formatter.value -eq "{wl:random}") {
        $chosen_wordlist = $wordlists_available | Get-Random
    }

    # specific wordlist formatter
    else {
        $chosen_wordlist = ParseExplicitWordlistMask -ExplicitWordlistMask "$($formatter.Value)"
    }

    # allocate and mark as unavailable
    $formatter.wordlist = "$chosen_wordlist"
    $wordlists_available.Remove("$chosen_wordlist") | Out-Null

}

# to nag or not to nag, that is the question
if (-not $NoInfo) {

    Write-Host "Generating passwords using pattern: " -NoNewline
    Write-Host "$PasswordMask" -ForegroundColor Yellow -NoNewline
    Write-Host ", with wordlist(s): " -NoNewline
    Write-Host "$( ($($formatters | Sort-Object Index).wordlist | Where-Object {$_ -ne ''}) -join ',')" -ForegroundColor Yellow

}

# do the thing
for ($i = 0; $i -lt $Count; $i++) {

    # each element of the password will go here, we'll join it in the end
    $pw = @()
    
    foreach ($item in $formatters | Sort-Object Index) {

        switch -Wildcard ($item.Value) {
            
            '{wl:random}'       {$pw += GetWordFromWordlist($($item.wordlist)); break}
            '{wl:*}'            {$pw += GetWordFromWordlist($($item.wordlist)); break}
            '{int}'             {$pw += Get-Random -Minimum 1000 -Maximum 9999; break}
            '{vowel_lower}'           {$pw += $vowel_lower | Get-Random; break}
            '{consonant_lower}' {$pw += $consonant_lower | Get-Random; break}
            '{vowel_upper}'     {$pw += $vowel_upper | Get-Random; break}
            '{consonant_upper}' {$pw += $consonant_upper | Get-Random; break}

            default {$pw += $item.Value}

        }
    }

    $rtnpwdList += -join $pw
}

## Output

if ($rtnpwdList.Count -eq 1) {
    Write-Output $rtnpwdList[0]
    } 

else {
    return $rtnpwdList
    }