unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, System.Actions,
  Vcl.ActnList, Vcl.PlatformDefaultStyleActnCtrls, Vcl.ActnMan, CommPort;

type
  TForm1 = class(TForm)
    Button1: TButton;
    edtPort: TEdit;
    ActionManager1: TActionManager;
    actOpen: TAction;
    actClose: TAction;
    Button2: TButton;
    Button3: TButton;
    actWriteString: TAction;
    Edit2: TEdit;
    Button4: TButton;
    Memo1: TMemo;
    edtBytesToRead: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    comboboxSpeed: TComboBox;
    Label3: TLabel;
    comboboxByteSize: TComboBox;
    Label4: TLabel;
    comboboxStopBits: TComboBox;
    Label5: TLabel;
    comboboxParity: TComboBox;
    Label10: TLabel;
    edtReadTimeout: TEdit;
    Label6: TLabel;
    edtWriteTimeout: TEdit;
    Label7: TLabel;
    procedure actOpenExecute(Sender: TObject);
    procedure EnableIfClose(Sender: TObject);
    procedure actCloseExecute(Sender: TObject);
    procedure EnableIfOpen(Sender: TObject);
    procedure actWriteStringExecute(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure actOpenUpdate(Sender: TObject);
  private
    { Private declarations }
    comm : TCommPort;

    function GetComPort : string;
    function GetBaudRate : integer;
    function ParamsOk : BOOL;
    function GetByteSize : integer;
    function GetParity : integer;
    function GetStopBits : integer;
    function GetBytesToRead : integer;
    function GetReadTimeout : integer;
    function GetWriteTimeout : integer;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.actCloseExecute(Sender: TObject);
begin
  comm.CloseCommPort;
  FreeAndNil( comm );
end;

function TForm1.GetComPort : string;
begin
  Result := Trim( edtPort.Text );
end;

function TForm1.GetBaudRate : integer;
begin
  Result := StrToInt( comboboxSpeed.Text );
end;

function TForm1.GetByteSize : integer;
begin
  Result := StrToInt( comboboxByteSize.Text );
end;

function TForm1.GetParity : integer;
begin
  Result := comboboxParity.ItemIndex;
end;

function TForm1.GetStopBits : integer;
begin
  Result := comboboxStopBits.ItemIndex;
end;

function TForm1.GetBytesToRead : integer;
begin
  Result := StrToInt( edtBytesToRead.Text );
end;

function TForm1.GetReadTimeout : integer;
begin
  Result := StrToInt( edtReadTimeout.Text );
end;

function TForm1.GetWriteTimeout : integer;
begin
  Result := StrToInt( edtWriteTimeout.Text );
end;

procedure TForm1.actOpenExecute(Sender: TObject);
begin
  comm := TCommPort.Create( GetReadTimeout, GetWriteTimeout );
  comm.SetCommPort( GetComPort );
  comm.SetBaudRate( GetBaudRate );
  comm.SetByteSize( GetByteSize );
  comm.SetParity( comboboxParity.ItemIndex );
  comm.SetStopBits( comboboxStopBits.ItemIndex );
  //comm.SetRTS(TCommPort.RTSMode.TOGGLE); // Maybe needed for RS485 stupid devices
  comm.OpenCommPort;
end;

function TForm1.ParamsOk : BOOL;
var
 bs : integer;
 sb : integer;
begin
  bs := GetByteSize;
  sb := GetStopBits;
  Result := ( ( bs <> 5 ) or ( sb <> 2 ) ) and ( ( bs = 5 ) or ( sb <> 1 ) );
end;

procedure TForm1.actOpenUpdate(Sender: TObject);
var
  Act : TAction;
begin
  Act := Sender as TAction;
  Act.Enabled :=
    ParamsOK and ( ( comm = nil ) or not comm.GetConnected );
end;

procedure TForm1.actWriteStringExecute(Sender: TObject);
begin
  comm.WriteString( Edit2.Text );
end;

procedure TForm1.Button4Click(Sender: TObject);
begin
  Memo1.Lines.Add( comm.ReadString( GetBytesToRead ) );
end;

procedure TForm1.EnableIfOpen(Sender: TObject);
var
  Act : TAction;
begin
  Act := Sender as TAction;
  Act.Enabled := ( comm <> nil ) and comm.GetConnected;
end;

procedure TForm1.EnableIfClose(Sender: TObject);
var
  Act : TAction;
begin
  Act := Sender as TAction;
  Act.Enabled := ( comm = NIL ) or not comm.GetConnected;
end;

end.
