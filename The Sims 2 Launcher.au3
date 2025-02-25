; The Sims 1 Launcher by anadius

#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <Array.au3>

Global Const $sKEY = '\Software\Electronic Arts\The Sims 2 Ultimate Collection 25', _
    $sExePath = 'EP9\TSBin\Sims2EP9.exe', _
    $aLangCodes[22] = [11, 9, 3, 13, 1, 5, 7, 2, 24, 4, 14, 15, 8, 22, 20, 10, 23, 16, 6, 21, 17, 18], _
    $aLangNames[22] = ['Czech', 'Danish', 'German', 'English (United Kingdom)', _
    'English (United States)', 'Spanish', 'Finnish', 'French', 'Hungarian', _
    'Italian', 'Japanese', 'Korean', 'Dutch', 'Norwegian', 'Polish', _
    'Portuguese (Brazil)', 'Portuguese (Portugal)', 'Russian', 'Swedish', _
    'Thai', 'Chinese (Simplified)', 'Chinese (Traditional)']

Global $sHKCU

If @OSArch = 'X64' Then
    $sHKCU = 'HKCU64'
Else
    $sHKCU = 'HKCU'
EndIf

ShowGUI()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func _PathRemoveTrail($sPath)
    If StringRight($sPath, 1) == '\' Then
        $sPath = StringTrimRight($sPath, 1)
    EndIf
    Return $sPath
EndFunc

Func ShowGUI()
    Local $iLangIndex = -1, $iLang, $hGUI, $hComboBox, $hPlayButton, $hRedistButton

    ; create main GUI window
    $hGUI = GUICreate('The Sims 2 Launcher', 305, 123)

    $iFromTop = 5
    GUICtrlCreateLabel('made by anadius', 9, $iFromTop)

    ; create dropdown menu
    $hComboBox = GUICtrlCreateCombo('', 10, 28, 280)
    GUICtrlSetData($hComboBox, _ArrayToString($aLangNames))
    ; create Play button
    $hPlayButton =  GUICtrlCreateButton('Play', 10, 58, 280)
    ; create Redist button
    $hRedistButton =  GUICtrlCreateButton('Install redists', 10, 88, 280)

    ; try to get language from registry
    $iLang = RegRead($sHKCU & $sKEY & '\1.0', 'language')
    If @error <> 0 Then ; fallback to english
        $iLang = 1
    EndIf

    ; get index of language
    $iLangIndex = _ArraySearch($aLangCodes, $iLang)
    If $iLangIndex == -1 Then $iLangIndex = _ArraySearch($aLangCodes, 1)
    ; set default language
    GUICtrlSetData($hComboBox, $aLangNames[$iLangIndex])

    ; show GUI
    GUISetState(@SW_SHOW, $hGUI)

    While 1
        Switch GUIGetMsg()
            Case $GUI_EVENT_CLOSE
                $iLangIndex = -1
                ExitLoop
            Case $hPlayButton
                $iLangIndex = _ArraySearch($aLangNames, GUICtrlRead($hComboBox))
                ExitLoop
            Case $hRedistButton
                GUICtrlSetState($hPlayButton, $GUI_DISABLE)
                GUICtrlSetState($hRedistButton, $GUI_DISABLE)
                InstallRedists()
                GUICtrlSetState($hPlayButton, $GUI_ENABLE)
                GUICtrlSetState($hRedistButton, $GUI_ENABLE)
        EndSwitch
    WEnd

    ; Delete the previous GUI and all controls.
    GUIDelete($hGUI)

    If $iLangIndex <> -1 Then Play($aLangCodes[$iLangIndex])
EndFunc

Func Play($iLanguage)
    Local Const $sCD = _PathRemoveTrail(@ScriptDir)
    RegWrite($sHKCU & $sKEY & '\1.0', 'language', 'REG_DWORD', $iLanguage)

    RegWrite($sHKCU & $sKEY, 'DisplayName', 'REG_SZ', 'The Sims 2 Legacy')
    RegWrite($sHKCU & $sKEY, 'EPsInstalled', 'REG_SZ', 'Sims2EP1.exe,Sims2EP2.exe,Sims2EP3.exe,Sims2SP1.exe,Sims2SP2.exe,Sims2EP4.exe,Sims2EP5.exe,Sims2SP4.exe,Sims2SP5.exe,Sims2EP6.exe,Sims2SP6.exe,,Sims2EP7.exe,Sims2SP7.exe,Sims2SP8.exe,Sims2EP8.exe,Sims2EP9.exe')

    RegWrite($sHKCU & $sKEY & '\Sims2.exe', 'Game Registry', 'REG_SZ', 'Software\Electronic Arts\The Sims 2 Ultimate Collection 25')
    RegWrite($sHKCU & $sKEY & '\Sims2.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2.exe', 'Path', 'REG_SZ', $sCD & '\Base')

    RegWrite($sHKCU & $sKEY & '\Sims2EP1.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2EP1.exe', 'Path', 'REG_SZ', $sCD & '\EP1')

    RegWrite($sHKCU & $sKEY & '\Sims2EP2.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2EP2.exe', 'Path', 'REG_SZ', $sCD & '\EP2')

    RegWrite($sHKCU & $sKEY & '\Sims2EP3.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2EP3.exe', 'Path', 'REG_SZ', $sCD & '\EP3')

    RegWrite($sHKCU & $sKEY & '\Sims2EP4.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2EP4.exe', 'Path', 'REG_SZ', $sCD & '\EP4')

    RegWrite($sHKCU & $sKEY & '\Sims2EP5.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2EP5.exe', 'Path', 'REG_SZ', $sCD & '\EP5')

    RegWrite($sHKCU & $sKEY & '\Sims2EP6.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2EP6.exe', 'Path', 'REG_SZ', $sCD & '\EP6')

    RegWrite($sHKCU & $sKEY & '\Sims2EP7.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2EP7.exe', 'Path', 'REG_SZ', $sCD & '\EP7')

    RegWrite($sHKCU & $sKEY & '\Sims2EP8.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2EP8.exe', 'Path', 'REG_SZ', $sCD & '\EP8')

    RegWrite($sHKCU & $sKEY & '\Sims2EP9.exe', 'Game Registry', 'REG_SZ', 'Software\Electronic Arts\The Sims 2 Ultimate Collection 25')
    RegWrite($sHKCU & $sKEY & '\Sims2EP9.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2EP9.exe', 'Path', 'REG_SZ', $sCD & '\EP9')

    RegWrite($sHKCU & $sKEY & '\Sims2SP1.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2SP1.exe', 'Path', 'REG_SZ', $sCD & '\SP1')

    RegWrite($sHKCU & $sKEY & '\Sims2SP2.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2SP2.exe', 'Path', 'REG_SZ', $sCD & '\SP2')

    RegWrite($sHKCU & $sKEY & '\Sims2SP4.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2SP4.exe', 'Path', 'REG_SZ', $sCD & '\SP4')

    RegWrite($sHKCU & $sKEY & '\Sims2SP5.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2SP5.exe', 'Path', 'REG_SZ', $sCD & '\SP5')

    RegWrite($sHKCU & $sKEY & '\Sims2SP6.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2SP6.exe', 'Path', 'REG_SZ', $sCD & '\SP6')

    RegWrite($sHKCU & $sKEY & '\Sims2SP7.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2SP7.exe', 'Path', 'REG_SZ', $sCD & '\SP7')

    RegWrite($sHKCU & $sKEY & '\Sims2SP8.exe', 'Installed', 'REG_DWORD', 1)
    RegWrite($sHKCU & $sKEY & '\Sims2SP8.exe', 'Path', 'REG_SZ', $sCD & '\SP8')

    ShellExecute($sExePath, '', @ScriptDir)
EndFunc

Func InstallRedists()
    ShellExecuteWait('__Installer\directx\redist\dxsetup.exe', '/silent', @ScriptDir, 'runas')
    ShellExecuteWait('__Installer\vc\vc2015\redist\vc_redist.x86.exe', '/install /quiet /norestart', @ScriptDir, 'runas')
    ShellExecuteWait('__Installer\vc\vc2022\redist\vc_redist.x86.exe', '/q /norestart', @ScriptDir, 'runas')
    ShellExecuteWait('__Installer\customcomponent\vp6\vp6install.exe', '', @ScriptDir, 'runas')
EndFunc
