# Run inside workspace-smoke's isolated HTTP server and temporary database.
$account = Request 'POST' '/api/v1/auth/register' @{ email = 'cycle-probe@smoke.example'; password = 'SmokePassword123!'; displayName = 'Cycle probe' } -Expected 201
$token = $account.accessToken
$profilePath = '/api/v1/cycles/profile'
$listPath = '/api/v1/cycles/me'
$historyPath = '/api/v1/cycles/history'
$periodsPath = '/api/v1/cycles/periods'
$profile = @{ trackingEnabled = $true; visibility = 'private'; averageCycleLength = 28; averagePeriodLength = 5 }
$null = Request 'PUT' $profilePath $profile $token
$start = [DateTime]::UtcNow.Date.AddDays(-60)
$original = @{ startDate = $start.ToString('yyyy-MM-dd'); endDate = $start.AddDays(4).ToString('yyyy-MM-dd'); flowLevel = 'medium'; painLevel = 2; notes = 'Original private note' }
$created = Request 'POST' $periodsPath $original $token 201
$period = $created.periods[0]
$path = "$periodsPath/$($period.id)"
Assert-True (-not [string]::IsNullOrWhiteSpace($period.version)) 'Every created period has an observable version'

# F1: two devices open the same version; B's full form still contains old notes.
$deviceA = $original.Clone(); $deviceA.notes = 'New private note written on device A'; $deviceA.expectedVersion = $period.version
$null = Request 'PUT' $path $deviceA $token
$deviceB = $original.Clone(); $deviceB.flowLevel = 'heavy'; $deviceB.expectedVersion = $period.version
$conflict = Request 'PUT' $path $deviceB $token 409
$null = Request 'DELETE' $path -Token $token -Expected 409 -Version $period.version
$null = Request 'PUT' $path $original $token 409
$null = Request 'DELETE' $path -Token $token -Expected 409
$latest = (Request 'GET' $listPath -Token $token).periods[0]
Assert-True ($conflict.code -eq 'cycle_period_changed' -and $latest.notes -eq $deviceA.notes -and $latest.flowLevel -eq $original.flowLevel -and $latest.version -ne $period.version) 'Stale and unversioned period edits/deletes cannot overwrite the winning edit'
$deviceA.expectedVersion = $latest.version
Assert-ConcurrentUpdate $path $deviceA $token $token
$latest = (Request 'GET' $listPath -Token $token).periods[0]

# F2: move an existing start date, then remove the corrected entry.
$corrected = $deviceA.Clone()
$corrected.expectedVersion = $latest.version
$corrected.startDate = $start.AddDays(-1).ToString('yyyy-MM-dd')
$corrected.endDate = $start.AddDays(3).ToString('yyyy-MM-dd')
$afterCorrection = Request 'PUT' $path $corrected $token
$history = @(Request 'GET' $historyPath -Token $token)
Assert-True ($history.Count -gt 0 -and @($history | Where-Object anchorStart -eq $corrected.startDate).Count -gt 0 -and @($history | Where-Object anchorStart -eq $original.startDate).Count -eq 0) 'Correcting a period removes old anchors while retaining the corrected prediction'
$null = Request 'DELETE' $path -Token $token -Expected 204 -Version $afterCorrection.periods[0].version
$empty = Request 'GET' $listPath -Token $token
$history = @(Request 'GET' $historyPath -Token $token)
Assert-True (@($empty.periods).Count -eq 0 -and $null -eq $empty.prediction -and $history.Count -eq 0) 'Deleting the corrected period clears both its current prediction and its history'

# F3: leave a stale tracking confirmation open while another device changes lengths.
$settings = $profile.Clone(); $settings.settingsOnly = $true; $settings.averageCycleLength = 35; $settings.averagePeriodLength = 6
$null = Request 'PUT' $profilePath $settings $token
$legacyToggle = $profile.Clone(); $legacyToggle.trackingEnabled = $false
$disabled = Request 'PUT' $profilePath $legacyToggle $token
Assert-True (-not $disabled.trackingEnabled -and $disabled.averageCycleLength -eq 35 -and $disabled.averagePeriodLength -eq 6) 'Original full-form disable cannot reset newer length settings'
foreach ($enabled in @($true, $false, $false, $true)) {
    $toggled = Request 'PUT' $profilePath @{ trackingOnly = $true; trackingEnabled = $enabled } $token
    if ($toggled.trackingEnabled -ne $enabled -or $toggled.visibility -ne 'private' -or $toggled.averageCycleLength -ne 35 -or $toggled.averagePeriodLength -ne 6) {
        throw 'A tracking-only toggle changed length settings or restored sharing.'
    }
}
Assert-True $true 'Enabling, disabling and retrying tracking preserves the latest lengths and private visibility'
