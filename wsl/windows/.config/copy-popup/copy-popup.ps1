# Omarchy-style "Copied to clipboard" popup for Windows Terminal.
# Listens for clipboard changes and, when Windows Terminal is the foreground
# window (copy on select, Ctrl+C), shows a Tokyo Night card in the top-right
# corner for a moment. Started at login from the Startup folder.
Add-Type -ReferencedAssemblies System.Windows.Forms, System.Drawing -TypeDefinition @'
using System;
using System.Diagnostics;
using System.Drawing;
using System.Runtime.InteropServices;
using System.Text.RegularExpressions;
using System.Windows.Forms;

public class CopyPopup : Form {
    [DllImport("user32.dll")] static extern bool AddClipboardFormatListener(IntPtr hwnd);
    [DllImport("user32.dll")] static extern IntPtr GetForegroundWindow();
    [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr hwnd, out uint pid);
    [DllImport("user32.dll")] static extern bool SetProcessDPIAware();

    const int WM_CLIPBOARDUPDATE = 0x031D;
    const int WS_EX_TOPMOST = 0x8, WS_EX_TOOLWINDOW = 0x80, WS_EX_NOACTIVATE = 0x08000000;
    const string FontName = "JetBrainsMono Nerd Font";

    readonly Label preview;
    readonly Timer hideTimer = new Timer { Interval = 1800 };
    readonly float scale;

    public CopyPopup() {
        using (var g = CreateGraphics()) scale = g.DpiX / 96f;
        Text = "copy-popup";
        FormBorderStyle = FormBorderStyle.None;
        ShowInTaskbar = false;
        StartPosition = FormStartPosition.Manual;
        Size = new Size(S(360), S(66));
        // Tokyo Night: accent border around the background
        BackColor = ColorTranslator.FromHtml("#7aa2f7");
        Padding = new Padding(S(2));

        var card = new Panel { Dock = DockStyle.Fill, BackColor = ColorTranslator.FromHtml("#1a1b26") };
        card.Controls.Add(new Label {
            Text = "Copied to clipboard",
            ForeColor = ColorTranslator.FromHtml("#c0caf5"),
            Font = new Font(FontName, 10f, FontStyle.Bold),
            Location = new Point(S(14), S(10)), AutoSize = true
        });
        preview = new Label {
            ForeColor = ColorTranslator.FromHtml("#a9b1d6"),
            Font = new Font(FontName, 9f),
            Location = new Point(S(14), S(34)), Size = new Size(S(328), S(20)),
            AutoEllipsis = true
        };
        card.Controls.Add(preview);
        Controls.Add(card);

        hideTimer.Tick += (s, e) => { hideTimer.Stop(); Hide(); };
    }

    int S(int px) { return (int)Math.Round(px * scale); }

    protected override bool ShowWithoutActivation { get { return true; } }

    protected override CreateParams CreateParams {
        get {
            var cp = base.CreateParams;
            cp.ExStyle |= WS_EX_TOPMOST | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE;
            return cp;
        }
    }

    protected override void OnHandleCreated(EventArgs e) {
        base.OnHandleCreated(e);
        AddClipboardFormatListener(Handle);
    }

    protected override void WndProc(ref Message m) {
        if (m.Msg == WM_CLIPBOARDUPDATE && TerminalIsForeground()) Popup();
        base.WndProc(ref m);
    }

    static bool TerminalIsForeground() {
        uint pid;
        GetWindowThreadProcessId(GetForegroundWindow(), out pid);
        try { return Process.GetProcessById((int)pid).ProcessName == "WindowsTerminal"; }
        catch { return false; }
    }

    void Popup() {
        string text = "";
        try { if (Clipboard.ContainsText()) text = Clipboard.GetText(); } catch { }
        string[] lines = text.Trim().Split('\n');
        string first = Regex.Replace(lines[0], @"\s+", " ").Trim();
        preview.Text = lines.Length > 1 ? first + "  (+" + (lines.Length - 1) + " lines)" : first;

        var area = Screen.FromPoint(Cursor.Position).WorkingArea;
        Location = new Point(area.Right - Width - S(10), area.Top + S(10));
        Show();
        hideTimer.Stop();
        hideTimer.Start();
    }

    public static void Run() {
        SetProcessDPIAware();
        Application.EnableVisualStyles();
        var popup = new CopyPopup();
        IntPtr handle = popup.Handle; // create the window (hidden) so it gets clipboard messages
        Application.Run();
    }
}
'@

$mutex = New-Object System.Threading.Mutex($false, 'Local\CopyPopup')
if (-not $mutex.WaitOne(0)) { exit }
[CopyPopup]::Run()
