# SVG-Transparencyer

## About

Searches in SVG files for a color string and sets the corresponding color attributes to transparent.

## Command Line

```console
$ ./svg-transparencyer --help
Usage: svg-transparencyer <PARAMETER>

PARAMETERS

  -v, --version     Shows the version number
  -h, --help        Shows this help text
  <COLOR> <PATH>    Processes the SVG files

<COLOR> is the color string that is being searched for.
During the search, whitespace characters, tab characters and
upper/lower case differences are ignored.

<PATH> is either a path to a directory containing SVG files
(other files are ignored), or a path to an SVG file. The path
can be relative or absolute.

EXAMPLE

  Search for '#fff' and make the color transparent:

      svg-transparencyer '#fff' example.svg
```
