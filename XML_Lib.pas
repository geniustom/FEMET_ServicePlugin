unit XML_Lib;

interface
uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls;

  
type
  XMLRecord=record
     IDNO:string;
     BP_MeaDateTime:string;
     GM_MeaDateTime:string;
     GwDateTime:string;
     BP_SYS:string;
     BP_Dia:string;
     BP_HR:string;
     GLU_Normal:string;
  end;

  function CreateXML(SourceStr:string;XML:XMLRecord):string;
  function CreateTxt(SourceStr:string;XML:XMLRecord):string;

implementation

function CreateTxt(SourceStr:string;XML:XMLRecord):string;
var
  XMLFile:Textfile;
  SelfPath:string;
  DatePath:string;
  TimeStr:string;
  Path:string;
  RecordText:Tstringlist;
begin
   SelfPath:=ExtractFileDir(application.ExeName)+'\OfflineData';
   DatePath:=formatdatetime('YY_MM_DD_HH_NN_SS',now);
   Path:=SelfPath+'\'+DatePath+'.txt';
   result:=Path;
   RecordText:=Tstringlist.Create;
   RecordText.Delimiter:=',';
   RecordText.Add(SourceStr);
   RecordText.Add(XML.IDNO);
   RecordText.Add(XML.BP_SYS);
   RecordText.Add(XML.BP_DIA);
   RecordText.Add(XML.BP_HR);
   RecordText.Add(XML.BP_MeaDateTime);
   RecordText.Add(XML.GLU_Normal);
   RecordText.Add(XML.GM_MeaDateTime);


   if DirectoryExists(SelfPath)=false then
    CreateDir(SelfPath);

   assignFile(XMLFile,Path);
   rewrite(XMLFile);

   writeln(XMLFile,RecordText.DelimitedText);
   closefile(XMLFile);
end;

function CreateXML(SourceStr:string;XML:XMLRecord):string;
var
  XMLFile:Textfile;
  SelfPath:string;
  DatePath:string;
  TimeStr:string;
  Path:string;
begin
  SelfPath:=ExtractFileDir(application.ExeName)+'\Data';
  DatePath:=formatdatetime('YY_MM_DD',now);
  TimeStr:=formatdatetime('HH_NN_SS',now);
  Path:=SelfPath+'\'+DatePath+'\'+TimeStr+'.xml';
  result:='Data\'+DatePath+'\'+TimeStr+'.xml';

  if DirectoryExists(SelfPath)=false then
    CreateDir(SelfPath);

  if DirectoryExists(SelfPath+'\'+DatePath)=false then
    CreateDir(SelfPath+'\'+DatePath);

   assignFile(XMLFile,Path);
   rewrite(XMLFile);
   writeln(XMLFile,'<?xml version="1.0" encoding="utf-8" ?>');
   writeln(XMLFile,'<string xmlns="http://tempuri.org/">');
   writeln(XMLFile,'  <Source>'+SourceStr+'</Source>');
   writeln(XMLFile,'  <Member>');
   writeln(XMLFile,'    <IDNo>'+XML.IDNO+'</IDNo>');
   writeln(XMLFile,'    <GWNo></GWNo>');
   writeln(XMLFile,'    <BtnNo></BtnNo>');
   writeln(XMLFile,'    <TelNo></TelNo>');
   writeln(XMLFile,'  </Member>');
   writeln(XMLFile,'  <MeaRecs>');
   writeln(XMLFile,'    <MeaRec>');
   writeln(XMLFile,'      <MeaDateTime>'+XML.BP_MeaDateTime+'</MeaDateTime>');
   writeln(XMLFile,'      <GwDateTime>'+XML.GwDateTime+'</GwDateTime>');
   writeln(XMLFile,'      <CTIDateTime></CTIDateTime>');
   writeln(XMLFile,'      <BP>');
   writeln(XMLFile,'        <SYS>'+XML.BP_SYS+'</SYS>');
   writeln(XMLFile,'        <DIA>'+XML.BP_DIA+'</DIA>');
   writeln(XMLFile,'        <PAUSE>'+XML.BP_HR+'</PAUSE>');
   writeln(XMLFile,'      </BP>');
   writeln(XMLFile,'      <GLU>');
   writeln(XMLFile,'        <AC></AC>');
   writeln(XMLFile,'        <PC></PC>');
   writeln(XMLFile,'        <Normal></Normal>');
   writeln(XMLFile,'      </GLU>');
   writeln(XMLFile,'    </MeaRec>');

   writeln(XMLFile,'    <MeaRec>');
   writeln(XMLFile,'      <MeaDateTime>'+XML.GM_MeaDateTime+'</MeaDateTime>');
   writeln(XMLFile,'      <GwDateTime>'+XML.GwDateTime+'</GwDateTime>');
   writeln(XMLFile,'      <CTIDateTime></CTIDateTime>');
   writeln(XMLFile,'      <BP>');
   writeln(XMLFile,'        <SYS></SYS>');
   writeln(XMLFile,'        <DIA></DIA>');
   writeln(XMLFile,'        <PAUSE></PAUSE>');
   writeln(XMLFile,'      </BP>');
   writeln(XMLFile,'      <GLU>');
   writeln(XMLFile,'        <AC></AC>');
   writeln(XMLFile,'        <PC></PC>');
   writeln(XMLFile,'        <Normal>'+XML.GLU_Normal+'</Normal>');
   writeln(XMLFile,'      </GLU>');
   writeln(XMLFile,'    </MeaRec>');

   writeln(XMLFile,'  </MeaRecs>');
   writeln(XMLFile,'</string>');
   closeFile(XMLFile);
end;


end.
