{ Delphi 接口定义示例 }
unit InterfaceTypes;

interface

uses
  Windows, SysUtils;

type
  // ========== 基础接口 ==========
  ILogProcessor = interface(IInterface)
    ['{CBC58D11-A65F-4D4F-A649-E0A227A099D8}']
    procedure Start;
    procedure Stop;
  end;

  IExecutor = interface(IInterface)
    ['{94D4F763-544E-4109-8EC0-1233F05D42A5}']
    function Execute(AppName: string; var AErrMsg: string): Integer;
  end;

  IServerCLI = interface(IInterface)
    ['{43A9A365-3BCF-43FB-9B23-57AB741F1F6D}']
    function Execute(const AppName, AReqId, ACmdString: string;
      const IsBroadcast: Boolean; var AErrMsg: string): Integer;
  end;

  ICondition = interface(IInterface)
    ['{31C71649-5229-4F47-A573-911FFF194E8C}']
    function ParseCond(AParamJson: IJson): Boolean;
  end;

  ICmdManager = interface(IInterface)
    ['{EB59B76A-0DA3-452D-8E46-EA13F8276E95}']
    procedure AddExecutor(const ACmd: string; AExecutor: IExecutor);
  end;

  // ========== 带方法的接口 ==========
  INcDataTransIntf = interface
    ['{E1E04AC4-AB50-431F-A5BC-434467FD8C56}']
    function CheckConnection: Boolean;
    function SendBuff(Buffer: TBytes): Boolean;
    function GetReceiveBuff(): TBytes;
  end;

  INcSerialCommTransIntf = interface(INcDataTransIntf)
    procedure SetCommParams(AParams: TCommSerial);
  end;

  INcNetTransIntf = interface(INcDataTransIntf)
    procedure SetNetParams(AParams: TCommNet);
  end;

  INcDevDatacomIntf = interface
    ['{C4B1442B-20EB-415E-80F0-15D6C277E437}']
    function ParserBuff(const Buffer: TBytes): Boolean;
    function CheckDatavalid(Buf: TBytes): Boolean;
    function SendCMD(ACmd: Byte; AParams: TBytes; IsImmCmd: Boolean = True): Boolean;
    function GetSendCmdBuff(ACmd: Byte; AParams: TBytes): TBytes;
    function ExtractData(Buffer: TBytes): Boolean;
    procedure SetDataTransIntf(AIntf: INcDataTransIntf);
  end;

  // ========== 泛型接口 ==========
  IRunnable = interface(IInterface)
    ['{3F2271B6-7C61-4B46-A1C9-ED9E2F2CF8DC}']
    procedure Run();
  end;

  IJson = interface
    function AsJson: string;
  end;

implementation

end.
