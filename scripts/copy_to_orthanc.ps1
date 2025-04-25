<#
.SYNOPSIS
  NMPACS to ORTHANC study copy script (debug output enabled)
.DESCRIPTION
  Query PT modality studies within a date range and perform C-MOVE from remote (NMPACS) to local (ORTHANC), printing debug messages.
#>

# Variables
$AETLocal  = "ORTHANC"
$AETRemote = "NMPACS"
$DicomHost = "172.17.111.214"
$Port      = 104
$DateRange = "20250103-20250103"
$Modality  = "NM"

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
