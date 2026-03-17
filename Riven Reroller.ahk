#Requires AutoHotkey v2.0
#SingleInstance Force

global RELEASE_BUILD := false

#Include modules\OCR.ahk
#Include modules\Json.ahk
#Include modules\Config.ahk
#Include modules\Logger.ahk
#Include modules\ProfileLoader.ahk
#Include modules\StateDetection.ahk
#Include modules\Actions.ahk
#Include modules\RivenAttributes.ahk
#Include modules\Decision.ahk
#Include modules\MainLoop.ahk
#Include modules\Tests.ahk
#Include modules\TestingHotkeys.ahk
#Include modules\Hotkeys.ahk

SetWorkingDir A_ScriptDir
CoordMode "Mouse", "Window"
SendMode "Event"
SetTitleMatchMode 2

InitializeRuntimeConfig()
InitializeLogger()

if (TryAutoLoadLastProfile()) {
    PrintStatus("Auto-loaded profile: " . ACTIVE_PROFILE.profileName)
    LogEvent("INFO", "AutoLoadProfileSuccess", {path: ACTIVE_PROFILE.sourcePath})
} else {
    PrintStatus("Press F8 to load a JSON profile.")
    LogEvent("INFO", "AwaitingProfileSelection")
}

ShowProfileOverviewDialog("Riven Reroller Ready")
