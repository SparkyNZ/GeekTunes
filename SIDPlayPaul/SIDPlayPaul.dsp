# Microsoft Developer Studio Project File - Name="SIDPlayPaul" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) Console Application" 0x0103

CFG=SIDPlayPaul - Win32 Debug
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE 
!MESSAGE NMAKE /f "SIDPlayPaul.mak".
!MESSAGE 
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE 
!MESSAGE NMAKE /f "SIDPlayPaul.mak" CFG="SIDPlayPaul - Win32 Debug"
!MESSAGE 
!MESSAGE Possible choices for configuration are:
!MESSAGE 
!MESSAGE "SIDPlayPaul - Win32 Release" (based on "Win32 (x86) Console Application")
!MESSAGE "SIDPlayPaul - Win32 Debug" (based on "Win32 (x86) Console Application")
!MESSAGE 

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""
CPP=cl.exe
RSC=rc.exe

!IF  "$(CFG)" == "SIDPlayPaul - Win32 Release"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "Release"
# PROP BASE Intermediate_Dir "Release"
# PROP BASE Target_Dir ""
# PROP Use_MFC 0
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "Release"
# PROP Intermediate_Dir "Release"
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD CPP /nologo /W3 /GX /O2 /D "WIN32" /D "NDEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /c
# ADD BASE RSC /l 0x409 /d "NDEBUG"
# ADD RSC /l 0x409 /d "NDEBUG"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib  kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386
# ADD LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib  kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /machine:I386

!ELSEIF  "$(CFG)" == "SIDPlayPaul - Win32 Debug"

# PROP BASE Use_MFC 0
# PROP BASE Use_Debug_Libraries 1
# PROP BASE Output_Dir "Debug"
# PROP BASE Intermediate_Dir "Debug"
# PROP BASE Target_Dir ""
# PROP Use_MFC 2
# PROP Use_Debug_Libraries 1
# PROP Output_Dir "Debug"
# PROP Intermediate_Dir "Debug"
# PROP Ignore_Export_Lib 0
# PROP Target_Dir ""
# ADD BASE CPP /nologo /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /YX /FD /GZ  /c
# ADD CPP /nologo /MDd /W3 /Gm /GX /ZI /Od /D "WIN32" /D "_DEBUG" /D "_CONSOLE" /D "_MBCS" /D "_AFXDLL" /YX /FD /GZ  /c
# ADD BASE RSC /l 0x409 /d "_DEBUG"
# ADD RSC /l 0x409 /d "_DEBUG" /d "_AFXDLL"
BSC32=bscmake.exe
# ADD BASE BSC32 /nologo
# ADD BSC32 /nologo
LINK32=link.exe
# ADD BASE LINK32 kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib  kernel32.lib user32.lib gdi32.lib winspool.lib comdlg32.lib advapi32.lib shell32.lib ole32.lib oleaut32.lib uuid.lib odbc32.lib odbccp32.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept
# ADD LINK32 sdl.lib sdlmain.lib /nologo /subsystem:console /debug /machine:I386 /pdbtype:sept

!ENDIF 

# Begin Target

# Name "SIDPlayPaul - Win32 Release"
# Name "SIDPlayPaul - Win32 Debug"
# Begin Group "Source Files"

# PROP Default_Filter "cpp;c;cxx;rc;def;r;odl;idl;hpj;bat"
# Begin Source File

SOURCE=.\config.cpp
# End Source File
# Begin Source File

SOURCE=.\envelope.cpp
# End Source File
# Begin Source File

SOURCE=.\event.cpp
# End Source File
# Begin Source File

SOURCE=.\extfilt.cpp
# End Source File
# Begin Source File

SOURCE=.\filter.cpp
# End Source File
# Begin Source File

SOURCE=.\IconInfo.cpp
# End Source File
# Begin Source File

SOURCE=.\InfoFile.cpp
# End Source File
# Begin Source File

SOURCE=.\main.cpp
# End Source File
# Begin Source File

SOURCE=.\mixer.cpp
# End Source File
# Begin Source File

SOURCE=.\mos6510.cpp
# End Source File
# Begin Source File

SOURCE=.\mos6526.cpp
# End Source File
# Begin Source File

SOURCE=.\mos656x.cpp
# End Source File
# Begin Source File

SOURCE=.\MUS.cpp
# End Source File
# Begin Source File

SOURCE=.\p00.cpp
# End Source File
# Begin Source File

SOURCE=.\player.cpp
# End Source File
# Begin Source File

SOURCE=.\pot.cpp
# End Source File
# Begin Source File

SOURCE=.\PP20.cpp
# End Source File
# Begin Source File

SOURCE=.\prg.cpp
# End Source File
# Begin Source File

SOURCE=.\PSID.cpp
# End Source File
# Begin Source File

SOURCE=.\psiddrv.cpp
# End Source File
# Begin Source File

SOURCE=.\reloc65.cpp
# End Source File
# Begin Source File

SOURCE=".\resid-builder.cpp"
# End Source File
# Begin Source File

SOURCE=.\resid.cpp
# End Source File
# Begin Source File

SOURCE=.\sid.cpp
# End Source File
# Begin Source File

SOURCE=.\sid6526.cpp
# End Source File
# Begin Source File

SOURCE=.\sidplay2.cpp
# End Source File
# Begin Source File

SOURCE=.\SidTune.cpp
# End Source File
# Begin Source File

SOURCE=.\SidTuneTools.cpp
# End Source File
# Begin Source File

SOURCE=.\version.cpp
# End Source File
# Begin Source File

SOURCE=.\voice.cpp
# End Source File
# Begin Source File

SOURCE=.\wave.cpp
# End Source File
# Begin Source File

SOURCE=.\wave6581__ST.cpp
# End Source File
# Begin Source File

SOURCE=.\wave6581_P_T.cpp
# End Source File
# Begin Source File

SOURCE=.\wave6581_PS_.cpp
# End Source File
# Begin Source File

SOURCE=.\wave6581_PST.cpp
# End Source File
# Begin Source File

SOURCE=.\wave8580__ST.cpp
# End Source File
# Begin Source File

SOURCE=.\wave8580_P_T.cpp
# End Source File
# Begin Source File

SOURCE=.\wave8580_PS_.cpp
# End Source File
# Begin Source File

SOURCE=.\wave8580_PST.cpp
# End Source File
# Begin Source File

SOURCE=.\xsid.cpp
# End Source File
# End Group
# Begin Group "Header Files"

# PROP Default_Filter "h;hpp;hxx;hm;inl"
# Begin Source File

SOURCE=.\Buffer.h
# End Source File
# Begin Source File

SOURCE=.\c64cia.h
# End Source File
# Begin Source File

SOURCE=.\c64env.h
# End Source File
# Begin Source File

SOURCE=.\c64vic.h
# End Source File
# Begin Source File

SOURCE=.\c64xsid.h
# End Source File
# Begin Source File

SOURCE=.\component.h
# End Source File
# Begin Source File

SOURCE=.\conf6510.h
# End Source File
# Begin Source File

SOURCE=.\config.h
# End Source File
# Begin Source File

SOURCE=.\envelope.h
# End Source File
# Begin Source File

SOURCE=.\event.h
# End Source File
# Begin Source File

SOURCE=.\extfilt.h
# End Source File
# Begin Source File

SOURCE=.\filter.h
# End Source File
# Begin Source File

SOURCE=.\MoreMath.h
# End Source File
# Begin Source File

SOURCE=.\mos6510.h
# End Source File
# Begin Source File

SOURCE=.\mos6510c.h
# End Source File
# Begin Source File

SOURCE=.\mos6526.h
# End Source File
# Begin Source File

SOURCE=.\mos656x.h
# End Source File
# Begin Source File

SOURCE=.\nullsid.h
# End Source File
# Begin Source File

SOURCE=.\opcodes.h
# End Source File
# Begin Source File

SOURCE=.\player.h
# End Source File
# Begin Source File

SOURCE=.\pot.h
# End Source File
# Begin Source File

SOURCE=.\PP20.h
# End Source File
# Begin Source File

SOURCE=.\PP20_Defs.h
# End Source File
# Begin Source File

SOURCE=".\resid-emu.h"
# End Source File
# Begin Source File

SOURCE=.\resid.h
# End Source File
# Begin Source File

SOURCE=.\sid.h
# End Source File
# Begin Source File

SOURCE=.\sid2types.h
# End Source File
# Begin Source File

SOURCE=.\sid6510c.h
# End Source File
# Begin Source File

SOURCE=.\sid6526.h
# End Source File
# Begin Source File

SOURCE=.\sidbuilder.h
# End Source File
# Begin Source File

SOURCE=.\sidconfig.h
# End Source File
# Begin Source File

SOURCE=.\siddefs.h
# End Source File
# Begin Source File

SOURCE=.\sidendian.h
# End Source File
# Begin Source File

SOURCE=.\sidenv.h
# End Source File
# Begin Source File

SOURCE=.\sidint.h
# End Source File
# Begin Source File

SOURCE=.\sidplay2.h
# End Source File
# Begin Source File

SOURCE=.\SidTune.h
# End Source File
# Begin Source File

SOURCE=.\SidTuneCfg.h
# End Source File
# Begin Source File

SOURCE=.\SidTuneTools.h
# End Source File
# Begin Source File

SOURCE=.\sidtypes.h
# End Source File
# Begin Source File

SOURCE=.\SmartPtr.h
# End Source File
# Begin Source File

SOURCE=.\spline.h
# End Source File
# Begin Source File

SOURCE=.\voice.h
# End Source File
# Begin Source File

SOURCE=.\wave.h
# End Source File
# Begin Source File

SOURCE=.\xsid.h
# End Source File
# End Group
# Begin Group "Resource Files"

# PROP Default_Filter "ico;cur;bmp;dlg;rc2;rct;bin;rgs;gif;jpg;jpeg;jpe"
# End Group
# End Target
# End Project
