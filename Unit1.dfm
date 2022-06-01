object Form1: TForm1
  Left = 0
  Top = 0
  Caption = 'Form1'
  ClientHeight = 441
  ClientWidth = 624
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object Label1: TLabel
    Left = 128
    Top = 24
    Width = 22
    Height = 15
    Caption = 'Port'
  end
  object Label2: TLabel
    Left = 128
    Top = 174
    Width = 37
    Height = 15
    Caption = 'Length'
  end
  object Label3: TLabel
    Left = 240
    Top = 24
    Width = 32
    Height = 15
    Caption = 'Speed'
  end
  object Label4: TLabel
    Left = 328
    Top = 24
    Width = 45
    Height = 15
    Caption = 'Byte size'
  end
  object Label5: TLabel
    Left = 392
    Top = 24
    Width = 46
    Height = 15
    Caption = 'Stop bits'
  end
  object Label10: TLabel
    Left = 131
    Top = 72
    Width = 30
    Height = 15
    Caption = 'Parity'
  end
  object Label6: TLabel
    Left = 216
    Top = 72
    Width = 98
    Height = 15
    Caption = 'Read timeout (ms)'
  end
  object Label7: TLabel
    Left = 336
    Top = 70
    Width = 100
    Height = 15
    Caption = 'Write timeout (ms)'
  end
  object Button1: TButton
    Left = 40
    Top = 40
    Width = 75
    Height = 25
    Action = actOpen
    TabOrder = 0
  end
  object edtPort: TEdit
    Left = 128
    Top = 41
    Width = 89
    Height = 23
    TabOrder = 1
    Text = '\\.\COM4'
  end
  object Button2: TButton
    Left = 40
    Top = 88
    Width = 75
    Height = 25
    Action = actClose
    TabOrder = 2
  end
  object Button3: TButton
    Left = 40
    Top = 136
    Width = 75
    Height = 25
    Action = actWriteString
    TabOrder = 3
  end
  object Edit2: TEdit
    Left = 128
    Top = 137
    Width = 306
    Height = 23
    TabOrder = 4
    Text = 'THE QUICK BROWN FOX JUMPS OVER THE LAZY DOG'
  end
  object Button4: TButton
    Left = 40
    Top = 192
    Width = 75
    Height = 25
    Caption = 'Read String'
    TabOrder = 5
    OnClick = Button4Click
  end
  object Memo1: TMemo
    Left = 128
    Top = 224
    Width = 321
    Height = 161
    TabOrder = 6
  end
  object edtBytesToRead: TEdit
    Left = 128
    Top = 195
    Width = 68
    Height = 23
    Alignment = taRightJustify
    NumbersOnly = True
    TabOrder = 7
    Text = '10'
  end
  object comboboxSpeed: TComboBox
    Left = 240
    Top = 41
    Width = 65
    Height = 23
    Style = csDropDownList
    ItemIndex = 6
    TabOrder = 8
    Text = '9600'
    Items.Strings = (
      '110'
      '300'
      '600'
      '1200'
      '2400'
      '4800'
      '9600'
      '14400'
      '19200'
      '38400'
      '57600'
      '115200'
      '128000'
      '256000')
  end
  object comboboxByteSize: TComboBox
    Left = 328
    Top = 41
    Width = 45
    Height = 23
    Style = csDropDownList
    ItemIndex = 3
    TabOrder = 9
    Text = '8'
    Items.Strings = (
      '5'
      '6'
      '7'
      '8')
  end
  object comboboxStopBits: TComboBox
    Left = 392
    Top = 41
    Width = 42
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 10
    Text = '1'
    Items.Strings = (
      '1'
      '1.5'
      '2')
  end
  object comboboxParity: TComboBox
    Left = 131
    Top = 89
    Width = 65
    Height = 23
    Style = csDropDownList
    ItemIndex = 0
    TabOrder = 11
    Text = 'NONE'
    Items.Strings = (
      'NONE'
      'ODD'
      'EVEN'
      'MARK'
      'SPACE')
  end
  object edtReadTimeout: TEdit
    Left = 216
    Top = 89
    Width = 98
    Height = 23
    Alignment = taRightJustify
    NumbersOnly = True
    TabOrder = 12
    Text = '5000'
  end
  object edtWriteTimeout: TEdit
    Left = 336
    Top = 89
    Width = 98
    Height = 23
    Alignment = taRightJustify
    NumbersOnly = True
    TabOrder = 13
    Text = '5000'
  end
  object ActionManager1: TActionManager
    Left = 496
    Top = 288
    StyleName = 'Platform Default'
    object actOpen: TAction
      Caption = '&Open'
      OnExecute = actOpenExecute
      OnUpdate = actOpenUpdate
    end
    object actClose: TAction
      Caption = 'Close'
      OnExecute = actCloseExecute
      OnUpdate = EnableIfOpen
    end
    object actWriteString: TAction
      Caption = 'Write String'
      OnExecute = actWriteStringExecute
      OnUpdate = EnableIfOpen
    end
  end
end
