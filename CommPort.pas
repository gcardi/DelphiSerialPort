unit CommPort;

interface

uses
  System.SysUtils, System.Types, Winapi.Windows;

type
  ECommError = class( Exception )
    private
      type
        ErrorType = (
            BAD_SERIAL_PORT   ,
            BAD_BAUD_RATE     ,
            BAD_PORT_NUMBER   ,
            BAD_STOP_BITS     ,
            BAD_PARITY        ,
            BAD_BYTESIZE      ,
            PORT_ALREADY_OPEN ,
            PORT_NOT_OPEN     ,
            OPEN_ERROR        ,
            WRITE_ERROR       ,
            READ_ERROR        ,
            CLOSE_ERROR       ,
            PURGE_COMM        ,
            FLUSH_FILE_BUFFERS,
            GET_COMM_STATE    ,
            SET_COMM_STATE    ,
            SETUP_COMM        ,
            SET_COMM_TIMEOUTS ,
            CLEAR_COMM_ERROR
        );
    const
      ErrorString : array[0..18] of string = (
        'BAD_SERIAL_PORT'  ,
        'BAD_BAUD_RATE'    ,
        'BAD_PORT_NUMBER'  ,
        'BAD_STOP_BITS'    ,
        'BAD_PARITY'       ,
        'BAD_BYTESIZE'     ,
        'PORT_ALREADY_OPEN',
        'PORT_NOT_OPEN'    ,
        'OPEN_ERROR'       ,
        'WRITE_ERROR'      ,
        'READ_ERROR'       ,
        'CLOSE_ERROR'      ,
        'PURGECOMM'        ,
        'FLUSHFILEBUFFERS' ,
        'GETCOMMSTATE'     ,
        'SETCOMMSTATE'     ,
        'SETUPCOMM'        ,
        'SETCOMMTIMEOUTS'  ,
        'CLEARCOMMERROR'
      ) ;

    public
      constructor Create( PError : ErrorType );

    private
      Error: ErrorType;
      Errno: DWORD;

      class function FormatErrorMessage( PError : ErrorType ) : string;
  end;

type
  TCommPort = class
    public
      type
        RTSMode = (
          DISABLE  ,
          ENABLE   ,
          HANDSHAKE,
          TOGGLE
        );

      constructor Create( ReadTimeout, WriteTimeout : DWORD );
      destructor Destroy; override;
      procedure OpenCommPort;
      procedure CloseCommPort;
      procedure SetCommPort( Port : string );
      function GetCommPort : string;
      procedure SetBaudRate( newBaud : DWORD);
      function GetBaudRate : DWORD;
      procedure SetParity( newParity : BYTE );
      function GetParity : BYTE;
      procedure SetByteSize( newByteSize : BYTE );
      function GetByteSize : BYTE;
      procedure SetStopBits( newStopBits : BYTE );
      function GetStopBits : BYTE;
      procedure SetCommDCBProperties( var Properties : DCB );
      procedure GetCommDCBProperties( out Properties : DCB );
      procedure GetCommProp( out properties: COMMPROP );
      procedure WriteBuffer(const Buffer: TBytes; NumBytes: integer);
      procedure WriteString( outString : string );
      function ReadBytes( out Buffer : TBytes ; MaxBytes : DWORD ) : DWORD;
      function ReadString( MaxBytes : DWORD ) : string;
      procedure PurgeCommPort;
      procedure FlushCommPort;
      procedure PutByte( value : BYTE );
      function GetByte : BYTE;
      function BytesAvailable : DWORD;
      function GetConnected : BOOL;
      function GetHandle() : THandle;
      procedure SetRTS( Mode : RTSMode );
    private
      procedure VerifyOpen;
      procedure VerifyClosed;
    const
      DCBFlags_Binary           = $00000001; // fBinary : 1;
      DCBFlags_Parity           = $00000002; // fParity : 1;
      DCBFlags_OutxCtsFlow      = $00000004; // fOutxCtsFlow : 1;
      DCBFlags_OutxDsrFlow      = $00000008; // fOutxDsrFlow : 1;
      DCBFlags_DtrControlMask   = $00000030; // fDtrControl : 2;
      DCBFlags_DsrSensitivity   = $00000040; // fDsrSensitivity : 1;
      DCBFlags_TXContinueOnXoff = $00000080; // fTXContinueOnXoff : 1;
      DCBFlags_OutX             = $00000100; // fOutX : 1;
      DCBFlags_InX              = $00000200; // fInX : 1;
      DCBFlags_ErrorChar        = $00000400; // fErrorChar : 1;
      DCBFlags_Null             = $00000800; // fNull : 1;
      DCBFlags_RtsControlMask   = $00003000; // fRtsControl : 2;
      DCBFlags_AbortOnError     = $00040000; // fAbortOnError : 1;
      DCBFlags_Dummy2Mask       = $FFFB0000; // fDummy2 : 17;

      DtrControl_DISABLE   = $00000000;
      DtrControl_ENABLE    = $00000010;
      DtrControl_HANDSHAKE = $00000020;

      RtsControl_DISABLE   = $00000000;
      RtsControl_ENABLE    = $00001000;
      RtsControl_HANDSHAKE = $00002000;
      RtsControl_TOGGLE    = $00003000;
    var
      FCommOpen : BOOL;
      FTimeOuts : COMMTIMEOUTS;
      FCommPort : string;
      FDcb : DCB; // a DCB is a windows structure used for configuring the port
      FHCom : THandle; // handle to the comm port.
      FReadTimeOut : DWORD;
      FWriteTimeOut :DWORD;
  end;

implementation

constructor ECommError.Create( PError : ErrorType );
begin
  inherited Create( FormatErrorMessage( Error ) );
  Error := PError;
  Errno := GetLastError;
end;

class function ECommError.FormatErrorMessage( PError : ErrorType ) : string;
begin
  Result :=
    Format(
      'Serial port failed with code %d, %s: %s',
      [Ord( PError ), ErrorString[Ord( PError )],SysErrorMessage( Ord( PError ) )]
    );
end;

constructor TCommPort.Create( ReadTimeout, WriteTimeout : DWORD );
begin
  FCommOpen := false;
  FHCom := 0;
  FReadTimeOut := ReadTimeout;
  FWritetimeOut := WriteTimeout;
  FCommPort := '\\.\COM1';

  FDcb.DCBlength := SizeOf( DCB );
  FDcb.BaudRate := 9600;
  FDcb.ByteSize := 8;
  FDcb.Parity := NOPARITY;
  FDcb.StopBits := ONESTOPBIT;
  FDcb.Flags := ( FDCB.Flags and not DCBFlags_AbortOnError ) or DCBFlags_Binary;
end;

destructor TCommPort.Destroy;
begin
  if FCommOpen then
  begin
    CloseCommPort;
  end;
end;

procedure TCommPort.VerifyOpen;
begin
  if FCommOpen = FALSE then
  begin
    raise ECommError.Create( PORT_NOT_OPEN );
  end;
end;

procedure TCommPort.VerifyClosed;
begin
  if FCommOpen = TRUE then
  begin
    raise ECommError.Create( PORT_ALREADY_OPEN );
  end;
end;

procedure TCommPort.OpenCommPort;
var
  TempDCB : DCB;
begin
  if FCommOpen = TRUE then
  begin
    Exit;
  end;
  ZeroMemory( @TempDCB, SizeOf( DCB ) );
  TempDCB.BaudRate  := FDcb.BaudRate;
  TempDCB.ByteSize  := FDcb.ByteSize;
  TempDCB.Parity    := FDcb.Parity;
  TempDCB.StopBits  := FDcb.StopBits;
  TempDCB.Flags     := FDcb.Flags;
  FHCom :=
    CreateFile(
      PWChar( FCommPort ),
      GENERIC_READ or GENERIC_WRITE,
      0,              // comm devices must be opened w/exclusive-access
      nil,            // no security attrs
      OPEN_EXISTING,  // comm devices must use OPEN_EXISTING
      0,              // not overlapped I/O
      0               // hTemplate must be NULL for comm devices
    );
  if FHCom = INVALID_HANDLE_VALUE then
    begin
      raise ECommError.Create(OPEN_ERROR);
    end;

  if not GetCommState( FHCom, FDcb ) then
  begin
    CloseHandle( FHCom );
    raise ECommError.Create( GET_COMM_STATE );
  end;

  FDcb.DCBlength := SizeOf( DCB );
  FDcb.BaudRate  := TempDCB.BaudRate;
  FDcb.ByteSize  := TempDCB.ByteSize;
  FDcb.Parity    := TempDCB.Parity;
  FDcb.StopBits  := TempDCB.StopBits;
  FDcb.Flags     := TempDCB.Flags;

  if not SetCommState( FHCom, FDcb ) then
  begin
    CloseHandle( FHCom );
    raise ECommError.Create( SET_COMM_STATE );
  end;

  if not SetupComm( FHCom, 1024*32, 1024*9 ) then
  begin
    CloseHandle( FHCom );
    raise ECommError.Create( SETUP_COMM );
  end;

  FTimeOuts.ReadIntervalTimeout         := 0;
  FTimeOuts.ReadTotalTimeoutMultiplier  := 0;
  FTimeOuts.ReadTotalTimeoutConstant    := FReadTimeOut;

  FTimeOuts.WriteTotalTimeoutMultiplier := 0;
  FTimeOuts.WriteTotalTimeoutConstant   := FWriteTimeOut;

  if not SetCommTimeouts( FHCom, FTimeOuts ) then
  begin
    CloseHandle( FHCom );
    raise ECommError.Create( SET_COMM_TIMEOUTS );
  end;

  FCommOpen := true;
end;

procedure TCommPort.CloseCommPort;
begin
  if FCommOpen then
  begin
    if FHCom <> 0 then
    begin
      CloseHandle( FHCom );
    end;
    FCommOpen := FALSE;
  end;
end;

procedure TCommPort.SetCommPort( Port : string );
begin
  VerifyClosed;
  FCommPort := Port;
end;

function TCommPort.GetCommPort : string;
begin
  Result := FCommPort;
end;

procedure TCommPort.SetBaudRate( newBaud : DWORD);
var
  OldBaudRate: DWORD;
begin
  OldBaudRate := FDcb.BaudRate;
  FDcb.BaudRate := newBaud;

  if (FCommOpen) then
  begin
    if not SetCommState( FHCom, FDcb ) then
    begin
      FDcb.BaudRate := OldBaudRate;
      raise ECommError.Create( BAD_BAUD_RATE );
    end;
  end;
end;

function TCommPort.GetBaudRate : DWORD;
begin
  Result := FDcb.BaudRate;
end;

procedure TCommPort.SetParity( newParity : BYTE );
var
  OldParity: BYTE;
begin
  oldParity := FDcb.Parity;
  FDcb.Parity := newParity;

  if (FCommOpen) then
  begin
    if not SetCommState( FHCom, FDcb ) then
    begin
     FDcb.Parity := OldParity;
     raise ECommError.Create( BAD_PARITY );
    end;
  end;
end;

function TCommPort.GetParity : BYTE;
begin
  Result := FDcb.Parity;
end;

procedure TCommPort.SetByteSize( newByteSize : BYTE );
var
  OldByteSize: BYTE;
begin
  OldByteSize := FDcb.ByteSize;
  FDcb.ByteSize := newByteSize;

  if (FCommOpen) then
  begin
    if not SetCommState(FHCom, FDcb) then
    begin
      FDcb.ByteSize := OldByteSize;
      raise ECommError.Create(BAD_BYTESIZE);
    end;
  end;
end;

function TCommPort.GetByteSize : BYTE;
begin
  Result := FDcb.ByteSize;
end;

procedure TCommPort.SetStopBits( newStopBits : BYTE );
var
  OldStopBits: BYTE;
begin
  OldStopBits := FDcb.StopBits;
  FDcb.StopBits := newStopBits;

  if (FCommOpen) then
  begin
    if not SetCommState(FHCom, FDcb) then
    begin
      FDcb.StopBits := OldStopBits;
      raise ECommError.Create(BAD_STOP_BITS);
    end;
  end;
end;

function TCommPort.GetStopBits : BYTE;
begin
  Result := FDcb.StopBits;
end;

procedure TCommPort.SetCommDCBProperties( var Properties : DCB );
begin
  if (FCommOpen) then
  begin
   if not SetCommState( FHCom, Properties ) then
   begin
     raise ECommError.Create( SET_COMM_STATE );
   end;
  end;
  FDcb := Properties;
end;

procedure TCommPort.GetCommDCBProperties( out Properties : DCB );
begin
  Properties := FDcb;
end;

procedure TCommPort.GetCommProp( out properties: COMMPROP );
var
  prop: COMMPROP;
begin
  VerifyOpen;
  ZeroMemory( @prop, SizeOf( COMMPROP ) );
  GetCommProperties( FHCom, prop );
  properties := prop;
end;

procedure TCommPort.WriteBuffer(const Buffer: TBytes; NumBytes: integer);
var
  Dummy : DWORD;
begin
  VerifyOpen;
  if NumBytes = 0 then
  begin
    Exit;
  end;

  if not WriteFile( FHCom, Pointer( Buffer )^, NumBytes, Dummy, NIL ) then
  begin
    raise ECommError.Create( WRITE_ERROR );
  end;
end;

procedure TCommPort.WriteString( outString : string );
var  buffer: TBytes;
begin
  buffer := TEncoding.ASCII.GetBytes( outString );
  WriteBuffer( buffer, Length(buffer) );
end;

function TCommPort.ReadBytes( out Buffer : TBytes ; MaxBytes : DWORD ) : DWORD;
var
  BytesRead : DWORD;
begin
  BytesRead := 0;

  VerifyOpen;

  SetLength( Buffer, MaxBytes );
  if not ReadFile( FHCom, Pointer( Buffer )^, MaxBytes, BytesRead, NIL ) then
  begin
    raise ECommError.Create( READ_ERROR );
  end;
  Result := BytesRead;
end;

function TCommPort.ReadString( MaxBytes : DWORD ) : string;
var
  Buff : TBytes;
begin
  SetLength( Buff, MaxBytes );
  ReadBytes( Buff, MaxBytes );
  Result := TEncoding.ASCII.GetString( Buff );
end;

procedure TCommPort.PurgeCommPort;
begin
  VerifyOpen;

  if not PurgeComm( FHCom, PURGE_RXCLEAR ) then
  begin
    raise ECommError.Create( PURGE_COMM );
  end;
end;

procedure TCommPort.FlushCommPort;
begin
  VerifyOpen;

  if not FlushFileBuffers( FHCom ) then
  begin
    raise ECommError.Create( FLUSH_FILE_BUFFERS );
  end;
end;

procedure TCommPort.PutByte(value : BYTE );
var
  Dummy : DWORD;
  ptr: pointer;
begin
    VerifyOpen;
    ptr := @value;
    if not WriteFile( FHCom, ptr, 1, Dummy, NIL ) then
    begin
        raise ECommError.Create( WRITE_ERROR );
    end;
end;

function TCommPort.GetByte : BYTE;
var
  Dummy : DWORD;
  Value : BYTE;
  ptr: Pointer;
begin
  VerifyOpen;
  Value := 0;
  ptr := @Value;
  if not ReadFile( FHCom, ptr, 1, Dummy, NIL ) then
  begin
    raise ECommError.Create( READ_ERROR );
  end;
  Result := Value;
end;

function TCommPort.BytesAvailable : DWORD;
var
  com_stat : COMSTAT;
  Dummy : DWORD;
begin
  VerifyOpen;

  if not ClearCommError( FHCom, Dummy, @com_stat ) then
  begin
    raise ECommError.Create( CLEAR_COMM_ERROR );
  end;
  Result := com_stat.cbInQue;
end;

function TCommPort.GetConnected : BOOL;
begin
  Result := FCommOpen;
end;

function TCommPort.GetHandle() : THandle;
begin
  Result := FHCom;
end;

procedure TCommPort.SetRTS( Mode : RTSMode );
begin
  FDcb.Flags := FDcb.Flags and not DCBFlags_RtsControlMask;
  case Mode of
    DISABLE:
      FDcb.Flags := FDcb.Flags or RtsControl_DISABLE;
    ENABLE:
      FDcb.Flags := FDcb.Flags or RtsControl_ENABLE;
    HANDSHAKE:
      FDcb.Flags := FDcb.Flags or RtsControl_HANDSHAKE;
    TOGGLE:
      FDcb.Flags := FDcb.Flags or RtsControl_TOGGLE;
  end;
  if GetConnected then
  begin
    if not SetCommState( FHCom, FDcb ) then
    begin
      raise ECommError.Create( WRITE_ERROR );
    end;
  end;
end;

end.
