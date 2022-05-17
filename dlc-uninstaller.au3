; The Sims 4 DLC uninstaller by anadius

#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <FileConstants.au3>
#include <GUIConstantsEx.au3>
#include <Array.au3>
#include <Math.au3>
#include <File.au3>

Global Const $iHANDLE = 0, $iNAME = 1, $iCODE = 2, _
    $sTogglerConfig = 'dlc.ini', _
    $sKEY = '\SOFTWARE\Maxis\The Sims 4', $sVALUENAME = 'Locale'

WriteTest()

ShowGUI()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; check for writing permissions, run script as admin if necessary
Func WriteTest()
    Local Const $sTestFileName = 'dlc-uninstaller.write-test', _
        $hTest = FileOpen($sTestFileName, $FO_OVERWRITE)
    If $hTest == -1 Then
        If @Compiled == 1 Then
            ShellExecute(@ScriptName, '', '', 'runas')
        Else
            ShellExecute(@AutoItExe, @ScriptName, '', 'runas')
        EndIf
        Exit
    Else
        FileClose($hTest)
        FileDelete($sTestFileName)
    EndIf
EndFunc

Func GetDLCInfo()
    Local $sLang, $aDLCs

    ; try to get language from registry
    $sLang = RegRead('HKLM' & $sKEY, $sVALUENAME)
    If @error <> 0 Then ; fallback to 64bit registry tree
        $sLang = RegRead('HKLM64' & $sKEY, $sVALUENAME)
    EndIf
    If @error <> 0 Then ; fallback to english
        $sLang = 'en_US'
    EndIf

    $aDLCs = _FileListToArray(@ScriptDir, '?P??', $FLTA_FOLDERS)
    If @error <> 0 Then
        MsgBox($MB_ICONERROR, 'ERROR', 'Could not find any DLCs.' & @CRLF & 'error code: ' & @error)
        Exit
    EndIf

    ; create 2D array with all DLC information:
    ; $aInfo[n][$iHANDLE] - reserved for checkbox handle
    ; $aInfo[n][$iNAME] - DLC name in format: "[<short code>] <localised name>"
    ; $aInfo[n][$iCODE] - DLC code
    Local $aInfo[$aDLCs[0]][3]
    For $i = 0 to $aDLCs[0] - 1
        $aInfo[$i][$iCODE] = $aDLCs[$i+1]
        $aInfo[$i][$iNAME] = $aDLCs[$i+1] & ' ' & IniRead($sTogglerConfig, $aDLCs[$i+1], 'Name_' & $sLang, '')
    Next
    Return $aInfo
EndFunc

Func ShowGUI()
    Local $aDLCInfo, $iFromTop = 5, $bState, $aPos, $iMaxHeight = 0, $iMaxWidth = 0, $iTotlaWidth = 0, _
        $hUnCheckAll, $hUninstall, $hGUI = GUICreate('DLC uninstaller', 400, 500) ; create main GUI

    $aDLCInfo = GetDLCInfo()
    GUICtrlCreateLabel('made by anadius', 9, $iFromTop)
    $dsc = GUICtrlCreateLabel('Discord', 100, $iFromTop, 38)
    GUICtrlSetColor(-1, 0x0000FF)
    GUICtrlSetCursor(-1, 0)
    $site = GUICtrlCreateLabel('website', 142, $iFromTop, 38)
    GUICtrlSetColor(-1, 0x0000FF)
    GUICtrlSetCursor(-1, 0)

    $iFromTop += 20
    $hUnCheckAll = GUICtrlCreateCheckbox('(un)check all', 9, $iFromTop)
    $hUninstall = GUICtrlCreateButton('Uninstall', 100, $iFromTop-2)

    For $i = 0 To UBound($aDLCInfo) - 1
        If Mod($i, 20) == 0 Then
            $iMaxHeight = $iFromTop + 33
            $iFromTop = 50
            $iTotlaWidth += $iMaxWidth + 9
            $iMaxWidth = -1
        EndIf

        ; add checkbox for each DLC
        $aDLCInfo[$i][$iHANDLE] = GUICtrlCreateCheckbox($aDLCInfo[$i][$iNAME], $iTotlaWidth, $iFromTop)
        $aPos = ControlGetPos($hGUI, '', $aDLCInfo[$i][$iHANDLE])
        $iMaxWidth = _Max($iMaxWidth, $aPos[2])
        $iFromTop += 22
    Next

    $iTotlaWidth += $iMaxWidth + 11
    $iMaxHeight = _Max($iMaxHeight, $iFromTop + 33)
    $iTotlaWidth = _Max($iTotlaWidth, 290)
    ; 
    WinMove ($hGUI, '', Default, Default, $iTotlaWidth, $iMaxHeight)
    ; show GUI
    GUISetState(@SW_SHOW, $hGUI)

    Local $bChecked
    While 1
        Switch GUIGetMsg()
            Case $hUnCheckAll
                $bState = GuiCtrlRead($hUnCheckAll)
                For $i = 0 To UBound($aDLCInfo) - 1
                    GUICtrlSetState($aDLCInfo[$i][$iHANDLE], $bState)
                Next
            Case $dsc
                ShellExecute('https://anadius.hermietkreeft.site/discord')
            Case $site
                ShellExecute('https://anadius.hermietkreeft.site/')
            Case $hUninstall
                For $i = 0 To UBound($aDLCInfo) - 1
                    If GuiCtrlRead($aDLCInfo[$i][$iHANDLE]) == $GUI_CHECKED Then
                        DirRemove($aDLCInfo[$i][$iCODE], $DIR_REMOVE)
                        DirRemove('__Installer\DLC\' & $aDLCInfo[$i][$iCODE], $DIR_REMOVE)
                        RunWait('dlc-toggler.exe disable ' & $aDLCInfo[$i][$iCODE])
                    EndIf
                Next
                ExitLoop
            Case $GUI_EVENT_CLOSE
                ExitLoop
        EndSwitch
    WEnd

    ; Delete the previous GUI and all controls.
    GUIDelete($hGUI)
EndFunc
