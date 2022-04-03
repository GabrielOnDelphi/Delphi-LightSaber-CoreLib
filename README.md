# Delphi-LightSaber  
Contains useful functions.   
Lightweight (only 10000 lines of code) alternative to Jedi library.   

Simple, crystal clear, non-obfuscated, fully commented code.   
No external dependencies.   
  
**This library will be expanded if it gets enough Stars.** Click the 'Star' button (top-right corner) if you like this library.  
Over 100 files are waiting to be cured and added: graphichs, simple encryption, internet functions (including file download routines), HTML manipulation, image manipulation, registry, math and LOTS of visual components!

Click the 'Watch' button if you want to get notified about updates.  
_________________


**ccCore.pas**  
  Over 200 functions for:  
- String manipulation (string conversions, sub-string detection, word manipulation, cut, copy, split, wrap, etc)  
- Programmer's helper  
- Form manipulation  
- Advanced/easy message boxes  
- DateTime utilities  
- etc etc etc etc etc etc etc 
    
    
**ccIO.pas**  
  Super useful functions for file/folder/disk manipulation:  
- Copy files   
- File/Folder Exists    
- Get special Windows folders (My Documents, etc)  
- Prompt user to select a file/folder  
- List specified files (.jpg for ex) in a folder and all its sub-folders  
- Increment the numbers in a filename (good for incremental backups)  
- Append strings to file name  
- Read text from files to a string variable  
- Compare files  
- Merge files  
- Sort lines in a file  
- Drive manipulation (IsDiskInDrive, etc)    
- etc  
     
**ccAppData.pas**  
Application-wide functions:
- Get application's appdata folder (the folder where you save temporary, app-related and ini files)
- Get application's command line parameters
- Detect if the application is running for the firs this in a computer
- Application self-restart
- Application self-delete
- etc
     
**ccStreamBuff.pas**  
Extends TBufferedFileStream
This class adds new functionality that does not exist in Delphi's original stream classes:
- Read/WriteBoolean
- Read/WriteString (ansi, unicode)
- Read/WriteInteger
- Read/WriteCardinal
- Read/WriteDate
- Read/Write mac files (inverted byte endianness)
- etc

TBufferedFileStream provides VERY fast reading/writing access to a file
TBufferedFileStream is optimized for multiple consecutive small reads or writes.
TBufferedFileStream will not give performance gain, when there are random position reads or writes, or large reads or writes.
TBufferedFileStream may be used as a drop-in replacement for TFileStream.   
     
**ccStreamFile.pas**  
     Expansion class for Delphi classical TFileStream. Allows you to directly read/write bytes, cardinals, words, integers, strings to a (binary) files.
     Now replaced by ccStreamBuff.
     
**ccBinary.pas**  
- String to hex, hex to string conversions (and many others)  
- Binary numbers (endianness) swapping  
- Data serialization  
- Bit manipulation (set bit, etc)  
- Reverse bits  
- Endianess
- etc   

**ccWinVersion.pas**
This library expands the TOSVersion.  
Use it to get Windows version.  
Example of functions:    
- IsWindowsXP  
- IsWindowsXPUp  
- IsWindowsVista    
- IsWindowsVistaUp  
- IsWindows7  
- IsWindows7Up  
- IsWindows8  
- IsWindows8Up  
- IsWindows10  
- etc   

**Resume application's GUI state**

ccINIFileVCL.pas 

Do you have applications with forms with lots of controls (like checkboxes/radiobuttons) and you want to save its status to disk on shutdown and resume exaclty from where you left on application startup with just one function call?  
  Use SaveForm/LoadForm.  

Example:   
- Call SaveForm(MySettingsForm) in TMySettingsForm.OnDestroy     
- Call LoadForm(MySettingsForm) after the creation of TMySettingsForm     

**ccINIFile**  

Features:  
- Extends the capabilities of TIniFile  
- Functions for easily accessing application's default INI file.  

Setup:  
     Before using it you must set the ccAppData.AppName global var.  
     The class will use that name to automatically determine the INI file name/path which is %AppData%\AppName.Ini.  
     Example: If the AppName is set to "DelphiLightSaber" the ini file will be  "c:\Users\UserName\AppData\Roaming\DelphiLightSaber\DelphiLightSaber.ini" 
 
_____

**Filename convention**  
  
- 'c' -> The first c stands for 'cubic', 
- 'c' -> The second 'c' stands for 'core'.  All files I posted in library/repository are 'core' because other libraries will be based on them.  
- 'v'-> visual component 
- 'Graph'-> graphic library  

Example:   
- ccBinary.pas  (Cubic core library)
- cvMemo.pas    (Cubic visual component)
- cGraphFX.pas  (Cubic graphic library) 
  
_____

This library is freeware (see included copyright notice). 
The library cannot be used in Russia!

Enjoy and "Star" the library if it is useful to you.
