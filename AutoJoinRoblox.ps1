Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$url = 'roblox://placeId=8304191830'
$script:language = 'th'
$script:internetOnline = $false
$script:robloxOnline = $false
function T([string]$th, [string]$en) { if ($script:language -eq 'en') { return $en }; return $th }
$intervalSeconds = 10
$script:monitoring = $false
$script:launching = $false
$script:everSeenRoblox = $false
$script:lastLaunch = [datetime]::MinValue
$script:internetDownChecks = 0
$script:internetUpChecks = 0
$script:internetDown = $false

function Test-InternetConnection {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $pending = $client.BeginConnect('1.1.1.1', 443, $null, $null)
        if (-not $pending.AsyncWaitHandle.WaitOne(2500, $false)) { return $false }
        $client.EndConnect($pending)
        return $client.Connected
    } catch {
        return $false
    } finally {
        $client.Close()
    }
}
function Add-Activity([string]$message) {
    $line = '[' + (Get-Date -Format 'HH:mm:ss') + '] ' + $message
    $logBox.AppendText($line + [Environment]::NewLine)
}
function Set-Status([string]$main, [string]$detail, [string]$color) {
    $statusLabel.Text = $main
    $statusDot.BackColor = [Drawing.Color]::FromName($color)
    $detailLabel.Text = $detail
}
function Set-InternetLamp([bool]$online, [string]$detail) {
    $script:internetOnline = $online
    if ($online) { $internetLamp.Text = T '● ออนไลน์' '● Online'; $internetLamp.ForeColor = [Drawing.Color]::FromArgb(28,153,96) }
    else { $internetLamp.Text = T '● ออฟไลน์' '● Offline'; $internetLamp.ForeColor = [Drawing.Color]::FromArgb(210,65,70) }
    $internetDetail.Text = $detail
}
function Set-RobloxLamp([bool]$online, [string]$detail) {
    $script:robloxOnline = $online
    if ($online) { $robloxLamp.Text = T '● ออนไลน์' '● Online'; $robloxLamp.ForeColor = [Drawing.Color]::FromArgb(28,153,96) }
    else { $robloxLamp.Text = T '● ออฟไลน์' '● Offline'; $robloxLamp.ForeColor = [Drawing.Color]::FromArgb(210,65,70) }
    $robloxDetail.Text = $detail
}

$form = New-Object Windows.Forms.Form
$form.Text = 'Roblox Auto Rejoin'
$form.Size = New-Object Drawing.Size(760,640)
$form.MinimumSize = New-Object Drawing.Size(760,640)
$form.MaximumSize = New-Object Drawing.Size(760,640)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.BackColor = [Drawing.Color]::FromArgb(245,247,250)
$form.Font = New-Object Drawing.Font('Segoe UI',10)

$header = New-Object Windows.Forms.Panel
$header.Location = New-Object Drawing.Point(0,0)
$header.Size = New-Object Drawing.Size(760,106)
$header.BackColor = [Drawing.Color]::FromArgb(27,39,66)
$form.Controls.Add($header)

$title = New-Object Windows.Forms.Label
$title.Text = 'ROBLOX AUTO REJOIN'
$title.Font = New-Object Drawing.Font('Segoe UI Semibold',18,[Drawing.FontStyle]::Bold)
$title.ForeColor = [Drawing.Color]::White
$title.Location = New-Object Drawing.Point(28,20)
$title.Size = New-Object Drawing.Size(420,34)
$header.Controls.Add($title)

$subtitle = New-Object Windows.Forms.Label
$subtitle.Text = 'เฝ้าดูการเชื่อมต่อ และพากลับเข้า Anime Adventures อัตโนมัติ'
$subtitle.Font = New-Object Drawing.Font('Segoe UI',10)
$subtitle.ForeColor = [Drawing.Color]::FromArgb(205,215,232)
$subtitle.Location = New-Object Drawing.Point(30,61)
$subtitle.Size = New-Object Drawing.Size(585,24)
$header.Controls.Add($subtitle)

$languageButton = New-Object Windows.Forms.Button
$languageButton.Text = 'EN'
$languageButton.Location = New-Object Drawing.Point(672,22)
$languageButton.Size = New-Object Drawing.Size(64,34)
$languageButton.FlatStyle = 'Flat'
$languageButton.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(120,139,170)
$languageButton.BackColor = [Drawing.Color]::FromArgb(43,59,91)
$languageButton.ForeColor = [Drawing.Color]::White
$languageButton.Font = New-Object Drawing.Font('Segoe UI Semibold',9,[Drawing.FontStyle]::Bold)
$languageButton.Cursor = 'Hand'
$header.Controls.Add($languageButton)


$gameCard = New-Object Windows.Forms.Panel
$gameCard.Location = New-Object Drawing.Point(24,122)
$gameCard.Size = New-Object Drawing.Size(696,70)
$gameCard.BackColor = [Drawing.Color]::White
$form.Controls.Add($gameCard)

$gameTitle = New-Object Windows.Forms.Label
$gameTitle.Text = 'Anime Adventures'
$gameTitle.Font = New-Object Drawing.Font('Segoe UI Semibold',13,[Drawing.FontStyle]::Bold)
$gameTitle.ForeColor = [Drawing.Color]::FromArgb(35,45,65)
$gameTitle.Location = New-Object Drawing.Point(18,11)
$gameTitle.Size = New-Object Drawing.Size(350,26)
$gameCard.Controls.Add($gameTitle)

$gameId = New-Object Windows.Forms.Label
$gameId.Text = 'เกม Roblox  •  Place ID 8304191830'
$gameId.Font = New-Object Drawing.Font('Segoe UI',9)
$gameId.ForeColor = [Drawing.Color]::FromArgb(105,116,136)
$gameId.Location = New-Object Drawing.Point(19,40)
$gameId.Size = New-Object Drawing.Size(380,20)
$gameCard.Controls.Add($gameId)

$statusCard = New-Object Windows.Forms.Panel
$statusCard.Location = New-Object Drawing.Point(24,208)
$statusCard.Size = New-Object Drawing.Size(696,76)
$statusCard.BackColor = [Drawing.Color]::White
$form.Controls.Add($statusCard)

$statusDot = New-Object Windows.Forms.Panel
$statusDot.Location = New-Object Drawing.Point(20,18)
$statusDot.Size = New-Object Drawing.Size(14,14)
$statusDot.BackColor = [Drawing.Color]::FromName('Gray')
$statusCard.Controls.Add($statusDot)

$statusLabel = New-Object Windows.Forms.Label
$statusLabel.Text = 'หยุดทำงาน'
$statusLabel.Font = New-Object Drawing.Font('Segoe UI Semibold',13,[Drawing.FontStyle]::Bold)
$statusLabel.ForeColor = [Drawing.Color]::FromArgb(35,45,65)
$statusLabel.Location = New-Object Drawing.Point(45,10)
$statusLabel.Size = New-Object Drawing.Size(540,28)
$statusCard.Controls.Add($statusLabel)

$detailLabel = New-Object Windows.Forms.Label
$detailLabel.Text = 'กดปุ่มด้านล่างเพื่อเริ่มเข้าเกมและเฝ้าดูการเชื่อมต่อ'
$detailLabel.Font = New-Object Drawing.Font('Segoe UI',9)
$detailLabel.ForeColor = [Drawing.Color]::FromArgb(105,116,136)
$detailLabel.Location = New-Object Drawing.Point(45,43)
$detailLabel.Size = New-Object Drawing.Size(565,24)
$statusCard.Controls.Add($detailLabel)

$logTitle = New-Object Windows.Forms.Label
$logTitle.Text = 'บันทึกกิจกรรม'
$logTitle.Font = New-Object Drawing.Font('Segoe UI Semibold',10,[Drawing.FontStyle]::Bold)
$logTitle.ForeColor = [Drawing.Color]::FromArgb(55,65,85)
$logTitle.Location = New-Object Drawing.Point(26,406)
$logTitle.Size = New-Object Drawing.Size(200,24)
$form.Controls.Add($logTitle)

$logBox = New-Object Windows.Forms.TextBox
$logBox.Location = New-Object Drawing.Point(24,432)
$logBox.Size = New-Object Drawing.Size(696,74)
$logBox.Multiline = $true
$logBox.ReadOnly = $true
$logBox.ScrollBars = 'Vertical'
$logBox.BorderStyle = 'FixedSingle'
$logBox.BackColor = [Drawing.Color]::White
$logBox.ForeColor = [Drawing.Color]::FromArgb(68,78,96)
$logBox.Font = New-Object Drawing.Font('Consolas',9)
$form.Controls.Add($logBox)

$start = New-Object Windows.Forms.Button
$start.Text = 'เริ่มเฝ้าดูและเข้าเกม'
$start.Location = New-Object Drawing.Point(24,526)
$start.Size = New-Object Drawing.Size(230,42)
$start.FlatStyle = 'Flat'
$start.FlatAppearance.BorderSize = 0
$start.BackColor = [Drawing.Color]::FromArgb(46,115,220)
$start.ForeColor = [Drawing.Color]::White
$start.Font = New-Object Drawing.Font('Segoe UI Semibold',10,[Drawing.FontStyle]::Bold)
$start.Cursor = 'Hand'
$form.Controls.Add($start)

$stop = New-Object Windows.Forms.Button
$stop.Text = (T 'หยุดเฝ้าดู' 'Monitoring stopped')
$stop.Location = New-Object Drawing.Point(266,526)
$stop.Size = New-Object Drawing.Size(125,42)
$stop.FlatStyle = 'Flat'
$stop.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(210,216,226)
$stop.BackColor = [Drawing.Color]::White
$stop.ForeColor = [Drawing.Color]::FromArgb(55,65,85)
$stop.Enabled = $false
$stop.Cursor = 'Hand'
$form.Controls.Add($stop)

$footer = New-Object Windows.Forms.Label
$footer.Text = 'ตรวจ Roblox และอินเทอร์เน็ตทุก 10 วินาที'
$footer.Location = New-Object Drawing.Point(458,537)
$footer.Size = New-Object Drawing.Size(250,22)
$footer.TextAlign = 'MiddleRight'
$footer.Font = New-Object Drawing.Font('Segoe UI',8)
$footer.ForeColor = [Drawing.Color]::FromArgb(120,130,148)
$form.Controls.Add($footer)


$connectionCards = New-Object Windows.Forms.Panel
$connectionCards.Location = New-Object Drawing.Point(24,296)
$connectionCards.Size = New-Object Drawing.Size(696,96)
$connectionCards.BackColor = $form.BackColor
$form.Controls.Add($connectionCards)

$internetCard = New-Object Windows.Forms.Panel
$internetCard.Location = New-Object Drawing.Point(0,0)
$internetCard.Size = New-Object Drawing.Size(338,96)
$internetCard.BackColor = [Drawing.Color]::White
$connectionCards.Controls.Add($internetCard)

$internetHeading = New-Object Windows.Forms.Label
$internetHeading.Text = 'อินเทอร์เน็ต'
$internetHeading.Font = New-Object Drawing.Font('Segoe UI Semibold',10,[Drawing.FontStyle]::Bold)
$internetHeading.ForeColor = [Drawing.Color]::FromArgb(93,105,126)
$internetHeading.Location = New-Object Drawing.Point(16,10)
$internetHeading.Size = New-Object Drawing.Size(300,22)
$internetCard.Controls.Add($internetHeading)

$internetLamp = New-Object Windows.Forms.Label
$internetLamp.Text = '● ออฟไลน์'
$internetLamp.Font = New-Object Drawing.Font('Segoe UI Semibold',15,[Drawing.FontStyle]::Bold)
$internetLamp.ForeColor = [Drawing.Color]::FromArgb(210,65,70)
$internetLamp.Location = New-Object Drawing.Point(16,35)
$internetLamp.Size = New-Object Drawing.Size(300,30)
$internetCard.Controls.Add($internetLamp)

$internetDetail = New-Object Windows.Forms.Label
$internetDetail.Text = (T 'รอเริ่มตรวจสอบ' 'Waiting to start monitoring')
$internetDetail.Font = New-Object Drawing.Font('Segoe UI',8)
$internetDetail.ForeColor = [Drawing.Color]::FromArgb(125,135,150)
$internetDetail.Location = New-Object Drawing.Point(18,68)
$internetDetail.Size = New-Object Drawing.Size(300,18)
$internetCard.Controls.Add($internetDetail)

$robloxCard = New-Object Windows.Forms.Panel
$robloxCard.Location = New-Object Drawing.Point(358,0)
$robloxCard.Size = New-Object Drawing.Size(338,96)
$robloxCard.BackColor = [Drawing.Color]::White
$connectionCards.Controls.Add($robloxCard)

$robloxHeading = New-Object Windows.Forms.Label
$robloxHeading.Text = 'ROBLOX PLAYER'
$robloxHeading.Font = New-Object Drawing.Font('Segoe UI Semibold',10,[Drawing.FontStyle]::Bold)
$robloxHeading.ForeColor = [Drawing.Color]::FromArgb(93,105,126)
$robloxHeading.Location = New-Object Drawing.Point(16,10)
$robloxHeading.Size = New-Object Drawing.Size(300,22)
$robloxCard.Controls.Add($robloxHeading)

$robloxLamp = New-Object Windows.Forms.Label
$robloxLamp.Text = '● ออฟไลน์'
$robloxLamp.Font = New-Object Drawing.Font('Segoe UI Semibold',15,[Drawing.FontStyle]::Bold)
$robloxLamp.ForeColor = [Drawing.Color]::FromArgb(210,65,70)
$robloxLamp.Location = New-Object Drawing.Point(16,35)
$robloxLamp.Size = New-Object Drawing.Size(300,30)
$robloxCard.Controls.Add($robloxLamp)

$robloxDetail = New-Object Windows.Forms.Label
$robloxDetail.Text = (T 'รอเริ่มตรวจสอบ' 'Waiting to start monitoring')
$robloxDetail.Font = New-Object Drawing.Font('Segoe UI',8)
$robloxDetail.ForeColor = [Drawing.Color]::FromArgb(125,135,150)
$robloxDetail.Location = New-Object Drawing.Point(18,68)
$robloxDetail.Size = New-Object Drawing.Size(300,18)
$robloxCard.Controls.Add($robloxDetail)


function Apply-Language {
    $subtitle.Text = T 'เฝ้าดูการเชื่อมต่อ และพากลับเข้า Anime Adventures อัตโนมัติ' 'Monitor your connection and automatically rejoin Anime Adventures'
    $gameId.Text = T 'เกม Roblox  •  Place ID 8304191830' 'Roblox experience  •  Place ID 8304191830'
    $internetHeading.Text = T 'อินเทอร์เน็ต' 'INTERNET'
    $robloxHeading.Text = 'ROBLOX PLAYER'
    $logTitle.Text = T 'บันทึกกิจกรรม' 'Activity log'
    $start.Text = T 'เริ่มเฝ้าดูและเข้าเกม' 'Start monitoring'
    $stop.Text = T 'หยุดเฝ้าดู' 'Stop monitoring'
    $footer.Text = T 'ตรวจ Roblox และอินเทอร์เน็ตทุก 10 วินาที' 'Checks Roblox and internet every 10 seconds'
    $languageButton.Text = if ($script:language -eq 'th') { 'EN' } else { 'ไทย' }
    Set-InternetLamp $script:internetOnline (T 'สถานะการเชื่อมต่ออินเทอร์เน็ต' 'Internet connection status')
    Set-RobloxLamp $script:robloxOnline (T 'สถานะ Roblox Player' 'Roblox Player status')
    if ($script:monitoring) {
        Set-Status (T 'กำลังเฝ้าดู' 'Monitoring') (T 'กำลังตรวจสอบ Roblox และอินเทอร์เน็ต' 'Checking Roblox and internet connection') 'SeaGreen'
    } else {
        Set-Status (T 'หยุดทำงาน' 'Stopped') (T 'กดปุ่มด้านล่างเพื่อเริ่มเฝ้าดูและเข้าเกม' 'Press the button below to start monitoring and launch the game') 'Gray'
    }
}
$languageButton.Add_Click({
    if ($script:language -eq 'th') { $script:language = 'en' } else { $script:language = 'th' }
    Apply-Language
    Add-Activity (T 'เปลี่ยนภาษาแล้ว' 'Language changed')
})

$timer = New-Object Windows.Forms.Timer
$timer.Interval = $intervalSeconds * 1000
$launchGame = {
    if ($script:launching) { return }
    $script:launching = $true
    $script:lastLaunch = Get-Date
    Set-Status (T 'กำลังเปิดเกม' 'Launching game') (T 'กำลังเรียก Roblox เพื่อเข้า Anime Adventures...' 'Opening Roblox to join Anime Adventures...') 'DodgerBlue'
    Add-Activity (T 'กำลังเรียก Roblox ให้เข้าเกม' 'Opening Roblox to join the game')
    try { Start-Process $url } catch {
        Set-Status (T 'เปิดเกมไม่สำเร็จ' 'Could not launch game') $_.Exception.Message 'Tomato'
        Add-Activity ((T 'เปิดลิงก์ไม่สำเร็จ: ' 'Could not open link: ') + $_.Exception.Message)
    }
    $until = (Get-Date).AddSeconds(20)
    while ((Get-Date) -lt $until) {
        [Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 200
        if (Get-Process RobloxPlayerBeta -ErrorAction SilentlyContinue) { break }
    }
    $script:launching = $false
}
$start.Add_Click({
    $script:monitoring = $true
    $script:everSeenRoblox = $false
    $script:internetDown = $false
    $script:internetDownChecks = 0
    $script:internetUpChecks = 0
    Set-InternetLamp $false (T 'กำลังตรวจสอบ...' 'Checking...')
    Set-RobloxLamp $false (T 'กำลังเปิดเกม...' 'Launching game...')
    $start.Enabled = $false
    $stop.Enabled = $true
    $timer.Start()
    Add-Activity (T 'เริ่มเฝ้าดู Roblox และอินเทอร์เน็ต' 'Started monitoring Roblox and internet')
    $players = @(Get-Process RobloxPlayerBeta -ErrorAction SilentlyContinue)
    if ($players.Count -gt 0) {
        $script:everSeenRoblox = $true
        Set-RobloxLamp $true (T 'พบ Roblox Player กำลังทำงาน' 'Roblox Player is running')
        Set-Status (T 'กำลังเฝ้าดู' 'Monitoring') (T 'พบเกมที่เปิดอยู่แล้ว จะไม่เปิดซ้ำเพื่อไม่รบกวนการเล่น' 'An existing game was found. It will not be launched again.') 'SeaGreen'
        Add-Activity (T 'พบ Roblox Player ที่เปิดอยู่แล้ว ข้ามการเปิดเกมใหม่' 'Existing Roblox Player found; skipped relaunch')
        Set-InternetLamp (Test-InternetConnection) (T 'ตรวจพบสถานะอินเทอร์เน็ต' 'Internet status checked')
        return
    }
    Set-RobloxLamp $false (T 'ไม่พบ Roblox Player กำลังเข้าเกม' 'Roblox Player not found; launching game')
    & $launchGame
})
$stop.Add_Click({
    $script:monitoring = $false
    $timer.Stop()
    Set-Status (T 'หยุดเฝ้าดู' 'Monitoring stopped') (T 'Roblox ที่กำลังเปิดอยู่จะไม่ถูกปิด' 'The currently running Roblox Player will not be closed') 'Gray'
    $players = @(Get-Process RobloxPlayerBeta -ErrorAction SilentlyContinue)
    Set-RobloxLamp ($players.Count -gt 0) $(if ($players.Count -gt 0) { (T 'Roblox Player ยังทำงาน' 'Roblox Player is still running') } else { (T 'ไม่พบ Roblox Player' 'Roblox Player not found') })
    Add-Activity (T 'หยุดเฝ้าดูแล้ว' 'Stopped monitoring')
    $start.Enabled = $true
    $stop.Enabled = $false
})
$timer.Add_Tick({
    if (-not $script:monitoring -or $script:launching) { return }
    $currentPlayers = @(Get-Process RobloxPlayerBeta -ErrorAction SilentlyContinue)
    if ($currentPlayers.Count -gt 0) { Set-RobloxLamp $true (T 'พบ Roblox Player กำลังทำงาน' 'Roblox Player is running') }
    else { Set-RobloxLamp $false (T 'ไม่พบ Roblox Player' 'Roblox Player not found') }
    if (Test-InternetConnection) {
        Set-InternetLamp $true (T 'เชื่อมต่ออินเทอร์เน็ตได้' 'Internet connection available')
        $script:internetDownChecks = 0
        if ($script:internetDown) {
            $script:internetUpChecks++
            Set-Status (T 'กำลังตรวจเน็ต' 'Checking internet') (T 'เน็ตกลับมาแล้ว กำลังยืนยันความเสถียร...' 'Internet is back; checking stability...') 'DarkOrange'
            if ($script:internetUpChecks -lt 2) { return }
            $script:internetDown = $false
            $script:internetUpChecks = 0
            $players = @(Get-Process RobloxPlayerBeta -ErrorAction SilentlyContinue)
            if ($players.Count -gt 0) {
                Add-Activity (T 'เน็ตกลับมาแล้ว ปิด Roblox Player ที่ค้างเพื่อเชื่อมต่อใหม่' 'Internet restored; restarting Roblox Player to reconnect')
                $players | Stop-Process -Force -ErrorAction SilentlyContinue
                Set-RobloxLamp $false (T 'กำลังเริ่มเกมใหม่หลังเน็ตกลับมา' 'Restarting game after internet recovery')
                Start-Sleep -Seconds 2
            } else {
                Add-Activity (T 'เน็ตกลับมาแล้ว กำลังเปิดเกม' 'Internet restored; launching game')
            }
            $script:everSeenRoblox = $false
            & $launchGame
            return
        }
    } else {
        Set-InternetLamp $false (T 'ไม่สามารถเชื่อมต่อปลายทางตรวจสอบได้' 'Cannot reach the connectivity check endpoint')
        $script:internetUpChecks = 0
        $script:internetDownChecks++
        if ($script:internetDownChecks -ge 3) {
            if (-not $script:internetDown) { Add-Activity (T 'ตรวจพบอินเทอร์เน็ตขาด กำลังรอการเชื่อมต่อกลับมา' 'Internet connection lost; waiting for it to return') }
            $script:internetDown = $true
            Set-Status (T 'อินเทอร์เน็ตขาด' 'Internet disconnected') (T 'กำลังรอให้เน็ตกลับมา แล้วจะเข้าเกมใหม่อัตโนมัติ' 'Waiting for internet; the game will rejoin automatically') 'Tomato'
        } else {
            Set-Status (T 'กำลังตรวจสอบเน็ต' 'Checking internet') (T 'ยังเชื่อมต่อไม่ได้ กำลังตรวจซ้ำ...' 'No connection yet; checking again...') 'DarkOrange'
        }
        return
    }
    if ($script:internetDown) { return }
    $players = @(Get-Process RobloxPlayerBeta -ErrorAction SilentlyContinue)
    if ($players.Count -gt 0) {
        $script:everSeenRoblox = $true
        Set-RobloxLamp $true (T 'พบ Roblox Player กำลังทำงาน' 'Roblox Player is running')
        Set-Status (T 'กำลังเฝ้าดู' 'Monitoring') (T 'อินเทอร์เน็ตปกติ และพบ Roblox Player กำลังทำงาน' 'Internet is connected and Roblox Player is running') 'SeaGreen'
        return
    }
    Set-RobloxLamp $false (T 'ไม่พบ Roblox Player' 'Roblox Player not found')
    if (-not $script:everSeenRoblox -and ((Get-Date) - $script:lastLaunch).TotalSeconds -lt 90) {
        Set-Status (T 'กำลังเข้าเกม' 'Joining game') (T 'รอ Roblox Player เริ่มทำงาน...' 'Waiting for Roblox Player to start...') 'DodgerBlue'
        return
    }
    if (((Get-Date) - $script:lastLaunch).TotalSeconds -ge 30) {
        Add-Activity (T 'ไม่พบ Roblox Player กำลังลองเข้าเกมใหม่' 'Roblox Player not found; trying to rejoin')
        & $launchGame
    }
})
$form.Add_FormClosing({ $timer.Stop() })
Apply-Language
Set-InternetLamp $false (T 'รอเริ่มตรวจสอบ' 'Waiting to start monitoring')
Set-RobloxLamp $false (T 'รอเริ่มตรวจสอบ' 'Waiting to start monitoring')
Add-Activity (T 'พร้อมใช้งาน' 'Ready')
[void]$form.ShowDialog()