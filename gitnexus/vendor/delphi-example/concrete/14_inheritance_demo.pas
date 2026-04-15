{ Delphi 类继承与 inherited 调用示例 }
unit InheritanceDemo;

interface

uses
  SysUtils, Classes;

type
  TBaseDomain = class(TObject)
  private
    FID: Integer;
    FName: string;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadData;
    function Validate: Boolean; virtual;
    property ID: Integer read FID write FID;
    property Name: string read FName write FName;
  end;

  TMatchInfoDomain = class(TBaseDomain)
  private
    FMatchCode: string;
    FMatchDate: TDateTime;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadData; override;
    function Validate: Boolean; override;
    property MatchCode: string read FMatchCode write FMatchCode;
    property MatchDate: TDateTime read FMatchDate write FMatchDate;
  end;

implementation

{ TBaseDomain }

constructor TBaseDomain.Create;
begin
  inherited Create;
  FID := 0;
  FName := '';
end;

destructor TBaseDomain.Destroy;
begin
  inherited;
end;

procedure TBaseDomain.LoadData;
begin
  // 基础数据加载
end;

function TBaseDomain.Validate: Boolean;
begin
  Result := (FID > 0) and (FName <> '');
end;

{ TMatchInfoDomain }

constructor TMatchInfoDomain.Create;
begin
  inherited Create;
  FMatchCode := '';
  FMatchDate := 0;
end;

destructor TMatchInfoDomain.Destroy;
begin
  inherited;
end;

procedure TMatchInfoDomain.LoadData;
begin
  inherited LoadData;
  // 加载比赛特有数据
end;

function TMatchInfoDomain.Validate: Boolean;
begin
  Result := inherited Validate and (FMatchCode <> '');
end;

end.
