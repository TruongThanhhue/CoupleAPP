param(
    [string]$PsqlPath = 'C:\Program Files\PostgreSQL\17\bin\psql.exe',
    [string]$DatabaseHost = 'localhost',
    [int]$DatabasePort = 5432,
    [string]$DatabaseUser = 'postgres'
)

# Creates and removes only its own randomly named database. Never uses couple_app.
# Build the solution before running. PGPASSWORD may be supplied when trust is disabled.
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Net.Http
$repoRoot = Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$apiDll = Join-Path $repoRoot 'backend\CoupleApp.API\bin\Debug\net9.0\CoupleApp.API.dll'
if (-not (Test-Path -LiteralPath $apiDll)) { throw 'Build backend/CoupleApp.sln first.' }
if (-not (Test-Path -LiteralPath $PsqlPath)) { throw "psql was not found at $PsqlPath" }
$databaseName = 'couple_app_test_' + [Guid]::NewGuid().ToString('N')
$logDirectory = Join-Path ([IO.Path]::GetTempPath()) $databaseName
New-Item -ItemType Directory -Path $logDirectory | Out-Null
$listener = [Net.Sockets.TcpListener]::new([Net.IPAddress]::Loopback, 0)
$listener.Start()
$port = $listener.LocalEndpoint.Port
$listener.Stop()
$baseUrl = "http://127.0.0.1:$port"
$client = [Net.Http.HttpClient]::new()
$client.Timeout = [TimeSpan]::FromSeconds(10)
$createdDatabase = $false
$apiProcess = $null
$script:checks = 0
$savedEnvironment = @{}
$environmentKeys = @('ASPNETCORE_ENVIRONMENT', 'ConnectionStrings__CoupleDb', 'Jwt__Key', 'Jwt__Issuer', 'Jwt__Audience')
foreach ($key in $environmentKeys) { $savedEnvironment[$key] = [Environment]::GetEnvironmentVariable($key, 'Process') }

function Assert-True([bool]$Condition, [string]$Label) {
    if (-not $Condition) { throw "FAIL: $Label" }
    $script:checks++
    Write-Output "PASS: $Label"
}

function Request([string]$Method, [string]$Path, $Body = $null, [string]$Token = '', [int]$Expected = 200, [string]$Version = '') {
    if ($Version) { $Path += '?expectedVersion=' + [Uri]::EscapeDataString($Version) }
    $request = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::new($Method), "$baseUrl$Path")
    if ($Token) { $request.Headers.Authorization = [Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $Token) }
    if ($null -ne $Body) {
        $request.Content = [Net.Http.StringContent]::new(($Body | ConvertTo-Json -Depth 10 -Compress), [Text.Encoding]::UTF8, 'application/json')
    }
    try {
        $response = $client.SendAsync($request).GetAwaiter().GetResult()
        try {
            $text = $response.Content.ReadAsStringAsync().GetAwaiter().GetResult()
            if ([int]$response.StatusCode -ne $Expected) {
                throw "$Method $Path expected $Expected, received $([int]$response.StatusCode): $text"
            }
            if ($text) { return ($text | ConvertFrom-Json) }
        } finally { $response.Dispose() }
    } finally { $request.Dispose() }
}

function Start-TestApi {
    $script:apiProcess = Start-Process -FilePath (Get-Command dotnet).Source -ArgumentList @('"' + $apiDll + '"', '--urls', $baseUrl) -WorkingDirectory (Split-Path $apiDll -Parent) -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $logDirectory 'api.stdout.log') -RedirectStandardError (Join-Path $logDirectory 'api.stderr.log')
    for ($attempt = 0; $attempt -lt 80; $attempt++) {
        if ($script:apiProcess.HasExited) {
            throw ('API exited: ' + (Get-Content -LiteralPath (Join-Path $logDirectory 'api.stderr.log') -Raw))
        }
        try { $null = Request 'GET' '/health'; return } catch { Start-Sleep -Milliseconds 250 }
    }
    throw "API did not start. See $logDirectory"
}

function Stop-TestApi {
    if ($script:apiProcess -and -not $script:apiProcess.HasExited) {
        $script:apiProcess.Kill()
        $script:apiProcess.WaitForExit()
    }
    $script:apiProcess = $null
}

function Execute-TestSql([string]$Sql) {
    $Sql | & $PsqlPath -h $DatabaseHost -p $DatabasePort -U $DatabaseUser -w -d $databaseName -v ON_ERROR_STOP=1 -f - | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Test database SQL failed.' }
}

function Assert-ConcurrentUpdate([string]$Path, $Body, [string]$FirstToken, [string]$SecondToken) {
    $requests = @()
    $responses = @()
    try {
        foreach ($token in @($FirstToken, $SecondToken)) {
            $request = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Put, "$baseUrl$Path")
            $request.Headers.Authorization = [Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $token)
            $request.Content = [Net.Http.StringContent]::new(($Body | ConvertTo-Json), [Text.Encoding]::UTF8, 'application/json')
            $requests += $request
        }
        $first = $client.SendAsync($requests[0])
        $second = $client.SendAsync($requests[1])
        $responses += $first.GetAwaiter().GetResult()
        $responses += $second.GetAwaiter().GetResult()
        $statuses = @($responses | ForEach-Object { [int]$_.StatusCode } | Sort-Object)
        Assert-True ($statuses[0] -eq 200 -and $statuses[1] -eq 409) "Simultaneous edits to $Path accept exactly one observed version"
    } finally {
        foreach ($response in $responses) { $response.Dispose() }
        foreach ($request in $requests) { $request.Dispose() }
    }
}

try {
    & $PsqlPath -h $DatabaseHost -p $DatabasePort -U $DatabaseUser -w -d postgres -v ON_ERROR_STOP=1 -c "CREATE DATABASE $databaseName" | Out-Null
    if ($LASTEXITCODE -ne 0) { throw 'Could not create isolated test database.' }
    $createdDatabase = $true
    $env:ASPNETCORE_ENVIRONMENT = 'Development'
    $env:ConnectionStrings__CoupleDb = "Host=$DatabaseHost;Port=$DatabasePort;Database=$databaseName;Username=$DatabaseUser"
    if ($env:PGPASSWORD) { $env:ConnectionStrings__CoupleDb += ";Password=$env:PGPASSWORD" }
    $env:Jwt__Key = [Guid]::NewGuid().ToString('N') + [Guid]::NewGuid().ToString('N')
    $env:Jwt__Issuer = 'CoupleAppSmoke'
    $env:Jwt__Audience = 'CoupleAppSmoke'
    Start-TestApi

    foreach ($path in @('/api/v1/tasks', '/api/v1/events', '/api/v1/home', '/api/v1/cycles/me', '/api/v1/cycles/partner', '/api/v1/cycles/history')) {
        $null = Request 'GET' $path -Expected 401
    }
    Assert-True $true 'Workspace endpoints require authentication'
    $a = Request 'POST' '/api/v1/auth/register' @{ email = 'a@smoke.example'; password = 'SmokePassword123!'; displayName = 'A' } -Expected 201
    $b = Request 'POST' '/api/v1/auth/register' @{ email = 'b@smoke.example'; password = 'SmokePassword123!'; displayName = 'B' } -Expected 201
    $c = Request 'POST' '/api/v1/auth/register' @{ email = 'c@smoke.example'; password = 'SmokePassword123!'; displayName = 'C' } -Expected 201

    # Emulate the old EnsureCreated schema with existing accounts, then verify additive upgrade.
    Stop-TestApi
    Execute-TestSql 'DROP TABLE cycle_predictions; DROP TABLE period_entries; DROP TABLE cycle_profiles; DROP TABLE workspace_tasks; DROP TABLE calendar_events;'
    Execute-TestSql (Get-Content (Join-Path $repoRoot 'backend/CoupleApp.API/Data/Migrations/001_workspace.sql') -Raw)
    Execute-TestSql (Get-Content (Join-Path $repoRoot 'backend/CoupleApp.API/Data/Migrations/002_cycles.sql') -Raw)
    Execute-TestSql @'
INSERT INTO workspace_tasks ("Id", "OwnerId", "Title", "IsComplete", "Priority", "CreatedAt", "UpdatedAt")
SELECT '11111111-1111-1111-1111-111111111111', "Id", 'Legacy task', false, 'normal', now(), now()
FROM users WHERE "Email" = 'a@smoke.example';
INSERT INTO cycle_profiles ("UserId", "TrackingEnabled", "Visibility", "AverageCycleLength", "AveragePeriodLength", "CreatedAt", "UpdatedAt")
SELECT "Id", true, 0, 28, 5, now(), now() FROM users WHERE "Email" = 'c@smoke.example';
INSERT INTO period_entries ("Id", "UserId", "StartDate", "FlowLevel", "Notes", "CreatedAt", "UpdatedAt")
SELECT gen_random_uuid(), "UserId", DATE '2020-01-01', 'medium', 'Preserve legacy note', now(), now() FROM cycle_profiles;
INSERT INTO cycle_predictions ("Id", "UserId", "AnchorStart", "ExpectedStart", "EarliestStart", "LatestStart", "Basis", "IntervalCount", "AlgorithmVersion", "GeneratedAt")
SELECT gen_random_uuid(), "UserId", anchor, anchor + 28, anchor + 28, anchor + 28, 'profile', 0, 'legacy', now()
FROM cycle_profiles CROSS JOIN (VALUES (DATE '2020-01-01'), (DATE '2019-12-31')) AS sample(anchor);
'@
    Start-TestApi
    $legacyCycle = Request 'GET' '/api/v1/cycles/me' -Token $c.accessToken
    $legacyHistory = @(Request 'GET' '/api/v1/cycles/history' -Token $c.accessToken)
    Assert-True ($legacyCycle.periods.Count -eq 1 -and $legacyCycle.periods[0].notes -eq 'Preserve legacy note' -and $legacyCycle.periods[0].version) 'Cycle upgrade preserves legacy periods and gives them an edit version'
    Assert-True ($legacyHistory.Count -eq 1 -and $legacyHistory[0].anchorStart -eq '2020-01-01') 'Cycle upgrade removes only orphan prediction anchors and retains valid history'
    $userProfile = Request 'GET' '/api/v1/couples/me' -Token $a.accessToken
    $null = Request 'GET' '/api/v1/tasks' -Token $a.accessToken
    $null = Request 'GET' '/api/v1/events' -Token $a.accessToken
    Assert-True ($userProfile.displayName -eq 'A') 'Additive schema upgrade preserves existing accounts'
    $legacy = @(Request 'GET' '/api/v1/tasks' -Token $a.accessToken)[0]
    Assert-True ($legacy.title -eq 'Legacy task' -and $legacy.assignedTo -eq 'unassigned' -and $legacy.version -eq [Guid]::Empty.ToString()) 'Assignment/version migration preserves legacy workspace rows'
    $null = Request 'DELETE' "/api/v1/tasks/$($legacy.id)" -Token $a.accessToken -Expected 204 -Version $legacy.version
    $cycle = Request 'GET' '/api/v1/cycles/me' -Token $a.accessToken
    Assert-True (-not $cycle.trackingEnabled -and $cycle.visibility -eq 'private' -and $cycle.averageCycleLength -eq 28 -and $cycle.averagePeriodLength -eq 5 -and @($cycle.periods).Count -eq 0 -and $null -eq $cycle.prediction) 'Cycle defaults are disabled and private after additive schema upgrade'
    $null = Request 'GET' '/api/v1/cycles/partner' -Token $a.accessToken -Expected 404
    $cycleProfile = @{ trackingEnabled = $true; visibility = 'private'; averageCycleLength = 28; averagePeriodLength = 5 }
    $settings = $cycleProfile.Clone(); $settings.settingsOnly = $true
    $null = Request 'PUT' '/api/v1/cycles/profile' $settings $a.accessToken 409
    $cycleToday = [DateTime]::UtcNow.Date
    $firstStart = $cycleToday.AddDays(-90)
    $period = @{ startDate = $firstStart.ToString('yyyy-MM-dd'); endDate = $firstStart.AddDays(4).ToString('yyyy-MM-dd'); flowLevel = 'medium'; painLevel = 3; notes = '  Private cycle note  ' }
    $null = Request 'POST' '/api/v1/cycles/periods' $period $a.accessToken 409
    $invalidProfile = $cycleProfile.Clone(); $invalidProfile.averageCycleLength = 0
    $null = Request 'PUT' '/api/v1/cycles/profile' $invalidProfile $a.accessToken 400
    $invalidProfile = $cycleProfile.Clone(); $invalidProfile.averagePeriodLength = 29
    $null = Request 'PUT' '/api/v1/cycles/profile' $invalidProfile $a.accessToken 400
    $invalidProfile = $cycleProfile.Clone(); $invalidProfile.visibility = 'public'
    $null = Request 'PUT' '/api/v1/cycles/profile' $invalidProfile $a.accessToken 400
    $invalidProfile.visibility = 'partner'; $invalidProfile.expectedPartnerCode = $b.user.partnerCode
    $null = Request 'PUT' '/api/v1/cycles/profile' $invalidProfile $a.accessToken 409
    Assert-True $true 'Cycle profile validates settings and requires a connected recipient'
    $cycle = Request 'PUT' '/api/v1/cycles/profile' $cycleProfile $a.accessToken
    Assert-True ($cycle.trackingEnabled -and $cycle.visibility -eq 'private' -and $null -eq $cycle.prediction) 'Cycle tracking can be enabled privately'
    $cycle = Request 'POST' '/api/v1/cycles/periods' $period $a.accessToken 201
    $firstPeriodId = $cycle.periods[0].id
    $firstPeriodVersion = $cycle.periods[0].version
    Assert-True (@($cycle.periods).Count -eq 1 -and $cycle.periods[0].notes -eq 'Private cycle note' -and $cycle.prediction.basis -eq 'profile' -and $cycle.prediction.expectedStart -eq $firstStart.AddDays(28).ToString('yyyy-MM-dd')) 'Cycle record persists and initial prediction uses configured length'
    $null = Request 'POST' '/api/v1/cycles/periods' $period $a.accessToken 409
    $invalidPeriod = $period.Clone(); $invalidPeriod.startDate = $firstStart.AddDays(2).ToString('yyyy-MM-dd')
    $null = Request 'POST' '/api/v1/cycles/periods' $invalidPeriod $a.accessToken 409
    $invalidPeriod = $period.Clone(); $invalidPeriod.endDate = $firstStart.AddDays(-1).ToString('yyyy-MM-dd')
    $null = Request 'POST' '/api/v1/cycles/periods' $invalidPeriod $a.accessToken 400
    $invalidPeriod = $period.Clone(); $invalidPeriod.startDate = $cycleToday.AddDays(3).ToString('yyyy-MM-dd'); $invalidPeriod.endDate = $null
    $null = Request 'POST' '/api/v1/cycles/periods' $invalidPeriod $a.accessToken 400
    $invalidPeriod = $period.Clone(); $invalidPeriod.startDate = '1999-12-31'; $invalidPeriod.endDate = $null
    $null = Request 'POST' '/api/v1/cycles/periods' $invalidPeriod $a.accessToken 400
    $invalidPeriod = $period.Clone(); $invalidPeriod.flowLevel = 'invalid'; $invalidPeriod.painLevel = 11; $invalidPeriod.notes = 'x' * 2001
    $null = Request 'POST' '/api/v1/cycles/periods' $invalidPeriod $a.accessToken 400
    Assert-True $true 'Cycle rejects duplicate, overlapping, reversed, future and invalid records'
    $period.startDate = $firstStart.AddDays(26).ToString('yyyy-MM-dd'); $period.endDate = $null
    $cycle = Request 'POST' '/api/v1/cycles/periods' $period $a.accessToken 201
    $secondPeriodId = $cycle.periods[0].id
    $laterPeriod = $period.Clone(); $laterPeriod.startDate = $firstStart.AddDays(56).ToString('yyyy-MM-dd')
    $null = Request 'POST' '/api/v1/cycles/periods' $laterPeriod $a.accessToken 409
    Assert-True $true 'Ongoing period blocks later records until it is ended'
    $period.endDate = $firstStart.AddDays(30).ToString('yyyy-MM-dd'); $period.flowLevel = 'light'; $period.painLevel = 0
    $editPeriod = $period.Clone(); $editPeriod.expectedVersion = $cycle.periods[0].version
    $cycle = Request 'PUT' "/api/v1/cycles/periods/$secondPeriodId" $editPeriod $a.accessToken
    Assert-True ($cycle.periods[0].flowLevel -eq 'light' -and $cycle.periods[0].painLevel -eq 0) 'Owner can edit and end a recorded period'
    $laterPeriod.endDate = $firstStart.AddDays(60).ToString('yyyy-MM-dd')
    $cycle = Request 'POST' '/api/v1/cycles/periods' $laterPeriod $a.accessToken 201
    $thirdPeriodId = $cycle.periods[0].id
    $thirdPeriodVersion = $cycle.periods[0].version
    Assert-True ($cycle.prediction.expectedStart -eq $firstStart.AddDays(84).ToString('yyyy-MM-dd') -and $cycle.prediction.earliestStart -eq $firstStart.AddDays(82).ToString('yyyy-MM-dd') -and $cycle.prediction.latestStart -eq $firstStart.AddDays(86).ToString('yyyy-MM-dd') -and $cycle.prediction.intervalCount -eq 2 -and $cycle.prediction.basis -eq 'history') 'Cycle prediction uses actual mean and observed interval range'
    $historyBefore = @(Request 'GET' '/api/v1/cycles/history' -Token $a.accessToken)
    $null = Request 'GET' '/api/v1/cycles/me' -Token $a.accessToken
    $historyAfter = @(Request 'GET' '/api/v1/cycles/history' -Token $a.accessToken)
    Assert-True ($historyBefore.Count -eq 3 -and $historyAfter.Count -eq 3 -and $historyAfter[0].algorithmVersion -eq 'mean-last-six-v1' -and @($historyAfter | Where-Object { $null -ne $_.actualStart }).Count -eq 0) 'Prediction snapshots persist on mutations only and do not score retrospective entries'
    $null = Request 'PUT' '/api/v1/couples/me' @{ displayName = 'Not authorized' } -Expected 401
    $null = Request 'PUT' '/api/v1/couples/me' @{ displayName = ' ' } $a.accessToken 400
    $null = Request 'PUT' '/api/v1/couples/me' @{ displayName = ('x' * 81) } $a.accessToken 400
    $renamed = Request 'PUT' '/api/v1/couples/me' @{ displayName = '  Updated A  '; id = 'ignored' } $a.accessToken
    Assert-True ($renamed.displayName -eq 'Updated A' -and $renamed.partnerCode -eq $a.user.partnerCode) 'Profile edit trims name and preserves personal code'
    Assert-True ((Request 'GET' '/api/v1/couples/me' -Token $b.accessToken).displayName -eq 'B') 'Profile edit cannot change another account'

    $task = @{ title = 'Private task'; notes = 'Only A'; isComplete = $false; isShared = $false; priority = 'high'; dueAt = '2026-12-02T12:00:00+07:00'; assignedTo = 'owner' }
    $privateTask = Request 'POST' '/api/v1/tasks' $task $a.accessToken 201
    Assert-True ($privateTask.createdByMe -and -not $privateTask.isShared) 'Private task persists with owner metadata'
    Assert-True ([DateTimeOffset]::Parse($privateTask.dueAt).UtcDateTime.Hour -eq 5) 'Task due date normalizes offset to UTC'
    Assert-True ($privateTask.assignedTo -eq 'owner' -and $privateTask.assignedToMe) 'Owner can assign a private task to themselves'
    $invalidAssignment = $task.Clone(); $invalidAssignment.assignedTo = 'partner'
    $null = Request 'POST' '/api/v1/tasks' $invalidAssignment $a.accessToken 400
    $invalidAssignment.assignedTo = 'stranger'
    $null = Request 'POST' '/api/v1/tasks' $invalidAssignment $a.accessToken 400
    Assert-True $true 'Assignment rejects unknown recipients and never implicitly enables sharing'
    $task.isShared = $true
    $null = Request 'POST' '/api/v1/tasks' $task $a.accessToken 409
    Assert-True $true 'Cannot share before connecting a partner'
    $invite = Request 'POST' '/api/v1/couples/invites' @{ partnerCode = $b.user.partnerCode } $a.accessToken 201
    $null = Request 'POST' "/api/v1/couples/invites/$($invite.id)/accept" @{} $b.accessToken
    . (Join-Path $repoRoot 'backend/tests/shared-books.ps1')
    $null = Request 'GET' '/api/v1/cycles/partner' -Token $b.accessToken -Expected 404
    $cycleProfile.visibility = 'partner'
    $null = Request 'PUT' '/api/v1/cycles/profile' $cycleProfile $a.accessToken 409
    $cycleProfile.expectedPartnerCode = $c.user.partnerCode
    $null = Request 'PUT' '/api/v1/cycles/profile' $cycleProfile $a.accessToken 409
    $cycleProfile.expectedPartnerCode = $b.user.partnerCode
    $cycle = Request 'PUT' '/api/v1/cycles/profile' $cycleProfile $a.accessToken
    Assert-True ($cycle.visibility -eq 'partner') 'Sharing requires explicit confirmation of the current partner code'
    $partnerCycle = Request 'GET' '/api/v1/cycles/partner' -Token $b.accessToken
    Assert-True (@($partnerCycle.periods).Count -eq 3 -and @($partnerCycle.periods | Where-Object { $null -ne $_.notes }).Count -eq 0 -and $null -ne $partnerCycle.prediction) 'Partner can read shared cycle dates but notes are always redacted'
    $null = Request 'GET' '/api/v1/cycles/partner' -Token $c.accessToken -Expected 404
    $null = Request 'PUT' "/api/v1/cycles/periods/$firstPeriodId" $period $b.accessToken 404
    $null = Request 'DELETE' "/api/v1/cycles/periods/$firstPeriodId" -Token $b.accessToken -Expected 404
    Assert-True (@(Request 'GET' '/api/v1/cycles/history' -Token $b.accessToken).Count -eq 0) 'Cycle records and prediction history remain owner-only for writes and private history'
    $cycleProfile.visibility = 'private'
    $null = Request 'PUT' '/api/v1/cycles/profile' $cycleProfile $a.accessToken
    $null = Request 'GET' '/api/v1/cycles/partner' -Token $b.accessToken -Expected 404
    $cycleProfile.visibility = 'partner'; $cycleProfile.trackingEnabled = $false
    $cycle = Request 'PUT' '/api/v1/cycles/profile' $cycleProfile $a.accessToken
    Assert-True ($cycle.visibility -eq 'private' -and $null -eq $cycle.prediction -and @($cycle.periods).Count -eq 3) 'Disabling tracking clears sharing and prediction while retaining owner records'
    $settings = $cycleProfile.Clone(); $settings.trackingEnabled = $true; $settings.visibility = 'partner'; $settings.settingsOnly = $true; $settings.averageCycleLength = 30
    $cycle = Request 'PUT' '/api/v1/cycles/profile' $settings $a.accessToken
    Assert-True (-not $cycle.trackingEnabled -and $cycle.visibility -eq 'private' -and $cycle.averageCycleLength -eq 30) 'Stale settings-only edit preserves revoked consent and disabled tracking'
    $sharing = $cycleProfile.Clone(); $sharing.trackingEnabled = $true; $sharing.sharingOnly = $true
    $null = Request 'PUT' '/api/v1/cycles/profile' $sharing $a.accessToken 409
    $sharing.visibility = 'private'
    $null = Request 'PUT' '/api/v1/cycles/profile' $sharing $a.accessToken 409
    Assert-True (-not (Request 'GET' '/api/v1/cycles/me' -Token $a.accessToken).trackingEnabled) 'Stale sharing controls cannot re-enable tracking disabled on another device'
    $null = Request 'POST' '/api/v1/cycles/periods' $period $a.accessToken 409
    $disabledPeriodEdit = $period.Clone(); $disabledPeriodEdit.expectedVersion = $firstPeriodVersion
    $null = Request 'PUT' "/api/v1/cycles/periods/$firstPeriodId" $disabledPeriodEdit $a.accessToken 409
    $null = Request 'GET' '/api/v1/cycles/partner' -Token $b.accessToken -Expected 404
    $null = Request 'DELETE' "/api/v1/cycles/periods/$thirdPeriodId" -Token $a.accessToken -Expected 204 -Version $thirdPeriodVersion
    Assert-True (@((Request 'GET' '/api/v1/cycles/me' -Token $a.accessToken).periods).Count -eq 2) 'Owner can delete cycle records while tracking is disabled'
    $cycleProfile.trackingEnabled = $true; $cycleProfile.visibility = 'private'
    $cycle = Request 'PUT' '/api/v1/cycles/profile' $cycleProfile $a.accessToken
    $null = Request 'GET' '/api/v1/cycles/partner' -Token $b.accessToken -Expected 404
    Assert-True ($cycle.prediction.intervalCount -eq 1 -and $cycle.visibility -eq 'private') 'Re-enabling tracking does not restore old consent and recomputes after deletion'
    $cycleProfile.visibility = 'partner'
    $sharing = $cycleProfile.Clone(); $sharing.sharingOnly = $true; $sharing.averageCycleLength = 60
    $cycle = Request 'PUT' '/api/v1/cycles/profile' $sharing $a.accessToken
    Assert-True ($cycle.visibility -eq 'partner' -and $cycle.averageCycleLength -eq $settings.averageCycleLength) 'Sharing-only edit preserves current length settings'
    $task.assignedTo = 'partner'
    $task.expectedPartnerCode = $b.user.partnerCode
    $sharedTask = Request 'POST' '/api/v1/tasks' $task $a.accessToken 201
    $bTasks = @(Request 'GET' '/api/v1/tasks' -Token $b.accessToken)
    Assert-True ($bTasks.Count -eq 1 -and $bTasks[0].id -eq $sharedTask.id -and -not $bTasks[0].createdByMe) 'Partner sees shared task but not private task'
    Assert-True ($sharedTask.assignedTo -eq 'partner' -and -not $sharedTask.assignedToMe -and $bTasks[0].assignedToMe) 'Assignment is displayed relative to the signed-in viewer'
    $probe = $task.Clone(); $probe.title = 'Assignment probe'
    $probeSaved = Request 'POST' '/api/v1/tasks' $probe $a.accessToken 201
    $probe.expectedVersion = $probeSaved.version; $probe.isShared = $false; $probe.assignedTo = 'unassigned'
    $probeSaved = Request 'PUT' "/api/v1/tasks/$($probeSaved.id)" $probe $a.accessToken
    Assert-True (-not $probeSaved.isShared -and $probeSaved.assignedTo -eq 'unassigned') 'Unsharing removes the previous partner assignment'
    $null = Request 'DELETE' "/api/v1/tasks/$($probeSaved.id)" -Token $a.accessToken -Expected 204 -Version $probeSaved.version
    $null = Request 'PUT' "/api/v1/tasks/$($privateTask.id)" $task $b.accessToken 404
    $null = Request 'DELETE' "/api/v1/tasks/$($sharedTask.id)" -Token $c.accessToken -Expected 404
    Assert-True $true 'Private and unrelated task mutations return 404'
    $task.isComplete = $true
    $null = Request 'PUT' "/api/v1/tasks/$($sharedTask.id)" $task $b.accessToken 428
    $task.expectedVersion = $sharedTask.version
    $reassign = $task.Clone(); $reassign.assignedTo = 'owner'
    $null = Request 'PUT' "/api/v1/tasks/$($sharedTask.id)" $reassign $b.accessToken 403
    Assert-True $true 'Partner cannot reassign a task and edits require an observed version'
    $updated = Request 'PUT' "/api/v1/tasks/$($sharedTask.id)" $task $b.accessToken
    Assert-True $updated.isComplete 'Partner can complete a shared task'
    $null = Request 'PUT' "/api/v1/tasks/$($sharedTask.id)" $task $a.accessToken 409
    $null = Request 'DELETE' "/api/v1/tasks/$($sharedTask.id)" -Token $a.accessToken -Version $sharedTask.version -Expected 409
    $null = Request 'DELETE' "/api/v1/tasks/$($sharedTask.id)" -Token $a.accessToken -Expected 428
    Assert-True ($updated.version -ne $sharedTask.version -and @(Request 'GET' '/api/v1/tasks' -Token $b.accessToken)[0].isComplete) 'Stale task edit/delete cannot overwrite or remove a newer completion'
    $task.expectedVersion = $updated.version
    Assert-ConcurrentUpdate "/api/v1/tasks/$($sharedTask.id)" $task $a.accessToken $b.accessToken
    $updated = @(Request 'GET' '/api/v1/tasks' -Token $b.accessToken)[0]
    $task.isShared = $false
    $task.assignedTo = 'unassigned'
    $null = Request 'PUT' "/api/v1/tasks/$($sharedTask.id)" $task $b.accessToken 403
    Assert-True $true 'Partner cannot change owner sharing settings'
    $task.title = ' '
    $null = Request 'POST' '/api/v1/tasks' $task $a.accessToken 400
    $task.title = 'Invalid priority'
    $task.priority = 'urgent'
    $null = Request 'POST' '/api/v1/tasks' $task $a.accessToken 400
    Assert-True $true 'Task title and priority validation reject bad input'

    $event = @{ title = 'Dinner'; notes = 'Shared'; location = 'Home'; startsAt = '2026-12-02T19:00:00+07:00'; endsAt = '2026-12-02T20:00:00+07:00'; isShared = $true; expectedPartnerCode = $b.user.partnerCode }
    $sharedEvent = Request 'POST' '/api/v1/events' $event $a.accessToken 201
    $event.isShared = $false
    $privateEvent = Request 'POST' '/api/v1/events' $event $a.accessToken 201
    $bEvents = @(Request 'GET' '/api/v1/events' -Token $b.accessToken)
    Assert-True ($bEvents.Count -eq 1 -and $bEvents[0].id -eq $sharedEvent.id) 'Partner sees only shared calendar event'
    $null = Request 'PUT' "/api/v1/events/$($sharedEvent.id)" $event $b.accessToken 403
    $null = Request 'DELETE' "/api/v1/events/$($privateEvent.id)" -Token $b.accessToken -Expected 404
    $event.isShared = $true
    $event.title = 'Updated dinner'
    $event.expectedVersion = $sharedEvent.version
    $updatedEvent = Request 'PUT' "/api/v1/events/$($sharedEvent.id)" $event $b.accessToken
    Assert-True ($updatedEvent.title -eq 'Updated dinner') 'Partner can edit shared event content'
    $null = Request 'PUT' "/api/v1/events/$($sharedEvent.id)" $event $a.accessToken 409
    $null = Request 'DELETE' "/api/v1/events/$($sharedEvent.id)" -Token $a.accessToken -Expected 409 -Version $sharedEvent.version
    $null = Request 'DELETE' "/api/v1/events/$($sharedEvent.id)" -Token $a.accessToken -Expected 428
    Assert-True ($updatedEvent.version -ne $sharedEvent.version) 'Stale event edit/delete cannot overwrite or remove a newer event'
    $event.expectedVersion = $updatedEvent.version
    Assert-ConcurrentUpdate "/api/v1/events/$($sharedEvent.id)" $event $a.accessToken $b.accessToken
    $updatedEvent = @(Request 'GET' '/api/v1/events' -Token $b.accessToken)[0]
    $event.endsAt = $event.startsAt
    $null = Request 'POST' '/api/v1/events' $event $a.accessToken 400
    Assert-True $true 'Calendar rejects empty or backwards intervals'

    $summary = Request 'GET' '/api/v1/home' -Token $b.accessToken
    Assert-True ($summary.totalTasks -eq 1 -and $summary.completedTasks -eq 1) 'Dashboard counts only accessible persisted tasks'
    Stop-TestApi
    Start-TestApi
    $persisted = @(Request 'GET' '/api/v1/tasks' -Token $a.accessToken)
    Assert-True ($persisted.Count -eq 2) 'Records survive API restart'
    $persistedCycle = Request 'GET' '/api/v1/cycles/me' -Token $a.accessToken
    $partnerCycle = Request 'GET' '/api/v1/cycles/partner' -Token $b.accessToken
    Assert-True (@($persistedCycle.periods).Count -eq 2 -and $persistedCycle.periods[0].notes -eq 'Private cycle note' -and @($partnerCycle.periods).Count -eq 2 -and @($partnerCycle.periods | Where-Object { $null -ne $_.notes }).Count -eq 0) 'Cycle records, explicit sharing and note redaction survive API restart'
    $null = Request 'DELETE' "/api/v1/events/$($sharedEvent.id)" -Token $b.accessToken -Expected 204 -Version $updatedEvent.version
    Assert-True (@(Request 'GET' '/api/v1/events' -Token $b.accessToken).Count -eq 0) 'Partner can delete shared event'

    $event.endsAt = '2026-12-02T20:00:00+07:00'
    $retainedEvent = Request 'POST' '/api/v1/events' $event $a.accessToken 201
    $bTask = Request 'POST' '/api/v1/tasks' @{ title = 'B owns this'; notes = ''; isComplete = $false; isShared = $true; priority = 'normal'; dueAt = $null; assignedTo = 'owner'; expectedPartnerCode = $a.user.partnerCode } $b.accessToken 201
    $null = Request 'POST' '/api/v1/couples/disconnect' @{ partnerCode = $b.user.partnerCode } -Expected 401
    $null = Request 'POST' '/api/v1/couples/disconnect' @{} $a.accessToken 400
    $null = Request 'POST' '/api/v1/couples/disconnect' @{ partnerCode = $c.user.partnerCode } $a.accessToken 409
    $disconnected = Request 'POST' '/api/v1/couples/disconnect' @{ partnerCode = $b.user.partnerCode } $a.accessToken
    $null = Request 'GET' $ledgerB -Token $b.accessToken -Expected 409
    Assert-True ($null -eq $disconnected.partner -and $null -eq (Request 'GET' '/api/v1/couples/me' -Token $b.accessToken).partner) 'Disconnect clears both partner links'
    $null = Request 'GET' '/api/v1/cycles/partner' -Token $b.accessToken -Expected 404
    $cycle = Request 'GET' '/api/v1/cycles/me' -Token $a.accessToken
    Assert-True ($cycle.visibility -eq 'private' -and @($cycle.periods).Count -eq 2) 'Disconnect atomically revokes cycle sharing and retains owner data'
    $null = Request 'POST' '/api/v1/couples/disconnect' @{ partnerCode = $b.user.partnerCode } $a.accessToken
    $ownedAfterDisconnect = @(Request 'GET' '/api/v1/tasks' -Token $a.accessToken)
    Assert-True ($ownedAfterDisconnect.Count -eq 2 -and @($ownedAfterDisconnect | Where-Object isShared).Count -eq 0) 'Disconnect retains owner tasks and clears sharing'
    $afterShared = $ownedAfterDisconnect | Where-Object id -eq $sharedTask.id
    Assert-True ($afterShared.assignedTo -eq 'unassigned' -and $afterShared.version -ne $updated.version) 'Disconnect clears former partner assignment and invalidates stale editors'
    $ownedEvents = @(Request 'GET' '/api/v1/events' -Token $a.accessToken)
    Assert-True ($ownedEvents.Count -eq 2 -and @($ownedEvents | Where-Object isShared).Count -eq 0) 'Disconnect retains owner events and clears sharing'
    Assert-True (@(Request 'GET' '/api/v1/tasks' -Token $b.accessToken).Count -eq 1) 'Other owner retains their own formerly shared task'
    $bOwnedAfter = @(Request 'GET' '/api/v1/tasks' -Token $b.accessToken)[0]
    Assert-True ($bOwnedAfter.assignedTo -eq 'owner' -and $bOwnedAfter.assignedToMe) 'Disconnect retains assignment to the task creator'
    $null = Request 'DELETE' "/api/v1/tasks/$($bTask.id)" -Token $b.accessToken -Expected 204 -Version $bOwnedAfter.version
    Assert-True (@(Request 'GET' '/api/v1/tasks' -Token $b.accessToken).Count -eq 0) 'Former partner loses shared-record access'
    $null = Request 'DELETE' "/api/v1/tasks/$($sharedTask.id)" -Token $b.accessToken -Expected 404
    $again = Request 'POST' '/api/v1/couples/invites' @{ partnerCode = $b.user.partnerCode } $a.accessToken 201
    $null = Request 'POST' "/api/v1/couples/invites/$($again.id)/accept" @{} $b.accessToken
    Assert-True ((Request 'GET' $ledgerB -Token $b.accessToken).items.Count -eq 0) 'Reconnect does not restore old shared expenses'
    Assert-True (@(Request 'GET' '/api/v1/tasks' -Token $b.accessToken).Count -eq 0 -and @(Request 'GET' '/api/v1/events' -Token $b.accessToken).Count -eq 0) 'Reconnecting same partner never restores old sharing'
    $null = Request 'GET' '/api/v1/cycles/partner' -Token $b.accessToken -Expected 404
    Assert-True ((Request 'GET' '/api/v1/cycles/me' -Token $a.accessToken).visibility -eq 'private') 'Reconnecting same partner never restores cycle consent'
    $null = Request 'POST' '/api/v1/couples/disconnect' @{ partnerCode = $b.user.partnerCode } $a.accessToken
    $newInvite = Request 'POST' '/api/v1/couples/invites' @{ partnerCode = $c.user.partnerCode } $a.accessToken 201
    $null = Request 'POST' "/api/v1/couples/invites/$($newInvite.id)/accept" @{} $c.accessToken
    Assert-True (@(Request 'GET' '/api/v1/tasks' -Token $c.accessToken).Count -eq 0) 'New partner never inherits old shared records'
    $null = Request 'GET' '/api/v1/cycles/partner' -Token $c.accessToken -Expected 404
    $null = Request 'PUT' '/api/v1/cycles/profile' $cycleProfile $a.accessToken 409
    Assert-True $true 'New partner cannot inherit cycle sharing or accept stale consent for previous partner'
    $null = Request 'POST' '/api/v1/couples/disconnect' @{ partnerCode = $b.user.partnerCode } $a.accessToken 409
    Assert-True ((Request 'GET' '/api/v1/couples/me' -Token $a.accessToken).partner.partnerCode -eq $c.user.partnerCode) 'Stale disconnect cannot remove a different partner'
    $staleRecipient = @{ title = 'Stale recipient'; isShared = $true; isComplete = $false; priority = 'normal'; assignedTo = 'partner'; expectedPartnerCode = $b.user.partnerCode }
    $null = Request 'POST' '/api/v1/tasks' $staleRecipient $a.accessToken 409
    $null = Request 'POST' '/api/v1/events' $event $a.accessToken 409
    Assert-True $true 'Stale partner confirmations cannot transfer a new shared task or event to another partner'

    # Run a shared write concurrently with disconnect: either it commits first and is
    # made private, or it observes disconnection and is rejected. No late re-sharing.
    $raceWrite = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Post, "$baseUrl/api/v1/tasks")
    $raceDisconnect = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Post, "$baseUrl/api/v1/couples/disconnect")
    $raceWrite.Headers.Authorization = [Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $a.accessToken)
    $raceDisconnect.Headers.Authorization = [Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $a.accessToken)
    $raceWrite.Content = [Net.Http.StringContent]::new((@{ title = 'Concurrent task'; isComplete = $false; isShared = $true; priority = 'normal'; expectedPartnerCode = $c.user.partnerCode } | ConvertTo-Json), [Text.Encoding]::UTF8, 'application/json')
    $raceDisconnect.Content = [Net.Http.StringContent]::new((@{ partnerCode = $c.user.partnerCode } | ConvertTo-Json), [Text.Encoding]::UTF8, 'application/json')
    try {
        $writePending = $client.SendAsync($raceWrite)
        $disconnectPending = $client.SendAsync($raceDisconnect)
        $writeResult = $writePending.GetAwaiter().GetResult()
        $disconnectResult = $disconnectPending.GetAwaiter().GetResult()
        try {
            Assert-True ([int]$writeResult.StatusCode -in @(201, 409) -and [int]$disconnectResult.StatusCode -eq 200) 'Concurrent shared write and disconnect resolve safely'
            $afterRace = @(Request 'GET' '/api/v1/tasks' -Token $a.accessToken)
            Assert-True (@($afterRace | Where-Object isShared).Count -eq 0) 'No racing write can restore sharing after disconnect'
            foreach ($raceTask in @($afterRace | Where-Object title -eq 'Concurrent task')) {
                $null = Request 'DELETE' "/api/v1/tasks/$($raceTask.id)" -Token $a.accessToken -Expected 204 -Version $raceTask.version
            }
        } finally { $writeResult.Dispose(); $disconnectResult.Dispose() }
    } finally { $raceWrite.Dispose(); $raceDisconnect.Dispose() }
    foreach ($remaining in @(Request 'GET' '/api/v1/tasks' -Token $a.accessToken)) {
        $null = Request 'DELETE' "/api/v1/tasks/$($remaining.id)" -Token $a.accessToken -Expected 204 -Version $remaining.version
    }
    foreach ($remaining in @(Request 'GET' '/api/v1/events' -Token $a.accessToken)) {
        $null = Request 'DELETE' "/api/v1/events/$($remaining.id)" -Token $a.accessToken -Expected 204 -Version $remaining.version
    }
    Assert-True (@(Request 'GET' '/api/v1/tasks' -Token $a.accessToken).Count -eq 0) 'Owner can delete remaining records'
    . (Join-Path $repoRoot 'backend/tests/cycle-regressions.ps1')
    Write-Output "Workspace smoke: $script:checks checks passed. Logs: $logDirectory"
} finally {
    Stop-TestApi
    $client.Dispose()
    foreach ($key in $environmentKeys) { [Environment]::SetEnvironmentVariable($key, $savedEnvironment[$key], 'Process') }
    if ($createdDatabase -and $databaseName -match '^couple_app_test_[a-f0-9]{32}$') {
        & $PsqlPath -h $DatabaseHost -p $DatabasePort -U $DatabaseUser -w -d postgres -v ON_ERROR_STOP=1 -c "DROP DATABASE $databaseName WITH (FORCE)" | Out-Null
        if ($LASTEXITCODE -ne 0) { Write-Warning "Test database cleanup failed: $databaseName" }
        else { Write-Output "Removed isolated test database $databaseName; original databases were untouched." }
    }
}
