[Setup]
AppName=Equilibrium
AppVersion=v1.0-Preview
AppPublisher=Equilibrium Team
DefaultDirName={autopf}\Equilibrium
DefaultGroupName=Equilibrium
OutputDir=installer
OutputBaseFilename=Equilibrium_Setup
SetupIconFile=assets\model.ico
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Languages]
Name: "brazilianportuguese"; MessagesFile: "compiler:Languages\BrazilianPortuguese.isl"

[Files]
Source: "assets\model.ico"; DestDir: "{app}"; Flags: ignoreversion
Source: "build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs

[Icons]
Name: "{group}\Equilibrium"; Filename: "{app}\equilibrium.exe"; IconFilename: "{app}\model.ico"
Name: "{commondesktop}\Equilibrium"; Filename: "{app}\equilibrium.exe"; IconFilename: "{app}\model.ico"