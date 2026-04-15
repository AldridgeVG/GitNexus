unit Unit1;

interface

type
  TParent = class
  public
    constructor Create;
    procedure DoWork;
  end;

  TChild = class(TParent)
  public
    constructor Create;
    procedure DoWork; override;
  end;

implementation

{ TParent }

constructor TParent.Create;
begin
end;

procedure TParent.DoWork;
begin
end;

{ TChild }

constructor TChild.Create;
begin
  inherited Create;
end;

procedure TChild.DoWork;
begin
  inherited DoWork;
end;

end.
