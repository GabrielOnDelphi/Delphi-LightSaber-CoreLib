# Delphi-LightSaber  
Contains useful functions.   
Lightweight alternative to Jedi library.   

Simple, crystal clear, non-obfuscated, fully commented code.   
No external dependencies.   
  
**This library will be expanded it gets enough Stars.** Click the 'Star' button (top-right corner) if you like this library.  
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
- Get application's system/appdata folder  (Example: c:\Users\UserName\AppData\Roaming\AppName\System\)
- Get application's INI file  (Example: c:\Users\UserName\AppData\Roaming\AppName\AppName.ini )
- Get application's command line parameters  
- Detect if the application is running for the first time in this computer  
- Application self-restart  
- Application self-delete  
- etc   
     
**ccStreamBuff.pas**  
     Buffered file access (VERY fast reading/writing to a file). 
     Adds new functionality that does not exist in Delphi's original stream classes:
- Read/WriteBoolean
- Read/WriteString (ansi, unicode)
- Read/WriteInteger
- Read/WriteCardinal
- Read/WriteDate
- Read/Write mac files (inverted byte endianness) 
- etc   
     
**ccStreamFile.pas**  
     Expansion class for Delphi classical TFileStream. Allows you to directly read/write bytes, cardinals, words, integers, strings to a (binary) files.  
     
**ccBinary.pas**  
- String to hex, hex to string conversions (and many others)  
- Binary numbers (endianness) swapping  
- Data serialization  
- Bit manipulation (set bit, etc)  
- Reverse bits  
- Endianess
- etc   

**ccWinVersion.pas**
     This library provides 3 ways to get Windows version.  
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

**Resume application**

Do you have applications with forms with lots of controls (like checkboxes) and you want to save its status to disk on shutdown and resume exaclty from where you left on application startup?    
Use SaveForm/LoadForm from cvINIFileEx.pas (to be added as soon as the project receives 50 Stars).  
Example:   
- Call SaveForm(MySettingsForm) in TMySettingsForm.OnDestroy     
- Call LoadForm(MySettingsForm) in TMySettingsForm.OnCreate      

 
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

This library is freeware (see included copyright notice). The requirements are quite relaxed and involve no legalese. 
So, enjoy and "Star" the library if it is useful to you.
