@echo off

rem Process contains two steps:
rem 1. Process the log of stack traces and produce a graph in the text based dot-language (RefCountTracer.exe)
rem 2. Generate a nicely layouted graphic diagram out of the dot file (dot.exe)

rem Step 1 - generate dot file
%~dp0RefCountTracer.exe "%1" "%1.dot" %3 %4 %5 %6 %7

if not errorlevel 0 goto exit

rem Step 2 - generate a diagram

rem Path to dot.exe (part of Graphviz -> http://www.graphviz.org/)
set dot=dot.exe

rem Output format. Other valid formats are png, pdf, svg, and all listed here: http://www.graphviz.org/content/output-formats
set format=png

%dot% -T%format% -o "%2" "%1.dot"

:exit