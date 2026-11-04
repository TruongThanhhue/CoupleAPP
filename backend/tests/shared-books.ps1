# Run after connecting A and B on the disposable test database.
$pairA = "partnerCode=$($b.user.partnerCode)"
$pairB = "partnerCode=$($a.user.partnerCode)"
$ledgerA = "/api/v1/shared/expenses?${pairA}&month=2026-11"
$ledgerB = "/api/v1/shared/expenses?${pairB}&month=2026-11"
$line = @{ title='Dinner'; amount=125000; paidBy='partner'; day='2026-11-30' }
$line.requestId = [Guid]::NewGuid().ToString()
$entry = Request 'POST' $ledgerA $line $a.accessToken 201
$replay = Request 'POST' $ledgerA $line $a.accessToken
Assert-True ($entry.id -eq $replay.id) 'Retry after a lost response cannot count an expense twice'
$line.Remove('requestId')
$line.amount=26000; $line.paidBy='partner'
$null = Request 'POST' $ledgerB $line $b.accessToken 201
$line.day='2026-12-01'; $line.amount=10000
$null = Request 'POST' $ledgerB $line $b.accessToken 201
$left = Request 'GET' $ledgerA -Token $a.accessToken
$right = Request 'GET' $ledgerB -Token $b.accessToken
Assert-True ($left.total -eq 151000 -and $right.total -eq 151000 -and $left.items.Count -eq 2) 'Both partners see the same VND total for the selected calendar month'
Assert-True (($right.items | Where-Object id -eq $entry.id).paidByMe -and -not ($left.items | Where-Object id -eq $entry.id).paidByMe) 'Payer follows the selected person independent of who recorded the expense'
$null = Request 'GET' $ledgerA -Token $c.accessToken -Expected 409
$null = Request 'GET' $ledgerA -Expected 401
$line.amount=0
$null = Request 'POST' $ledgerA $line $a.accessToken 400
$null = Request 'GET' "/api/v1/shared/expenses?${pairA}&month=invalid" -Token $a.accessToken -Expected 400
$null = Request 'DELETE' "/api/v1/shared/expenses/$($entry.id)?$pairB" -Token $b.accessToken -Expected 404
Assert-True $true 'Expense endpoint rejects invalid inputs, unconnected viewers and non-owner deletion'
foreach ($kind in @('shopping','memories','anniversaries')) {
    $item = Request 'POST' "/api/v1/shared/${kind}?$pairA" @{ title='Weekend'; detail='Details'; day='2026-11-04' } $a.accessToken 201
    $path = "/api/v1/shared/$kind/$($item.id)"
    if ($kind -eq 'shopping') {
        $null = Request 'PUT' "${path}?$pairB" @{done=$true} $b.accessToken 204
        Assert-True ((Request 'GET' "/api/v1/shared/${kind}?$pairA" -Token $a.accessToken).items[0].done) 'Partner can mark a shopping item purchased'
    }
    Assert-True ((Request 'GET' "/api/v1/shared/${kind}?$pairB" -Token $b.accessToken).items[0].detail -eq 'Details') "$kind is visible to both partners"
    $null = Request 'DELETE' "${path}?$pairA" -Token $a.accessToken -Expected 204
}
