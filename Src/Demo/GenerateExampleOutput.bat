@echo off
call ..\..\bin\GenerateGraph.bat refcounttrace_leak1.txt refcounttrace_leak1.svg -l
call ..\..\bin\GenerateGraph.bat refcounttrace_leak2.txt refcounttrace_leak2.svg
