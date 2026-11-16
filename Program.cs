using System;
using System.Collections.Generic;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.IO;
using System.Linq;
using System.Net.Sockets;
using System.Diagnostics;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace RobloxRejoin
{
    internal static class Program
    {
        [STAThread]
        private static void Main()
        {
            Application.SetHighDpiMode(HighDpiMode.PerMonitorV2);
            Application.EnableVisualStyles();
            Application.SetCompatibleTextRenderingDefault(false);
            Application.Run(new RejoinForm());
        }
    }

    internal sealed class SoftCard : Panel
    {
        public Color BorderColor { get; set; } = Color.FromArgb(38, 44, 56);
        public int Radius { get; set; } = 18;
        public bool ShowPattern { get; set; }
        private Point? _spotlight;

        public SoftCard()
        {
            DoubleBuffered = true;
            BackColor = Color.FromArgb(17, 18, 22);
            Resize += (_, __) => ApplyRegion();
        }

        private void ApplyRegion()
        {
            if (Width < 2 || Height < 2) return;
            using (var path = RoundedPath(new Rectangle(0, 0, Width - 1, Height - 1), Radius))
                Region = new Region(path);
            Invalidate();
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            base.OnPaint(e);
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            var bounds = new Rectangle(0, 0, Width - 1, Height - 1);
            using (var path = RoundedPath(bounds, Radius))
            {
                var state = e.Graphics.Save();
                e.Graphics.SetClip(path);
                using (var top = new LinearGradientBrush(new Rectangle(0, 0, Width, Math.Max(1, Height / 2)),
                           Color.FromArgb(13, 255, 255, 255), Color.FromArgb(0, 255, 255, 255), LinearGradientMode.Vertical))
                    e.Graphics.FillRectangle(top, 0, 0, Width, Height / 2);
                if (ShowPattern)
                {
                    using (var dot = new SolidBrush(Color.FromArgb(13, 255, 255, 255)))
                        for (var x = Math.Max(16, Width - 150); x < Width - 12; x += 12)
                            for (var y = 18; y < Height - 12; y += 12)
                                e.Graphics.FillEllipse(dot, x, y, 1.5f, 1.5f);
                }
                if (_spotlight.HasValue)
                {
                    var p = _spotlight.Value;
                    var glow = new Rectangle(p.X - 135, p.Y - 135, 270, 270);
                    using (var glowPath = new GraphicsPath())
                    {
                        glowPath.AddEllipse(glow);
                        using (var brush = new PathGradientBrush(glowPath)
                        {
                            CenterColor = Color.FromArgb(22, 16, 185, 129),
                            SurroundColors = new[] { Color.FromArgb(0, 16, 185, 129) },
                            CenterPoint = p,
                            FocusScales = new PointF(0.15f, 0.15f)
                        })
                            e.Graphics.FillEllipse(brush, glow);
                    }
                }
                e.Graphics.Restore(state);
                using (var pen = new Pen(BorderColor, 1f)) e.Graphics.DrawPath(pen, path);
                if (_spotlight.HasValue)
                {
                    using (var pen = new Pen(Color.FromArgb(55, 16, 185, 129), 1f))
                        e.Graphics.DrawPath(pen, path);
                }
            }
        }

        public void SetSpotlight(Point? point)
        {
            if (_spotlight.HasValue == point.HasValue && (!_spotlight.HasValue ||
                (Math.Abs(_spotlight.Value.X - point.Value.X) < 3 && Math.Abs(_spotlight.Value.Y - point.Value.Y) < 3))) return;
            _spotlight = point;
            Invalidate();
        }

        internal static GraphicsPath RoundedPath(Rectangle bounds, int radius)
        {
            var path = new GraphicsPath();
            var d = Math.Max(2, radius * 2);
            path.AddArc(bounds.Left, bounds.Top, d, d, 180, 90);
            path.AddArc(bounds.Right - d, bounds.Top, d, d, 270, 90);
            path.AddArc(bounds.Right - d, bounds.Bottom - d, d, d, 0, 90);
            path.AddArc(bounds.Left, bounds.Bottom - d, d, d, 90, 90);
            path.CloseFigure();
            return path;
        }
    }

    internal sealed class AccentButton : Button
    {
        private bool _hover;
        private readonly Color _baseColor;
        private readonly Color _hoverColor;
        private Point _pointer;

        public AccentButton(string text, Color baseColor, Color hoverColor)
        {
            Text = text;
            _baseColor = baseColor;
            _hoverColor = hoverColor;
            FlatStyle = FlatStyle.Flat;
            FlatAppearance.BorderSize = 0;
            ForeColor = Color.White;
            Font = new Font("Segoe UI Semibold", 10f, FontStyle.Bold);
            Cursor = Cursors.Hand;
            TextAlign = ContentAlignment.MiddleCenter;
            SetStyle(ControlStyles.UserPaint | ControlStyles.AllPaintingInWmPaint | ControlStyles.OptimizedDoubleBuffer, true);
            MouseEnter += (_, __) => { _hover = true; Invalidate(); };
            MouseLeave += (_, __) => { _hover = false; Invalidate(); };
            MouseMove += (_, e) => { _pointer = e.Location; Invalidate(); };
        }

        protected override void OnPaint(PaintEventArgs e)
        {
            e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
            var bounds = new Rectangle(0, 0, Width - 1, Height - 1);
            e.Graphics.Clear(Parent?.BackColor ?? Color.FromArgb(12, 13, 16));
            var pullX = _hover ? (int)Math.Round((_pointer.X - Width / 2.0) / Math.Max(1, Width) * 4.0) : 0;
            var pullY = _hover ? (int)Math.Round((_pointer.Y - Height / 2.0) / Math.Max(1, Height) * 4.0) : 0;
            var scale = _hover ? 1.02f : 1f;
            var faceWidth = Math.Max(1, (int)((Width - 5) * scale));
            var faceHeight = Math.Max(1, (int)((Height - 5) * scale));
            var face = new Rectangle((Width - faceWidth) / 2 + pullX, (Height - faceHeight) / 2 + pullY, faceWidth, faceHeight);
            using (var path = SoftCard.RoundedPath(face, 12))
            {
                using (var brush = new LinearGradientBrush(face, _hover ? _hoverColor : _baseColor,
                           _hover ? _baseColor : _hoverColor, LinearGradientMode.Horizontal))
                    e.Graphics.FillPath(brush, path);
                if (_hover)
                {
                    using (var edge = new Pen(Color.FromArgb(100, 255, 255, 255), 1f)) e.Graphics.DrawPath(edge, path);
                    using (var glowPath = new GraphicsPath())
                    {
                        glowPath.AddEllipse(_pointer.X - 90 + pullX, _pointer.Y - 90 + pullY, 180, 180);
                        using (var glow = new PathGradientBrush(glowPath)
                        {
                            CenterColor = Color.FromArgb(44, 255, 255, 255),
                            SurroundColors = new[] { Color.FromArgb(0, 255, 255, 255) }
                        })
                        {
                            var state = e.Graphics.Save();
                            e.Graphics.SetClip(path);
                            e.Graphics.FillEllipse(glow, _pointer.X - 90 + pullX, _pointer.Y - 90 + pullY, 180, 180);
                            e.Graphics.Restore(state);
                        }
                    }
                }
            }
            TextRenderer.DrawText(e.Graphics, Text, Font, face, ForeColor,
                TextFormatFlags.HorizontalCenter | TextFormatFlags.VerticalCenter | TextFormatFlags.EndEllipsis);
        }
    }

    internal sealed class RejoinForm : Form
    {
        private static readonly Color Back = Color.FromArgb(9, 10, 12);
        private static readonly Color Card = Color.FromArgb(18, 20, 23);
        private static readonly Color Muted = Color.FromArgb(113, 113, 122);
        private static readonly Color Bright = Color.FromArgb(255, 255, 255);
        private static readonly Color Cyan = Color.FromArgb(20, 184, 166);
        private static readonly Color Purple = Color.FromArgb(139, 92, 246);
        private static readonly Color Green = Color.FromArgb(16, 185, 129);
        private static readonly Color Red = Color.FromArgb(255, 76, 109);
        private const string GameUri = "roblox://placeId=8304191830";
        private const int PollSeconds = 10;

        private bool _english;
        private bool _monitoring;
        private bool _busy;
        private bool _everSawPlayer;
        private bool _internetDown;
        private int _downChecks;
        private int _upChecks;
        private DateTime _lastLaunch = DateTime.MinValue;
        private DateTime? _appReturnSince;
        private string _appReturnKey;
        private string _handledAppReturnKey;
        private string _sessionLogPath;
        private DateTime _sessionLogWriteTime = DateTime.MinValue;
        private string _sessionLogState = "unknown";
        private bool _sessionSawPlay;
        private string _sessionEventKey;

        private Label _subtitle;
        private Label _experienceLabel;
        private Label _gameHint;
        private Label _noteTitle;
        private Label _noteText;
        private Label _activitySubtitle;
        private Label _internetHeading;
        private Label _robloxHeading;
        private Label _gameId;
        private Label _gameBadge;
        private Label _mainStatus;
        private Label _mainDetail;
        private Label _internetValue;
        private Label _internetDetail;
        private Label _robloxValue;
        private Label _robloxDetail;
        private Label _activityTitle;
        private Label _gameTitle;
        private Label _languageButton;
        private Label _minimizeButton;
        private Label _maximizeButton;
        private Label _closeButton;
        private Panel _internetDot;
        private Panel _robloxDot;
        private Panel _mainDot;
        private FlowLayoutPanel _activityList;
        private AccentButton _startButton;
        private AccentButton _stopButton;
        private System.Windows.Forms.Timer _timer;
        private System.Windows.Forms.Timer _ambientTimer;
        private Point _dragOrigin;
        private Point _formOrigin;

        public RejoinForm()
        {
            Text = "Roblox Rejoin";
            StartPosition = FormStartPosition.CenterScreen;
            Size = new Size(1320, 850);
            MinimumSize = new Size(1100, 740);
            BackColor = Back;
            ForeColor = Bright;
            Font = new Font("Segoe UI", 9f);
            FormBorderStyle = FormBorderStyle.None;
            DoubleBuffered = true;
            BuildInterface();
            ApplyLanguage();
            _timer = new System.Windows.Forms.Timer { Interval = PollSeconds * 1000 };
            _timer.Tick += async (_, __) => await MonitorTickAsync();
            FormClosed += (_, __) => _timer.Stop();
            AddActivity("พร้อมใช้งาน", "Ready");
        }

                private void BuildInterface()
        {
            var header = new Panel { Dock = DockStyle.Top, Height = 68, BackColor = Back };
            header.Paint += (_, e) =>
            {
                using (var p = new Pen(Color.FromArgb(30, 255, 255, 255), 1))
                    e.Graphics.DrawLine(p, 0, header.Height - 1, header.Width, header.Height - 1);
            };
            Controls.Add(header);
            HookDrag(header);

            var logo = new SoftCard
            {
                Location = new Point(22, 14), Size = new Size(38, 38),
                BackColor = Color.FromArgb(16, 185, 129), BorderColor = Color.FromArgb(72, 221, 178), Radius = 12
            };
            var logoText = Label("R", 15, FontStyle.Bold, Color.White, ContentAlignment.MiddleCenter);
            logoText.Dock = DockStyle.Fill;
            logo.Controls.Add(logoText);
            header.Controls.Add(logo);
            HookDrag(logo);
            HookDrag(logoText);

            var brand = Label("REJOIN", 11, FontStyle.Bold, Bright);
            brand.Location = new Point(72, 13);
            brand.Size = new Size(112, 18);
            header.Controls.Add(brand);
            HookDrag(brand);

            var aaTab = new SoftCard
            {
                Location = new Point(190, 18), Size = new Size(48, 29),
                BackColor = Color.FromArgb(28, 24, 42), BorderColor = Color.FromArgb(80, 62, 125), Radius = 11
            };
            var aaTabText = Label("AA", 9, FontStyle.Bold, Color.FromArgb(190, 164, 255), ContentAlignment.MiddleCenter);
            aaTabText.Dock = DockStyle.Fill;
            aaTab.Controls.Add(aaTabText);
            header.Controls.Add(aaTab);
            HookDrag(aaTab);

            _subtitle = Label(T("ศูนย์ควบคุม", "CONTROL CENTER"), 8, FontStyle.Regular, Muted);
            _subtitle.Location = new Point(72, 34);
            _subtitle.Size = new Size(160, 16);
            header.Controls.Add(_subtitle);
            HookDrag(_subtitle);

            _languageButton = Label("EN", 9, FontStyle.Bold, Color.FromArgb(191, 198, 205), ContentAlignment.MiddleCenter);
            _languageButton.Cursor = Cursors.Hand;
            _languageButton.Size = new Size(48, 30);
            _languageButton.Anchor = AnchorStyles.Top | AnchorStyles.Right;
            _languageButton.Location = new Point(ClientSize.Width - 202, 18);
            _languageButton.Click += (_, __) => { _english = !_english; ApplyLanguage(); };
            header.Controls.Add(_languageButton);

            _minimizeButton = Label("—", 12, FontStyle.Bold, Muted, ContentAlignment.MiddleCenter);
            _minimizeButton.Cursor = Cursors.Hand;
            _minimizeButton.Size = new Size(34, 30);
            _minimizeButton.Anchor = AnchorStyles.Top | AnchorStyles.Right;
            _minimizeButton.Location = new Point(ClientSize.Width - 104, 18);
            _minimizeButton.Click += (_, __) => WindowState = FormWindowState.Minimized;
            header.Controls.Add(_minimizeButton);

            _maximizeButton = Label("□", 12, FontStyle.Regular, Muted, ContentAlignment.MiddleCenter);
            _maximizeButton.Cursor = Cursors.Hand;
            _maximizeButton.Size = new Size(32, 30);
            _maximizeButton.Anchor = AnchorStyles.Top | AnchorStyles.Right;
            _maximizeButton.Location = new Point(ClientSize.Width - 148, 18);
            _maximizeButton.Click += (_, __) =>
            {
                WindowState = WindowState == FormWindowState.Maximized ? FormWindowState.Normal : FormWindowState.Maximized;
                _maximizeButton.Text = WindowState == FormWindowState.Maximized ? "▣" : "□";
            };
            header.Controls.Add(_maximizeButton);

            _closeButton = Label("×", 18, FontStyle.Regular, Muted, ContentAlignment.MiddleCenter);
            _closeButton.Cursor = Cursors.Hand;
            _closeButton.Size = new Size(34, 30);
            _closeButton.Anchor = AnchorStyles.Top | AnchorStyles.Right;
            _closeButton.Location = new Point(ClientSize.Width - 58, 18);
            _closeButton.Click += (_, __) => Close();
            _closeButton.MouseEnter += (_, __) => _closeButton.ForeColor = Red;
            _closeButton.MouseLeave += (_, __) => _closeButton.ForeColor = Muted;
            header.Controls.Add(_closeButton);

            var shell = new TableLayoutPanel
            {
                Dock = DockStyle.Fill, BackColor = Back, ColumnCount = 2, RowCount = 1,
                Margin = Padding.Empty, Padding = Padding.Empty
            };
            shell.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, 232));
            shell.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100));
            Controls.Add(shell);
            shell.BringToFront();
            header.BringToFront();

            var sidebar = new Panel { Dock = DockStyle.Fill, BackColor = Color.FromArgb(12, 13, 16), Padding = new Padding(16, 18, 16, 16) };
            sidebar.Paint += (_, e) =>
            {
                using (var p = new Pen(Color.FromArgb(22, 255, 255, 255), 1))
                    e.Graphics.DrawLine(p, sidebar.Width - 1, 0, sidebar.Width - 1, sidebar.Height);
            };
            shell.Controls.Add(sidebar, 0, 0);

            var side = new TableLayoutPanel { Dock = DockStyle.Fill, BackColor = Color.Transparent, ColumnCount = 1, RowCount = 8, Margin = Padding.Empty };
            side.RowStyles.Add(new RowStyle(SizeType.Absolute, 54));
            side.RowStyles.Add(new RowStyle(SizeType.Absolute, 28));
            side.RowStyles.Add(new RowStyle(SizeType.Absolute, 42));
            side.RowStyles.Add(new RowStyle(SizeType.Absolute, 44));
            side.RowStyles.Add(new RowStyle(SizeType.Percent, 100));
            side.RowStyles.Add(new RowStyle(SizeType.Absolute, 38));
            side.RowStyles.Add(new RowStyle(SizeType.Absolute, 56));
            side.RowStyles.Add(new RowStyle(SizeType.Absolute, 48));
            sidebar.Controls.Add(side);

            var sideBrand = Label("REJOIN  /  AA", 10, FontStyle.Bold, Bright);
            sideBrand.Dock = DockStyle.Fill;
            side.Controls.Add(sideBrand, 0, 0);
            var navHeading = Label(T("เมนูหลัก", "WORKSPACE"), 7, FontStyle.Bold, Color.FromArgb(91, 99, 108));
            navHeading.Dock = DockStyle.Fill;
            side.Controls.Add(navHeading, 0, 1);
            var activeNav = new SoftCard { Dock = DockStyle.Fill, Margin = new Padding(0, 2, 0, 3), BackColor = Color.FromArgb(17, 36, 31), BorderColor = Color.FromArgb(39, 67, 59), Radius = 12 };
            var activeNavLabel = Label("◉     " + T("ภาพรวม", "Overview"), 9, FontStyle.Bold, Color.FromArgb(110, 231, 183));
            activeNavLabel.Dock = DockStyle.Fill;
            activeNavLabel.Padding = new Padding(12, 0, 0, 0);
            activeNav.Controls.Add(activeNavLabel);
            side.Controls.Add(activeNav, 0, 2);
            var gameNav = new SoftCard { Dock = DockStyle.Fill, Margin = new Padding(0, 2, 0, 4), BackColor = Color.Transparent, BorderColor = Color.Transparent, Radius = 12 };
            var gameNavLabel = Label("◈     ANIME ADVENTURES", 7, FontStyle.Bold, Muted);
            gameNavLabel.Dock = DockStyle.Fill;
            gameNavLabel.Padding = new Padding(12, 0, 0, 0);
            gameNav.Controls.Add(gameNavLabel);
            side.Controls.Add(gameNav, 0, 3);
            var spacer = new Panel { Dock = DockStyle.Fill, BackColor = Color.Transparent };
            side.Controls.Add(spacer, 0, 4);
            var sidebarFoot = Label(T("ระบบพร้อมใช้งาน", "SYSTEM READY"), 7, FontStyle.Bold, Color.FromArgb(102, 111, 121));
            sidebarFoot.Dock = DockStyle.Fill;
            side.Controls.Add(sidebarFoot, 0, 5);

            _startButton = new AccentButton("START  ›", Color.FromArgb(16, 185, 129), Color.FromArgb(20, 184, 166))
            {
                Dock = DockStyle.Fill, Margin = new Padding(0, 2, 0, 4), ForeColor = Color.FromArgb(4, 18, 14)
            };
            _startButton.Click += StartMonitoring;
            side.Controls.Add(_startButton, 0, 6);
            _stopButton = new AccentButton("STOP", Color.FromArgb(30, 34, 39), Color.FromArgb(48, 53, 61))
            {
                Dock = DockStyle.Fill, Margin = new Padding(0, 2, 0, 0), Enabled = false, ForeColor = Color.FromArgb(190, 196, 203)
            };
            _stopButton.Click += StopMonitoring;
            side.Controls.Add(_stopButton, 0, 7);

            var main = new Panel { Dock = DockStyle.Fill, BackColor = Back, Padding = new Padding(25, 19, 25, 20) };
            shell.Controls.Add(main, 1, 0);
            var content = new TableLayoutPanel { Dock = DockStyle.Fill, BackColor = Color.Transparent, ColumnCount = 1, RowCount = 3, Margin = Padding.Empty };
            content.RowStyles.Add(new RowStyle(SizeType.Absolute, 74));
            content.RowStyles.Add(new RowStyle(SizeType.Percent, 55));
            content.RowStyles.Add(new RowStyle(SizeType.Percent, 45));
            main.Controls.Add(content);

            var pageHead = new Panel { Dock = DockStyle.Fill, BackColor = Color.Transparent, Margin = new Padding(0, 0, 0, 12) };
            var crumb = Label(T("ภาพรวม  /  สถานะเกม", "OVERVIEW  /  GAME STATUS"), 7, FontStyle.Bold, Color.FromArgb(107, 117, 128));
            crumb.Location = new Point(2, 0);
            crumb.Size = new Size(400, 18);
            pageHead.Controls.Add(crumb);
            var pageTitle = Label(T("ศูนย์ควบคุม", "Control center"), 22, FontStyle.Bold, Bright);
            pageTitle.Location = new Point(0, 20);
            pageTitle.Size = new Size(460, 40);
            pageHead.Controls.Add(pageTitle);
            var pageSub = Label(T("จัดการการเชื่อมต่อและการเข้าเกมของคุณ", "Manage your connection and game session"), 8, FontStyle.Regular, Muted);
            pageSub.Location = new Point(2, 54);
            pageSub.Size = new Size(520, 18);
            pageHead.Controls.Add(pageSub);
            content.Controls.Add(pageHead, 0, 0);

            var grid = new TableLayoutPanel { Dock = DockStyle.Fill, BackColor = Color.Transparent, ColumnCount = 2, RowCount = 1, Margin = new Padding(0, 0, 0, 14) };
            grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 62));
            grid.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 38));
            content.Controls.Add(grid, 0, 1);

            var hero = new SoftCard { Dock = DockStyle.Fill, Margin = new Padding(0, 0, 8, 0), BackColor = Card, BorderColor = Color.FromArgb(37, 255, 255, 255), Radius = 18, ShowPattern = true };
            grid.Controls.Add(hero, 0, 0);
            _experienceLabel = Label(T("เกมที่เลือก", "SELECTED EXPERIENCE"), 7, FontStyle.Bold, Color.FromArgb(110, 231, 183));
            _experienceLabel.Location = new Point(22, 17);
            _experienceLabel.Size = new Size(250, 18);
            hero.Controls.Add(_experienceLabel);

            var gameMark = new SoftCard { Location = new Point(22, 48), Size = new Size(190, 124), BackColor = Color.FromArgb(26, 28, 33), BorderColor = Color.FromArgb(50, 255, 255, 255), Radius = 14 };
            using (var coverStream = typeof(RejoinForm).Assembly.GetManifestResourceStream("RobloxRejoin.aa-cover.png"))
            using (var coverImage = Image.FromStream(coverStream))
            {
                var cover = new PictureBox { Dock = DockStyle.Fill, SizeMode = PictureBoxSizeMode.StretchImage, Image = new Bitmap(coverImage), BackColor = Color.FromArgb(24, 25, 31) };
                gameMark.Controls.Add(cover);
            }
            hero.Controls.Add(gameMark);

            _gameTitle = Label("Anime Adventures", 17, FontStyle.Bold, Bright);
            _gameTitle.Location = new Point(232, 56);
            _gameTitle.Size = new Size(300, 30);
            _gameTitle.Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right;
            hero.Controls.Add(_gameTitle);
            _gameId = Label("ROBLOX EXPERIENCE   ·   8304191830", 7, FontStyle.Regular, Muted);
            _gameId.Location = new Point(234, 91);
            _gameId.Size = new Size(300, 22);
            _gameId.Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right;
            hero.Controls.Add(_gameId);
            _gameBadge = Label("READY", 7, FontStyle.Bold, Color.FromArgb(110, 231, 183), ContentAlignment.MiddleCenter);
            _gameBadge.BackColor = Color.FromArgb(20, 46, 39);
            _gameBadge.Location = new Point(234, 124);
            _gameBadge.Size = new Size(75, 25);
            hero.Controls.Add(_gameBadge);
            _gameHint = Label(T("พร้อมเชื่อมต่อกลับอัตโนมัติ", "Auto rejoin is standing by"), 8, FontStyle.Regular, Muted);
            _gameHint.Location = new Point(22, 186);
            _gameHint.Size = new Size(360, 18);
            hero.Controls.Add(_gameHint);
            _mainDot = new Panel { BackColor = Color.FromArgb(88, 96, 106), Size = new Size(8, 8), Location = new Point(24, 224) };
            _mainDot.Paint += (_, e) => { e.Graphics.SmoothingMode = SmoothingMode.AntiAlias; using (var b = new SolidBrush(_mainDot.BackColor)) e.Graphics.FillEllipse(b, 0, 0, 7, 7); };
            hero.Controls.Add(_mainDot);
            _mainStatus = Label("หยุดทำงาน", 8, FontStyle.Bold, Muted);
            _mainStatus.Location = new Point(40, 214);
            _mainStatus.Size = new Size(102, 26);
            hero.Controls.Add(_mainStatus);
            _mainDetail = Label(T("กดเริ่มทำงานเพื่อเชื่อมต่อเกม", "Press Start to connect"), 8, FontStyle.Regular, Muted);
            _mainDetail.Location = new Point(144, 214);
            _mainDetail.Size = new Size(350, 26);
            _mainDetail.Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right;
            hero.Controls.Add(_mainDetail);

            var statusStack = new TableLayoutPanel { Dock = DockStyle.Fill, ColumnCount = 1, RowCount = 3, BackColor = Color.Transparent, Margin = new Padding(8, 0, 0, 0) };
            statusStack.RowStyles.Add(new RowStyle(SizeType.Percent, 33.3f));
            statusStack.RowStyles.Add(new RowStyle(SizeType.Percent, 33.3f));
            statusStack.RowStyles.Add(new RowStyle(SizeType.Percent, 33.4f));
            grid.Controls.Add(statusStack, 1, 0);
            var netCard = BuildIndicator(T("อินเทอร์เน็ต", "INTERNET"), out _internetDot, out _internetValue, out _internetDetail);
            netCard.Margin = new Padding(0, 0, 0, 6);
            statusStack.Controls.Add(netCard, 0, 0);
            var robloxCard = BuildIndicator("ROBLOX PLAYER", out _robloxDot, out _robloxValue, out _robloxDetail);
            robloxCard.Margin = new Padding(0, 3, 0, 3);
            statusStack.Controls.Add(robloxCard, 0, 1);
            var note = new SoftCard { Dock = DockStyle.Fill, Margin = new Padding(0, 6, 0, 0), BackColor = Color.FromArgb(19, 18, 27), BorderColor = Color.FromArgb(56, 45, 77), Radius = 16, ShowPattern = true };
            _noteTitle = Label(T("เข้าเกมอัตโนมัติ", "AUTO REJOIN"), 7, FontStyle.Bold, Color.FromArgb(190, 164, 255));
            _noteTitle.Location = new Point(15, 11);
            _noteTitle.Size = new Size(220, 17);
            note.Controls.Add(_noteTitle);
            _noteText = Label(T("เมื่อเน็ตหลุดหรือกลับหน้าแอป จะพยายามเข้าเกมใหม่", "Rejoins after an outage or return to the app."), 7, FontStyle.Regular, Muted);
            _noteText.Location = new Point(15, 33);
            _noteText.Size = new Size(240, 40);
            _noteText.Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right;
            note.Controls.Add(_noteText);
            statusStack.Controls.Add(note, 0, 2);

            var activity = new SoftCard { Dock = DockStyle.Fill, Margin = new Padding(0), BackColor = Card, BorderColor = Color.FromArgb(37, 255, 255, 255), Radius = 18, Padding = new Padding(20, 15, 20, 12) };
            content.Controls.Add(activity, 0, 2);
            _activityTitle = Label(T("กิจกรรมล่าสุด", "Recent activity"), 12, FontStyle.Bold, Bright);
            _activityTitle.Location = new Point(20, 15);
            _activityTitle.Size = new Size(320, 23);
            activity.Controls.Add(_activityTitle);
            _activitySubtitle = Label(T("สถานะการเชื่อมต่อและกิจกรรมเกม", "Connection and game events"), 7, FontStyle.Regular, Muted);
            _activitySubtitle.Location = new Point(21, 39);
            _activitySubtitle.Size = new Size(400, 17);
            activity.Controls.Add(_activitySubtitle);
            var line = new Panel { BackColor = Color.FromArgb(30, 255, 255, 255), Location = new Point(20, 65), Height = 1, Anchor = AnchorStyles.Top | AnchorStyles.Left | AnchorStyles.Right };
            activity.Controls.Add(line);
            _activityList = new FlowLayoutPanel
            {
                Location = new Point(20, 76), Size = new Size(600, 220),
                Anchor = AnchorStyles.Top | AnchorStyles.Bottom | AnchorStyles.Left | AnchorStyles.Right,
                FlowDirection = FlowDirection.TopDown, WrapContents = false, AutoScroll = true,
                BackColor = Card, Margin = Padding.Empty
            };
            activity.Controls.Add(_activityList);

            _ambientTimer = new System.Windows.Forms.Timer { Interval = 33 };
            _ambientTimer.Tick += (_, __) => UpdateSpotlights();
            _ambientTimer.Start();
            Resize += (_, __) =>
            {
                if (WindowState == FormWindowState.Maximized) Region = null; else ApplyRoundedControls();
                _languageButton.Location = new Point(ClientSize.Width - 202, 18);
                _maximizeButton.Location = new Point(ClientSize.Width - 148, 18);
                _minimizeButton.Location = new Point(ClientSize.Width - 104, 18);
                _closeButton.Location = new Point(ClientSize.Width - 58, 18);
            };
            FormClosed += (_, __) => _ambientTimer.Stop();
            ApplyRoundedControls();
        }

        private void UpdateSpotlights()
        {
            var pointer = Cursor.Position;
            foreach (var card in FindCards(this))
            {
                if (!card.IsHandleCreated || !card.Visible) continue;
                var local = card.PointToClient(pointer);
                var inside = card.ClientRectangle.Contains(local);
                card.SetSpotlight(inside ? (Point?)local : null);
            }
        }

        private static IEnumerable<SoftCard> FindCards(Control parent)
        {
            foreach (Control child in parent.Controls)
            {
                if (child is SoftCard card) yield return card;
                foreach (var nested in FindCards(child)) yield return nested;
            }
        }
private SoftCard BuildIndicator(string heading, out Panel dot, out Label value, out Label detail)
        {
            var card = new SoftCard
            {
                Dock = DockStyle.Fill, BackColor = Card,
                BorderColor = Color.FromArgb(37, 40, 49), Radius = 16
            };
            var header = Label(heading, 7, FontStyle.Bold, Muted);
            if (heading.Contains("INTERNET") || heading.Contains("อินเทอร์เน็ต")) _internetHeading = header;
            else _robloxHeading = header;
            header.Location = new Point(14, 12);
            header.Size = new Size(160, 17);
            card.Controls.Add(header);

            dot = new Panel { Size = new Size(7, 7), BackColor = Red, Location = new Point(15, 42) };
            var dotControl = dot;
            dotControl.Paint += (_, e) =>
            {
                e.Graphics.SmoothingMode = SmoothingMode.AntiAlias;
                using (var b = new SolidBrush(dotControl.BackColor)) e.Graphics.FillEllipse(b, 0, 0, dotControl.Width - 1, dotControl.Height - 1);
            };
            card.Controls.Add(dotControl);

            value = Label(T("ออฟไลน์", "Offline"), 11, FontStyle.Bold, Red);
            value.Location = new Point(29, 35);
            value.Size = new Size(150, 24);
            card.Controls.Add(value);

            detail = Label(T("รอเริ่มตรวจสอบ", "Waiting to monitor"), 7, FontStyle.Regular, Muted);
            detail.Location = new Point(14, 69);
            detail.Size = new Size(166, 20);
            card.Controls.Add(detail);
            return card;
        }

        private void ApplyRoundedControls()
        {
            Region = new Region(SoftCard.RoundedPath(new Rectangle(0, 0, Width - 1, Height - 1), 18));
        }

        private void HookDrag(Control control)
        {
            control.MouseDown += (_, e) =>
            {
                if (e.Button != MouseButtons.Left) return;
                _dragOrigin = Cursor.Position;
                _formOrigin = Location;
            };
            control.MouseMove += (_, e) =>
            {
                if (e.Button == MouseButtons.Left)
                    Location = new Point(_formOrigin.X + Cursor.Position.X - _dragOrigin.X,
                                         _formOrigin.Y + Cursor.Position.Y - _dragOrigin.Y);
            };
        }

        private static Label Label(string text, float size, FontStyle style, Color color,
                                   ContentAlignment align = ContentAlignment.MiddleLeft)
        {
            return new Label
            {
                Text = text, Font = new Font("Segoe UI", size, style), ForeColor = color,
                BackColor = Color.Transparent, AutoSize = false, TextAlign = align, UseCompatibleTextRendering = true
            };
        }

        private string T(string thai, string english) => _english ? english : thai;

        private void ApplyLanguage()
        {
            _languageButton.Text = _english ? "TH" : "EN";
            _subtitle.Text = T("ศูนย์ควบคุม", "CONTROL CENTER");
            _experienceLabel.Text = T("ประสบการณ์ของคุณ", "YOUR EXPERIENCE");
            _gameHint.Text = T("พร้อมเชื่อมต่อกลับอัตโนมัติ", "Auto rejoin is standing by");
            _noteTitle.Text = T("เข้าเกมอัตโนมัติ", "AUTO REJOIN");
            _noteText.Text = T("เมื่อเน็ตหลุดหรือ Roblox กลับหน้าแอป โปรแกรมจะพยายามเข้าเกมใหม่", "Rejoins after an outage or a return to the Roblox app.");
            _activitySubtitle.Text = T("สถานะการเชื่อมต่อและกิจกรรมเกม", "Connection and game events");
            _gameId.Text = T("ประสบการณ์ Roblox  ·  Place ID 8304191830", "Roblox experience  ·  Place ID 8304191830");
            _gameBadge.Text = _monitoring ? T("กำลังทำงาน", "ACTIVE") : T("พร้อมใช้งาน", "READY");
            _startButton.Text = T("เริ่มทำงาน", "START");
            _stopButton.Text = T("หยุดทำงาน", "STOP");
            _activityTitle.Text = T("กิจกรรมล่าสุด", "Recent activity");
            _internetHeading.Text = T("อินเทอร์เน็ต", "INTERNET");
            _robloxHeading.Text = "ROBLOX PLAYER";
            _mainStatus.Text = _monitoring ? T("กำลังทำงาน", "Running") : T("หยุดทำงาน", "Stopped");
            _mainDetail.Text = _monitoring
                ? T("ตรวจสอบ Roblox และอินเทอร์เน็ตทุก 10 วินาที", "Roblox and internet are checked every 10 seconds")
                : T("กดเริ่มทำงานเพื่อเชื่อมต่อ Anime Adventures", "Press Start to connect to Anime Adventures");
            _internetValue.Text = _internetValue.ForeColor == Green ? T("ออนไลน์", "Online") : T("ออฟไลน์", "Offline");
            _robloxValue.Text = _robloxValue.ForeColor == Green ? T("ออนไลน์", "Online") : T("ออฟไลน์", "Offline");
        }

        private void SetMainStatus(string titleThai, string titleEnglish, string detailThai, string detailEnglish, Color color)
        {
            _mainStatus.Text = T(titleThai, titleEnglish);
            _mainStatus.ForeColor = color;
            _mainDot.BackColor = color;
            _mainDot.Invalidate();
            _mainDetail.Text = T(detailThai, detailEnglish);
            _gameBadge.Text = _monitoring ? T("กำลังทำงาน", "ACTIVE") : T("พร้อมใช้งาน", "READY");
        }

        private void SetIndicator(bool online, Label value, Label detail, Panel dot, string detailThai, string detailEnglish)
        {
            value.Text = online ? T("ออนไลน์", "Online") : T("ออฟไลน์", "Offline");
            value.ForeColor = online ? Green : Red;
            dot.BackColor = online ? Green : Red;
            dot.Invalidate();
            detail.Text = T(detailThai, detailEnglish);
        }

        private void AddActivity(string thai, string english)
        {
            var row = new Panel
            {
                Width = Math.Max(300, _activityList.ClientSize.Width - 28),
                Height = 62, BackColor = Card, Margin = new Padding(0, 0, 0, 2)
            };
            var time = Label(DateTime.Now.ToString("HH:mm"), 8, FontStyle.Regular, Muted);
            time.Location = new Point(2, 8);
            time.Size = new Size(48, 20);
            row.Controls.Add(time);

            var marker = new Panel { BackColor = Color.FromArgb(54, 62, 76), Location = new Point(60, 11), Size = new Size(6, 6) };
            row.Controls.Add(marker);

            var message = Label(T(thai, english), 9, FontStyle.Regular, Color.FromArgb(224, 228, 236));
            message.Location = new Point(78, 4);
            message.Size = new Size(Math.Max(180, row.Width - 92), 46);
            row.Controls.Add(message);
            row.Resize += (_, __) => message.Width = Math.Max(180, row.Width - 92);

            _activityList.Controls.Add(row);
            while (_activityList.Controls.Count > 36)
            {
                var first = _activityList.Controls[0];
                _activityList.Controls.RemoveAt(0);
                first.Dispose();
            }
            _activityList.ScrollControlIntoView(row);
        }

        private void StartMonitoring(object sender, EventArgs e)
        {
            if (_monitoring) return;
            _monitoring = true;
            _everSawPlayer = false;
            _internetDown = false;
            _downChecks = 0;
            _upChecks = 0;
            _appReturnSince = null;
            _appReturnKey = null;
            _handledAppReturnKey = null;
            ApplyLanguage();
            _startButton.Enabled = false;
            _stopButton.Enabled = true;
            _timer.Start();

            var players = GetPlayerIds();
            if (players.Length > 0)
            {
                _everSawPlayer = true;
                SetIndicator(true, _robloxValue, _robloxDetail, _robloxDot,
                    "พบ Roblox Player กำลังทำงาน", "Roblox Player process is running");
                SetMainStatus("กำลังทำงาน", "Running",
                    "พบเกมที่เปิดอยู่แล้ว จะไม่เปิดซ้ำ", "An existing Roblox Player was found; skipping launch", Green);
                AddActivity("พบ Roblox Player ที่เปิดอยู่แล้ว จึงไม่เปิดเกมซ้ำ",
                    "Found a running Roblox Player; skipped duplicate launch");
                _ = RefreshInternetIndicatorAsync();
            }
            else
            {
                SetIndicator(false, _robloxValue, _robloxDetail, _robloxDot,
                    "กำลังเปิด Roblox", "Launching Roblox");
                SetMainStatus("กำลังเปิดเกม", "Launching game",
                    "กำลังเชื่อมต่อ Anime Adventures", "Connecting to Anime Adventures", Cyan);
                AddActivity("เริ่มทำงานและกำลังเปิด Anime Adventures",
                    "Started; launching Anime Adventures");
                LaunchGame();
            }
        }

        private async Task RefreshInternetIndicatorAsync()
        {
            var online = await Task.Run(CheckInternet);
            SetIndicator(online, _internetValue, _internetDetail, _internetDot,
                online ? "เชื่อมต่ออินเทอร์เน็ตได้" : "ยังเชื่อมต่ออินเทอร์เน็ตไม่ได้",
                online ? "Internet connection available" : "Internet is unreachable");
        }

        private void StopMonitoring(object sender, EventArgs e)
        {
            _monitoring = false;
            _timer.Stop();
            _appReturnSince = null;
            var active = GetPlayerIds().Length > 0;
            SetIndicator(active, _robloxValue, _robloxDetail, _robloxDot,
                active ? "Roblox Player ยังทำงาน" : "ไม่พบ Roblox Player",
                active ? "Roblox Player is still running" : "Roblox Player not found");
            SetMainStatus("หยุดทำงาน", "Stopped",
                "Roblox ที่กำลังเปิดอยู่จะไม่ถูกปิด", "The running Roblox Player will not be closed", Muted);
            _startButton.Enabled = true;
            _stopButton.Enabled = false;
            AddActivity("หยุดทำงานแล้ว", "Stopped");
        }

        private async Task MonitorTickAsync()
        {
            if (!_monitoring || _busy) return;
            _busy = true;
            try
            {
                bool internet = await Task.Run(CheckInternet);
                var players = GetPlayerIds();

                SetIndicator(players.Length > 0, _robloxValue, _robloxDetail, _robloxDot,
                    players.Length > 0 ? "พบ Roblox Player กำลังทำงาน" : "ไม่พบ Roblox Player",
                    players.Length > 0 ? "Roblox Player process is running" : "Roblox Player not found");

                if (!internet)
                {
                    _upChecks = 0;
                    _downChecks++;
                    SetIndicator(false, _internetValue, _internetDetail, _internetDot,
                        "เชื่อมต่ออินเทอร์เน็ตไม่ได้", "Internet connection is unreachable");
                    if (_downChecks >= 3)
                    {
                        if (!_internetDown)
                            AddActivity("ตรวจพบว่าอินเทอร์เน็ตขาด กำลังรอการเชื่อมต่อกลับมา",
                                "Internet outage detected; waiting for connection to return");
                        _internetDown = true;
                        SetMainStatus("อินเทอร์เน็ตขาด", "Internet disconnected",
                            "จะเข้าเกมใหม่เมื่ออินเทอร์เน็ตกลับมา", "The game will rejoin when internet returns", Red);
                    }
                    else
                    {
                        SetMainStatus("กำลังตรวจสอบเน็ต", "Checking internet",
                            "การเชื่อมต่อสะดุด กำลังตรวจซ้ำ", "Connection check failed; retrying", Purple);
                    }
                    return;
                }

                _downChecks = 0;
                SetIndicator(true, _internetValue, _internetDetail, _internetDot,
                    "เชื่อมต่ออินเทอร์เน็ตได้", "Internet connection available");
                if (_internetDown)
                {
                    _upChecks++;
                    SetMainStatus("เน็ตกลับมาแล้ว", "Internet restored",
                        "กำลังยืนยันความเสถียรก่อนเข้าเกม", "Confirming a stable connection before rejoining", Purple);
                    if (_upChecks < 2) return;

                    _internetDown = false;
                    _upChecks = 0;
                    players = GetPlayerIds();
                    if (players.Length > 0)
                    {
                        AddActivity("เน็ตกลับมาแล้ว กำลังเริ่ม Roblox ใหม่เพื่อเชื่อมต่อ",
                            "Internet restored; restarting Roblox to reconnect");
                        StopPlayers(players);
                        SetIndicator(false, _robloxValue, _robloxDetail, _robloxDot,
                            "กำลังเริ่มเกมใหม่", "Restarting game");
                        await Task.Delay(1500);
                    }
                    _everSawPlayer = false;
                    LaunchGame();
                    return;
                }

                players = GetPlayerIds();
                var session = await Task.Run(ReadSessionState);
                if (players.Length > 0 && session != null && session.State == "app-after-play" && !string.IsNullOrEmpty(session.EventKey))
                {
                    var key = session.Path + "|" + session.EventKey;
                    if (key != _handledAppReturnKey)
                    {
                        if (key != _appReturnKey)
                        {
                            _appReturnKey = key;
                            _appReturnSince = DateTime.Now;
                            SetMainStatus("กลับมาหน้า Roblox แล้ว", "Returned to Roblox home",
                                "กำลังรอ 20 วินาที เผื่อเกมกำลังเชื่อมต่อใหม่", "Waiting 20 seconds in case Roblox is still transitioning", Purple);
                            AddActivity("ตรวจพบการกลับสู่หน้าแอป Roblox หลังออกจากเกม",
                                "Detected a return to the Roblox app after gameplay");
                        }
                        if (_appReturnSince.HasValue && (DateTime.Now - _appReturnSince.Value).TotalSeconds >= 20)
                        {
                            _handledAppReturnKey = key;
                            _appReturnSince = null;
                            _appReturnKey = null;
                            AddActivity("ยังอยู่หน้า Roblox หลังรอ 20 วินาที กำลังเข้าเกมใหม่",
                                "Still on the Roblox app screen after 20 seconds; rejoining");
                            StopPlayers(players);
                            await Task.Delay(1500);
                            _everSawPlayer = false;
                            LaunchGame();
                        }
                        return;
                    }
                }
                else
                {
                    _appReturnSince = null;
                    _appReturnKey = null;
                }

                if (players.Length > 0)
                {
                    _everSawPlayer = true;
                    SetMainStatus("กำลังทำงาน", "Running",
                        "Roblox Player ทำงานและอินเทอร์เน็ตปกติ", "Roblox Player is running and internet is available", Green);
                    return;
                }

                if (!_everSawPlayer && (DateTime.Now - _lastLaunch).TotalSeconds < 90)
                {
                    SetMainStatus("กำลังเข้าเกม", "Joining game",
                        "รอ Roblox Player เริ่มทำงาน", "Waiting for Roblox Player to start", Cyan);
                    return;
                }
                if ((DateTime.Now - _lastLaunch).TotalSeconds >= 30)
                {
                    AddActivity("ไม่พบ Roblox Player กำลังลองเข้าเกมใหม่",
                        "Roblox Player not found; trying to rejoin");
                    LaunchGame();
                }
            }
            catch (Exception ex)
            {
                SetMainStatus("เกิดข้อผิดพลาด", "Monitor error",
                    ex.Message, ex.Message, Red);
                AddActivity("เกิดข้อผิดพลาดระหว่างตรวจสอบ", "An error occurred while monitoring");
            }
            finally
            {
                _busy = false;
            }
        }

        private static bool CheckInternet()
        {
            using (var client = new TcpClient())
            {
                try
                {
                    var pending = client.BeginConnect("1.1.1.1", 443, null, null);
                    if (!pending.AsyncWaitHandle.WaitOne(2500)) return false;
                    client.EndConnect(pending);
                    return client.Connected;
                }
                catch { return false; }
            }
        }

        private static int[] GetPlayerIds()
        {
            try
            {
                return Process.GetProcessesByName("RobloxPlayerBeta").Select(p =>
                {
                    int id = p.Id;
                    p.Dispose();
                    return id;
                }).ToArray();
            }
            catch { return Array.Empty<int>(); }
        }

        private static void StopPlayers(int[] playerIds)
        {
            foreach (var id in playerIds)
            {
                try { using (var process = Process.GetProcessById(id)) process.Kill(); }
                catch { }
            }
        }
        private void LaunchGame()
        {
            _lastLaunch = DateTime.Now;
            SetMainStatus("กำลังเปิดเกม", "Launching game",
                "กำลังเรียก Roblox ให้เข้า Anime Adventures", "Opening Roblox to join Anime Adventures", Cyan);
            try
            {
                Process.Start(new ProcessStartInfo(GameUri) { UseShellExecute = true });
            }
            catch (Exception ex)
            {
                SetMainStatus("เปิดเกมไม่สำเร็จ", "Could not launch",
                    ex.Message, ex.Message, Red);
                AddActivity("เรียก Roblox ไม่สำเร็จ", "Could not start Roblox");
            }
        }

        private SessionSnapshot ReadSessionState()
        {
            var directory = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "Roblox", "logs");
            try
            {
                var file = new DirectoryInfo(directory).GetFiles("*_Player_*_last.log")
                    .Where(f => !f.Name.Contains("_CrashHandler_", StringComparison.OrdinalIgnoreCase))
                    .OrderByDescending(f => f.LastWriteTimeUtc).FirstOrDefault();
                if (file == null) return null;

                if (string.Equals(_sessionLogPath, file.FullName, StringComparison.OrdinalIgnoreCase)
                    && _sessionLogWriteTime == file.LastWriteTimeUtc)
                    return new SessionSnapshot(_sessionLogPath, _sessionLogState, _sessionEventKey);

                bool newLog = !string.Equals(_sessionLogPath, file.FullName, StringComparison.OrdinalIgnoreCase);
                if (newLog)
                {
                    _sessionLogPath = file.FullName;
                    _sessionLogState = "unknown";
                    _sessionSawPlay = false;
                    _sessionEventKey = null;
                }

                IEnumerable<string> lines = File.ReadLines(file.FullName);
                if (!newLog)
                    lines = lines.TakeLast(5000);

                foreach (var line in lines)
                {
                    if (line.Contains("[FLog::SessionTransitionFSM] Entered play session.", StringComparison.Ordinal))
                    {
                        _sessionSawPlay = true;
                        _sessionLogState = "play";
                        _sessionEventKey = null;
                    }
                    else if (line.Contains("[FLog::SessionTransitionFSM] Entered app session.", StringComparison.Ordinal))
                    {
                        if (_sessionSawPlay)
                        {
                            _sessionLogState = "app-after-play";
                            _sessionEventKey = line;
                        }
                        else _sessionLogState = "app-before-play";
                    }
                }
                _sessionLogWriteTime = file.LastWriteTimeUtc;
                return new SessionSnapshot(_sessionLogPath, _sessionLogState, _sessionEventKey);
            }
            catch { return null; }
        }

        private sealed class SessionSnapshot
        {
            public string Path { get; }
            public string State { get; }
            public string EventKey { get; }
            public SessionSnapshot(string path, string state, string eventKey)
            {
                Path = path;
                State = state;
                EventKey = eventKey;
            }
        }
    }
}
