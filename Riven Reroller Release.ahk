#Requires AutoHotkey v2.0
#SingleInstance Force

global RELEASE_BUILD := true

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
#Include modules\Hotkeys.Release.ahk

SetWorkingDir A_ScriptDir
CoordMode "Mouse", "Window"
SendMode "Event"
SetTitleMatchMode 2

InitializeRuntimeConfig()
InitializeLogger()

PrintStatus("Press Change profile or F8 to load a JSON profile.")
ShowProfileOverviewDialog("Riven Reroller Ready")
