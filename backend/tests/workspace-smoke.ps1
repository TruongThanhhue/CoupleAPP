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

function Request([string]$Method, [string]$Path, $Body = $null, [string]$Token = '', [int]$Expected = 200) {
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

    foreach ($path in @('/api/v1/tasks', '/api/v1/events', '/api/v1/home')) {
        $null = Request 'GET' $path -Expected 401
    }
    Assert-True $true 'Workspace endpoints require authentication'
    $a = Request 'POST' '/api/v1/auth/register' @{ email = 'a@smoke.example'; password = 'SmokePassword123!'; displayName = 'A' } -Expected 201
    $b = Request 'POST' '/api/v1/auth/register' @{ email = 'b@smoke.example'; password = 'SmokePassword123!'; displayName = 'B' } -Expected 201
    $c = Request 'POST' '/api/v1/auth/register' @{ email = 'c@smoke.example'; password = 'SmokePassword123!'; displayName = 'C' } -Expected 201

    # Emulate the old EnsureCreated schema with existing accounts, then verify additive upgrade.
    Stop-TestApi
    Execute-TestSql 'DROP TABLE workspace_tasks; DROP TABLE calendar_events;'
    Start-TestApi
    $userProfile = Request 'GET' '/api/v1/couples/me' -Token $a.accessToken
    $null = Request 'GET' '/api/v1/tasks' -Token $a.accessToken
    $null = Request 'GET' '/api/v1/events' -Token $a.accessToken
    Assert-True ($userProfile.displayName -eq 'A') 'Additive schema upgrade preserves existing accounts'
    $null = Request 'PUT' '/api/v1/couples/me' @{ displayName = 'Not authorized' } -Expected 401
    $null = Request 'PUT' '/api/v1/couples/me' @{ displayName = ' ' } $a.accessToken 400
    $null = Request 'PUT' '/api/v1/couples/me' @{ displayName = ('x' * 81) } $a.accessToken 400
    $renamed = Request 'PUT' '/api/v1/couples/me' @{ displayName = '  Updated A  '; id = 'ignored' } $a.accessToken
    Assert-True ($renamed.displayName -eq 'Updated A' -and $renamed.partnerCode -eq $a.user.partnerCode) 'Profile edit trims name and preserves personal code'
    Assert-True ((Request 'GET' '/api/v1/couples/me' -Token $b.accessToken).displayName -eq 'B') 'Profile edit cannot change another account'

    $task = @{ title = 'Private task'; notes = 'Only A'; isComplete = $false; isShared = $false; priority = 'high'; dueAt = '2026-12-02T12:00:00+07:00' }
    $privateTask = Request 'POST' '/api/v1/tasks' $task $a.accessToken 201
    Assert-True ($privateTask.createdByMe -and -not $privateTask.isShared) 'Private task persists with owner metadata'
    Assert-True ([DateTimeOffset]::Parse($privateTask.dueAt).UtcDateTime.Hour -eq 5) 'Task due date normalizes offset to UTC'
    $task.isShared = $true
    $null = Request 'POST' '/api/v1/tasks' $task $a.accessToken 409
    Assert-True $true 'Cannot share before connecting a partner'
    $invite = Request 'POST' '/api/v1/couples/invites' @{ partnerCode = $b.user.partnerCode } $a.accessToken 201
    $null = Request 'POST' "/api/v1/couples/invites/$($invite.id)/accept" @{} $b.accessToken
    $sharedTask = Request 'POST' '/api/v1/tasks' $task $a.accessToken 201
    $bTasks = @(Request 'GET' '/api/v1/tasks' -Token $b.accessToken)
    Assert-True ($bTasks.Count -eq 1 -and $bTasks[0].id -eq $sharedTask.id -and -not $bTasks[0].createdByMe) 'Partner sees shared task but not private task'
    $null = Request 'PUT' "/api/v1/tasks/$($privateTask.id)" $task $b.accessToken 404
    $null = Request 'DELETE' "/api/v1/tasks/$($sharedTask.id)" -Token $c.accessToken -Expected 404
    Assert-True $true 'Private and unrelated task mutations return 404'
    $task.isComplete = $true
    $updated = Request 'PUT' "/api/v1/tasks/$($sharedTask.id)" $task $b.accessToken
    Assert-True $updated.isComplete 'Partner can complete a shared task'
    $task.isShared = $false
    $null = Request 'PUT' "/api/v1/tasks/$($sharedTask.id)" $task $b.accessToken 403
    Assert-True $true 'Partner cannot change owner sharing settings'
    $task.title = ' '
    $null = Request 'POST' '/api/v1/tasks' $task $a.accessToken 400
    $task.title = 'Invalid priority'
    $task.priority = 'urgent'
    $null = Request 'POST' '/api/v1/tasks' $task $a.accessToken 400
    Assert-True $true 'Task title and priority validation reject bad input'

    $event = @{ title = 'Dinner'; notes = 'Shared'; location = 'Home'; startsAt = '2026-12-02T19:00:00+07:00'; endsAt = '2026-12-02T20:00:00+07:00'; isShared = $true }
    $sharedEvent = Request 'POST' '/api/v1/events' $event $a.accessToken 201
    $event.isShared = $false
    $privateEvent = Request 'POST' '/api/v1/events' $event $a.accessToken 201
    $bEvents = @(Request 'GET' '/api/v1/events' -Token $b.accessToken)
    Assert-True ($bEvents.Count -eq 1 -and $bEvents[0].id -eq $sharedEvent.id) 'Partner sees only shared calendar event'
    $null = Request 'PUT' "/api/v1/events/$($sharedEvent.id)" $event $b.accessToken 403
    $null = Request 'DELETE' "/api/v1/events/$($privateEvent.id)" -Token $b.accessToken -Expected 404
    $event.isShared = $true
    $event.title = 'Updated dinner'
    $updatedEvent = Request 'PUT' "/api/v1/events/$($sharedEvent.id)" $event $b.accessToken
    Assert-True ($updatedEvent.title -eq 'Updated dinner') 'Partner can edit shared event content'
    $event.endsAt = $event.startsAt
    $null = Request 'POST' '/api/v1/events' $event $a.accessToken 400
    Assert-True $true 'Calendar rejects empty or backwards intervals'

    $summary = Request 'GET' '/api/v1/home' -Token $b.accessToken
    Assert-True ($summary.totalTasks -eq 1 -and $summary.completedTasks -eq 1) 'Dashboard counts only accessible persisted tasks'
    Stop-TestApi
    Start-TestApi
    $persisted = @(Request 'GET' '/api/v1/tasks' -Token $a.accessToken)
    Assert-True ($persisted.Count -eq 2) 'Records survive API restart'
    $null = Request 'DELETE' "/api/v1/events/$($sharedEvent.id)" -Token $b.accessToken -Expected 204
    Assert-True (@(Request 'GET' '/api/v1/events' -Token $b.accessToken).Count -eq 0) 'Partner can delete shared event'

    $event.endsAt = '2026-12-02T20:00:00+07:00'
    $retainedEvent = Request 'POST' '/api/v1/events' $event $a.accessToken 201
    $bTask = Request 'POST' '/api/v1/tasks' @{ title = 'B owns this'; notes = ''; isComplete = $false; isShared = $true; priority = 'normal'; dueAt = $null } $b.accessToken 201
    $null = Request 'POST' '/api/v1/couples/disconnect' @{ partnerCode = $b.user.partnerCode } -Expected 401
    $null = Request 'POST' '/api/v1/couples/disconnect' @{} $a.accessToken 400
    $null = Request 'POST' '/api/v1/couples/disconnect' @{ partnerCode = $c.user.partnerCode } $a.accessToken 409
    $disconnected = Request 'POST' '/api/v1/couples/disconnect' @{ partnerCode = $b.user.partnerCode } $a.accessToken
    Assert-True ($null -eq $disconnected.partner -and $null -eq (Request 'GET' '/api/v1/couples/me' -Token $b.accessToken).partner) 'Disconnect clears both partner links'
    $null = Request 'POST' '/api/v1/couples/disconnect' @{ partnerCode = $b.user.partnerCode } $a.accessToken
    $ownedAfterDisconnect = @(Request 'GET' '/api/v1/tasks' -Token $a.accessToken)
    Assert-True ($ownedAfterDisconnect.Count -eq 2 -and @($ownedAfterDisconnect | Where-Object isShared).Count -eq 0) 'Disconnect retains owner tasks and clears sharing'
    $ownedEvents = @(Request 'GET' '/api/v1/events' -Token $a.accessToken)
    Assert-True ($ownedEvents.Count -eq 2 -and @($ownedEvents | Where-Object isShared).Count -eq 0) 'Disconnect retains owner events and clears sharing'
    Assert-True (@(Request 'GET' '/api/v1/tasks' -Token $b.accessToken).Count -eq 1) 'Other owner retains their own formerly shared task'
    $null = Request 'DELETE' "/api/v1/tasks/$($bTask.id)" -Token $b.accessToken -Expected 204
    Assert-True (@(Request 'GET' '/api/v1/tasks' -Token $b.accessToken).Count -eq 0) 'Former partner loses shared-record access'
    $null = Request 'DELETE' "/api/v1/tasks/$($sharedTask.id)" -Token $b.accessToken -Expected 404
    $again = Request 'POST' '/api/v1/couples/invites' @{ partnerCode = $b.user.partnerCode } $a.accessToken 201
    $null = Request 'POST' "/api/v1/couples/invites/$($again.id)/accept" @{} $b.accessToken
    Assert-True (@(Request 'GET' '/api/v1/tasks' -Token $b.accessToken).Count -eq 0 -and @(Request 'GET' '/api/v1/events' -Token $b.accessToken).Count -eq 0) 'Reconnecting same partner never restores old sharing'
    $null = Request 'POST' '/api/v1/couples/disconnect' @{ partnerCode = $b.user.partnerCode } $a.accessToken
    $newInvite = Request 'POST' '/api/v1/couples/invites' @{ partnerCode = $c.user.partnerCode } $a.accessToken 201
    $null = Request 'POST' "/api/v1/couples/invites/$($newInvite.id)/accept" @{} $c.accessToken
    Assert-True (@(Request 'GET' '/api/v1/tasks' -Token $c.accessToken).Count -eq 0) 'New partner never inherits old shared records'
    $null = Request 'POST' '/api/v1/couples/disconnect' @{ partnerCode = $b.user.partnerCode } $a.accessToken 409
    Assert-True ((Request 'GET' '/api/v1/couples/me' -Token $a.accessToken).partner.partnerCode -eq $c.user.partnerCode) 'Stale disconnect cannot remove a different partner'

    # Run a shared write concurrently with disconnect: either it commits first and is
    # made private, or it observes disconnection and is rejected. No late re-sharing.
    $raceWrite = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Post, "$baseUrl/api/v1/tasks")
    $raceDisconnect = [Net.Http.HttpRequestMessage]::new([Net.Http.HttpMethod]::Post, "$baseUrl/api/v1/couples/disconnect")
    $raceWrite.Headers.Authorization = [Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $a.accessToken)
    $raceDisconnect.Headers.Authorization = [Net.Http.Headers.AuthenticationHeaderValue]::new('Bearer', $a.accessToken)
    $raceWrite.Content = [Net.Http.StringContent]::new((@{ title = 'Concurrent task'; isComplete = $false; isShared = $true; priority = 'normal' } | ConvertTo-Json), [Text.Encoding]::UTF8, 'application/json')
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
                $null = Request 'DELETE' "/api/v1/tasks/$($raceTask.id)" -Token $a.accessToken -Expected 204
            }
        } finally { $writeResult.Dispose(); $disconnectResult.Dispose() }
    } finally { $raceWrite.Dispose(); $raceDisconnect.Dispose() }
    $null = Request 'DELETE' "/api/v1/tasks/$($sharedTask.id)" -Token $a.accessToken -Expected 204
    $null = Request 'DELETE' "/api/v1/tasks/$($privateTask.id)" -Token $a.accessToken -Expected 204
    $null = Request 'DELETE' "/api/v1/events/$($privateEvent.id)" -Token $a.accessToken -Expected 204
    $null = Request 'DELETE' "/api/v1/events/$($retainedEvent.id)" -Token $a.accessToken -Expected 204
    Assert-True (@(Request 'GET' '/api/v1/tasks' -Token $a.accessToken).Count -eq 0) 'Owner can delete remaining records'
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
