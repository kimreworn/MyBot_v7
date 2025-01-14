; #FUNCTION# ====================================================================================================================
; Name ..........: PrepareAttack
; Description ...: Checks the troops when in battle, checks for type, slot, and quantity.  Saved in $g_avAttackTroops[SLOT][TYPE/QUANTITY] variable
; Syntax ........: PrepareAttack($pMatchMode[, $Remaining = False])
; Parameters ....: $pMatchMode          - a pointer value.
;                  $Remaining           - [optional] Flag for when checking remaining troops. Default is False.
; Return values .: None
; Author ........:
; Modified ......:
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2019
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
Func PrepareAttack($pMatchMode, $bRemaining = False) ;Assigns troops

	; Attack CSV has debug option to save attack line image, save have png of current $g_hHBitmap2
	If ($pMatchMode = $DB And $g_aiAttackAlgorithm[$DB] = 1) Or ($pMatchMode = $LB And $g_aiAttackAlgorithm[$LB] = 1) Then
		If $g_bDebugMakeIMGCSV And $bRemaining = False And TestCapture() = 0 Then
			If $g_iSearchTH = "-" Then ; If TH is unknown, try again to find as it is needed for filename
				imglocTHSearch(True, False, False)
			EndIf
			DebugImageSave("clean", False, Default, Default, "TH" & $g_iSearchTH & "-") ; make clean snapshot as well
		EndIf
	EndIf

	If Not $bRemaining Then ; reset Hero variables before attack if not checking remaining troops
		$g_bDropKing = False ; reset hero dropped flags
		$g_bDropQueen = False
		$g_bDropWarden = False
		If $g_iActivateKing = 1 Or $g_iActivateKing = 2 Then $g_aHeroesTimerActivation[$eHeroBarbarianKing] = 0
		If $g_iActivateQueen = 1 Or $g_iActivateQueen = 2 Then $g_aHeroesTimerActivation[$eHeroArcherQueen] = 0
		If $g_iActivateWarden = 1 Or $g_iActivateWarden = 2 Then $g_aHeroesTimerActivation[$eHeroGrandWarden] = 0

		$g_iTotalAttackSlot = 10 ; reset flag - Slot11+
		$g_bDraggedAttackBar = False
	EndIf

	If $g_bDebugSetlog Then SetDebugLog("PrepareAttack for " & $pMatchMode & " " & $g_asModeText[$pMatchMode], $COLOR_DEBUG)
	If $bRemaining Then
		SetLog("Checking remaining unused troops for: " & $g_asModeText[$pMatchMode], $COLOR_INFO)
	Else
		SetLog("Initiating attack for: " & $g_asModeText[$pMatchMode], $COLOR_ERROR)
	EndIf

	If _Sleep($DELAYPREPAREATTACK1) Then Return

	Local $iTroopNumber = 0

	Local $avAttackBar = GetAttackBar($bRemaining, $pMatchMode)
	For $i = 0 To UBound($g_avAttackTroops, 1) - 1
		Local $bClearSlot = True ; by default clear the slot, if no corresponding slot is found in attackbar detection
		If $bRemaining Then
			; keep initial heroes to avoid possibly "losing" them when not dropped yet
			;Local $bSlotDetectedAgain = UBound($avAttackBar, 1) > $i And $g_avAttackTroops[$i][0] = Number($avAttackBar[$i][0]) ; wrong, as attackbar array on remain is shorter
			Local $bDropped = Default
			Local $iTroopIndex = $g_avAttackTroops[$i][0]
			Switch $iTroopIndex
				Case $eKing
					$bDropped = $g_bDropKing
				Case $eQueen
					$bDropped = $g_bDropQueen
				Case $eWarden
					$bDropped = $g_bDropWarden
			EndSwitch
			If $bDropped = False Then
				SetDebugLog("Discard updating hero " & GetTroopName($g_avAttackTroops[$i][0]) & " because not dropped yet")
				$iTroopNumber += $g_avAttackTroops[$i][2]
				ContinueLoop
			EndIf
			If $bDropped = True Then
				;If $bSlotDetectedAgain Then
					; ok, hero was dropped, really? don't know yet... TODO add check if hero was really dropped...
				;EndIf
				SetDebugLog("Discard updating hero " & GetTroopName($g_avAttackTroops[$i][0]) & " because already dropped")
				$iTroopNumber += $g_avAttackTroops[$i][2]
				ContinueLoop
			EndIf
		EndIf

		If UBound($avAttackBar, 1) > 0 Then
			For $j = 0 To UBound($avAttackBar, 1) - 1
				If $avAttackBar[$j][1] = $i Then
					; troop slot found
					If IsUnitUsed($pMatchMode, $avAttackBar[$j][0]) Then
						$bClearSlot = False
						Local $sLogExtension = ""
						If Not $bRemaining Then
							; Select castle, siege machine and warden mode
							If $pMatchMode = $DB Or $pMatchMode = $LB Then
								Switch $avAttackBar[$j][0]
									Case $eCastle, $eWallW, $eBattleB, $eStoneS
										If $g_aiAttackUseSiege[$pMatchMode] <= 4 Then
											SelectCastleOrSiege($avAttackBar[$j][0], Number($avAttackBar[$j][5]), $g_aiAttackUseSiege[$pMatchMode])
											If $avAttackBar[$j][0] <> $eCastle Then $sLogExtension = " (level " & $g_iSiegeLevel & ")"
										EndIf
									Case $eWarden
										If $g_aiAttackUseWardenMode[$pMatchMode] <= 1 Then $sLogExtension = SelectWardenMode($g_aiAttackUseWardenMode[$pMatchMode], Number($avAttackBar[$j][5]))
								EndSwitch
							EndIf

							; populate the i-th slot
							$g_avAttackTroops[$i][0] = Number($avAttackBar[$j][0]) ; Troop Index
							$g_avAttackTroops[$i][1] = Number($avAttackBar[$j][2]) ; Amount
							$g_avAttackTroops[$i][2] = Number($avAttackBar[$j][3]) ; X-Coord
							$g_avAttackTroops[$i][3] = Number($avAttackBar[$j][4]) ; Y-Coord
							$g_avAttackTroops[$i][4] = Number($avAttackBar[$j][5]) ; OCR X-Coord
							$g_avAttackTroops[$i][5] = Number($avAttackBar[$j][6]) ; OCR Y-Coord
						Else
							; only update amount of i-th slot
							$g_avAttackTroops[$i][1] = Number($avAttackBar[$j][2]) ; Amount
						EndIf
						$iTroopNumber += $avAttackBar[$j][2]

						Local $sDebugText = $g_bDebugSetlog ? " (X:" & $avAttackBar[$j][3] & "|Y:" & $avAttackBar[$j][4] & "|OCR-X:" & $avAttackBar[$j][5] & "|OCR-Y:" & $avAttackBar[$j][6] & ")" : ""
						SetLog($avAttackBar[$j][1] & ": " & $avAttackBar[$j][2] & " " & GetTroopName($avAttackBar[$j][0], $avAttackBar[$j][2]) & $sLogExtension & $sDebugText, $COLOR_SUCCESS)
					Else
						SetDebugLog("Discard use of " & GetTroopName($avAttackBar[$j][0]) & " (" & $avAttackBar[$j][0] & ")", $COLOR_ERROR)
					EndIf
					ExitLoop
				EndIf
			Next
		EndIf

		If $bClearSlot Then
			; slot not identified
			$g_avAttackTroops[$i][0] = -1
			$g_avAttackTroops[$i][1] = 0
			$g_avAttackTroops[$i][2] = 0
			$g_avAttackTroops[$i][3] = 0
			$g_avAttackTroops[$i][4] = 0
			$g_avAttackTroops[$i][5] = 0
		EndIf
	Next
	If Not $bRemaining Then SetSlotSpecialTroops()

	Return $iTroopNumber
EndFunc   ;==>PrepareAttack

Func SelectCastleOrSiege(ByRef $iTroopIndex, $XCoord, $iCmbSiege)

	Local $hStarttime = _Timer_Init()
	Local $aSiegeTypes[5] = [$eCastle, $eWallW, $eBattleB, $eStoneS, "Any"]

	Local $ToUse = $aSiegeTypes[$iCmbSiege]
	Local $bNeedSwitch = False, $bAnySiege = False

	Local $sLog = GetTroopName($iTroopIndex)

	Switch $ToUse
		Case $iTroopIndex ; the same as current castle/siege
			If $iTroopIndex <> $eCastle And $g_iSiegeLevel < 3 Then
				$bNeedSwitch = True
				SetLog(GetTroopName($iTroopIndex) & " level " & $g_iSiegeLevel & " detected. Try looking for higher level.")
			EndIf

		Case $eCastle, $eWallW, $eBattleB, $eStoneS ; NOT the same as current castle/siege
			$bNeedSwitch = True
			SetLog(GetTroopName($iTroopIndex) & ($ToUse <> $eCastle ? " level " & $g_iSiegeLevel & " detected. Try looking for " : " detected. Switching to ") & GetTroopName($ToUse))

		Case "Any" ; use any siege
			If $iTroopIndex = $eCastle Or ($iTroopIndex <> $eCastle And $g_iSiegeLevel < 3) Then ; found Castle or a low level Siege
				$bNeedSwitch = True
				$bAnySiege = True
				SetLog(GetTroopName($iTroopIndex) & ($iTroopIndex = $eCastle ? " detected. Try looking for any siege machine" : " level " & $g_iSiegeLevel & " detected. Try looking for any higher siege machine"))
			EndIf
	EndSwitch

	If $bNeedSwitch Then
		If QuickMIS("BC1", $g_sImgSwitchSiegeMachine, $XCoord - 30, 700, $XCoord + 35, 720, True, False) Then
			Click($g_iQuickMISX + $XCoord - 30, $g_iQuickMISY + 700, 1)

			; wait to appears the new small window
			Local $lastX = $g_iQuickMISX + $XCoord - 30, $lastY = $g_iQuickMISY + 700
			If _Sleep(1250) Then Return

			; Lets detect the CC & Sieges and click
			Local $sSearchArea = GetDiamondFromRect(_Min($XCoord - 50, 470) & ",530(390,30)") ; x = 470 when Castle is at slot 6+ and there are 5 slots in siege switching window
			Local $aSearchResult = findMultiple($g_sImgSwitchSiegeMachine, $sSearchArea, $sSearchArea, 0, 1000, 5, "objectname,objectpoints", True)
			If $g_bDebugSetlog Then SetDebugLog("Benchmark Switch Siege imgloc: " & StringFormat("%.2f", _Timer_Diff($hStarttime)) & "'ms")
			$hStarttime = _Timer_Init()

			If $aSearchResult <> "" And IsArray($aSearchResult) Then
				Local $aFinalCoords, $iFinalLevel = 0, $iFinalSiege

				For $i = 0 To UBound($aSearchResult) - 1
					Local $aAvailable = $aSearchResult[$i]
					SetDebugLog("SelectCastleOrSiege() $aSearchResult[" & $i & "]: " & _ArrayToString($aAvailable))

					Local $iSiegeIndex = TroopIndexLookup($aAvailable[0], "SelectCastleOrSiege()")
					Local $sAllCoordsString = _ArrayToString($aAvailable, "|", 1)
					Local $aAllCoords = decodeMultipleCoords($sAllCoordsString, 50)

					If $iSiegeIndex = $ToUse And $iSiegeIndex = $eCastle Then
						$aFinalCoords = $aAllCoords[0]
						$iFinalSiege = $iSiegeIndex
						ExitLoop
					EndIf

					If $iSiegeIndex >= $eWallW And $iSiegeIndex <= $eStoneS And ($bAnySiege Or $iSiegeIndex = $ToUse) Then
						For $j = 0 To UBound($aAllCoords) - 1
							Local $aCoords = $aAllCoords[$j]
							Local $SiegeLevel = getTroopsSpellsLevel(Number($aCoords[0]) - 30, 587)
							; Just in case of Level 1
							If $SiegeLevel = "" Then $SiegeLevel = 1
							If $iFinalLevel < Number($SiegeLevel) Then
								$iFinalLevel = Number($SiegeLevel)
								$aFinalCoords = $aCoords
								$iFinalSiege = $iSiegeIndex
							EndIf
							SetDebugLog($i & "." & $j & ". Name: " & $aAvailable[0] & ", Level: " & $SiegeLevel & ", Coords: " & _ArrayToString($aCoords))
							If $iFinalLevel = 3 Then ExitLoop 2
						Next
					EndIf
				Next
				If $g_bDebugSetlog Then SetDebugLog("Benchmark Switch Siege Levels: " & StringFormat("%.2f", _Timer_Diff($hStarttime)) & "'ms")
				$hStarttime = _Timer_Init()

				If ($iTroopIndex = $ToUse Or $bAnySiege) And $g_iSiegeLevel >= $iFinalLevel Then
					SetLog($bAnySiege ? "No higher level siege machine found" : "No higher level of " & GetTroopName($iTroopIndex) & " found")
					Click($lastX, $lastY, 1)
				ElseIf IsArray($aFinalCoords) Then
					ClickP($aFinalCoords, 1, 0)
					$g_iSiegeLevel = $iFinalLevel
					$iTroopIndex = $iFinalSiege
				Else
					If Not $bAnySiege Then SetLog("No " & GetTroopName($ToUse) & " found")
					Click($lastX, $lastY, 1)
				EndIf

			Else
				If $g_bDebugImageSave Then DebugImageSave("PrepareAttack_SwitchSiege")
				; If was not detectable lets click again on green icon to hide the window!
				Setlog("Undetected " & ($bAnySiege ? "any siege machine " : GetTroopName($ToUse)) & " after click on switch btn!", $COLOR_DEBUG)
				Click($lastX, $lastY, 1)
			EndIf
			If _Sleep(750) Then Return
		EndIf
	EndIf
	If $g_bDebugSetlog Then SetDebugLog("Benchmark Switch Siege Detection: " & StringFormat("%.2f", _Timer_Diff($hStarttime)) & "'ms")

EndFunc   ;==>SelectCastleOrSiege

Func SelectWardenMode($iMode, $XCoord)
	; check current G.Warden's mode. Switch to preferred $iMode if needed. Return log text as "(Ground)"  or "(Air)"

	Local $hStarttime = _Timer_Init()
	Local $aSelectMode[2] = ["Ground", "Air"], $aSelectSymbol[2] = ["Foot", "Wing"]
	Local $sLogText = ""

	Local $sArrow = GetDiamondFromRect($XCoord - 20 & ",700(68,20)")
	Local $aCurrentMode = findMultiple($g_sImgSwitchWardenMode, $sArrow, $sArrow, 0, 1000, 1, "objectname,objectpoints", True)

	If $aCurrentMode <> "" And IsArray($aCurrentMode) Then
		Local $aCurrentModeArray = $aCurrentMode[0]
		If Not IsArray($aCurrentModeArray) Or UBound($aCurrentModeArray) < 2 Then Return $sLogText

		SetDebugLog("SelectWardenMode() $aCurrentMode[0]: " & _ArrayToString($aCurrentModeArray))
		If $g_bDebugSetlog Then SetLog("Benchmark G. Warden mode detection: " & StringFormat("%.2f", _Timer_Diff($hStarttime)) & "'ms", $COLOR_DEBUG)

		If $aCurrentModeArray[0] = $aSelectMode[$iMode] Then
			$sLogText = " (" & $aCurrentModeArray[0] & " mode)"
		Else
			Local $aArrowCoords = StringSplit($aCurrentModeArray[1], ",", $STR_NOCOUNT)
			ClickP($aArrowCoords, 1, 0)
			If _Sleep(1200) Then Return

			Local $sSymbol = GetDiamondFromRect(_Min($XCoord - 30, 696) & ",576(162,18)") ; x = 696 when Grand Warden is at slot 10
			Local $aAvailableMode = findMultiple($g_sImgSwitchWardenMode, $sSymbol, $sSymbol, 0, 1000, 2, "objectname,objectpoints", True)
			If $aAvailableMode <> "" And IsArray($aAvailableMode) Then
				For $i = 0 To UBound($aAvailableMode, $UBOUND_ROWS) - 1
					Local $aAvailableModeArray = $aAvailableMode[$i]
					SetDebugLog("SelectWardenMode() $aAvailableMode[" & $i & "]: " & _ArrayToString($aAvailableModeArray))
					If $aAvailableModeArray[0] = $aSelectSymbol[$iMode] Then
						Local $aSymbolCoords = StringSplit($aAvailableModeArray[1], ",", $STR_NOCOUNT)
						ClickP($aSymbolCoords, 1, 0)
						$sLogText =  " (" & $aSelectMode[$iMode] & " mode)"
						ExitLoop
					EndIf
				Next
				If $sLogText = "" Then ClickP($aArrowCoords, 1, 0)
				If $g_bDebugSetlog Then SetLog("Benchmark G. Warden mode selection: " & StringFormat("%.2f", _Timer_Diff($hStarttime)) & "'ms", $COLOR_DEBUG)
			EndIf
		EndIf
	EndIf
	Return $sLogText

EndFunc   ;==>SelectWardenMode

Func IsUnitUsed($iMatchMode, $iTroopIndex)
	Local $iTempMode = ($iMatchMode = $MA ? $DB : $iMatchMode)

	If $iTroopIndex < $eKing Then ;Index is a Troop
		If $iMatchMode = $DT Or $iMatchMode = $TB Then Return True
		Local $aTempArray = $g_aaiTroopsToBeUsed[$g_aiAttackTroopSelection[$iTempMode]]
		Local $iFoundAt = _ArraySearch($aTempArray, $iTroopIndex)
		If $iFoundAt <> -1 Then
			If $iMatchMode = $MA And $iTroopIndex = $eGobl Then
				Return False
			Else
				Return True
			EndIf
		EndIf
		Return False
	Else ; Index is a Hero/Siege/Castle/Spell
		Local $iTempMode = ($iMatchMode = $MA ? $DB : $iMatchMode)

		If $iMatchMode <> $DB And $iMatchMode <> $LB And $iMatchMode <> $TS And $iMatchMode <> $MA Then
			Return True
		Else
			Switch $iTroopIndex
				Case $eKing
					If (BitAND($g_aiAttackUseHeroes[$iTempMode], $eHeroKing) = $eHeroKing) Then Return True
				Case $eQueen
					If (BitAND($g_aiAttackUseHeroes[$iTempMode], $eHeroQueen) = $eHeroQueen) Then Return True
				Case $eWarden
					If (BitAND($g_aiAttackUseHeroes[$iTempMode], $eHeroWarden) = $eHeroWarden) Then Return True
				Case $eCastle, $eWallW, $eBattleB, $eStoneS
					If $g_abAttackDropCC[$iTempMode] Then Return True
				Case $eLSpell
					If $g_abAttackUseLightSpell[$iTempMode] Or $g_bSmartZapEnable Then Return True
				Case $eHSpell
					If $g_abAttackUseHealSpell[$iTempMode] Then Return True
				Case $eRSpell
					If $g_abAttackUseRageSpell[$iTempMode] Then Return True
				Case $eJSpell
					If $g_abAttackUseJumpSpell[$iTempMode] Then Return True
				Case $eFSpell
					If $g_abAttackUseFreezeSpell[$iTempMode] Then Return True
				Case $ePSpell
					If $g_abAttackUsePoisonSpell[$iTempMode] Then Return True
				Case $eESpell
					If $g_abAttackUseEarthquakeSpell[$iTempMode] = 1 Or $g_bSmartZapEnable Then Return True
				Case $eHaSpell
					If $g_abAttackUseHasteSpell[$iTempMode] Then Return True
				Case $eCSpell
					If $g_abAttackUseCloneSpell[$iTempMode] Then Return True
				Case $eSkSpell
					If $g_abAttackUseSkeletonSpell[$iTempMode] Then Return True
				Case $eBtSpell
					If $g_abAttackUseBatSpell[$iTempMode] Then Return True
				Case Else
					Return False
			EndSwitch
			Return False
		EndIf

		Return False
	EndIf
	Return False
EndFunc   ;==>IsUnitUsed

Func AttackRemainingTime($bInitialze = Default)
	If $bInitialze Then
		$g_hAttackTimer = __TimerInit()
		$g_iAttackTimerOffset = Default
		SuspendAndroidTime(True) ; Reset suspend Android time for compensation when Android is suspended
		Return
	EndIf

	Local $iPrepareTime = 29 * 1000

	If $g_iAttackTimerOffset = Default Then

		; now attack is really starting (or it has already after 30 Seconds)

		; set offset
		$g_iAttackTimerOffset = __TimerDiff($g_hAttackTimer) - SuspendAndroidTime()

		If $g_iAttackTimerOffset > $iPrepareTime Then
			; adjust offset by remove "lost" attack time
			$g_iAttackTimerOffset = $iPrepareTime - $g_iAttackTimerOffset
		EndIf

	EndIf

;~ 	If Not $bInitialze Then Return

	; Return remaining attack time
	Local $iAttackTime = 3 * 60 * 1000
	Local $iRemaining = $iAttackTime - (__TimerDiff($g_hAttackTimer) - SuspendAndroidTime() - $g_iAttackTimerOffset)
	If $iRemaining < 0 Then Return 0
	Return $iRemaining

EndFunc   ;==>AttackRemainingTime
