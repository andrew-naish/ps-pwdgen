## Init

param(

    #[Parameter(Mandatory=$true, ParameterSetName="ByLength")]
    #[Parameter(Mandatory=$true, ParameterSetName="BySentiment")]
    [Parameter(Mandatory=$true, ParameterSetName="ExplicitWordlists")]
    [String[]] $Wordlists,

    #[Parameter(Mandatory=$true, ParameterSetName="ByLength")]
    #[Parameter(Mandatory=$true, ParameterSetName="BySentiment")]
    [Parameter(Mandatory=$true, ParameterSetName="AllWordlists")]
    [Switch] $AllWordlists,

    ## ByLength

    # Parameter help description
    [Parameter(Mandatory=$false, ParameterSetName="ExplicitWordlists")]
    [Parameter(Mandatory=$false, ParameterSetName="AllWordlists")]
    [Parameter(Mandatory=$false, ParameterSetName="ByLength")]
    [Switch] $ByLength,

    # Parameter help description
    [Parameter(Mandatory=$true, ParameterSetName="ByLength")]
    [Int] $MinLength,

    # Parameter help description
    [Parameter(Mandatory=$true, ParameterSetName="ByLength")]
    [Int] $MaxLength,

    ## BySentiment

    # Parameter help description
    [Parameter(Mandatory=$false, ParameterSetName="ExplicitWordlists")]
    [Parameter(Mandatory=$false, ParameterSetName="AllWordlists")]
    [Parameter(Mandatory=$false, ParameterSetName="BySentiment")]
    [Switch] $BySentiment,
    
    # Parameter help description
    [Parameter(Mandatory=$true, ParameterSetName="ExplicitWordlists")]
    [Parameter(Mandatory=$true, ParameterSetName="AllWordlists")]
    [Parameter(Mandatory=$true, ParameterSetName="BySentiment")]
    [String] $AWSCredentialProfile,
    
    # Parameter help description
    [Parameter(Mandatory=$false, ParameterSetName="ExplicitWordlists")]
    [Parameter(Mandatory=$false, ParameterSetName="AllWordlists")]
    [Parameter(Mandatory=$false, ParameterSetName="BySentiment")]
    [Int] $AWSBatchRequestLimit = 10,

    # Parameter help description
    [Parameter(Mandatory=$false, ParameterSetName="ExplicitWordlists")]
    [Parameter(Mandatory=$false, ParameterSetName="AllWordlists")]
    [Parameter(Mandatory=$false, ParameterSetName="BySentiment")]
    [String] $AWSLanguageCode = 'en'

)

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
