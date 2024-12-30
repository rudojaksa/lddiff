# `lddiff` tool to diff `ldd` of two or more files

`Lddiff` lists shared libs required by programs or libs.
For two or more files it aligns them as a line-by-line diff.
It's a wrapper of `ldd` and `od`.

<a href=doc/sshot1.png><img src=doc/sshot1.png></a>

```
      red  missing libs
  default  primary libs, referenced directly from the file
    green  libs referenced from libs
  magenta  additional libs not seen by `ldd` but found by `od`
    black  blacked-out libs present in all existing columns  
    white  blacked-out libs with columns missing (`-b` option)
```

<a href=doc/sshot2.png><img height=153px src=doc/sshot2.png></a>
<a href=doc/sshot3.png><img height=153px src=doc/sshot3.png></a>
<a href=doc/sshot4.png><img height=153px src=doc/sshot4.png></a>

### Man page

 * [lddiff -h](doc/lddiff.md)  

### Try also

``` sh
objdump -p $FILE | grep NEEDED | sed 's:.* ::' | sort
readelf -d $FILE | grep NEEDED | sed 's:.*\[::' | sed 's:\]::' | sort
lsof -p $PID | sed 's:.* ::' | grep .so | sed 's:.*/::' | sort
ldd $FILE | grep ' => ' | sed 's: => .*::' | sed 's:\t::' | sort
od -S 7 $FILE | grep lib | grep -F .so | cut -d ' ' -f 2 | sed 's:^.*/::' | grep '^lib' | sort -u
```

<br><div align=right><i>R.Jaksa 2024 GPLv3</i></div>
