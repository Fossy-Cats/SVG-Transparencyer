;~~~~~~~~~~~~~~~~~~~~~~~~~~~
;- *** Compiler Settings ***
;~~~~~~~~~~~~~~~~~~~~~~~~~~~
;{
EnableExplicit

CompilerIf #PB_Compiler_OS = #PB_OS_Windows And
           #PB_Compiler_ExecutableFormat <> #PB_Compiler_Console
  CompilerError "Must be compiled as a console program"
CompilerEndIf
;}
;~~~~~~~~~~~~~~~~~~~~~~
;- *** Enumerations ***
;~~~~~~~~~~~~~~~~~~~~~~
;{
Enumeration ErrorCode 1
  #ErrorCode_OpenConsoleError
  #ErrorCode_DirectoryFileNotFoundError
  #ErrorCode_SvgFileOpenSaveError
  #ErrorCode_InternalError
EndEnumeration
;}
;~~~~~~~~~~~~~~~~~~~
;- *** Constants ***
;~~~~~~~~~~~~~~~~~~~
;{
#ProgramName = "svg-transparencyer"
#ProgramVersion = "1.0.0-beta"
;}
;~~~~~~~~~~~~~~~~~~~~~~~~~~
;- *** Global Variables ***
;~~~~~~~~~~~~~~~~~~~~~~~~~~
;{
; Global variables should not be changed within procedures to avoid hidden changes and
; should start with a capital letter to distinguish them from local variables.
Global RegEx_Color
Global RegEx_FillOpacity
Global RegEx_StrokeOpacity
Global Settings_TransparentColor$
;}
;~~~~~~~~~~~~~~~~~~~~
;- *** Procedures ***
;~~~~~~~~~~~~~~~~~~~~
;{
Procedure SetSvgElementTransparency(xmlNode, svgStyleAttributeValue$, cssAttributeName$,
                                    cssAttributeValue$)
  
  If cssAttributeValue$ = Settings_TransparentColor$
    
    Select cssAttributeName$
        
      Case "fill"
        
        If MatchRegularExpression(RegEx_FillOpacity, svgStyleAttributeValue$)
          svgStyleAttributeValue$ = ReplaceRegularExpression(RegEx_FillOpacity,
                                                             svgStyleAttributeValue$,
                                                             "fill-opacity:0")
        Else
          svgStyleAttributeValue$ + ";fill-opacity:0"
        EndIf
        SetXMLAttribute(xmlNode, "style", svgStyleAttributeValue$)
        
      Case "stroke"
        
        If MatchRegularExpression(RegEx_StrokeOpacity, svgStyleAttributeValue$)
          svgStyleAttributeValue$ = ReplaceRegularExpression(RegEx_StrokeOpacity,
                                                             svgStyleAttributeValue$,
                                                             "stroke-opacity:0")
        Else
          svgStyleAttributeValue$ + ";stroke-opacity:0"
        EndIf
        SetXMLAttribute(xmlNode, "style", svgStyleAttributeValue$)
        
    EndSelect
    
  EndIf
  
EndProcedure

Procedure ParseCssAttributes(xmlNode, svgStyleAttributeValue$)
  
  Protected cssAttributeName$, cssAttributeValue$
  
  If ExamineRegularExpression(RegEx_Color, svgStyleAttributeValue$)
    
    While NextRegularExpressionMatch(RegEx_Color)
      
      cssAttributeName$ = RegularExpressionGroup(RegEx_Color, 1)
      cssAttributeName$ = LCase(cssAttributeName$)
      cssAttributeName$ = RemoveString(cssAttributeName$, " ")
      cssAttributeName$ = RemoveString(cssAttributeName$, #TAB$)
      
      cssAttributeValue$ = RegularExpressionGroup(RegEx_Color, 2)
      cssAttributeValue$ = LCase(cssAttributeValue$)
      cssAttributeValue$ = RemoveString(cssAttributeValue$, " ")
      cssAttributeValue$ = RemoveString(cssAttributeValue$, #TAB$)
      
      SetSvgElementTransparency(xmlNode, svgStyleAttributeValue$, cssAttributeName$,
                                cssAttributeValue$)
    Wend
    
  EndIf
  
EndProcedure

Procedure ParseXmlAttributes(xmlNode)
  
  Protected svgStyleAttributeValue$
  
  If ExamineXMLAttributes(xmlNode)
    
    While NextXMLAttribute(xmlNode)
      
      If LCase(XMLAttributeName(xmlNode)) = "style"
        
        svgStyleAttributeValue$ = XMLAttributeValue(xmlNode)
        If svgStyleAttributeValue$ = ""
          Continue
        EndIf
        ParseCssAttributes(xmlNode, svgStyleAttributeValue$)
        Break
        
      EndIf
      
    Wend
    
  EndIf
  
EndProcedure

Procedure ParseXmlSubNodes(xmlNode)
  
  Protected xmlSubNode = ChildXMLNode(xmlNode)
  
  While xmlSubNode
    ParseXmlAttributes(xmlSubNode)
    ParseXmlSubNodes(xmlSubNode)
    xmlSubNode = NextXMLNode(xmlSubNode)
  Wend
  
EndProcedure

Procedure MakeSvgFileTransparent(svgFullFilePath$)
  
  Protected xml = LoadXML(#PB_Any, svgFullFilePath$)
  Protected xmlNode, result
  
  If xml = 0
    ProcedureReturn #False
  EndIf
  
  xmlNode = RootXMLNode(xml)
  ParseXMLSubNodes(xmlNode)
  result = SaveXML(xml, svgFullFilePath$, #PB_XML_NoDeclaration)
  FreeXML(xml)
  
  ProcedureReturn result
  
EndProcedure
;}
;~~~~~~~~~~~~~~~~~~~
;- *** Main Code ***
;~~~~~~~~~~~~~~~~~~~
;{
Define settings_Path$
Define exitCode, directory

If OpenConsole(#ProgramName) = 0
  End #ErrorCode_OpenConsoleError
EndIf


Select ProgramParameter(0)
    
  Case "-v", "--version"
    
    PrintN(#ProgramVersion)
    
  Case "-h", "--help"
    
    PrintN("Usage: " + #ProgramName + " <PARAMETER>")
    PrintN("")
    PrintN("PARAMETERS")
    PrintN("")
    PrintN("  -v, --version     Shows the version number")
    PrintN("  -h, --help        Shows this help text")
    PrintN("  <COLOR> <PATH>    Processes the SVG files")
    PrintN("")
    PrintN("<COLOR> is the color string that is being searched for.")
    PrintN("During the search, whitespace characters, tab characters and")
    PrintN("upper/lower case differences are ignored.")
    PrintN("")
    PrintN("<PATH> is either a path to a directory containing SVG files")
    PrintN("(other files are ignored), or a path to an SVG file. The path")
    PrintN("can be relative or absolute.")
    PrintN("")
    PrintN("EXAMPLE")
    PrintN("")
    PrintN("  Search for '#fff' and make the color transparent:")
    PrintN("")
    PrintN("      svg-transparencyer '#fff' example.svg")
    
  Default
    
    ;- Create RegExes
    
    RegEx_Color = CreateRegularExpression(#PB_Any, ~"(fill|stroke):([^\"|;]*)",
                                          #PB_RegularExpression_NoCase)
    
    RegEx_FillOpacity = CreateRegularExpression(#PB_Any, ~"fill-opacity:(?:[^\"|;]*)",
                                                #PB_RegularExpression_NoCase)
    
    RegEx_StrokeOpacity = CreateRegularExpression(#PB_Any, ~"stroke-opacity:(?:[^\"|;]*)",
                                                  #PB_RegularExpression_NoCase)
    
    If RegEx_Color = 0 Or RegEx_FillOpacity = 0 Or RegEx_StrokeOpacity = 0
      End #ErrorCode_InternalError
    EndIf
    
    ;- Set Settings
    
    Settings_TransparentColor$ = ProgramParameter(0)
    Settings_TransparentColor$ = LCase(Settings_TransparentColor$)
    Settings_TransparentColor$ = RemoveString(Settings_TransparentColor$, " ")
    Settings_TransparentColor$ = RemoveString(Settings_TransparentColor$, #TAB$)
    
    settings_Path$ = ProgramParameter(1)
    
    Select FileSize(settings_Path$)
        
      Case -1 ;- Process Error
        
        PrintN("ERROR: Directory or SVG file not found!")
        exitCode = #ErrorCode_DirectoryFileNotFoundError
        
      Case -2 ;- Process Directory
        
        If Right(settings_Path$, 1) <> #PS$
          settings_Path$ + #PS$
        EndIf
        
        directory = ExamineDirectory(#PB_Any, settings_Path$, "")
        If directory = 0
          PrintN("ERROR: Directory could not be read!")
          exitCode = #ErrorCode_SvgFileOpenSaveError
          Goto CleanUp
        EndIf
        
        While NextDirectoryEntry(directory)
          
          If DirectoryEntryType(directory) = #PB_DirectoryEntry_File And
             LCase(GetExtensionPart(DirectoryEntryName(directory))) = "svg"
            
            If Not MakeSvgFileTransparent(settings_Path$ + DirectoryEntryName(directory))
              PrintN("ERROR: SVG file could not be opened or saved: " +
                     settings_Path$ + DirectoryEntryName(directory))
              exitCode = #ErrorCode_SvgFileOpenSaveError
            EndIf
            
          EndIf
          
        Wend
        
        FinishDirectory(directory)
        
      Default ;- Process File
        
        If Not MakeSvgFileTransparent(settings_Path$)
          PrintN("ERROR: SVG file could not be opened or saved: " + settings_Path$)
          exitCode = #ErrorCode_SvgFileOpenSaveError
        EndIf
        
    EndSelect
    
    ;- Clean Up RegExes
    CleanUp:
    FreeRegularExpression(RegEx_Color)
    FreeRegularExpression(RegEx_FillOpacity)
    FreeRegularExpression(RegEx_StrokeOpacity)
    
EndSelect

End exitCode
;}
