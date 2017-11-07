@REM Set the Java classpath to include xalan.jar, serializer.jar, xml-apis.jar, and xercesImpl.jar -- or another conformant XML Parser -- (see Plugging in the Transformer and XML parser).
@REM Call java and the Process class with the appropriate flags and arguments (described below). The following command line, for example, includes the -IN, -XSL, and -OUT flags with their accompanying arguments -- the XML source document, the XSL stylesheet, and the output file:
@REM  java org.apache.xalan.xslt.Process -IN foo.xml -XSL foo.xsl -OUT foo.out

@setlocal


@echo off
@REM the xml file to parse
@if %1"O" EQU "O" goto error

@REM xslt stylesheets
@if %2"O" EQU "O" goto error

@REM name of the output file
@if %3"O" EQU "O" goto error

@REM file extension of the output file
@if %4"O" EQU "O" goto error

@REM XSL parameter: document ID
@if %5"O" EQU "O" goto error

@REM choice of 'simulation' or 'processing' mode
@if %6"O" EQU "O" goto error

PATH=%PATH%;"C:\Program Files (x86)\Java\jre6\bin"

set LIBSPATH=..\Java\xalan.jar;..\Java\serializer.jar;..\Java\xml-apis.jar;..\Java\xercesImpl.jar


if "%6%"=="-exec" (@echo ...
"C:\Program Files (x86)\Java\jre6\bin\java.exe" -Xmx1024m -classpath %LIBSPATH% org.apache.xalan.xslt.Process  -IN %1  -XSL %2 -OUT %3.%4 -PARAM xslParam %5
) else (
echo "C:\Program Files (x86)\Java\jre6\bin\java.exe -Xmx1024m -classpath ... org.apache.xalan.xslt.Process  -IN %1  -XSL %2 -OUT %3.%4 -PARAM idDoc %5" )

@goto end

:error
@echo Usage : %0 file.xml stylesheet.xsl file_out format id_doc -sim/-exec
goto end


:end

echo.