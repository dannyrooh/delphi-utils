{
  Usada para simplificar a conversão de dados de dataset para classes, e vice versa
  A query esta usando a biblioteca Zeus (zDataset), para utilizar com query
  subsituir pelo component que utiliza para persistencia de dados

  dannyrooh@hotmail.com
}

unit Convert.Entity;

interface

uses

  TypInfo, Classes, SysUtils, Variants, DB, zDataSet, strUtils;

type
  TClassConvertEntity = Class of TConvertEntity;

  TConvertEntity = class
  public
    class function Str(objeto: TObject; prop, value: string): TClassConvertEntity;
    class function Int(objeto: TObject; prop: string; value: Integer): TClassConvertEntity;
    class function Dub(objeto: TObject; prop: string; value: Double): TClassConvertEntity;
    class function Val(objeto: TObject; prop: string; value: Variant): TClassConvertEntity;

    class function fromDataSet(dataset: TdataSet; objeto: TObject): TClassConvertEntity;

    class function toDataSet(objeto: TObject; dataset: TdataSet; const doEdit: boolean = true; const doPost: boolean = true): TClassConvertEntity;

    class function toQuery(objeto: TObject; dataset: TZQuery; const doExec: boolean = true): TClassConvertEntity;

    //alias de from dataset
    class function toEntity(objeto: TObject; dataset: TdataSet;
      conST removePrefixField: string = '';
      const doEdit: boolean = true;
      const doPost: boolean = true): TClassConvertEntity;

    //mostra as propriedades de valores
    class function stringList(objeto: TObject): TStringList;

    class function ClearParamsZero(params: TParams; paramFields: array of string):TClassConvertEntity;
  end;

implementation

{ TConvertEntity }

class function TConvertEntity.ClearParamsZero(params: TParams;
  paramFields: array of string): TClassConvertEntity;
var
  i: integer;
  p: TParam;
begin
  for i := low(paramFields) to  high(paramFields) do
  begin
    p := params.FindParam(paramFields[i]);
    if (p <> nil) and (not p.IsNull)
    and ((p.AsString = '0') or (p.AsString = '00:00:00')) then
      p.Clear;
  end;
  result := Self;
end;

class function TConvertEntity.Dub(objeto: TObject; prop: string;
  value: Double): TClassConvertEntity;
begin
  SetFloatProp(objeto,prop,value);
  result := TConvertEntity;
end;

class function TConvertEntity.fromDataSet(dataset: TdataSet;
  objeto: TObject): TClassConvertEntity;
var
  i: integer;
  f: TField;
begin

  for i := 0 to dataset.FieldCount - 1 do
  begin
    f := dataset.Fields[i];

    if not IsPublishedProp(objeto, f.FieldName) then
      Continue;

    if f.DataType in [ftSmallint, ftInteger, ftWord] then
      Self.Int(objeto,f.FieldName, f.AsInteger)
    else if f.DataType in [ftFloat, ftCurrency, ftBCD, ftDate, ftTime, ftDateTime, ftFMTBcd] then
      self.Dub( objeto, f.FieldName, f.AsFloat )
    else if f.DataType in [ftString, ftMemo, ftFmtMemo, ftFixedChar, ftWideString] then
      self.Str( objeto, f.FieldName, f.AsString)
    else
     self.Val( objeto, f.FieldName, f.AsVariant);
  end;

  result := TConvertEntity;
end;

class function TConvertEntity.Int(objeto: TObject; prop: string;
  value: Integer): TClassConvertEntity;
begin
  SetOrdProp(objeto,prop,value);
  result := TConvertEntity;
end;

class function TConvertEntity.Str(objeto: TObject; prop, value: string): TClassConvertEntity;
begin
  SetStrProp(objeto, prop, value);
  result := TConvertEntity;
end;

class function TConvertEntity.stringList(objeto: TObject): TStringList;
var
  PropList: PPropList;
  PropCount, I: Integer;
begin
  result := TStringList.Create;

   PropCount := GetPropList(objeto, PropList);
  try
    for I := 0 to PropCount-1 do
    begin
      // use PropList[I]^ as needed...
      result.Add(PropList[I].Name + '=' + VarToStr(GetPropValue(objeto,PropList[I].Name)));
    end;
  finally
    FreeMem(PropList);
  end;
end;


class function TConvertEntity.toDataSet(objeto: TObject; dataset: TdataSet;
  const doEdit, doPost: boolean): TClassConvertEntity;
var
  PropList: PPropList;
  PropCount, I: Integer;
  f: TField;
  n: string;
begin

  if doEdit then
    dataset.Append;

  PropCount := GetPropList(objeto, PropList);
  try
    for I := 0 to PropCount-1 do
    begin

      n := PropList[I].Name;
      f := dataset.Fields.FindField(n);

      if f = nil then
        Continue;

    if f.DataType in [ftSmallint, ftInteger, ftWord] then
      f.AsInteger := GetOrdProp(objeto,n)
    else if f.DataType in [ftFloat, ftCurrency, ftBCD, ftDate, ftTime, ftDateTime, ftFMTBcd] then
      f.AsFloat := GetFloatProp(objeto,n)
    else if f.DataType in [ftString, ftMemo, ftFmtMemo, ftFixedChar, ftWideString] then
      f.AsString := GetStrProp(objeto,n)
    else
      f.Value := GetPropValue(objeto,n);

    end;
  finally
    FreeMem(PropList);
  end;

  if doPost then
    dataset.Post;

  result := TConvertEntity;

end;

class function TConvertEntity.toEntity(objeto: TObject; dataset: TdataSet;
  const removePrefixField: string;
  const doEdit, doPost: boolean): TClassConvertEntity;
var
  i: integer;
  f: TField;
  propName: string;
begin

  for i := 0 to dataset.FieldCount - 1 do
  begin
    f := dataset.Fields[i];

    propName := f.FieldName;

    if removePrefixField <> emptyStr then
      propName := StringReplace(propName,removePrefixField, '',[]);

    if not IsPublishedProp(objeto, propName) then
      Continue;

    if f.DataType in [ftSmallint, ftInteger, ftWord] then
      Self.Int(objeto,f.FieldName, f.AsInteger)
    else if f.DataType in [ftFloat, ftCurrency, ftBCD, ftDate, ftTime, ftDateTime, ftFMTBcd] then
      self.Dub( objeto, f.FieldName, f.AsFloat )
    else if f.DataType in [ftString, ftMemo, ftFmtMemo, ftFixedChar, ftWideString] then
      self.Str( objeto, f.FieldName, f.AsString)
    else
     self.Val( objeto, f.FieldName, f.AsVariant);
  end;

  result := TConvertEntity;
end;



class function TConvertEntity.toQuery(objeto: TObject; dataset: TZQuery;
  const doExec: boolean): TClassConvertEntity;
var
  PropList: PPropList;
  p: PPropInfo;
  PropCount, I: Integer;
  f: TParam;
  n, t : string;


begin

  for i := 0 to dataset.Params.Count - 1 do
    dataset.Params[i].Clear;


  PropCount := GetPropList(objeto, PropList);
  try
    for i := 0 to PropCount-1 do
    begin


      n := PropList[i]^.Name;
      t :=  LowerCase(PropList[i]^.PropType^.name);

      f := dataset.Params.FindParam(n);

      if f = nil then
        Continue;

     if t = 'integer' then
       f.AsInteger := GetOrdProp(objeto,n)
     else if t = 'double' then
       f.AsFloat := GetFloatProp(objeto,n)
     else if t = 'tdatetime' then
       f.AsDateTime := GetPropValue(objeto,n)
     else if t = 'string'  then
       f.AsString := GetStrProp(objeto,n)
     else
       f.Value := GetPropValue(objeto,n);;

    end;
  finally
    FreeMem(PropList);
  end;


  result := TConvertEntity;

end;

class function TConvertEntity.Val(objeto: TObject; prop: string;
  value: Variant): TClassConvertEntity;
begin
  SetPropValue(objeto, prop, value);
  result := TConvertEntity;
end;

end.
