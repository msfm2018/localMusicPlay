[Setup]
AppName=CV Player
AppVersion=1.0
AppPublisher=CV
DefaultDirName={pf}\CVPlayer
DefaultGroupName=CV Player
OutputDir=.
OutputBaseFilename=CVPlayerSetup
Compression=lzma2
SolidCompression=yes
ArchitecturesInstallIn64BitMode=x64
ChangesAssociations=yes

[Files]
; 主程序 + 所有资源（递归整个目录）
Source: "D:\music\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Icons]
Name: "{group}\CV Player"; Filename: "{app}\cv.exe"
Name: "{commondesktop}\CV Player"; Filename: "{app}\cv.exe"; Tasks: desktopicon

[Tasks]
Name: "desktopicon"; Description: "创建桌面快捷方式"; GroupDescription: "附加任务:"; Flags: unchecked

; =========================
; 文件类型定义
; =========================
[Registry]

; ---- 定义统一文件类型 ----
Root: HKCR; Subkey: "CVPlayer.Media"; ValueType: string; ValueData: "CV Player Media File"; Flags: uninsdeletekey
Root: HKCR; Subkey: "CVPlayer.Media\DefaultIcon"; ValueType: string; ValueData: "{app}\cv.exe,0"
Root: HKCR; Subkey: "CVPlayer.Media\shell"; ValueType: string; ValueData: "open"

; 默认双击行为
Root: HKCR; Subkey: "CVPlayer.Media\shell\open"; ValueType: string; ValueData: "打开"
Root: HKCR; Subkey: "CVPlayer.Media\shell\open\command"; ValueType: string; ValueData: """{app}\cv.exe"" ""%1"""

; =========================
; 右键菜单增强
; =========================

; 用 CV 播放
Root: HKCR; Subkey: "CVPlayer.Media\shell\PlayWithCV"; ValueType: string; ValueData: "用 CV Player 播放"
Root: HKCR; Subkey: "CVPlayer.Media\shell\PlayWithCV\command"; ValueType: string; ValueData: """{app}\cv.exe"" ""%1"""

; 加入播放列表（多文件）
Root: HKCR; Subkey: "CVPlayer.Media\shell\AddToCV"; ValueType: string; ValueData: "添加到 CV 播放列表"
Root: HKCR; Subkey: "CVPlayer.Media\shell\AddToCV\command"; ValueType: string; ValueData: """{app}\cv.exe"" ""%*"""

; =========================
; 关联扩展名
; =========================

; ---- 音频 ----
Root: HKCR; Subkey: ".mp3"; ValueType: string; ValueData: "CVPlayer.Media"; Flags: uninsdeletevalue
Root: HKCR; Subkey: ".wav"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".flac"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".aac"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".m4a"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".ogg"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".wma"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".opus"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".alac"; ValueType: string; ValueData: "CVPlayer.Media"

; ---- 视频 ----
Root: HKCR; Subkey: ".mp4"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".mkv"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".avi"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".mov"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".wmv"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".flv"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".webm"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".m4v"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".ts"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".mpg"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".mpeg"; ValueType: string; ValueData: "CVPlayer.Media"
Root: HKCR; Subkey: ".3gp"; ValueType: string; ValueData: "CVPlayer.Media"

; =========================
; 卸载清理
; =========================
[UninstallDelete]
Type: filesandordirs; Name: "{app}"
