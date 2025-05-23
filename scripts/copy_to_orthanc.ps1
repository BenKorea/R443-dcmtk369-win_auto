$config = Get-Content "$PSScriptRoot\config\config.json" | ConvertFrom-Json

$AETLocal  = $config.NMPACS.CallingAET
$AETRemote = $config.NMPACS.AET
$DicomHost = $config.NMPACS.Host
$Port      = $config.NMPACS.Port
$DateRange = $config.Transfer.DateRange
$Modality  = $config.Transfer.Modality


# Start message
Write-Host "Script started for date range $DateRange and modality $Modality" -ForegroundColor Cyan

# 1) Query UIDs on NMPACS
Write-Host "Querying studies on NMPACS..." -ForegroundColor Yellow

$uids = @(
    & findscu -v -S -aet $AETLocal -aec $AETRemote $DicomHost $Port -k QueryRetrieveLevel=STUDY -k StudyDate=$DateRange -k ModalitiesInStudy=$Modality -k StudyInstanceUID 2>&1 |
    Select-String 'StudyInstanceUID' |
    ForEach-Object {
        if ($_ -match 'UI \[([^\]]+)\]') { $matches[1] }
    }
)

Write-Host "Query completed: found $($uids.Count) UIDs" -ForegroundColor Green

if ($uids.Count -eq 0) {
    Write-Host "No studies to synchronize. Exiting script." -ForegroundColor Magenta
    return
}

# 2) Execute C-MOVE for each UID
Write-Host "Starting C-MOVE operations..." -ForegroundColor Yellow

foreach ($uid in $uids) {
    Write-Host "Moving study UID: $uid" -ForegroundColor Yellow

    movescu -v -S -aet $AETLocal -aec $AETRemote -aem $AETLocal $DicomHost $Port -k QueryRetrieveLevel=STUDY -k StudyInstanceUID=$uid

    Write-Host "Completed move for UID: $uid" -ForegroundColor Green
    Write-Host ""
}

Write-Host "All C-MOVE requests completed." -ForegroundColor Cyan
