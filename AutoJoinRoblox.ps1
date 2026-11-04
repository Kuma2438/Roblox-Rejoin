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

$form = New-Object Windows.Forms.Form
$form.Text = 'Roblox Auto Rejoin'
$form.Size = New-Object Drawing.Size(520,300)
$form.StartPosition = 'CenterScreen'
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false
$form.Font = New-Object Drawing.Font('Segoe UI',10)
$title = New-Object Windows.Forms.Label
$title.Text = 'Roblox Auto Rejoin'
$title.Font = New-Object Drawing.Font('Segoe UI',16,[Drawing.FontStyle]::Bold)
$title.Location = New-Object Drawing.Point(20,18); $title.Size = New-Object Drawing.Size(460,34); $form.Controls.Add($title)
$game = New-Object Windows.Forms.Label
$game.Text = 'เกม: Anime Adventures (8304191830)'
$game.Location = New-Object Drawing.Point(22,63); $game.Size = New-Object Drawing.Size(460,24); $form.Controls.Add($game)
$state = New-Object Windows.Forms.Label
$state.Text = 'สถานะ: หยุดทำงาน'
$state.Location = New-Object Drawing.Point(22,99); $state.Size = New-Object Drawing.Size(460,25); $form.Controls.Add($state)
$detail = New-Object Windows.Forms.Label
$detail.Text = 'กดเริ่มเฝ้าดูเพื่อเปิดเกมและตรวจสอบ Roblox'
$detail.Location = New-Object Drawing.Point(22,130); $detail.Size = New-Object Drawing.Size(460,48); $form.Controls.Add($detail)
$start = New-Object Windows.Forms.Button
$start.Text = 'เริ่มเฝ้าดูและเข้าเกม'
$start.Location = New-Object Drawing.Point(22,195); $start.Size = New-Object Drawing.Size(220,42); $form.Controls.Add($start)
$stop = New-Object Windows.Forms.Button
$stop.Text = 'หยุด'
$stop.Location = New-Object Drawing.Point(254,195); $stop.Size = New-Object Drawing.Size(100,42); $stop.Enabled = $false; $form.Controls.Add($stop)
$timer = New-Object Windows.Forms.Timer
$timer.Interval = $intervalSeconds * 1000
$launchGame = {
    if ($script:launching) { return }
    $script:launching = $true; $script:lastLaunch = Get-Date
    $detail.Text = 'กำลังเรียก Roblox ให้เข้าเกม...'
    try { Start-Process $url } catch { $detail.Text = 'เปิดลิงก์ไม่สำเร็จ: ' + $_.Exception.Message }
    $until = (Get-Date).AddSeconds(20)
    while ((Get-Date) -lt $until) {
        [Windows.Forms.Application]::DoEvents()
        Start-Sleep -Milliseconds 200
        if (Get-Process RobloxPlayerBeta -ErrorAction SilentlyContinue) { break }
    }
    $script:launching = $false
}
$start.Add_Click({
    $script:monitoring = $true; $script:everSeenRoblox = $false; $timer.Start()
    $state.Text = 'สถานะ: กำลังเฝ้าดู'; $start.Enabled = $false; $stop.Enabled = $true
    & $launchGame
})
$stop.Add_Click({
    $script:monitoring = $false; $timer.Stop()
    $state.Text = 'สถานะ: หยุดทำงาน'
    $detail.Text = 'หยุดเฝ้าดูแล้ว (ไม่ได้ปิด Roblox ที่กำลังเล่นอยู่)'
    $start.Enabled = $true; $stop.Enabled = $false
})
$timer.Add_Tick({
    if (-not $script:monitoring -or $script:launching) { return }

    if (Test-InternetConnection) {
        $script:internetDownChecks = 0
        if ($script:internetDown) {
            $script:internetUpChecks++
            $detail.Text = 'เน็ตกลับมาแล้ว กำลังตรวจยืนยันการเชื่อมต่อ...'
            if ($script:internetUpChecks -lt 2) { return }

            $script:internetDown = $false
            $script:internetUpChecks = 0
            $players = @(Get-Process RobloxPlayerBeta -ErrorAction SilentlyContinue)
            if ($players.Count -gt 0) {
                $detail.Text = 'เน็ตกลับมาแล้ว กำลังเริ่ม Roblox ใหม่เพื่อเชื่อมต่อเกม...'
                $players | Stop-Process -Force -ErrorAction SilentlyContinue
                Start-Sleep -Seconds 2
            } else {
                $detail.Text = 'เน็ตกลับมาแล้ว กำลังเข้าเกม...'
            }
            $script:everSeenRoblox = $false
            & $launchGame
            return
        }
    } else {
        $script:internetUpChecks = 0
        $script:internetDownChecks++
        if ($script:internetDownChecks -ge 3) {
            $script:internetDown = $true
            $detail.Text = 'ตรวจพบว่าอินเทอร์เน็ตขาด กำลังรอให้กลับมา...'
        } else {
            $detail.Text = 'กำลังตรวจสอบการเชื่อมต่ออินเทอร์เน็ต...'
        }
        return
    }

    if ($script:internetDown) { return }

    $players = @(Get-Process RobloxPlayerBeta -ErrorAction SilentlyContinue)
    if ($players.Count -gt 0) {
        $script:everSeenRoblox = $true
        $detail.Text = 'อินเทอร์เน็ตปกติ พบ Roblox Player กำลังทำงาน'
        return
    }
    if (-not $script:everSeenRoblox -and ((Get-Date) - $script:lastLaunch).TotalSeconds -lt 90) {
        $detail.Text = 'รอ Roblox เปิดเกม... หากไม่เริ่มภายใน 90 วินาทีจะลองใหม่'; return
    }
    if (((Get-Date) - $script:lastLaunch).TotalSeconds -ge 30) {
        $detail.Text = 'ไม่พบ Roblox Player กำลังเปิดเกมใหม่...'
        & $launchGame
    }
})
$timer.Start()
$form.Add_FormClosing({ $timer.Stop() })
[void]$form.ShowDialog()