;27/APR/2019 - Written by KramWell.com
;Updated 16/JAN/2022
;Use this program with FreeFileSync and it will email you the log results when its finished its latest sync job

#NoEnv
SetWorkingDir %A_ScriptDir%

#NoTrayIcon
#SingleInstance FORCE

outputFile := A_AppData "\FreeFileSync\Logs\emailSync-output.log"

FormatTime, TimeString, A_Now, dd/MM/yy HH:mm:ss

FileAppend,`n[%TimeString%] Starting app..`n, %outputFile%

emailSubject :=

TimeThreshold := A_Now
TimeThreshold += -30, seconds

FileAppend, [%TimeString%] Finding FreeFileSync log files`n, %outputFile%

sleep, 5000

Loop, %A_AppData%\FreeFileSync\Logs\*.html
{
	FileGetTime, ModTime, %A_AppData%\FreeFileSync\Logs\%A_LoopFileName%

	;only show log file created in the last 30 seconds (most recent run) 
	if (ModTime > TimeThreshold){
	
		FileAppend,[%TimeString%] Found log file %A_LoopFileName%`n, %outputFile%
	
		sAttach := A_LoopFilePath
		emailSubject := A_LoopFileName 
	}
}	
	
	toAddress := "example@gmail.com"
	smtpAddress := "smtp.gmail.com"
	fromAddress := "example@gmail.com"
	
	pmsg 						:= ComObjCreate("CDO.Message")
	pmsg.From 					:= fromAddress
	pmsg.To 					:= toAddress
	
	if (emailSubject){
		pmsg.AddAttachment(sAttach)
		pmsg.Subject := emailSubject
	}else{
		FileAppend,[%TimeString%] No Attachment found`n, %outputFile%
		pmsg.Subject := "Sync settings :" A_ComputerName " No attachment"
	}
	
	pmsg.TextBody 					:= "Report from server " A_ComputerName " regarding sync settings, please see attached."
	fields 						:= Object()
	fields.smtpserver   				:= smtpAddress
	fields.smtpserverport   			:= 465
	fields.smtpusessl      				:= True
	fields.sendusing     				:= 2
	fields.smtpauthenticate 			:= 1
	fields.sendusername 				:= "example@gmail.com"
	fields.sendpassword 				:= "password"
	fields.smtpconnectiontimeout			:= 10
	schema 						:= "http://schemas.microsoft.com/cdo/configuration/"
	pfld 						:=  pmsg.Configuration.Fields
	For field,value in fields
		pfld.Item(schema . field) 		:= value
	pfld.Update()

	FileAppend,[%TimeString%] Sending email...`n, %outputFile%
	
	try  ; Attempt to send email.
	{
		pmsg.Send()
	}
		catch e
		{
			outputError := "Exception thrown!`n`nwhat: " e.what "`nfile: " e.file "`nline: " e.line "`nmessage: " e.message "`nextra: " e.extra
			;log failure in file dump
			FileAppend,[%TimeString%] %outputError%`n, %outputFile%
			ExitApp
		}

	FileAppend,[%TimeString%] Email sent!`n, %outputFile%