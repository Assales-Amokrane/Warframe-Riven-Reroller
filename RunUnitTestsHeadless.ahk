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

SetWorkingDir A_ScriptDir

InitializeRuntimeConfig()
InitializeLogger()

resultPath := A_Args.Length >= 1 ? A_Args[1] : (A_ScriptDir "\logs\unit-test-results.txt")
results := RunUnitTestsHeadless(resultPath)
ExitApp(results.failed > 0 ? 1 : 0)
