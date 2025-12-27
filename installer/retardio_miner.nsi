; Retardio Miner Installer Script
; Requires NSIS (https://nsis.sourceforge.io/)

!include "MUI2.nsh"

; General
Name "Retardio Miner"
OutFile "RetardioMiner-Setup.exe"
InstallDir "$LOCALAPPDATA\RetardioMiner"
RequestExecutionLevel user

; Interface
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\modern-install.ico"
!define MUI_HEADERIMAGE
!define MUI_ABORTWARNING

; Pages
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

; Language
!insertmacro MUI_LANGUAGE "English"

; Installation
Section "Install"
    SetOutPath "$INSTDIR"

    ; Files to install
    File "..\miner_package\miner_gui.html"
    File "..\miner_package\start_mining.bat"
    File "..\wallet_gui.html"

    ; Create uninstaller
    WriteUninstaller "$INSTDIR\Uninstall.exe"

    ; Start menu shortcuts
    CreateDirectory "$SMPROGRAMS\Retardio Miner"
    CreateShortCut "$SMPROGRAMS\Retardio Miner\Mining Guide.lnk" "$INSTDIR\miner_gui.html"
    CreateShortCut "$SMPROGRAMS\Retardio Miner\Wallet.lnk" "$INSTDIR\wallet_gui.html"
    CreateShortCut "$SMPROGRAMS\Retardio Miner\Start Mining.lnk" "$INSTDIR\start_mining.bat"
    CreateShortCut "$SMPROGRAMS\Retardio Miner\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

    ; Desktop shortcut
    CreateShortCut "$DESKTOP\Retardio Miner.lnk" "$INSTDIR\miner_gui.html"
SectionEnd

; Uninstaller
Section "Uninstall"
    Delete "$INSTDIR\miner_gui.html"
    Delete "$INSTDIR\start_mining.bat"
    Delete "$INSTDIR\wallet_gui.html"
    Delete "$INSTDIR\config.txt"
    Delete "$INSTDIR\Uninstall.exe"

    Delete "$SMPROGRAMS\Retardio Miner\*.*"
    RMDir "$SMPROGRAMS\Retardio Miner"
    Delete "$DESKTOP\Retardio Miner.lnk"

    RMDir "$INSTDIR"
SectionEnd
