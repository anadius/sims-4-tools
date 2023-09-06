; The Sims 4 DLC toggler by anadius
; normal usage (GUI): 
;   dlc-toggler
; auto disable missing DLCs and enable those present:
;   dlc-toggler auto
; export/import settings to/from 'dlc-toggler-export.ini':
;   dlc-toggler export/import
; enable/disable single DLC
;   dlc-toggler enable/disable EP01

#include <MsgBoxConstants.au3>
#include <StringConstants.au3>
#include <FileConstants.au3>
#include <GUIConstantsEx.au3>
#include <Array.au3>
#include <Math.au3>

Global Const $iHANDLE = 0, $iENABLED = 1, $iNAME = 2, $iCODE = 3, $iMISSING = 4, _
    $iCODE2 = 5, _
    $sTogglerConfig = 'dlc.ini', $sExportFile = 'dlc-toggler-export.ini', _
    $sCrackConfigs[8] = [ _
        'Game-cracked\Bin\RldOrigin.ini', _
        'Game-cracked\Bin\codex.cfg', _
        'Game-cracked\Bin\anadius.cfg', _
        'Game-cracked\Bin\anadius.cfg', _
        'Game\Bin\RldOrigin.ini', _
        'Game\Bin\codex.cfg', _
        'Game\Bin\anadius.cfg', _
        'Game\Bin\anadius.cfg'], _
    $sCrackRegExps[8] = [ _
        '(?i)(\n)(;?)(IID\d+=%s)', _
        '(?i)("%s"[\s\n]+\{[^\}]+"Group"\s+")([^"]+)()', _
        '(?i)(\s)(/*)("%s")', _
        '(?i)("%s"[\s\n]+\{[^\}]+"Group"\s+")([^"]+)()', _
        '(?i)(\n)(;?)(IID\d+=%s)', _
        '(?i)("%s"[\s\n]+\{[^\}]+"Group"\s+")([^"]+)()', _
        '(?i)(\s)(/*)("%s")', _
        '(?i)("%s"[\s\n]+\{[^\}]+"Group"\s+")([^"]+)()'], _
    $sKEY = '\SOFTWARE\Maxis\The Sims 4', $sVALUENAME = 'Locale', _
    $sValidGroups[8] = ['', 'THESIMS4PC', '', 'THESIMS4PC', '', 'THESIMS4PC', '', 'THESIMS4PC'], _
    $sInvalidGroups[8] = [';', '_', '//', '_', ';', '_', '//', '_']
Global $iCrack, $bConfigModified = False, _
    $sConfig, $aDLCInfo

If $CmdLine[0] > 0 And $CmdLine[1] <> '' Then
    $sConfig = LoadConfig($CmdLine[1])
Else
    $sConfig = LoadConfig()
EndIf
$aDLCInfo = GetDLCInfo()

WriteTest()

If $CmdLine[0] > 0 And $CmdLine[1] <> '' Then
    Switch $CmdLine[1]
        Case 'export'
            Export()
        Case 'import'
            Import()
        Case 'auto'
            Auto()
        Case 'enable', 'disable'
            SetDLCVisibility(IniRead($sTogglerConfig, $CmdLine[2], 'Code', ''), _
                $CmdLine[1] == 'enable')
            SetDLCVisibility(IniRead($sTogglerConfig, $CmdLine[2], 'Code2', ''), _
                $CmdLine[1] == 'enable')
        Case Else
            Exit
    EndSwitch
Else
    ShowGUI()
EndIf

SaveConfig()

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Func CommandLineParametersToString()
    Return ' "' & _ArrayToString($CmdLine, '" "', 1) & '"'
EndFunc

; get crack config
Func LoadConfig($sCmdArg = '')
    Local $sConfigContent
    For $i = UBound($sCrackConfigs) - 1 To 0 Step -1
        $sConfigContent = FileRead($sCrackConfigs[$i])
        If @error == 0 Then
            ; fall back for old config format
            If StringRight($sCrackConfigs[$i], 11) == 'anadius.cfg' _
                And StringInStr($sConfigContent, '"Config2"') == 0 _
            Then
                $i = $i - 1
            EndIf
            $iCrack = $i
            Return $sConfigContent
        EndIf
    Next
    If $sCmdArg == '' Then
        ErrorMessage('crack config', _ArrayToString($sCrackConfigs, @CRLF & 'or' & @CRLF))
    Else
        Exit
    EndIf
EndFunc

; save crack config if modified
Func SaveConfig()
    If $bConfigModified Then
        Local $iMode
        If StringRight($sCrackConfigs[$iCrack], 9) == 'codex.cfg' Then
            $iMode = $FO_OVERWRITE + $FO_UTF8
        Else
            $iMode = $FO_OVERWRITE
        EndIf
        Local $hFileOpen = FileOpen($sCrackConfigs[$iCrack], $iMode)
        FileWrite($hFileOpen, $sConfig)
        FileClose($hFileOpen)
        FileCopy($sCrackConfigs[$iCrack], StringReplace($sCrackConfigs[$iCrack], 'Bin', 'Bin_LE'), $FC_OVERWRITE)
    EndIf
EndFunc

; check for writing permissions, run script as admin if necessary
Func WriteTest()
    Local Const $sTestFileName = 'dlc-toggler.write-test', _
        $hTest = FileOpen($sTestFileName, $FO_OVERWRITE)
    If $hTest == -1 Then
        If @Compiled == 1 Then
            ShellExecute(@ScriptName, CommandLineParametersToString(), '', 'runas')
        Else
            ShellExecute(@AutoItExe, @ScriptName & CommandLineParametersToString(), '', 'runas')
        EndIf
        Exit
    Else
        FileClose($hTest)
        FileDelete($sTestFileName)
    EndIf
EndFunc

Func ErrorMessage($sType, $sPath)
    MsgBox($MB_ICONERROR, 'ERROR', 'Could not read ' & _
        $sType & ' file:' & @CRLF & $sPath)
    Exit
EndFunc

Func RegExpPattern($sSection)
    Return StringFormat(StringReplace($sCrackRegExps[$iCrack], '\', '\\'), $sSection)
EndFunc

; get info about DLC from crack config
Func IsDLCEnabled($sSection)
    $aMatches = StringRegExp($sConfig, RegExpPattern($sSection), $STR_REGEXPARRAYMATCH)
    If @error == 1 Then Return -1
    Return $aMatches[1] == $sValidGroups[$iCrack]
EndFunc

Func SetDLCVisibility($sSection, $bEnabled)
    Local $sGroup
    If $sSection == '' Then Return
    If $bEnabled Then
        $sGroup = $sValidGroups[$iCrack]
    Else
        $sGroup = $sInvalidGroups[$iCrack]
    EndIf
    $bConfigModified = True
    $sConfig = StringRegExpReplace($sConfig, RegExpPattern($sSection), '$1' & $sGroup & '$3', 0)
EndFunc

Func GetDLCInfo()
    Local $sLang, $aSections, $sSection, $sName, $aMatches

    ; try to get language from registry
    $sLang = RegRead('HKLM' & $sKEY, $sVALUENAME)
    If @error <> 0 Then ; fallback to 64bit registry tree
        $sLang = RegRead('HKLM64' & $sKEY, $sVALUENAME)
    EndIf
    If @error <> 0 Then ; fallback to english
        $sLang = 'en_US'
    EndIf

    ; get DLC short codes (eg. EP01) from INI file
    $aSections = IniReadSectionNames($sTogglerConfig)
    If @error <> 0 Then ErrorMessage('config', $sTogglerConfig)

    ; create 2D array with all DLC information:
    ; $aInfo[n][$iHANDLE] - reserved for checkbox handle
    ; $aInfo[n][$iENABLED] - True when DLC enabled, False when disabled
    ; $aInfo[n][$iNAME] - DLC name in format: "[<short code>] <localised name>"
    ; $aInfo[n][$iCODE] - long DLC code used in crack config
    ; $aInfo[n][$iCODE2] - alternative long DLC code used in crack config
    ; $aInfo[n][$iMISSING] - True when DLC not found
    Local $aInfo[$aSections[0]][6]

    For $i = 0 To $aSections[0] - 1
        $sSection = $aSections[$i+1]
        $sName = IniRead($sTogglerConfig, $sSection, 'Name_' & $sLang, -1)
        If $sName == -1 Then $sName = IniRead($sTogglerConfig, $sSection, 'Name_en_US', -1)
        $sName = StringReplace($sName, '&', '&&')
        $aInfo[$i][$iNAME] = '[' & $sSection & '] ' & $sName
        $aInfo[$i][$iCODE] = IniRead($sTogglerConfig, $sSection, 'Code', '')
        $aInfo[$i][$iCODE2] = IniRead($sTogglerConfig, $sSection, 'Code2', '')
        $aInfo[$i][$iENABLED] = IsDLCEnabled($aInfo[$i][$iCODE])
        If ($aInfo[$i][$iENABLED] == -1) And ($aInfo[$i][$iCODE2] <> '') Then
            $aInfo[$i][$iENABLED] = IsDLCEnabled($aInfo[$i][$iCODE2])
        EndIf
        $aInfo[$i][$iMISSING] = Not FileExists($sSection & '\SimulationFullBuild0.package')
    Next
    Return $aInfo
EndFunc

; disable missing DLCs, enable the rest
Func Auto()
    For $i = 0 To UBound($aDLCInfo) - 1
        If $aDLCInfo[$i][$iENABLED] == $aDLCInfo[$i][$iMISSING] Then
            SetDLCVisibility($aDLCInfo[$i][$iCODE], (Not $aDLCInfo[$i][$iENABLED]))
            SetDLCVisibility($aDLCInfo[$i][$iCODE2], (Not $aDLCInfo[$i][$iENABLED]))
        EndIf
    Next
EndFunc

; used before applying patch
Func Export()
    Local $sStatus
    For $i = 0 To UBound($aDLCInfo) - 1
        If Not ($aDLCInfo[$i][$iENABLED] == -1) Then
            $sStatus = 'Enabled = ' & $aDLCInfo[$i][$iENABLED]
            IniWriteSection($sExportFile, $aDLCInfo[$i][$iCODE], $sStatus)
            If $aDLCInfo[$i][$iCODE2] <> '' Then
                IniWriteSection($sExportFile, $aDLCInfo[$i][$iCODE2], $sStatus)
            EndIf
        EndIf
    Next
EndFunc

; used after applying patch
Func Import()
    Local $bEnabled, $aSections = IniReadSectionNames($sExportFile)
    If @error <> 0 Then Exit
    
    For $i = 1 To $aSections[0]
        $bEnabled = IniRead($sExportFile, $aSections[$i], 'Enabled', 'True') == 'True'
        SetDLCVisibility($aSections[$i], $bEnabled)
    Next
    FileDelete($sExportFile)
EndFunc

Func ShowGUI()
    Local $iFromTop = 5, $bState, $aPos, $iMaxWidth = 0, $iTotlaWidth = 0, _
        $bAllChecked = True, _
        $hGUI = GUICreate('DLC toggler', 800, 600) ; create main GUI

    GUICtrlCreateLabel('made by anadius', 9, $iFromTop)
    $dsc = GUICtrlCreateLabel('Discord', 100, $iFromTop, 38)
    GUICtrlSetColor(-1, 0x0000FF)
    GUICtrlSetCursor(-1, 0)
    $site = GUICtrlCreateLabel('website', 142, $iFromTop, 38)
    GUICtrlSetColor(-1, 0x0000FF)
    GUICtrlSetCursor(-1, 0)

    $iFromTop += 20
    $hUnCheckAll = GUICtrlCreateCheckbox('(un)check all', 9, $iFromTop)

    For $i = 0 To UBound($aDLCInfo) - 1
        If Mod($i, 25) == 0 Then
            $iFromTop = 47
            $iTotlaWidth += $iMaxWidth + 9
            $iMaxWidth = -1
        EndIf

        If $aDLCInfo[$i][$iENABLED] == -1 Then ContinueLoop
        ; add checkbox for each DLC
        $aDLCInfo[$i][$iHANDLE] = GUICtrlCreateCheckbox($aDLCInfo[$i][$iNAME], $iTotlaWidth, $iFromTop)
        $aPos = ControlGetPos($hGUI, '', $aDLCInfo[$i][$iHANDLE])
        If $aPos[2] > $iMaxWidth Then $iMaxWidth = $aPos[2]
        ; check checkbox if DLC is enabled
        If $aDLCInfo[$i][$iENABLED] Then
            $bState = $GUI_CHECKED
        Else
            $bState = $GUI_UNCHECKED
            $bAllChecked = False
        EndIf
        GUICtrlSetState($aDLCInfo[$i][$iHANDLE], $bState)
        ; change background color to red for missing DLCs
        If $aDLCInfo[$i][$iMISSING] Then GUICtrlSetBkColor($aDLCInfo[$i][$iHANDLE], 0xffaaaa)
        $iFromTop += 22
    Next
    If $bAllChecked Then GUICtrlSetState($hUnCheckAll, $GUI_CHECKED)

    $iTotlaWidth += $iMaxWidth + 11
    ; 
    WinMove ($hGUI, '', Default, Default, $iTotlaWidth, 630)
    ; show GUI
    GUISetState(@SW_SHOW, $hGUI)

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
            Case $GUI_EVENT_CLOSE
                ExitLoop
        EndSwitch
    WEnd

    Local $bChecked
    For $i = 0 To UBound($aDLCInfo) - 1
        $bChecked = GuiCtrlRead($aDLCInfo[$i][$iHANDLE]) == $GUI_CHECKED
        ; if state of a button changed - apply it in crack config
        If Not ($aDLCInfo[$i][$iENABLED] == -1) And ($bChecked <> $aDLCInfo[$i][$iENABLED]) Then
            SetDLCVisibility($aDLCInfo[$i][$iCODE], $bChecked)
            SetDLCVisibility($aDLCInfo[$i][$iCODE2], $bChecked)
        EndIf
    Next

    ; Delete the previous GUI and all controls.
    GUIDelete($hGUI)
EndFunc
