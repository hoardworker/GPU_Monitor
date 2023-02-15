; ===========================================================================================================================================================================

/*
	BUILD ON TOP OF
	
	
	AutoHotkey wrapper for NVIDIA NvAPI (Example Script)

	Author ....: jNizM
	Released ..: 2014-12-29
	Modified ..: 2020-09-30
	License ...: MIT
	GitHub ....: https://github.com/jNizM/AHK_NVIDIA_NvAPI
	Forum .....: https://www.autohotkey.com/boards/viewtopic.php?t=95112
*/

; SCRIPT DIRECTIVES =========================================================================================================================================================

#Requires AutoHotkey v2.0-


; GUI =======================================================================================================================================================================

OnMessage 0x0111, EN_SETFOCUS

Main := Gui()
Main.MarginX := 10
Main.MarginY := 10

Main.SetFont("s16 w700", "Segoe UI")
Main.AddText("xm ym w270 0x201", StrReplace(GPU.GetFullName(), "NVIDIA "))
Main.SetFont("s10 w400", "Segoe UI")

Main.AddGroupBox("xm y+10 w270 h300 Section", "Rolling Usage Monitor ")
Main.AddText("xs+10 ys+25 w148 h25 0x202", "Current GPU Core ")
MainCur := Main.AddEdit("x+4 yp w60 0x802")
Main.AddText("x+4 yp w40 h25 0x200", "%")
Main.AddText("xs+10 y+10 w148 h25 0x202", "10 Second Average ")
MainAve10 := Main.AddEdit("x+4 yp w60 0x802")
Main.AddText("x+4 yp w40 h25 0x200", "%")
Main.AddText("xs+10 y+10 w148 h25 0x202", "60 Second Average ")
MainAve60 := Main.AddEdit("x+4 yp w60 0x802")
Main.AddText("x+4 yp w40 h25 0x200", "%")
MainBox := Main.AddCheckBox("xs+10 y+5 w250 h35 vNotifyB", "Turn red when 60 second average is below Minimum Average Usage?")



Main.AddText("xs+10 y+10 w190 h25 0x202", "Minimum Average Usage: ")
MainAveTxt := Main.AddText("x+4 yp w23 h25 0x200", "50")
Main.AddText("x+0 yp w40 h25 0x200", "%")
MainSlider := Main.AddSlider("xs+30 y+10 w200 0x200 0x100 vUseSlider", 50)

MainSound := Main.AddCheckBox("xs+10 y+5 w250 h15 vNotifyS", "Notify with sound?")
MainSChoice := Main.AddDropDownList("xs+10 y+5 w250 h15 R3 vSChoice Choose1", ["Every 10 Seconds","Every 30 Seconds","Every 1 Minute","Every 5 Minutes"])



Main.Show()
SetTimer NVIDIA, 1000


; FUNCTIONS =================================================================================================================================================================

EN_SETFOCUS(wParam, lParam, *)
{
	static EM_SETSEL   := 0x00B1
	static EN_SETFOCUS := 0x0100
	if ((wParam >> 16) = EN_SETFOCUS)
	{
		DllCall("user32\HideCaret", "Ptr", lParam)
		PostMessage EM_SETSEL, -1, 0,, "ahk_id " lParam
	}
}

GPUloadSamples10 := Array()
GPUloadSamples60 := Array()
SamplesCount := 0
Samples10 := 10
Samples60 := 20
Ave10 := 0
Ave60 := 0

InitializeAve()
{
	PstatesInfoEx    := GPU.GetDynamicPstatesInfoEx()
	Loop Samples10 
	{
		GPUloadSamples10.Push(PstatesInfoEx["GPU"]["percentage"])
	}
	Loop Samples60 
	{
		GPUloadSamples60.Push(PstatesInfoEx["GPU"]["percentage"])
	}
}

RollingAve()
{	
global Ave10
global Ave60
global SamplesCount
	
	PstatesInfoEx    := GPU.GetDynamicPstatesInfoEx()
	GPUloadSamples10.Push(PstatesInfoEx["GPU"]["percentage"])
	global SamplesCount := SamplesCount + 1

	if(SamplesCount == 5)
	{
		GPUloadSamples60.Push(PstatesInfoEx["GPU"]["percentage"])
		SamplesCount := 0
		;SoundPlay "*16"
	}
	
	if(GPUloadSamples10.Length>Samples10)
	{
		GPUloadSamples10.RemoveAt(1)
	}
	
	if(GPUloadSamples60.Length>Samples60)
	{
		GPUloadSamples60.RemoveAt(1)
	}
	
	Sum10 := 0
	For s in GPUloadSamples10
	{
		Sum10 := Sum10 + s
	}
	
	Sum60 := 0
	For s in GPUloadSamples60
	{
		Sum60 := Sum60 + s
	}
	
	Ave10 := Sum10/Samples10
	Ave60 := Sum60/Samples60

	MainAve10.Text := Ave10
	MainAve60.Text := Ave60

	Warn()

}
UnderCount := 0

Warn()
{	global Ave60
	global UnderCount
	notifTime := 0
	
	Box := MainBox.Value
	if(Box == 1){
		if(Ave60 < MainSlider.Value){
			if(Main.BackColor != "F18D77")
			{
				Main.BackColor := "F18D77"
			}
			if(MainSChoice.Value == 1){
			notifTime := 10
			}
			if(MainSChoice.Value == 2){
			notifTime := 30
			}
			if(MainSChoice.Value == 3){
			notifTime := 60
			}
			if(MainSChoice.Value == 4){
			notifTime := 300
			}
			
			if(Mod(UnderCount,notifTime) == 0 && MainSound.Value == 1)
			{
				SoundPlay "*-1"
				UnderCount := 1
			}
			
			UnderCount := UnderCount + 1
		}else{
			Main.BackColor := ""
		}
		
	}
	if(Box == 0)
	{
		if(Main.BackColor != "")
		{
			Main.BackColor := ""
		}
	}

	
	
}

NVIDIA()
{
	if(GPUloadSamples10.Length == 0){
		InitializeAve()
	}
	PstatesInfoEx    := GPU.GetDynamicPstatesInfoEx()
	MainCur.Text   := PstatesInfoEx["GPU"]["percentage"]
	
	RollingAve()
	
	MainAveTxt.Value := MainSlider.Value
}


; INCLUDES ==================================================================================================================================================================

#Include src/Class_NvAPI.ahk


; ===========================================================================================================================================================================