# handbrakecli-massencode
Ported over from `code.google.com/p/handbrakecli-massencode` since it still seems to get a bit of activity now and again.

**DEPRECATED**

This project hasn't been worked on in years and is no longer supported.

##Introduction
A Handbrake CLI wrapper for mass encoding multiple items. For example, iterating through a collection of DVDs, encoding all, and deleting the originals. NOTE: This project is currently in BETA, so some functions may not work properly. Specifically, you should not use the -D flag to delete the original media files until you have confirmed that the script works properly for you. Please submit any issues or bugs!

Uses HandBrake http://handbrake.fr under the terms of the GNU General Public License.

##Uses
Great for iterating through a entire directories and sub-directories, looking for and encoding particular media types:

*raw DVD files.

Original designed to iterate through an entire drive and encode all raw DVD files to AVI encoded files. Schedule this script to run each night to automatically encode new files added to your library.

##Features
The Mass Encode wrapper for HandBrakeCLI has many useful features with more to come!

*Search a single directory for files or recursively search children.
*Delete original files once encoded (optional).
*Encode a collection of raw DVD files in separate directories.
*Save encoded files in once master directory or in the same directory as the originals.
*Use all your usual HandBrakeCLI commands.
*Lightweight, stand-alone executable, currently for Windows 32-bit systems.

##Examples

###Recursively encode all raw DVD files on a drive

Drive containing DVD files: M:\

Format to encode DVDs to: avi

Check child folders: Yes (-R)

Delete original files once encoded: Yes (-D)

Output: Save all files under M:\ regardless of child folder found in.

`massencode.exe -i M:\ -f avi -o M:\ -R -D --params "<Other CLI Commands>" --verbose`

###Same example as above, with pause
Pause between 8-10a and 4-6p

`massencode.exe -i M:\ -f avi -o M:\ -R -D --params "<Other CLI Commands>" --verbose -p 0800:1000,1600:1800`

##Latest Release Notes
24 August 2009

* Fixed bug with logging

* Forced log write after encoding a file

* Added log buffer

* Fixed bug with DVD folder deletion

* Removed log file retry

23 July 2009

* Fixed bug with detecting Windows OS 

* Fixed typo in Usage 

* Fixed bug parsing pause times 

* Log is written for every 1MB of log information 

* If log's file handle isn't opened, retry 3 times

17 July 2009 

* Pause functionality added in (-p, --pause flag).

* Linux executable.
