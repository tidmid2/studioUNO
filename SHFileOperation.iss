;***************************************************************;
;****************** SHFileOperation.iss ************************;
;***************************************************************;
;* Include this file in project. Example:
;* #include "SHFileOperation.iss"
;***************************************************************;
;************************ 1 ************************************;
;* function CopyDir(const fromDir, toDir: string): Boolean;
;* Example 1 (without <fromDir> trailing backslash):
;*     CopyDir('C:\TMP\MyApp', 'C:\TMP\Backup');
;* Result: C:\TMP\Backup\MyApp\..all <MyApp> subdirs and files
;* Example 2 (with <fromDir> trailing backslash):
;*     CopyDir('C:\TMP\MyApp\', 'C:\TMP\Backup');
;* Result: C:\TMP\Backup\..all <MyApp> subdirs and files
;***************************************************************;
;************************ 2 ************************************;
;* function MoveDir(const fromDir, toDir: string): Boolean;
;* Example 1 (without <fromDir> trailing backslash):
;*     MoveDir('C:\TMP\MyApp', 'C:\TMP\Backup');
;* Result: C:\TMP\Backup\MyApp\..all <MyApp> subdirs and files
;* Example 2 (with <fromDir> trailing backslash):
;*     MoveDir('C:\TMP\MyApp\', 'C:\TMP\Backup');
;* Result: C:\TMP\Backup\..all <MyApp> subdirs and files
;***************************************************************;
;************************ 3 ************************************;
;* function DelDir(dir: string; toRecycle: Boolean): Boolean;
;*   If <toRecycle> is True, <dir> deleted in Recycle Bin.
;***************************************************************;
;************************ 4 ************************************;
;* function RenameDir(const fromDir, toDir: string): Boolean;
;***************************************************************;
;***************************************************************;
;***************************************************************;

[Code]
type
   TSHFileOpStruct =  record
     Wnd: HWND;
     wFunc: UINT;
     pFrom: PAnsiChar;
     pTo: PAnsiChar;
     fFlags: Word; // FILEOP_FLAGS;
     fAnyOperationsAborted: BOOL;
     hNameMappings: HWND; // Pointer;
     lpszProgressTitle: PAnsiChar; { only used if FOF_SIMPLEPROGRESS }
   end;

const
// use in wFunc
   { $EXTERNALSYM FO_MOVE }
   FO_MOVE           = $0001;
   { $EXTERNALSYM FO_COPY }
   FO_COPY           = $0002;
   { $EXTERNALSYM FO_DELETE }
   FO_DELETE         = $0003;
   { $EXTERNALSYM FO_RENAME }
   FO_RENAME         = $0004;
// use in fFlags
   { $EXTERNALSYM FOF_MULTIDESTFILES }
   FOF_MULTIDESTFILES         = $0001;
   { $EXTERNALSYM FOF_CONFIRMMOUSE }
   FOF_CONFIRMMOUSE           = $0002;
   { $EXTERNALSYM FOF_SILENT }
   FOF_SILENT                 = $0004;  { don't create progress/report }
   { $EXTERNALSYM FOF_RENAMEONCOLLISION }
   FOF_RENAMEONCOLLISION      = $0008;
   { $EXTERNALSYM FOF_NOCONFIRMATION }
   FOF_NOCONFIRMATION         = $0010;  { Don't prompt the user. }
   { $EXTERNALSYM FOF_WANTMAPPINGHANDLE }
   FOF_WANTMAPPINGHANDLE      = $0020;  { Fill in
SHFILEOPSTRUCT.hNameMappings
                                          Must be freed using
SHFreeNameMappings }
   { $EXTERNALSYM FOF_ALLOWUNDO }
   FOF_ALLOWUNDO              = $0040;
   { $EXTERNALSYM FOF_FILESONLY }
   FOF_FILESONLY              = $0080;  { on *.*, do only files }
   { $EXTERNALSYM FOF_SIMPLEPROGRESS }
   FOF_SIMPLEPROGRESS         = $0100;  { means don't show names of files }
   { $EXTERNALSYM FOF_NOCONFIRMMKDIR }
   FOF_NOCONFIRMMKDIR         = $0200;  { don't confirm making any
needed dirs }
   { $EXTERNALSYM FOF_NOERRORUI }
   FOF_NOERRORUI              = $0400;  { don't put up error UI }


function SHFileOperation(const lpFileOp: TSHFileOpStruct):Integer;
external 'SHFileOperation@shell32.dll stdcall';

{****************************************************************}
{****************************************************************}
{****************************************************************}

function BackupDir(const fromDir, toDir: string; IsMove: Boolean): Boolean;
var
  fos: TSHFileOpStruct;
  _fromDir, _toDir: string;
  SR: TFindRec;
  res: Boolean;
begin
    ForceDirectories(toDir);
  if IsMove then
    fos.wFunc  := FO_MOVE else
    fos.wFunc  := FO_COPY;
    fos.fFlags := FOF_FILESONLY or FOF_SILENT or
               FOF_NOCONFIRMATION or FOF_NOCONFIRMMKDIR;
    _fromDir:= AddBackslash(fromDir);
    _toDir  := AddBackslash(toDir);
  if (Length(fromDir) = Length(_fromDir)) then
    begin
        res:= FindFirst(_fromDir + '*', SR);
      try
        while res do
        begin
          if (SR.Name <> '') and (SR.Name <> '.') and (SR.Name <> '..') then
          begin
            if SR.Attributes = FILE_ATTRIBUTE_DIRECTORY then
              begin
                _fromDir:= _fromDir + SR.Name + #0#0;
                _toDir  := _toDir + #0#0;
                fos.pFrom  := PAnsiChar(_fromDir);
                fos.pTo    := PAnsiChar(_toDir);
              end else
              begin
                _fromDir:= _fromDir + SR.Name + #0#0;
                _toDir  := _toDir   + SR.Name + #0#0;
                fos.pFrom  := PAnsiChar(_fromDir);
                fos.pTo    := PAnsiChar(_toDir);
              end;
                Result := (0 = ShFileOperation(fos));
                _fromDir:= ExtractFilePath(_fromDir);
                _toDir:= ExtractFilePath(_toDir);
          end;
          res := FindNext(SR);
        end;
      finally
        FindClose(SR);
      end;
    end else
    begin
      _fromDir:= RemoveBackslashUnlessRoot(_fromDir) + #0#0;
      _toDir  := RemoveBackslashUnlessRoot(_toDir)   + #0#0;
      fos.pFrom  := PAnsiChar(_fromDir);
      fos.pTo    := PAnsiChar(_toDir);
      Result := (0 = ShFileOperation(fos));
    end;
end;

{****************************************************************}
function MoveDir(const fromDir, toDir: string): Boolean;
begin
  Result := BackupDir(fromDir, toDir, True);
end;

{****************************************************************}
function CopyDir(const fromDir, toDir: string): Boolean;
begin
  Result := BackupDir(fromDir, toDir, False);
end;

{****************************************************************}
function DelDir(dir: string; toRecycle: Boolean): Boolean;
var
  fos: TSHFileOpStruct;
  _dir: string;
begin
    _dir:= RemoveBackslashUnlessRoot(dir) + #0#0;
    fos.wFunc  := FO_DELETE;
    fos.fFlags := FOF_SILENT or FOF_NOCONFIRMATION;
  if toRecycle then
    fos.fFlags := fos.fFlags or FOF_ALLOWUNDO;
    fos.pFrom  := PAnsiChar(_dir);
  Result := (0 = ShFileOperation(fos));
end;

{****************************************************************}
function RenameDir(const fromDir, toDir: string): Boolean;
var
  fos: TSHFileOpStruct;
  _fromDir, _toDir: string;
begin
    _fromDir:= RemoveBackslashUnlessRoot(fromDir) + #0#0;
    _toDir  := RemoveBackslashUnlessRoot(toDir) + #0#0;
    fos.wFunc  := FO_RENAME;
    fos.fFlags := FOF_FILESONLY or FOF_ALLOWUNDO or
              FOF_SILENT or FOF_NOCONFIRMATION;
    fos.pFrom  := PAnsiChar(_fromDir);
    fos.pTo    := PAnsiChar(_toDir);
  Result := (0 = ShFileOperation(fos));
end;

{****************************************************************}
function FilesMaskOperation(const fromDir, toDir, fileMask: string; FileOp: Integer; EmptyDirRemove: Boolean; toRecycle: Boolean): Boolean;
var
  fos: TSHFileOpStruct;
  _fromDir, _toDir: string;
  FSR, DSR: TFindRec;
  FindResult: Boolean;
  APath: string;
begin
  APath := AddBackslash(fromDir);
  FindResult := FindFirst(APath + fileMask, FSR);
  try
    while FindResult do
    begin
      if FSR.Attributes and FILE_ATTRIBUTE_DIRECTORY = 0 then
        begin
          Case FileOp of
            FO_COPY:
              begin
                fos.wFunc  := FO_COPY;
              end;
            FO_MOVE:
              begin
                fos.wFunc  := FO_MOVE;
              end;
            FO_DELETE:
              begin
                fos.wFunc  := FO_DELETE;
                if toRecycle then fos.fFlags := fos.fFlags or FOF_ALLOWUNDO;
              end;
            FO_RENAME:
              begin
                fos.wFunc  := FO_RENAME;
              end;
          else
            ;
          end;
            fos.fFlags := fos.fFlags or FOF_FILESONLY or FOF_SILENT or
                   FOF_NOCONFIRMATION or FOF_NOCONFIRMMKDIR;
            _fromDir:= APath + FSR.Name + #0#0;
            _toDir:= AddBackslash(toDir) + FSR.Name + #0#0;
            ForceDirectories(ExtractFilePath(_toDir));
            fos.pFrom  := PAnsiChar(_fromDir);
            fos.pTo    := PAnsiChar(_toDir);
            Result := (0 = ShFileOperation(fos));
        end;
      FindResult := FindNext(FSR);
    end;
    FindResult := FindFirst(APath + '*.*', DSR);
    while FindResult do
    begin
      if ((DSR.Attributes and FILE_ATTRIBUTE_DIRECTORY) = FILE_ATTRIBUTE_DIRECTORY) and
        not ((DSR.Name = '.') or (DSR.Name = '..')) then
{Recursion} FilesMaskOperation(APath + DSR.Name, AddBackslash(toDir) + DSR.Name, fileMask, FileOp, EmptyDirRemove, toRecycle);
      FindResult := FindNext(DSR);
    end;
  finally
    FindClose(FSR);
    FindClose(DSR);
    if EmptyDirRemove then RemoveDir(APath);
  end;
end;

function CopyFiles(const fromDir, toDir, fileMask: string): Boolean;
begin
  Result := FilesMaskOperation(fromDir, toDir, fileMask,
         FO_COPY, False, False);
end;

function MoveFiles(const fromDir, toDir, fileMask: string): Boolean;
begin
  Result := FilesMaskOperation(fromDir, toDir, fileMask,
         FO_MOVE, True, False);
end;

function DelFiles(const fromDir, fileMask: string; toRecycle: Boolean ): Boolean;
begin
  Result := FilesMaskOperation(fromDir, '', fileMask,
         FO_DELETE, True, toRecycle);
end;
{****************************************************************}
{****************************************************************}

