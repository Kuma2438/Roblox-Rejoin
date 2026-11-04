Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$url = 'roblox://placeId=8304191830'
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

$form = New-Object Windows.Forms.Form
$form.Text = 'Roblox Auto Rejoin'
$form.Size = New-Object Drawing.Size(700,520)
$form.MinimumSize = New-Object Drawing.Size(700,520)
$form.MaximumSize = New-Object Drawing.Size(700,520)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedSingle'
$form.MaximizeBox = $false
$form.BackColor = [Drawing.Color]::FromArgb(245,247,250)
$form.Font = New-Object Drawing.Font('Segoe UI',10)

$header = New-Object Windows.Forms.Panel
$header.Location = New-Object Drawing.Point(0,0)
$header.Size = New-Object Drawing.Size(700,106)
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
$subtitle.Size = New-Object Drawing.Size(630,24)
$header.Controls.Add($subtitle)

$gameCard = New-Object Windows.Forms.Panel
$gameCard.Location = New-Object Drawing.Point(24,124)
$gameCard.Size = New-Object Drawing.Size(636,70)
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
$statusCard.Size = New-Object Drawing.Size(636,91)
$statusCard.BackColor = [Drawing.Color]::White
$form.Controls.Add($statusCard)

$statusDot = New-Object Windows.Forms.Panel
$statusDot.Location = New-Object Drawing.Point(20,22)
$statusDot.Size = New-Object Drawing.Size(14,14)
$statusDot.BackColor = [Drawing.Color]::FromName('Gray')
$statusCard.Controls.Add($statusDot)

$statusLabel = New-Object Windows.Forms.Label
$statusLabel.Text = 'หยุดทำงาน'
$statusLabel.Font = New-Object Drawing.Font('Segoe UI Semibold',13,[Drawing.FontStyle]::Bold)
$statusLabel.ForeColor = [Drawing.Color]::FromArgb(35,45,65)
$statusLabel.Location = New-Object Drawing.Point(45,15)
$statusLabel.Size = New-Object Drawing.Size(540,28)
$statusCard.Controls.Add($statusLabel)

$detailLabel = New-Object Windows.Forms.Label
$detailLabel.Text = 'กดปุ่มด้านล่างเพื่อเริ่มเข้าเกมและเฝ้าดูการเชื่อมต่อ'
$detailLabel.Font = New-Object Drawing.Font('Segoe UI',9)
$detailLabel.ForeColor = [Drawing.Color]::FromArgb(105,116,136)
$detailLabel.Location = New-Object Drawing.Point(45,48)
$detailLabel.Size = New-Object Drawing.Size(565,24)
$statusCard.Controls.Add($detailLabel)

$logTitle = New-Object Windows.Forms.Label
$logTitle.Text = 'บันทึกกิจกรรม'
$logTitle.Font = New-Object Drawing.Font('Segoe UI Semibold',10,[Drawing.FontStyle]::Bold)
$logTitle.ForeColor = [Drawing.Color]::FromArgb(55,65,85)
$logTitle.Location = New-Object Drawing.Point(26,312)
$logTitle.Size = New-Object Drawing.Size(200,24)
$form.Controls.Add($logTitle)

$logBox = New-Object Windows.Forms.TextBox
$logBox.Location = New-Object Drawing.Point(24,340)
$logBox.Size = New-Object Drawing.Size(636,76)
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
$start.Location = New-Object Drawing.Point(24,432)
$start.Size = New-Object Drawing.Size(230,42)
$start.FlatStyle = 'Flat'
$start.FlatAppearance.BorderSize = 0
$start.BackColor = [Drawing.Color]::FromArgb(46,115,220)
$start.ForeColor = [Drawing.Color]::White
$start.Font = New-Object Drawing.Font('Segoe UI Semibold',10,[Drawing.FontStyle]::Bold)
$start.Cursor = 'Hand'
$form.Controls.Add($start)

$stop = New-Object Windows.Forms.Button
$stop.Text = 'หยุดเฝ้าดู'
$stop.Location = New-Object Drawing.Point(266,432)
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
$footer.Location = New-Object Drawing.Point(410,443)
$footer.Size = New-Object Drawing.Size(250,22)
$footer.TextAlign = 'MiddleRight'
$footer.Font = New-Object Drawing.Font('Segoe UI',8)
$footer.ForeColor = [Drawing.Color]::FromArgb(120,130,148)
$form.Controls.Add($footer)

$timer = New-Object Windows.Forms.Timer
$timer.Interval = $intervalSeconds * 1000
$launchGame = {
    if ($script:launching) { return }
    $script:launching = $true
    $script:lastLaunch = Get-Date
    Set-Status 'กำลังเปิดเกม' 'กำลังเรียก Roblox เพื่อเข้า Anime Adventures...' 'DodgerBlue'
    Add-Activity 'กำลังเรียก Roblox ให้เข้าเกม'
    try { Start-Process $url } catch {
        Set-Status 'เปิดเกมไม่สำเร็จ' $_.Exception.Message 'Tomato'
        Add-Activity ('เปิดลิงก์ไม่สำเร็จ: ' + $_.Exception.Message)
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
    $start.Enabled = $false
    $stop.Enabled = $true
    $timer.Start()
    Add-Activity 'เริ่มเฝ้าดู Roblox และอินเทอร์เน็ต'
    & $launchGame
})
$stop.Add_Click({
    $script:monitoring = $false
    $timer.Stop()
    Set-Status 'หยุดเฝ้าดู' 'Roblox ที่กำลังเปิดอยู่จะไม่ถูกปิด' 'Gray'
    Add-Activity 'หยุดเฝ้าดูแล้ว'
    $start.Enabled = $true
    $stop.Enabled = $false
})
$timer.Add_Tick({
    if (-not $script:monitoring -or $script:launching) { return }
    if (Test-InternetConnection) {
        $script:internetDownChecks = 0
        if ($script:internetDown) {
            $script:internetUpChecks++
            Set-Status 'กำลังตรวจเน็ต' 'เน็ตกลับมาแล้ว กำลังยืนยันความเสถียร...' 'DarkOrange'
            if ($script:internetUpChecks -lt 2) { return }
            $script:internetDown = $false
            $script:internetUpChecks = 0
            $players = @(Get-Process RobloxPlayerBeta -ErrorAction SilentlyContinue)
            if ($players.Count -gt 0) {
                Add-Activity 'เน็ตกลับมาแล้ว ปิด Roblox Player ที่ค้างเพื่อเชื่อมต่อใหม่'
                $players | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
            } else {
                Add-Activity 'เน็ตกลับมาแล้ว กำลังเปิดเกม'
            }
            $script:everSeenRoblox = $false
            & $launchGame
            return
        }
    } else {
        $script:internetUpChecks = 0
        $script:internetDownChecks++
        if ($script:internetDownChecks -ge 3) {
            if (-not $script:internetDown) { Add-Activity 'ตรวจพบอินเทอร์เน็ตขาด กำลังรอการเชื่อมต่อกลับมา' }
            $script:internetDown = $true
            Set-Status 'อินเทอร์เน็ตขาด' 'กำลังรอให้เน็ตกลับมา แล้วจะเข้าเกมใหม่อัตโนมัติ' 'Tomato'
        } else {
            Set-Status 'กำลังตรวจสอบเน็ต' 'ยังเชื่อมต่อไม่ได้ กำลังตรวจซ้ำ...' 'DarkOrange'
        }
        return
    }
    if ($script:internetDown) { return }
    $players = @(Get-Process RobloxPlayerBeta -ErrorAction SilentlyContinue)
    if ($players.Count -gt 0) {
        $script:everSeenRoblox = $true
        Set-Status 'กำลังเฝ้าดู' 'อินเทอร์เน็ตปกติ และพบ Roblox Player กำลังทำงาน' 'SeaGreen'
        return
    }
    if (-not $script:everSeenRoblox -and ((Get-Date) - $script:lastLaunch).TotalSeconds -lt 90) {
        Set-Status 'กำลังเข้าเกม' 'รอ Roblox Player เริ่มทำงาน...' 'DodgerBlue'
        return
    }
    if (((Get-Date) - $script:lastLaunch).TotalSeconds -ge 30) {
        Add-Activity 'ไม่พบ Roblox Player กำลังลองเข้าเกมใหม่'
        & $launchGame
    }
})
$form.Add_FormClosing({ $timer.Stop() })
Add-Activity 'พร้อมใช้งาน'
[void]$form.ShowDialog()