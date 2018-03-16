param(
    [switch]$NoInfo,
    $WordlistDirectory=".\wordlists",
    $Count=1,
    $PasswordMask="{word}#{int}"
)

$seperators=@("@","#")

$idx_formatters = @()
$using_WordLists = @{}
$rtnpwdList = @()

$vowel_upper = @('A', 'E', 'I', 'O', 'U')
$vowel_lower = @('a', 'e', 'i', 'o', 'u')
$consonant_lower = @("b", "c", "d", "f", "g", "h", "j", "k", "l", "m", "n", "p", "q", "r", "s", "t", "v", "w", "x", "y", "z")
$consonant_upper = @('B', 'C', 'D', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'Q', 'R', 'S', 'T', 'V', 'W', 'X', 'Y', 'Z')

## Locate formatters 

$count_wordlists  = ([regex]::Matches($PasswordMask, "{word}" )).count

[regex]::Matches($PasswordMask, "{(\w)+}|(.)" ) | ForEach-Object {
    
    $row = New-Object PSObject -Property @{
        "Index" = $_.Index
        "Value" = $_.Value
    }

    $idx_formatters += $row

}

## Choose random wordlists 

$allWordLists = Get-ChildItem -Path ($wordlistDirectory | Resolve-Path).Path -Filter "*.txt"
$usedIndex = @(); for ($i = 0; $i -lt $count_wordlists; $i++) {
    # Dowhile to prevent same index being chosen twice
    do {$rnd = Get-Random -Minimum 0 -Maximum $allWordLists.Length}
    while ($usedIndex -contains $rnd)
    $usedIndex += $rnd
        
    # Add to using
    $using_WordLists.Add(
        $($allWordLists[$rnd].Name),
        [array](Get-Content $allWordLists[$rnd].FullName)
    )
}

if (!$NoInfo) {
    # WRITE
    Write-Host "Generating passwords using pattern: " -NoNewline
    Write-Host "$PasswordMask" -ForegroundColor Yellow -NoNewline
    Write-Host ", with wordlist(s): " -NoNewline
    Write-Host "$($using_WordLists.Keys -join ',')" -ForegroundColor Yellow
}

## Main generate password loop

for ($i = 0; $i -lt $Count; $i++) {

    $pw = @()
    
    foreach ($item in $idx_formatters | Sort-Object Index) {

        switch ($item.Value) {
            
            '{word}'      {$pw += $using_WordLists.Values | Get-Random; break}
            '{seperator}' {$pw += $seperators | Get-Random; break}
            '{int}'       {$pw += Get-Random -Minimum 1000 -Maximum 9999; break}
            '{vowel}'     {$pw += $vowel_lower | Get-Random; break}
            '{conso}'     {$pw += $consonant_lower | Get-Random; break}
            '{vowelUpper}'     {$pw += $vowel_upper | Get-Random; break}
            '{consoUpper}'     {$pw += $consonant_upper | Get-Random; break}

            default {$pw += $item.Value}

        }

    }

    $rtnpwdList += (Get-Culture).TextInfo.ToTitleCase("$(-join $pw)") # to TitleCase

}

## Return to sender

if ($rtnpwdList.Count -eq 1) {

    Write-Output $rtnpwdList[0]

} else {

    return $rtnpwdList

}