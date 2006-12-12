unit Main;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms,
  AdDraws, AdSprites, AndorraUtils, IniFiles;

type
  TForm1 = class(TForm)
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
  private
    { Private-Deklarationen }
  public
    AdDraw:TAdDraw;
    AdSpriteEngine:TSpriteEngine;
    AdPictureCollection:TPictureCollection;
    procedure ApplicationIdle(Sender:TObject;var Done:boolean);
    { Public-Deklarationen }
  end;

  TWall = class(TImageSprite);

  TBall = class(TImageSpriteEx)
    private
      Falling:boolean;
      WillDie:boolean;
    public
      SX,SY:double;
      SourceX,SourceY:integer;
      Color:TColor;
      Light:TLightSprite;
      procedure DoDraw;override;
      constructor Create(AParent:TSprite);override;
      procedure Dead;override;
      procedure DoMove(TimeGap:double);override;
      procedure DoCollision(Sprite:TSprite; var Done:boolean);override;
      procedure Coll;
  end;

var
  Form1: TForm1;
  lx,ly:integer;
  timegap:double;
  lasttime:double;
  framecount:integer;
  settings:TIniFile;

const
  path='..\demos\SpriteEngine\Bounce\';

implementation

{$R *.dfm}

procedure TForm1.ApplicationIdle(Sender: TObject; var Done: boolean);
var tg:double;
begin
  //Calculate FPS
  tg := (gettickcount-lasttime);
  timegap := timegap + tg;
  lasttime := gettickcount;
  framecount := framecount+1;

  if timegap > 1000 then
  begin
    caption := 'FPS: '+inttostr(framecount);
    timegap := 0;
    framecount := 0;
  end;

  if AdDraw.CanDraw then
  begin
    AdDraw.BeginScene;
    AdDraw.ClearSurface(clSkyBlue);
    AdSpriteEngine.Move(tg/1000);
    AdSpriteEngine.Draw;
    AdSpriteEngine.Dead;
    AdDraw.EndScene;
    AdDraw.Flip;
  end;

  Done := false;
end;

procedure TForm1.FormCreate(Sender: TObject);
var
  ax,ay: Integer;
  level:TStringList;
  amessage:TAdLogMessage;
begin
  Randomize;

  Settings := TIniFile.Create(ExtractFilePath(Application.ExeName)+'settings.ini');

  AdDraw := TAdDraw.Create(self);
  AdDraw.DllName := Settings.ReadString('set','dllname','AndorraDX93D.dll');

  amessage.Text := 'Starting Application';
  amessage.Sender := 'Bounce.exe';
  amessage.Typ := 'Starting';
  AdDraw.Log.AddMessage(amessage);

  if Settings.ReadBool('set','light',false) then
  begin
    AdDraw.Options := AdDraw.Options+[doLights];
  end;
  if Settings.ReadBool('set','fullscreen',false) then
  begin
    AdDraw.Options := AdDraw.Options+[doFullscreen];
  end;

  AdDraw.Display.Width := Settings.ReadInteger('set','width',800);
  AdDraw.Display.Height := Settings.ReadInteger('set','height',600);
  AdDraw.Display.BitCount := Settings.ReadInteger('set','bits',32);
  AdDraw.Display.Freq := Settings.ReadInteger('set','refrate',0);

  ClientWidth := AdDraw.Display.Width;
  ClientHeight := AdDraw.Display.Height;

  if doFullscreen in AdDraw.Options then
  begin
    Top := 0;
    Left := 0;
    ClientWidth := AdDraw.Display.Width;
    ClientHeight := AdDraw.Display.Height;
    BorderStyle := bsNone;
  end;

  AdDraw.Initialize;

  AdDraw.AmbientColor := RGB(64,64,64);

  AdPictureCollection := TPictureCollection.Create(AdDraw);
  with AdPictureCollection.Add('wall')do
  begin
    Texture.LoadFromFile(path+'texture.bmp',false,clWhite);
    Detail := Settings.ReadInteger('set','meshdetail',16);
  end;
  with AdPictureCollection.Add('wallgras')do
  begin
    Texture.LoadFromFile(path+'texture2.bmp',false,clWhite);
    Detail := Settings.ReadInteger('set','meshdetail',16);
  end;
  with AdPictureCollection.Add('sky') do
  begin
    Texture.LoadFromFile(path+'sky.png',false,clBlack);
    Color := rgb(200,200,255);
  end;    
  with AdPictureCollection.Add('ball') do
  begin
    Texture.LoadFromFile(path+'ball.bmp',true,clYellow);
    PatternWidth := 32;
    PatternHeight := 32;
  end;
  AdPictureCollection.Restore;
  AdPictureCollection.Add('part').Texture.LoadFromFile('particle.bmp',false,0);

  AdSpriteEngine := TSpriteEngine.Create(nil);
  AdSpriteEngine.Surface := AdDraw;

  level := TStringList.Create;
  level.LoadFromFile(path+'level.txt');

  with TBackgroundSprite.Create(AdSpriteEngine) do
  begin
    Z := -10;
    Image := AdPictureCollection.Find('sky');
    Tiled := true;
    Depth := 10;
  end;

  for ay := 0 to level.Count - 1 do
  begin
    for ax := 1 to length(level[ay]) do
    begin
      case level[ay][ax] of
        'x':
        begin
          with TWall.Create(AdSpriteEngine) do
          begin
            Image := AdPictureCollection.Find('wall');
            x := ax*128;
            y := ay*128;
            z := 0;
          end;
        end;
        'X':
        begin
          with TWall.Create(AdSpriteEngine) do
          begin
            Image := AdPictureCollection.Find('wallgras');
            x := ax*128;
            y := ay*128;
            z := 0;
          end;
        end;
        'b':
        begin
          with TBall.Create(AdSpriteEngine) do
          begin
            Image := AdPictureCollection.Find('ball');
            x := ax*128;
            y := ay*128+128-height;
            z := 1;
            sourcex := round(x);
            sourcey := round(y);
           end;
        end;
      end;
    end;
  end;
  level.Free;
  lasttime := GetTickCount;

  Application.OnIdle := ApplicationIdle;

  Settings.Free;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  AdSpriteEngine.Free;
  AdPictureCollection.Free;
  AdDraw.Finalize;
  AdDraw.Free;
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if key = VK_LEFT then
  begin
    AdSpriteEngine.X := AdSpriteEngine.X + 10;
  end;
  if key = VK_RIGHT then
  begin
    AdSpriteEngine.X := AdSpriteEngine.X - 10;
  end;
  if key = VK_UP then
  begin
    AdSpriteEngine.Y := AdSpriteEngine.Y + 10;
  end;
  if key = VK_DOWN then
  begin
    AdSpriteEngine.Y := AdSpriteEngine.Y - 10;
  end;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  lx := x;
  ly := y;
end;

procedure TForm1.FormMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
begin
  if ssLeft in Shift then
  begin
    AdSpriteEngine.X := AdSpriteEngine.X + X - Lx;
    AdSpriteEngine.Y := AdSpriteEngine.Y + Y - Ly;
    Lx := X;
    Ly := Y;
  end;
end;

{ TBall }

procedure TBall.Coll;
begin
  WillDie := true;
  with TBall.Create(Engine) do
  begin
    Image := self.Image;
    x := self.sourcex;
    y := self.sourcey;
    sourcex := round(x);
    sourcey := round(y);
    Color := self.Color;
  end;
  CanDoCollisions := false;
end;

constructor TBall.Create(AParent: TSprite);
begin
  inherited Create(AParent);

  sy := 200;
  if random(2) = 0 then sx := -200 else sx := 200;

  AnimSpeed := 4;

  Alpha := 0;

  Color := RGB(random(255),random(255),random(255));

  Light := TLightSprite.Create(Engine);
  with Light do
  begin
    Z := -9;
    Range := 200;
    Falloff := 5;
    Color := clWhite;
  end;           
end;


procedure TBall.Dead;
begin
  Light.Dead;
  inherited Dead;
end;

procedure TBall.DoCollision(Sprite: TSprite; var Done: boolean);
begin
  if Sprite is TWall then
  begin
    falling := false;
    SY := 128;
    if (Sprite.Y > Y) and (Sprite.X > X) and (Sprite.X+Sprite.Width < Y+Width) and
       (Sprite.Y+Sprite.Height < Y+Height) then
    begin
      Coll;
      Done := true;
      exit;
    end;

    if Sprite.Y > Y then
    begin
      Y := Sprite.Y-Height+1;
    end
    else
    begin
      if (Sprite.X+Sprite.Width > X) and (SX < 0) then
      begin
        SX := -SX;
        X := Sprite.X+Sprite.Width+1;
        exit;
      end;
      if (Sprite.X < X+Width) and (SX > 0) then
      begin
        SX := -SX;
        X := Sprite.X-Width-1;
        exit;
      end;
    end;   
  end;
  if Sprite is TBall then
  begin
    Coll;
    TBall(Sprite).Coll;
    Done := true;
  end;
end;

procedure TBall.DoDraw;
begin
  Image.Color := Color;
  inherited DoDraw;
end;

procedure TBall.DoMove(TimeGap: double);
begin
  if not WillDie then
  begin
    inherited DoMove(TimeGap);

    if Alpha < 255 then
    begin
      Alpha := Alpha + 1000*TimeGap;
    end
    else
    begin
      Alpha := 255;
    end;

    falling := true;
    Collision;

    if falling then
    begin
      SY := SY + SY * 0.1*TimeGap;
      Y := Y + SY*TimeGap;
    end
    else
    begin
      Angle := Angle + 360*(SX/abs(SX))*TimeGap;
      if Angle > 360 then Angle := 0;
      X := X + SX*TimeGap;
    end;
  end
  else
  begin
    Alpha := Alpha - 1000*TimeGap;
    Light.Color  := RGB(round(Alpha),round(Alpha),round(Alpha));
    if Alpha <= 20 then Dead;    
  end;

  Light.X := X+Width / 2;
  Light.Y := Y+Height / 2;
end;

end.