Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$url = 'roblox://placeId=8304191830'
$script:language = 'th'
$script:internetOnline = $false
$script:robloxOnline = $false
$script:appReturnSince = $null
$script:appReturnKey = $null
$script:handledAppReturnKey = $null
$script:sessionLogPath = $null
$script:sessionLogWriteTime = [datetime]::MinValue
$script:sessionLogState = 'unknown'
$script:sessionLogSawPlay = $false
$script:sessionLogEventKey = $null
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

function Get-RobloxSessionState {
    $logDirectory = Join-Path $env:LOCALAPPDATA 'Roblox\logs'
    try {
        $logFile = Get-ChildItem -LiteralPath $logDirectory -Filter '*_Player_*_last.log' -ErrorAction Stop |
            Where-Object { $_.Name -notmatch '_CrashHandler_' } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if (-not $logFile) { return $null }

        $newLog = ($script:sessionLogPath -ne $logFile.FullName)
        if (-not $newLog -and $script:sessionLogWriteTime -eq $logFile.LastWriteTime) {
            return [pscustomobject]@{
                LogPath = $script:sessionLogPath
                State = $script:sessionLogState
                EventKey = $script:sessionLogEventKey
            }
        }

        if ($newLog) {
            $script:sessionLogPath = $logFile.FullName
            $script:sessionLogState = 'unknown'
            $script:sessionLogSawPlay = $false
            $script:sessionLogEventKey = $null
            $lines = @(Get-Content -LiteralPath $logFile.FullName -ErrorAction Stop)
        } else {
            $lines = @(Get-Content -LiteralPath $logFile.FullName -Tail 5000 -ErrorAction Stop)
        }

        foreach ($line in $lines) {
            if ($line -match '\[FLog::SessionTransitionFSM\] Entered play session\.') {
                $script:sessionLogSawPlay = $true
                $script:sessionLogState = 'play'
                $script:sessionLogEventKey = $null
            } elseif ($line -match '\[FLog::SessionTransitionFSM\] Entered app session\.') {
                if ($script:sessionLogSawPlay) {
                    $script:sessionLogState = 'app-after-play'
                    $script:sessionLogEventKey = $line
                } else {
                    $script:sessionLogState = 'app-before-play'
                }
            }
        }
        $script:sessionLogWriteTime = $logFile.LastWriteTime
        return [pscustomobject]@{
            LogPath = $script:sessionLogPath
            State = $script:sessionLogState
            EventKey = $script:sessionLogEventKey
        }
    } catch {
        return $null
    }
}
function Add-Activity([string]$message) {
    $line = '[' + (Get-Date -Format 'HH:mm:ss') + '] ' + $message
    $logBox.AppendText($line + [Environment]::NewLine)
}
function Set-Status([string]$main, [string]$detail, [string]$color) {
    $statusLabel.Text = $main
    switch ($color) { 'SeaGreen' { $statusDot.BackColor = [Drawing.Color]::FromArgb(32,255,160) } 'Tomato' { $statusDot.BackColor = [Drawing.Color]::FromArgb(255,63,113) } 'DodgerBlue' { $statusDot.BackColor = [Drawing.Color]::FromArgb(0,225,255) } 'DarkOrange' { $statusDot.BackColor = [Drawing.Color]::FromArgb(182,82,255) } default { $statusDot.BackColor = [Drawing.Color]::FromArgb(112,143,170) } }
    $detailLabel.Text = $detail
}
function Set-InternetLamp([bool]$online, [string]$detail) {
    $script:internetOnline = $online
    if ($online) { $internetLamp.Text = T '● ออนไลน์' '● Online'; $internetLamp.ForeColor = [Drawing.Color]::FromArgb(32,255,160) }
    else { $internetLamp.Text = T '● ออฟไลน์' '● Offline'; $internetLamp.ForeColor = [Drawing.Color]::FromArgb(255,63,113) }
    $internetDetail.Text = $detail
}
function Set-RobloxLamp([bool]$online, [string]$detail) {
    $script:robloxOnline = $online
    if ($online) { $robloxLamp.Text = T '● ออนไลน์' '● Online'; $robloxLamp.ForeColor = [Drawing.Color]::FromArgb(32,255,160) }
    else { $robloxLamp.Text = T '● ออฟไลน์' '● Offline'; $robloxLamp.ForeColor = [Drawing.Color]::FromArgb(255,63,113) }
    $robloxDetail.Text = $detail
}

$form = New-Object Windows.Forms.Form
$form.Text = 'Roblox Auto Rejoin'
$form.Size = New-Object Drawing.Size(820,780)
$form.MinimumSize = New-Object Drawing.Size(820,780)
$form.MaximumSize = New-Object Drawing.Size(820,780)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.BackColor = [Drawing.Color]::FromArgb(7,11,22)
$form.Font = New-Object Drawing.Font('Segoe UI',10)

$header = New-Object Windows.Forms.Panel
$header.Location = New-Object Drawing.Point(0,0)
$header.Size = New-Object Drawing.Size(804,142)
$header.BackColor = [Drawing.Color]::FromArgb(18,24,48)
$header.Add_Paint({
    param($sender, $eventArgs)
    $rect = $sender.ClientRectangle
    $brush = New-Object Drawing.Drawing2D.LinearGradientBrush($rect,[Drawing.Color]::FromArgb(13,23,48),[Drawing.Color]::FromArgb(40,18,71),25)
    $eventArgs.Graphics.FillRectangle($brush,$rect)
    $brush.Dispose()
})
$form.Controls.Add($header)

$headerKicker = New-Object Windows.Forms.Label
$headerKicker.Text = 'REJOIN CONTROL  /  ROBLOX'
$headerKicker.Font = New-Object Drawing.Font('Segoe UI Semibold',8,[Drawing.FontStyle]::Bold)
$headerKicker.ForeColor = [Drawing.Color]::FromArgb(84,229,255)
$headerKicker.Location = New-Object Drawing.Point(30,18)
$headerKicker.Size = New-Object Drawing.Size(420,18)
$header.Controls.Add($headerKicker)

$title = New-Object Windows.Forms.Label
$title.Text = 'ROBLOX REJOIN'
$title.Font = New-Object Drawing.Font('Segoe UI Semibold',21,[Drawing.FontStyle]::Bold)
$title.ForeColor = [Drawing.Color]::FromArgb(236,247,255)
$title.Location = New-Object Drawing.Point(28,39)
$title.Size = New-Object Drawing.Size(520,40)
$header.Controls.Add($title)

$subtitle = New-Object Windows.Forms.Label
$subtitle.Text = 'เฝ้าดูการเชื่อมต่อ และพากลับเข้า Anime Adventures อัตโนมัติ'
$subtitle.Font = New-Object Drawing.Font('Segoe UI',9)
$subtitle.ForeColor = [Drawing.Color]::FromArgb(160,181,210)
$subtitle.Location = New-Object Drawing.Point(30,91)
$subtitle.Size = New-Object Drawing.Size(620,24)
$header.Controls.Add($subtitle)

$languageButton = New-Object Windows.Forms.Button
$languageButton.Text = 'EN'
$languageButton.Location = New-Object Drawing.Point(706,24)
$languageButton.Size = New-Object Drawing.Size(66,36)
$languageButton.FlatStyle = 'Flat'
$languageButton.FlatAppearance.BorderSize = 1
$languageButton.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(0,220,255)
$languageButton.FlatAppearance.MouseOverBackColor = [Drawing.Color]::FromArgb(31,53,81)
$languageButton.BackColor = [Drawing.Color]::FromArgb(17,27,50)
$languageButton.ForeColor = [Drawing.Color]::FromArgb(100,238,255)
$languageButton.Font = New-Object Drawing.Font('Segoe UI Semibold',9,[Drawing.FontStyle]::Bold)
$languageButton.Cursor = 'Hand'
$header.Controls.Add($languageButton)

$headerAccent = New-Object Windows.Forms.Panel
$headerAccent.Location = New-Object Drawing.Point(28,137)
$headerAccent.Size = New-Object Drawing.Size(748,2)
$headerAccent.BackColor = [Drawing.Color]::FromArgb(0,225,255)
$header.Controls.Add($headerAccent)

$gameCard = New-Object Windows.Forms.Panel
$gameCard.Location = New-Object Drawing.Point(28,162)
$gameCard.Size = New-Object Drawing.Size(748,78)
$gameCard.BackColor = [Drawing.Color]::FromArgb(16,24,44)
$form.Controls.Add($gameCard)

$gameTitle = New-Object Windows.Forms.Label
$gameTitle.Text = 'Anime Adventures'
$gameTitle.Font = New-Object Drawing.Font('Segoe UI Semibold',14,[Drawing.FontStyle]::Bold)
$gameTitle.ForeColor = [Drawing.Color]::FromArgb(238,247,255)
$gameTitle.Location = New-Object Drawing.Point(20,12)
$gameTitle.Size = New-Object Drawing.Size(430,29)
$gameCard.Controls.Add($gameTitle)

$gameId = New-Object Windows.Forms.Label
$gameId.Text = 'เกม Roblox  •  Place ID 8304191830'
$gameId.Font = New-Object Drawing.Font('Segoe UI',9)
$gameId.ForeColor = [Drawing.Color]::FromArgb(145,171,197)
$gameId.Location = New-Object Drawing.Point(21,44)
$gameId.Size = New-Object Drawing.Size(430,20)
$gameCard.Controls.Add($gameId)

$heroBadge = New-Object Windows.Forms.Label
$heroBadge.Text = 'SELECTED EXPERIENCE'
$heroBadge.Font = New-Object Drawing.Font('Segoe UI Semibold',8,[Drawing.FontStyle]::Bold)
$heroBadge.ForeColor = [Drawing.Color]::FromArgb(94,234,212)
$heroBadge.BackColor = [Drawing.Color]::FromArgb(20,49,56)
$heroBadge.TextAlign = 'MiddleCenter'
$heroBadge.Location = New-Object Drawing.Point(568,22)
$heroBadge.Size = New-Object Drawing.Size(156,32)
$gameCard.Controls.Add($heroBadge)

$statusCard = New-Object Windows.Forms.Panel
$statusCard.Location = New-Object Drawing.Point(28,260)
$statusCard.Size = New-Object Drawing.Size(748,92)
$statusCard.BackColor = [Drawing.Color]::FromArgb(16,24,44)
$form.Controls.Add($statusCard)

$statusDot = New-Object Windows.Forms.Panel
$statusDot.Location = New-Object Drawing.Point(22,24)
$statusDot.Size = New-Object Drawing.Size(13,13)
$statusDot.BackColor = [Drawing.Color]::FromArgb(116,137,160)
$statusCard.Controls.Add($statusDot)
$statusDot.Add_Paint({
    param($sender, $eventArgs)
    $brush = New-Object Drawing.SolidBrush($sender.BackColor)
    $eventArgs.Graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $eventArgs.Graphics.FillEllipse($brush,0,0,$sender.Width - 1,$sender.Height - 1)
    $brush.Dispose()
})

$statusLabel = New-Object Windows.Forms.Label
$statusLabel.Text = 'หยุดทำงาน'
$statusLabel.Font = New-Object Drawing.Font('Segoe UI Semibold',14,[Drawing.FontStyle]::Bold)
$statusLabel.ForeColor = [Drawing.Color]::FromArgb(240,247,255)
$statusLabel.Location = New-Object Drawing.Point(49,14)
$statusLabel.Size = New-Object Drawing.Size(650,30)
$statusCard.Controls.Add($statusLabel)

$detailLabel = New-Object Windows.Forms.Label
$detailLabel.Text = 'กดปุ่มด้านล่างเพื่อเริ่มเข้าเกมและเฝ้าดูการเชื่อมต่อ'
$detailLabel.Font = New-Object Drawing.Font('Segoe UI',9)
$detailLabel.ForeColor = [Drawing.Color]::FromArgb(147,171,198)
$detailLabel.Location = New-Object Drawing.Point(49,49)
$detailLabel.Size = New-Object Drawing.Size(670,24)
$statusCard.Controls.Add($detailLabel)

$connectionCards = New-Object Windows.Forms.Panel
$connectionCards.Location = New-Object Drawing.Point(28,372)
$connectionCards.Size = New-Object Drawing.Size(748,116)
$connectionCards.BackColor = $form.BackColor
$form.Controls.Add($connectionCards)

$internetCard = New-Object Windows.Forms.Panel
$internetCard.Location = New-Object Drawing.Point(0,0)
$internetCard.Size = New-Object Drawing.Size(362,116)
$internetCard.BackColor = [Drawing.Color]::FromArgb(16,24,44)
$connectionCards.Controls.Add($internetCard)

$internetHeading = New-Object Windows.Forms.Label
$internetHeading.Text = 'อินเทอร์เน็ต'
$internetHeading.Font = New-Object Drawing.Font('Segoe UI Semibold',9,[Drawing.FontStyle]::Bold)
$internetHeading.ForeColor = [Drawing.Color]::FromArgb(145,173,204)
$internetHeading.Location = New-Object Drawing.Point(19,14)
$internetHeading.Size = New-Object Drawing.Size(320,20)
$internetCard.Controls.Add($internetHeading)

$internetLamp = New-Object Windows.Forms.Label
$internetLamp.Text = '● ออฟไลน์'
$internetLamp.Font = New-Object Drawing.Font('Segoe UI Semibold',16,[Drawing.FontStyle]::Bold)
$internetLamp.ForeColor = [Drawing.Color]::FromArgb(255,63,113)
$internetLamp.Location = New-Object Drawing.Point(18,40)
$internetLamp.Size = New-Object Drawing.Size(320,32)
$internetCard.Controls.Add($internetLamp)

$internetDetail = New-Object Windows.Forms.Label
$internetDetail.Text = 'รอเริ่มตรวจสอบ'
$internetDetail.Font = New-Object Drawing.Font('Segoe UI',8)
$internetDetail.ForeColor = [Drawing.Color]::FromArgb(132,158,186)
$internetDetail.Location = New-Object Drawing.Point(20,82)
$internetDetail.Size = New-Object Drawing.Size(320,19)
$internetCard.Controls.Add($internetDetail)

$robloxCard = New-Object Windows.Forms.Panel
$robloxCard.Location = New-Object Drawing.Point(386,0)
$robloxCard.Size = New-Object Drawing.Size(362,116)
$robloxCard.BackColor = [Drawing.Color]::FromArgb(16,24,44)
$connectionCards.Controls.Add($robloxCard)

$robloxHeading = New-Object Windows.Forms.Label
$robloxHeading.Text = 'ROBLOX PLAYER'
$robloxHeading.Font = New-Object Drawing.Font('Segoe UI Semibold',9,[Drawing.FontStyle]::Bold)
$robloxHeading.ForeColor = [Drawing.Color]::FromArgb(145,173,204)
$robloxHeading.Location = New-Object Drawing.Point(19,14)
$robloxHeading.Size = New-Object Drawing.Size(320,20)
$robloxCard.Controls.Add($robloxHeading)

$robloxLamp = New-Object Windows.Forms.Label
$robloxLamp.Text = '● ออฟไลน์'
$robloxLamp.Font = New-Object Drawing.Font('Segoe UI Semibold',16,[Drawing.FontStyle]::Bold)
$robloxLamp.ForeColor = [Drawing.Color]::FromArgb(255,63,113)
$robloxLamp.Location = New-Object Drawing.Point(18,40)
$robloxLamp.Size = New-Object Drawing.Size(320,32)
$robloxCard.Controls.Add($robloxLamp)

$robloxDetail = New-Object Windows.Forms.Label
$robloxDetail.Text = 'รอเริ่มตรวจสอบ'
$robloxDetail.Font = New-Object Drawing.Font('Segoe UI',8)
$robloxDetail.ForeColor = [Drawing.Color]::FromArgb(132,158,186)
$robloxDetail.Location = New-Object Drawing.Point(20,82)
$robloxDetail.Size = New-Object Drawing.Size(320,19)
$robloxCard.Controls.Add($robloxDetail)

$logTitle = New-Object Windows.Forms.Label
$logTitle.Text = 'บันทึกกิจกรรม'
$logTitle.Font = New-Object Drawing.Font('Segoe UI Semibold',10,[Drawing.FontStyle]::Bold)
$logTitle.ForeColor = [Drawing.Color]::FromArgb(92,230,255)
$logTitle.Location = New-Object Drawing.Point(31,510)
$logTitle.Size = New-Object Drawing.Size(230,23)
$form.Controls.Add($logTitle)

$logBox = New-Object Windows.Forms.TextBox
$logBox.Location = New-Object Drawing.Point(28,539)
$logBox.Size = New-Object Drawing.Size(748,102)
$logBox.Multiline = $true
$logBox.ReadOnly = $true
$logBox.ScrollBars = 'Vertical'
$logBox.BorderStyle = 'None'
$logBox.BackColor = [Drawing.Color]::FromArgb(10,17,32)
$logBox.ForeColor = [Drawing.Color]::FromArgb(156,204,218)
$logBox.Font = New-Object Drawing.Font('Consolas',9)
$form.Controls.Add($logBox)

$start = New-Object Windows.Forms.Button
$start.Text = 'เริ่มเฝ้าดูและเข้าเกม'
$start.Location = New-Object Drawing.Point(28,666)
$start.Size = New-Object Drawing.Size(226,46)
$start.FlatStyle = 'Flat'
$start.FlatAppearance.BorderSize = 0
$start.FlatAppearance.MouseOverBackColor = [Drawing.Color]::FromArgb(88,246,255)
$start.BackColor = [Drawing.Color]::FromArgb(0,225,255)
$start.ForeColor = [Drawing.Color]::FromArgb(4,15,26)
$start.Font = New-Object Drawing.Font('Segoe UI Semibold',10,[Drawing.FontStyle]::Bold)
$start.Cursor = 'Hand'
$form.Controls.Add($start)

$stop = New-Object Windows.Forms.Button
$stop.Text = 'หยุดเฝ้าดู'
$stop.Location = New-Object Drawing.Point(268,666)
$stop.Size = New-Object Drawing.Size(140,46)
$stop.FlatStyle = 'Flat'
$stop.FlatAppearance.BorderSize = 1
$stop.FlatAppearance.BorderColor = [Drawing.Color]::FromArgb(182,82,255)
$stop.FlatAppearance.MouseOverBackColor = [Drawing.Color]::FromArgb(35,46,75)
$stop.BackColor = [Drawing.Color]::FromArgb(18,27,49)
$stop.ForeColor = [Drawing.Color]::FromArgb(222,237,250)
$stop.Font = New-Object Drawing.Font('Segoe UI Semibold',9,[Drawing.FontStyle]::Bold)
$stop.Enabled = $false
$stop.Cursor = 'Hand'
$form.Controls.Add($stop)

$footer = New-Object Windows.Forms.Label
$footer.Text = 'ตรวจ Roblox และอินเทอร์เน็ตทุก 10 วินาที'
$footer.Location = New-Object Drawing.Point(452,679)
$footer.Size = New-Object Drawing.Size(324,22)
$footer.TextAlign = 'MiddleRight'
$footer.Font = New-Object Drawing.Font('Segoe UI',8)
$footer.ForeColor = [Drawing.Color]::FromArgb(116,146,176)
$form.Controls.Add($footer)

function Set-RoundedCorners($control, [int]$radius) {
    $path = New-Object Drawing.Drawing2D.GraphicsPath
    $diameter = $radius * 2
    $width = $control.Width - 1
    $height = $control.Height - 1
    $path.AddArc(0,0,$diameter,$diameter,180,90)
    $path.AddArc($width - $diameter,0,$diameter,$diameter,270,90)
    $path.AddArc($width - $diameter,$height - $diameter,$diameter,$diameter,0,90)
    $path.AddArc(0,$height - $diameter,$diameter,$diameter,90,90)
    $path.CloseFigure()
    $control.Region = New-Object Drawing.Region($path)
    $path.Dispose()
}
function Add-NeonBorder($control, [int]$red, [int]$green, [int]$blue) {
    $paint = {
        param($sender, $eventArgs)
        $eventArgs.Graphics.SmoothingMode = [Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $rect = New-Object Drawing.Rectangle(0,0,$sender.Width - 1,$sender.Height - 1)
        $path = New-Object Drawing.Drawing2D.GraphicsPath
        $radius = 14
        $d = $radius * 2
        $path.AddArc($rect.Left,$rect.Top,$d,$d,180,90)
        $path.AddArc($rect.Right - $d,$rect.Top,$d,$d,270,90)
        $path.AddArc($rect.Right - $d,$rect.Bottom - $d,$d,$d,0,90)
        $path.AddArc($rect.Left,$rect.Bottom - $d,$d,$d,90,90)
        $path.CloseFigure()
        $pen = New-Object Drawing.Pen([Drawing.Color]::FromArgb($red,$green,$blue),1)
        $eventArgs.Graphics.DrawPath($pen,$path)
        $pen.Dispose()
        $path.Dispose()
    }.GetNewClosure()
    $control.Add_Paint($paint)
}
Set-RoundedCorners $gameCard 15
Set-RoundedCorners $statusCard 15
Set-RoundedCorners $internetCard 15
Set-RoundedCorners $robloxCard 15
Set-RoundedCorners $logBox 12
Set-RoundedCorners $start 12
Set-RoundedCorners $stop 12
Set-RoundedCorners $languageButton 10
Add-NeonBorder $gameCard 0 225 255
Add-NeonBorder $statusCard 0 225 255
Add-NeonBorder $internetCard 182 82 255
Add-NeonBorder $robloxCard 0 225 255

function Apply-Language {
    $subtitle.Text = T 'เฝ้าดูการเชื่อมต่อ และพากลับเข้า Anime Adventures อัตโนมัติ' 'Monitor your connection and automatically rejoin Anime Adventures'
    $gameId.Text = T 'เกม Roblox  •  Place ID 8304191830' 'Roblox experience  •  Place ID 8304191830'
    $heroBadge.Text = T 'เกมที่เลือก' 'SELECTED EXPERIENCE'
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
    $sessionState = Get-RobloxSessionState
    if ($players.Count -gt 0 -and $sessionState -and $sessionState.State -eq 'app-after-play' -and $sessionState.EventKey) {
        $eventKey = $sessionState.LogPath + '|' + $sessionState.EventKey
        if ($eventKey -ne $script:handledAppReturnKey) {
            if ($script:appReturnKey -ne $eventKey) {
                $script:appReturnKey = $eventKey
                $script:appReturnSince = Get-Date
                Set-Status (T 'กลับมาหน้า Roblox แล้ว' 'Returned to Roblox home') (T 'กำลังยืนยันว่าเกมไม่ได้กลับเข้าเซิร์ฟเวอร์...' 'Checking whether the game rejoins automatically...') 'DarkOrange'
                Add-Activity (T 'ตรวจพบว่า Roblox กลับมาหน้าแอปหลังออกจากเกม' 'Detected Roblox returned to its app screen after leaving the game')
            }
            if (((Get-Date) - $script:appReturnSince).TotalSeconds -ge 20) {
                $script:handledAppReturnKey = $eventKey
                $script:appReturnSince = $null
                $script:appReturnKey = $null
                Add-Activity (T 'ยังอยู่หน้า Roblox หลัง 20 วินาที กำลังปิดแล้วเข้าเกมใหม่' 'Still on the Roblox app screen after 20 seconds; restarting and rejoining')
                $players | Stop-Process -Force -ErrorAction SilentlyContinue
                Set-RobloxLamp $false (T 'กำลังเริ่มเกมใหม่' 'Restarting the game')
                Start-Sleep -Seconds 2
                $script:everSeenRoblox = $false
                & $launchGame
                return
            }
            return
        }
    } else {
        $script:appReturnSince = $null
        $script:appReturnKey = $null
    }
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