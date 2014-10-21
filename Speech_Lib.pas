unit Speech_Lib;

interface
uses
    Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
    StdCtrls, OleServer, SpeechLib_TLB, OleCtrls;


  procedure TTSOutput(SpV:TSpVoice;STR:string);

implementation
uses cvcode;

function Big5ToGBUnicode(sBig5: string): WideString;
var Len:integer;
begin
  sBig5 := Big5ToGB(sBig5);
  Len:=Length(sBig5)+1;
  SetLength(Result,Len);
  Len:=MultiByteToWideChar(936,0,PChar(sBig5),-1,PWideChar(Result),Len);
  SetLength(Result,Len-1); //end is #0
end;

procedure TTSOutput(SpV:TSpVoice;STR:string);
var
  ST : SpObjectToken;
  Spi: ISpeechObjectTokens;
  i : integer;
  ss: widestring;
begin
  SpV.AutoConnect:=true;

  spi:= SpV.GetVoices('','');
  for i:=0 to spi.count-1 do
  begin
    st:= spi.item(i);
    //showmessage(st.GetDescription(i));

    if trim(st.GetDescription(i))='Microsoft Simplified Chinese' then
    begin
      spV.voice:= st; //¿ï¾ÜÂ²Åé
      break;
    end;
    
  end;

  ss:=BIG5toGBUnicode(STR);
  SpV.Speak(ss,0);        //***®ÔÅªÂ²Åé¦r***
end;

end.
