$titlecaseConverter = (Get-Culture).TextInfo

$bkDirName = "wordlist_backup"
if (!(Test-Path ".\$bkDirName")) {
    New-Item -ItemType Directory -Name "$bkDirName" | Out-Null
}

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
