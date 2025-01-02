### NAME
lddiff - diff ldd of two or more files

### USAGE
      lddiff [OPTIONS] FILE1 FILE2

### DESCRIPTION
Lddiff lists shared libs required by programs or libs.
For two or more files it aligns them as a line-by-line diff.
It is implemented as a wrapper of ldd and od.

### OPTIONS
      -h  This help.
      -v  Verbose.
     -bw  Black & white.
      -p  Primary libs only.
      -s  Short, strip lib and .so..
     -ng  Don't highlight secondary libs (green).
     -fh  Full header, display directory and filename.
      -d  Diff mode: black-out identical names. (not one column)
     -dw  Diff mode: white if some columns missing.

### COLORS
        red  Missing libs.
    default  Primary libs, referenced directly from the file.
      green  Libs referenced from libs.
    magenta  Additional libs not seen by ldd but found by od.
      black  Blacked-out libs present in all existing columns.
      white  Blacked-out libs with columns missing (-dw option).

### STATISTICS
      The last line "84-28-13+1" means:
  
    84  84 referenced libs found by ldd,
    28  from these, 28 are secondary, referenced from other libs,
    13  from these, 13 are not found, so program will not run,
     1  additional one potentially required lib is found by od.

### EXAMPLES
      lddiff -v libgtk*
      lddiff -bw libgtk* | grep libX
      lddiff -s -d libX*

### TRY ALSO
      objdump -p $FILE | grep NEEDED | sed 's:.* ::' | sort
      readelf -d $FILE | grep NEEDED | sed 's:.*\[::' | sed 's:\]::' | sort
      lsof -p $PID | sed 's:.* ::' | grep .so | sed 's:.*/::' | sort
      ldd $FILE | grep ' => ' | sed 's: => .*::' | sed 's:\t::' | sort
      od -S 7 $FILE | grep lib | grep -F .so | cut -d ' ' -f 2 | sed 's:^.*/::' | grep '^lib' | sort -u

### VERSION
lddiff-0.5a R.Jaksa 2024 GPLv3 built 2025-01-02

