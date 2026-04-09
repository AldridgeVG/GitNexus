{ Delphi 数据库操作示例 }
unit DatabaseOperations;

interface

uses
  Windows, SysUtils, Classes, Generics.Collections, Variants;

type
  TDBUtil = class
  private
    FDBFile: string;
    FDBReady: Boolean;
  public
    constructor Create;
    destructor Destroy; override;
    function ExecuteSql(ASql: string): Boolean;
    function QueryInt(ASql: string; ADefault: Integer): Integer;
    procedure StartTransaction;
    procedure Commit;
    procedure Rollback;
  end;

  TSQLBuilder = class
  private
    FSelect: TStringBuilder;
    FFrom: string;
    FWhere: TStringBuilder;
  public
    constructor Create;
    destructor Destroy; override;
    function Select(const Columns: string): TSQLBuilder;
    function From(const Table: string): TSQLBuilder;
    function Where(const Condition: string): TSQLBuilder;
    function Build: string;
  end;

implementation

constructor TDBUtil.Create;
begin
  inherited Create;
  FDBReady := False;
end;

destructor TDBUtil.Destroy;
begin
  inherited;
end;

function TDBUtil.ExecuteSql(ASql: string): Boolean;
begin
  Result := False;
  try
    if not FDBReady then Exit;
    Result := True;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

function TDBUtil.QueryInt(ASql: string; ADefault: Integer): Integer;
begin
  Result := ADefault;
  if not FDBReady then Exit;
end;

procedure TDBUtil.StartTransaction;
begin
  ExecuteSql('BEGIN TRANSACTION');
end;

procedure TDBUtil.Commit;
begin
  ExecuteSql('COMMIT');
end;

procedure TDBUtil.Rollback;
begin
  ExecuteSql('ROLLBACK');
end;

constructor TSQLBuilder.Create;
begin
  inherited Create;
  FSelect := TStringBuilder.Create;
  FWhere := TStringBuilder.Create;
end;

destructor TSQLBuilder.Destroy;
begin
  FSelect.Free;
  FWhere.Free;
  inherited;
end;

function TSQLBuilder.Select(const Columns: string): TSQLBuilder;
begin
  if FSelect.Length > 0 then
    FSelect.Append(', ');
  FSelect.Append(Columns);
  Result := Self;
end;

function TSQLBuilder.From(const Table: string): TSQLBuilder;
begin
  FFrom := Table;
  Result := Self;
end;

function TSQLBuilder.Where(const Condition: string): TSQLBuilder;
begin
  FWhere.Clear;
  FWhere.Append(' WHERE ');
  FWhere.Append(Condition);
  Result := Self;
end;

function TSQLBuilder.Build: string;
var
  SB: TStringBuilder;
begin
  SB := TStringBuilder.Create;
  try
    SB.Append('SELECT ');
    if FSelect.Length > 0 then
      SB.Append(FSelect.ToString)
    else
      SB.Append('*');

    if FFrom <> '' then
    begin
      SB.Append(' FROM ');
      SB.Append(FFrom);
    end;

    if FWhere.Length > 0 then
      SB.Append(FWhere.ToString);

    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

end.
