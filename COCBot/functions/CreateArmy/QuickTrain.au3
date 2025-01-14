; #FUNCTION# ====================================================================================================================
; Name ..........: Quick Train
; Description ...: New and a complete quick train system
; Syntax ........:
; Parameters ....: None
; Return values .: None
; Author ........: Demen
; Modified ......:
; Remarks .......: This file is part of MyBot, previously known as ClashGameBot. Copyright 2015-2019
;                  MyBot is distributed under the terms of the GNU GPL
; Related .......:
; Link ..........: https://github.com/MyBotRun/MyBot/wiki
; Example .......: No
; ===============================================================================================================================
#include-once

Func QuickTrain()

	Local $bDebug = $g_bDebugSetlogTrain Or $g_bDebugSetlog
	Local $bNeedRecheckTroop = False, $bNeedRecheckSpell = False
	Local $iTroopStatus = -1, $iSpellStatus = -1 ; 0 = empty, 1 = full camp, 2 = full queue

	If $bDebug Then SetLog(" == Quick Train == ", $COLOR_ACTION)

	CheckIfArmyIsReady()

	CheckQuickTrainTroop() ; update values of $g_aiArmyQuickTroops, $g_aiArmyQuickSpells

	If $g_bIsFullArmywithHeroesAndSpells Or ($g_CurrentCampUtilization = 0 And $g_bFirstStart) Then

		If $g_bIsFullArmywithHeroesAndSpells Then SetLog(" - Your Army is Full, let's make troops before Attack!", $COLOR_INFO)
		If ($g_CurrentCampUtilization = 0 And $g_bFirstStart) Then
			SetLog(" - Your Army is Empty, let's make troops before Attack!", $COLOR_ACTION1)
			SetLog(" - Go to Train Army Tab and select your Quick Army position!", $COLOR_ACTION1)
		EndIf

		If IsQueueEmpty("Troops", True, False) Then $iTroopStatus = $g_bIsFullArmywithHeroesAndSpells ? 1 : 0
		If IsQueueEmpty("Spells", True, False) And Number($g_iCurrentSpells) >= $g_iTotalQuickSpells Then $iSpellStatus = $g_bIsFullArmywithHeroesAndSpells ? 1 : 0

		If $bDebug Then SetLog("$iTroopStatus: " & $iTroopStatus & ", $iSpellStatus: " & $iSpellStatus, $COLOR_DEBUG)

		If $g_bFirstStart Then $g_bFirstStart = False
	EndIf

	; Troop
	If $iTroopStatus = -1 Then
		If Not $g_bDonationEnabled Or Not $g_bChkDonate Or Not MakingDonatedTroops("Troops") Then ; No need OpenTroopsTab() if MakingDonatedTroops() returns true
			If Not OpenTroopsTab(False, "QuickTrain()") Then Return
			If _Sleep(250) Then Return
		EndIf

		Local $Step = 1
		While 1
			Local $TroopCamp = GetCurrentArmy(48, 160)
			SetLog("Checking Troop tab: " & $TroopCamp[0] & "/" & $TroopCamp[1] * 2)
			If $TroopCamp[1] = 0 Then ExitLoop

			If $TroopCamp[0] <= 0 Then ; 0/280
				$iTroopStatus = 0
				If $bDebug Then SetLog("No troop", $COLOR_DEBUG)

			ElseIf $TroopCamp[0] < $TroopCamp[1] Then ; 1-279/280
				If Not IsQueueEmpty("Troops", True, False) Then DeleteQueued("Troops")
				$bNeedRecheckTroop = True
				If $bDebug Then SetLog("$bNeedRecheckTroop for at Army Tab: " & $bNeedRecheckTroop, $COLOR_DEBUG)

			ElseIf $TroopCamp[0] = $TroopCamp[1] Then ; 280/280
				$iTroopStatus = 1
				If $bDebug Then SetLog($g_bDoubleTrain ? "ready to make double troop training" : "troops are training perfectly", $COLOR_DEBUG)

			ElseIf $TroopCamp[0] <= $TroopCamp[1] * 1.5 Then ; 281-420/560
				RemoveExtraTroopsQueue()
				If $bDebug Then SetLog($Step & ". RemoveExtraTroopsQueue()", $COLOR_DEBUG)
				If _Sleep(250) Then Return
				$Step += 1
				If $Step = 6 Then ExitLoop
				ContinueLoop

			ElseIf $TroopCamp[0] <= $TroopCamp[1] * 2 Then ; 421-560/560
				$g_aiArmyCompTroops = $g_aiArmyQuickTroops
				If CheckQueueTroopAndTrainRemain($TroopCamp, $bDebug) Then
					$iTroopStatus = 2
					If $bDebug Then SetLog($Step & ". CheckQueueTroopAndTrainRemain()", $COLOR_DEBUG)
					ReadConfig_600_52_2() ; reload $g_aiArmyCompTroops from config
				Else
					ReadConfig_600_52_2() ; reload $g_aiArmyCompTroops from config
					RemoveExtraTroopsQueue()
					If $bDebug Then SetLog($Step & ". RemoveExtraTroopsQueue()", $COLOR_DEBUG)
					If _Sleep(250) Then Return
					$Step += 1
					If $Step = 6 Then ExitLoop
					ContinueLoop
				EndIf
			EndIf
			ExitLoop
		WEnd
	EndIf

	; Spell
	If $g_iTotalQuickSpells = 0 Then $iSpellStatus = 2
	If $iSpellStatus = -1 Or ($iSpellStatus < $iTroopStatus) Then
		If Not $g_bDonationEnabled Or Not $g_bChkDonate Or Not MakingDonatedTroops("Spells") Then ; No need OpenSpellsTab() if MakingDonatedTroops() returns true
			If Not OpenSpellsTab(False, "QuickTrain()") Then Return
			If _Sleep(250) Then Return
		EndIf

		Local $Step = 1
		While 1
			Local $aiSpellCamp = GetCurrentArmy(43, 160)
			SetLog("Checking Spell tab: " & $aiSpellCamp[0] & "/" & $aiSpellCamp[1] * 2)
			If $aiSpellCamp[1] = 0 Then ExitLoop

			If $aiSpellCamp[0] <= 0 Then ; 0/22
				If $iTroopStatus >= 1 And $g_bQuickArmyMixed Then
					$g_aiArmyCompSpells = $g_aiArmyQuickSpells
					TrainFullQueue(True)
					If $iTroopStatus = 2 And $g_bDoubleTrain Then TrainFullQueue(True)
					ReadConfig_600_52_2() ; reload $g_aiArmyCompTroops from config
					$iSpellStatus = 2
				Else
					$iSpellStatus = 0
					If $bDebug Then SetLog("No Spell", $COLOR_DEBUG)
				EndIf

			ElseIf $aiSpellCamp[0] < $aiSpellCamp[1] Then ; 1-10/11
				If Not IsQueueEmpty("Spells", True, False) Then DeleteQueued("Spells")
				$bNeedRecheckSpell = True
				If $bDebug Then SetLog("$bNeedRecheckSpell at Army Tab: " & $bNeedRecheckSpell, $COLOR_DEBUG)

			ElseIf $aiSpellCamp[0] = $aiSpellCamp[1] Then ; 11/22
				If $iTroopStatus = 2 And $g_bQuickArmyMixed And $g_bDoubleTrain Then
					$g_aiArmyCompSpells = $g_aiArmyQuickSpells
					TrainFullQueue(True)
					If $bDebug Then SetLog("$iTroopStatus = " & $iTroopStatus & ". Brewed full queued spell", $COLOR_DEBUG)
					ReadConfig_600_52_2() ; reload $g_aiArmyCompTroops from config
					$iSpellStatus = 2
				Else
					$iSpellStatus = 1
					If $bDebug Then SetLog($g_bDoubleTrain ? "ready to make double spell brewing" : "spells are brewing perfectly", $COLOR_DEBUG)
				EndIf

			ElseIf $aiSpellCamp[0] <= $aiSpellCamp[1] * 2 Then ; 12-22/22

				$g_aiArmyCompSpells = $g_aiArmyQuickSpells
				If ($iTroopStatus = 2 Or Not $g_bQuickArmyMixed) And CheckQueueSpellAndTrainRemain($aiSpellCamp, $bDebug) Then
					ReadConfig_600_52_2() ; reload $g_aiArmyCompTroops from config
					$iSpellStatus = 2
				Else
					ReadConfig_600_52_2() ; reload $g_aiArmyCompTroops from config
					RemoveExtraTroopsQueue()
					If _Sleep(500) Then Return
					$Step += 1
					If $Step = 6 Then ExitLoop
					ContinueLoop
				EndIf

			EndIf
			ExitLoop
		WEnd
	EndIf

	; check existing army then train missing troops, spells
	If $bNeedRecheckTroop Or $bNeedRecheckSpell Then
		$g_iTotalSpellValue = $g_iTotalQuickSpells ; this is to force WhatToTrain()
		$g_aiArmyCompTroops = $g_aiArmyQuickTroops
		$g_aiArmyCompSpells = $g_aiArmyQuickSpells

		Local $aWhatToRemove = WhatToTrain(True)
		RemoveExtraTroops($aWhatToRemove)

		Local $bEmptyTroop = _ColorCheck(_GetPixelColor(30, 205, True), Hex(0xCAC9C1, 6), 20) ; remove all troops
		Local $bEmptySpell = _ColorCheck(_GetPixelColor(30, 350, True), Hex(0xCAC9C1, 6), 20) ; remove all spells

		Local $aWhatToTrain = WhatToTrain()

		If DoWhatToTrainContainTroop($aWhatToTrain) Then
			If $bEmptyTroop And $bEmptySpell Then
				$iTroopStatus = 0
			ElseIf $bEmptyTroop And ($iSpellStatus >= 1 And Not $g_bQuickArmyMixed) Then
				$iTroopStatus = 0
			Else
				If $bDebug Then SetLog("Topping up troops", $COLOR_DEBUG)
				TrainUsingWhatToTrain($aWhatToTrain) ; troop
				$iTroopStatus = 1
			EndIf
		EndIf

		If DoWhatToTrainContainSpell($aWhatToTrain) Then
			If $bEmptySpell And $bEmptyTroop Then
				$iSpellStatus = 0
			ElseIf $bEmptySpell And ($iTroopStatus >= 1 And Not $g_bQuickArmyMixed) Then
				$iSpellStatus = 0
			Else
				If $bDebug Then SetLog("Topping up spells", $COLOR_DEBUG)
				TrainUsingWhatToTrain($aWhatToTrain, True) ; spell
				$iSpellStatus = 1
			EndIf
		EndIf

		ReadConfig_600_52_2() ; reload $g_aiArmyCompTroops, $g_aiArmyCompSpells and $g_iTotalSpellValue from config
	EndIf

	If _Sleep(250) Then Return

	SetDebugLog("$iTroopStatus = " & $iTroopStatus & ", $iSpellStatus = " & $iSpellStatus)
	If $iTroopStatus = -1 And $iSpellStatus = -1 Then
		SetLog("Quick Train failed. Unable to detect training status.", $COLOR_ERROR)
		Return
	EndIf

	Switch _Min($iTroopStatus, $iSpellStatus)
		Case 0
			If Not OpenQuickTrainTab(False, "QuickTrain()") Then Return
			If _Sleep(500) Then Return
			TrainArmyNumber($g_bQuickTrainArmy)
			If $g_bDoubleTrain Then TrainArmyNumber($g_bQuickTrainArmy)
		Case 1
			If $g_bIsFullArmywithHeroesAndSpells Or $g_bDoubleTrain Then
				If Not OpenQuickTrainTab(False, "QuickTrain()") Then Return
				If _Sleep(500) Then Return
				TrainArmyNumber($g_bQuickTrainArmy)
			EndIf
	EndSwitch
	If _Sleep(500) Then Return

EndFunc   ;==>QuickTrain

Func CheckQuickTrainTroop()

	Local $bResult = True
	If _DateIsValid($g_sQuickTrainCheckTime) Then
		Local $iLastCheck = _DateDiff('n', $g_sQuickTrainCheckTime, _NowCalc()) ; elapse time from last check (minutes)
		SetDebugLog("Latest CheckQuickTrainTroop() at: " & $g_sQuickTrainCheckTime & ", Check DateCalc: " & $iLastCheck & " min" & @CRLF & "_ArrayMax($g_aiArmyQuickTroops) = " & _ArrayMax($g_aiArmyQuickTroops))
		If $iLastCheck <= 360 And _ArrayMax($g_aiArmyQuickTroops) > 0 Then Return ; A check each 6 hours [6*60 = 360]
	EndIf

	If Not OpenQuickTrainTab(False, "QuickTrain()") Then Return
	If _Sleep(500) Then Return

	SetLog("Reading troops & spells in quick train army...")

	; reset troops/spells in quick army
	Local $aEmptyTroop[$eTroopCount] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	Local $aEmptySpell[$eSpellCount] = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]
	$g_aiArmyQuickTroops = $aEmptyTroop
	$g_aiArmyQuickSpells = $aEmptySpell
	$g_iTotalQuickTroops = 0
	$g_iTotalQuickSpells = 0
	$g_bQuickArmyMixed = False

	Local $iTroopCamp = 0, $iSpellCamp = 0, $sLog = ""

	Local $aEditButton[3][4] = [[808, 300, 0xd2f17a, 20], [808, 418, 0xd0f078, 20], [808, 536, 0xccee74, 20]] ; green
	Local $aSaveButton[4] = [808, 300, 0xdcf684, 20] ; green
	Local $aCancelButton[4] = [650, 300, 0xff8c91, 20] ; red
	Local $aRemoveButton[4] = [535, 300, 0xff8f94, 20] ; red

	For $i = 0 To UBound($g_bQuickTrainArmy) - 1 ; check all 3 army combo
		If Not $g_bQuickTrainArmy[$i] Then ContinueLoop ; skip unchecked quick train army

		If _ColorCheck(_GetPixelColor($aEditButton[$i][0], $aEditButton[$i][1], True), Hex($aEditButton[$i][2], 6), $aEditButton[$i][3]) Then
			Click($aEditButton[$i][0], $aEditButton[$i][1]) ; Click edit army 1, 2, 3
			If _Sleep(500) Then Return

			Local $TempTroopTotal = 0, $TempSpellTotal = 0

			Local $Step = 0
			While 1
				; read troops
				Local $aSearchResult = SearchArmy(@ScriptDir & "\imgxml\ArmyOverview\QuickTrain", 18, 182, 829, 261, "Quick Train") ; return Name, X, Y, Q'ty

				If $aSearchResult[0][0] = "" Then
					If Not $g_abUseInGameArmy[$i] Then
						$Step += 1
						Setlog("No troops/spells detected in Army " & $i + 1 & ", let's create quick train preset", $Step > 3 ? $COLOR_ERROR : $COLOR_BLACK)
						If $Step > 3 Then
							SetLog("Some problems creating army preset", $COLOR_ERROR)
							ContinueLoop 2
						EndIf
						CreateQuickTrainPreset($i)
						ContinueLoop
					Else
						Setlog("No troops/spells detected in Quick Army " & $i + 1, $COLOR_ERROR)
						ContinueLoop 2
					EndIf
				EndIf

				; get quantity
				Local $aiInGameTroop = $aEmptyTroop, $aiInGameSpell = $aEmptySpell, $aiGUITroop = $aEmptyTroop, $aiGUISpell = $aEmptySpell
				SetLog("Quick Army " & $i + 1 & ":", $COLOR_SUCCESS)
				For $j = 0 To (UBound($aSearchResult) - 1)
					Local $iTroopIndex = TroopIndexLookup($aSearchResult[$j][0])
					If $iTroopIndex >= 0 And $iTroopIndex < $eTroopCount Then
						SetLog("  - " & $g_asTroopNames[$iTroopIndex] & ": " & $aSearchResult[$j][3] & "x", $COLOR_SUCCESS)
						$aiInGameTroop[$iTroopIndex] = $aSearchResult[$j][3]

					ElseIf $iTroopIndex >= $eLSpell And $iTroopIndex <= $eBtSpell Then
						SetLog("  - " & $g_asSpellNames[$iTroopIndex - $eLSpell] & ": " & $aSearchResult[$j][3] & "x", $COLOR_SUCCESS)
						$aiInGameSpell[$iTroopIndex - $eLSpell] = $aSearchResult[$j][3]

					Else
						SetLog("  - Unsupport troop/spell index: " & $iTroopIndex)
					EndIf
				Next

				; cross check with GUI qty
				If Not $g_abUseInGameArmy[$i] Then
					If $Step <= 3 Then
						For $j = 0 To 6
							If $g_aiQuickTroopType[$i][$j] >= 0 Then $aiGUITroop[$g_aiQuickTroopType[$i][$j]] = $g_aiQuickTroopQty[$i][$j]
							If $g_aiQuickSpellType[$i][$j] >= 0 Then $aiGUISpell[$g_aiQuickSpellType[$i][$j]] = $g_aiQuickSpellQty[$i][$j]
						Next
						For $j = 0 To $eTroopCount - 1
							If $aiGUITroop[$j] <> $aiInGameTroop[$j] Then
								Setlog("Wrong Troop preset, let's create again. (" & $g_asTroopNames[$j] & ": " & $aiGUITroop[$j] & "/" & $aiInGameTroop[$j] & ")" & ($g_bDebugSetlog ? " - Retry: " & $Step : ""))
								$Step += 1
								CreateQuickTrainPreset($i)
								ContinueLoop 2
							EndIf
						Next
						For $j = 0 To $eSpellCount - 1
							If $aiGUISpell[$j] <> $aiInGameSpell[$j] Then
								Setlog("Wrong Spell preset, let's create again (" & $g_asSpellNames[$j] & ": " & $aiGUISpell[$j] & "/" & $aiInGameSpell[$j] & ")" & ($g_bDebugSetlog ? " - Retry: " & $Step : ""))
								$Step += 1
								CreateQuickTrainPreset($i)
								ContinueLoop 2
							EndIf
						Next
					Else
						SetLog("Some problems creating troop preset", $COLOR_ERROR)
					EndIf
				EndIf

				; If all correct (or after 3 times trying to preset QT army), add result to $g_aiArmyQuickTroops & $g_aiArmyQuickSpells
				For $j = 0 To $eTroopCount - 1
					$g_aiArmyQuickTroops[$j] += $aiInGameTroop[$j]
					$TempTroopTotal += $aiInGameTroop[$j] * $g_aiTroopSpace[$j]
					If $j > $eSpellCount - 1 Then ContinueLoop
					$g_aiArmyQuickSpells[$j] += $aiInGameSpell[$j]
					$TempSpellTotal += $aiInGameSpell[$j] * $g_aiSpellSpace[$j]
				Next

				ExitLoop
			WEnd

			; check if an army has both troops and spells
			If Not $g_bQuickArmyMixed And $TempTroopTotal > 0 And $TempSpellTotal > 0 Then $g_bQuickArmyMixed = True
			SetDebugLog("$g_bQuickArmyMixed: " & $g_bQuickArmyMixed)

			; cross check with army camp
			If _ArrayMax($g_aiArmyQuickTroops) > 0 Then
				Local $TroopCamp = GetCurrentArmy(48, 160)
				$iTroopCamp = $TroopCamp[1] * 2
				If $TempTroopTotal <> $TroopCamp[0] Then
					SetLog("Error reading troops in army setting (" & $TempTroopTotal & " vs " & $TroopCamp[0] & ")", $COLOR_ERROR)
					$bResult = False
				Else
					$g_iTotalQuickTroops += $TempTroopTotal
					SetDebugLog("$g_iTotalQuickTroops: " & $g_iTotalQuickTroops)
				EndIf
			EndIf
			If _ArrayMax($g_aiArmyQuickSpells) > 0 Then
				Local $aiSpellCamp = GetCurrentArmy(146, 160)
				$iSpellCamp = $aiSpellCamp[1] * 2
				If $TempSpellTotal <> $aiSpellCamp[0] Then
					SetLog("Error reading spells in army setting (" & $TempSpellTotal & " vs " & $aiSpellCamp[0] & ")", $COLOR_ERROR)
					$bResult = False
				Else
					$g_iTotalQuickSpells += $TempSpellTotal
					SetDebugLog("$g_iTotalQuickSpells: " & $g_iTotalQuickSpells)
				EndIf
			EndIf

			$sLog &= $i + 1 & " "

			ClickP($g_abUseInGameArmy[$i] ? $aCancelButton : $aSaveButton)

			If _Sleep(250) Then Return

		Else
			SetLog("Cannot find 'Edit' button for Army " & $i + 1, $COLOR_ERROR)
		EndIf
	Next

	If $g_iTotalQuickTroops > $iTroopCamp Then SetLog("Total troops in combo army " & $sLog & "exceeds your camp capacity (" & $g_iTotalQuickTroops & " vs " & $iTroopCamp & ")", $COLOR_ERROR)
	If $g_iTotalQuickSpells > $iSpellCamp Then SetLog("Total spells in combo army " & $sLog & "exceeds your camp capacity (" & $g_iTotalQuickSpells & " vs " & $iSpellCamp & ")", $COLOR_ERROR)

	$g_sQuickTrainCheckTime = $bResult ? _NowCalc() : ""

EndFunc   ;==>CheckQuickTrainTroop

Func CreateQuickTrainPreset($i)
	SetLog("Creating troops/spells preset for Army " & $i + 1)

	Local $aRemoveButton[4] = [535, 300, 0xff8f94, 20] ; red
	Local $iArmyPage = 0

	If _ColorCheck(_GetPixelColor($aRemoveButton[0], $aRemoveButton[1], True), Hex($aRemoveButton[2], 6), $aRemoveButton[2]) Then
		ClickP($aRemoveButton) ; click remove
		If _Sleep(250) Then Return

		DragIfNeeded("Barb")
		For $j = 0 To 6
			Local $iIndex = $g_aiQuickTroopType[$i][$j]
			If _ArrayIndexValid($g_aiArmyQuickTroops, $iIndex) Then
				If $iIndex >= $eMini And $iArmyPage = 0 Then
					If _Sleep(250) Then Return
					ClickDrag(620, 445 + $g_iMidOffsetY, 620 - 373, 445 + $g_iMidOffsetY, 2000)
					If _Sleep(1500) Then Return
					$iArmyPage = 1
				EndIf
				Local $sFilter = String($g_asTroopShortNames[$iIndex]) & "*"
				Local $asImageToUse = _FileListToArray($g_sImgTrainTroops, $sFilter, $FLTA_FILES, True)
				Local $aTrainPos = GetVariable($asImageToUse[1], $iIndex)
				If IsArray($aTrainPos) And $aTrainPos[0] <> -1 Then
					SetLog("Adding " & $g_aiQuickTroopQty[$i][$j] & "x " & $g_asTroopNames[$iIndex], $COLOR_SUCCESS)
					ClickP($aTrainPos, $g_aiQuickTroopQty[$i][$j], $g_iTrainClickDelay, "QTrain")
				EndIf
			EndIf
		Next
		For $j = 0 To 6
			Local $iIndex = $g_aiQuickSpellType[$i][$j]
			If _ArrayIndexValid($g_aiArmyQuickSpells, $iIndex) Then
				If $iArmyPage < 2 Then
					If Not DragIfNeeded("IceG") Then Return
					If _Sleep(1500) Then Return
					$iArmyPage = 2
				EndIf
				Local $sFilter = String($g_asSpellShortNames[$iIndex]) & "*"
				Local $asImageToUse = _FileListToArray($g_sImgTrainSpells, $sFilter, $FLTA_FILES, True)
				Local $aTrainPos = GetVariable($asImageToUse[1], $iIndex + $eLSpell)
				If IsArray($aTrainPos) And $aTrainPos[0] <> -1 Then
					SetLog("Adding " & $g_aiQuickSpellQty[$i][$j] & "x " & $g_asSpellNames[$iIndex], $COLOR_SUCCESS)
					ClickP($aTrainPos, $g_aiQuickSpellQty[$i][$j], $g_iTrainClickDelay, "QTrain")
				EndIf
			EndIf
		Next
		If _Sleep(1000) Then Return
	EndIf
EndFunc   ;==>CreateQuickTrainPreset
