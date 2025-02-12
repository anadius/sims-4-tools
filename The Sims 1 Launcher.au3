; The Sims 1 Launcher by anadius

#include <ButtonConstants.au3>
#include <GUIConstantsEx.au3>
#include <Array.au3>

Global Const $sKEY = '\Software\Electronic Arts\The Sims 25', _
    $sLANG1 = 'SIMS_LANGUAGE', $sLANG2 = 'SIMS_OTHERLANGUAGE', _
    $sSKU = 'SIMS_SKU', $sExePath = 'sims.exe', _
    $aLangCodes[18] = ['Danish', 'German', 'UKEnglish', _
        'USEnglish', 'Spanish', 'Finnish', 'French', 'Italian', 'Japanese', _
        'Korean', 'Dutch', 'Norwegian', 'Polish', 'Portuguese', 'Swedish', _
        'Thai', 'SimplifiedChinese', 'TraditionalChinese'], _
    $aLangNames[18] = ['Danish', 'German', 'English (United Kingdom)', _
        'English (United States)', 'Spanish', 'Finnish', 'French', 'Italian', _
        'Japanese', 'Korean', 'Dutch', 'Norwegian', 'Polish', 'Portuguese', _
        'Swedish', 'Thai', 'Chinese (Simplified)', 'Chinese (Traditional)'], _
    $aLangSKU[18] = [1, 2, 2, 1, 1, 1, 2, 2, 5, 8, 2, 1, 4, 3, 2, 7, 9, 6]

Global $sHKCU

If @OSArch = 'X64' Then
    $sHKCU = 'HKCU64'
Else
    $sHKCU = 'HKCU'
EndIf

ShowGUI()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func ShowGUI()
    Local $iLangIndex = -1, $sLang, $hGUI, $hComboBox, $hPlayButton, $hRedistButton

    ; create main GUI window
    $hGUI = GUICreate('The Sims 1 Launcher', 305, 123)

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
    $sLang = RegRead($sHKCU & $sKEY, $sLANG1)
    If @error <> 0 Then ; fallback to english
        $sLang = 'USEnglish'
    EndIf

    ; get index of language
    $iLangIndex = _ArraySearch($aLangCodes, $sLang)
    If $iLangIndex == -1 Then $iLangIndex = _ArraySearch($aLangCodes, 'USEnglish')
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

    If $iLangIndex <> -1 Then Play($aLangCodes[$iLangIndex], $aLangSKU[$iLangIndex])
EndFunc

Func Play($sLanguage, $iSKU)
    RegWrite($sHKCU & $sKEY, $sLANG1, 'REG_SZ', $sLanguage)
    RegWrite($sHKCU & $sKEY, $sLANG2, 'REG_SZ', $sLanguage)
    RegWrite($sHKCU & $sKEY, $sSKU, 'REG_DWORD', $iSKU)

    ShellExecute($sExePath, '', @ScriptDir)
EndFunc

Func InstallRedists()
    ShellExecuteWait('__Installer\vc\vc2015\redist\vc_redist.x86.exe', '/install /quiet /norestart', @ScriptDir, 'runas')
    ShellExecuteWait('__Installer\vc\vc2022\redist\vc_redist.x86.exe', '/q /norestart', @ScriptDir, 'runas')
EndFunc
