# Delphi-LightSaber  
Contains useful functions.   
Lightweight alternative to Jedi library.   

Simple, crystal clear, non-obfuscated, fully commented code.   
No external dependencies.   
  
This library will be expanded soon (graphichs, simple encryption, internet, HTML manipulation, image manipulation, registry, math, lots of visual components).

_________________


**ccCore.pas**  
  Over 200 functions for:  
     * String manipulation (string conversions, sub-string detection, word manipulation, cut, copy, split, wrap, etc)  
     * Programmer's helper  
     * Form manipulation  
     * Advanced/easy message boxes  
     * DateTime utilities  
     * etc etc etc etc etc etc etc 
    
    
**ccIO.pas**  
  Super useful functions for file/folder/disk manipulation:  
     * Copy files   
     * File/Folder Exists    
     * Get special Windows folders (My Documents, etc)  
     * Prompt user to select a file/folder  
     * List specified files (*.jpg for ex) in a folder and all its sub-folders  
     * Increment the numbers in a filename (good for incremental backups)  
     * Append strings to file name  
     * Read text from files to a string variable  
     * Compare files  
     * Merge files  
     * Sort lines in a file  
     * Drive manipulation (IsDiskInDrive, etc)    
     * etc  
     
     
**ccAppData.pas**  
  Application-wide functions:  
     * Get application's system/appdata folder  (Example: c:\Users\UserName\AppData\Roaming\AppName\System\)
     * Get application's INI file  (Example: c:\Users\UserName\AppData\Roaming\AppName\AppName.ini )
     * Get application's command line parameters  
     * Detect if the application is running for the first time in this computer  
     * Application self-restart  
     * Application self-delete  
     * etc   
     
**ccStreamBuff.pas**  
     Buffered file access (VERY fast reading/writing to a file). 
     Adds new functionality that does not exist in Delphi's original stream classes:
       Read/WriteBoolean
       Read/WriteString (ansi, unicode)
       Read/WriteInteger
       Read/WriteCardinal
       Read/WriteDate
       Read/Write mac files (inverted byte endianness) 
       etc   
     
**ccStreamFile.pas**  
     Expansion class for Delphi classical TFileStream. Allows you to directly read/write bytes, cardinals, words, integers, strings to a (binary) files.  
     
**ccBinary.pas**  
     String to hex, hex to string conversions (and many others)  
     Binary numbers (endianness) swapping  
     Data serialization  
     Bit manipulation (set bit, etc)  
     Reverse bits  
     Endianess
     etc   

**ccWinVersion.pas**
     This library provides 3 ways to get Windows version.  
     Example of functions:   
       IsWindowsXP  
       IsWindowsXPUp  
       IsWindowsVista    
       IsWindowsVistaUp  
       IsWindows7  
       IsWindows7Up  
       IsWindows8  
       IsWindows8Up  
       IsWindows10  
       etc   

_____

**Filename convention**

The first 'c' stands for 'cubic', the second 'c' stands for 'core'. 
This library is called 'core' because other libraries will be based on it. 
'cv' - cubic visual components
'cGraph' - cubic graphic library

Examples: 
     * ccBinary.pas
     * cvMemo.pas
     * cGraphFX.pas


_____

This library is freeware (see included copyright notice).
Click the 'Star' button (top-right corner) if you like this library.  
Click the 'Watch' button if you want to get notified about updates.  
