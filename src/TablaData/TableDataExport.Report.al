//TODO Review (no more PublishedApplication in table extension name but a suffix ext)

Report 87990 "WanaMove TableData Export"
{
    Caption = 'TableData Export';
    ProcessingOnly = true;
    UsageCategory = Administration;
    ApplicationArea = All;

    dataset
    {
        dataitem("Table Metadata"; "Table Metadata")
        {
            DataItemTableView = where(DataPerCompany = const(true), TableType = const(TableType::Normal), ObsoleteState = const(ObsoleteState::No));
            RequestFilterFields = "ID";
            trigger OnPreDataItem()
            var
                ConfirmMsg: Label 'Do you want to export table data for %1 tables?';
            begin
                if not Confirm(ConfirmMsg, false, Count) then
                    CurrReport.Quit();
                ProgressDialog.OpenCopyCountMax('', Count);
            end;

            trigger OnAfterGetRecord()
            begin
                ProgressDialog.UpdateCopyCount();
                ExportTable(ID);
            end;
        }
    }

    requestpage
    {
        SaveValues = true;

        layout
        {
            area(content)
            {
                group(Options)
                {
                    Caption = 'Options';
                    field(ExportBlob; ExportBlob)
                    {
                        ApplicationArea = All;
                        Caption = 'Export Blob';
                    }
                    field(ExportMedia; ExportMedia)
                    {
                        ApplicationArea = All;
                        Caption = 'Export Media';
                    }
                }
            }
        }
    }
    trigger OnInitReport()
    var
        UserPermissions: Codeunit "User Permissions";
        ErrorMsg: Label 'User must have SUPER permission set';
    begin
        if not UserPermissions.IsSuper(UserSecurityId()) then
            error(ErrorMsg);
    end;

    trigger OnPostReport()
    var
        YamlText: Text;
        TempBlob: Codeunit "Temp Blob";
        oStream: OutStream;
        iStream: InStream;
        FileName: Text;
        DialogTitleLbl: Label 'Export Table Data';
        // ToFolderLbl: Label ''; //C:\Temp';
        ToFilterLbl: Label 'yaml files (*.yaml)|*.yaml|All files (*.*)|*.*';
    begin
        jObject.WriteToYaml(YamlText);
        // jObject.WriteTo(YamlText);
        TempBlob.CreateOutStream(oStream);
        TempBlob.CreateInStream(iStream);
        oStream.WriteText(YamlText);
        CopyStream(oStream, iStream);
        // FileName := 'TableData.yaml';
        if DownloadFromStream(iStream, DialogTitleLbl, '', ToFilterLbl, FileName) then;
    end;

    var
        ProgressDialog: Codeunit "Progress Dialog";
        // JsonTools: Codeunit "Json Tools";
        jObject: JsonObject;

    local procedure ExportTable(pTableID: Integer)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
        jRecordArray: JsonArray;
    begin
        RecRef.Open(pTableID);
        if RecRef.IsEmpty() then
            exit;
        if RecRef.FindSet() then
            repeat
                jRecordArray.Add(ToJson(RecRef));
            until RecRef.Next() = 0;
        jObject.Add(Format(RecRef.Number), jRecordArray);
        RecRef.Close();
    end;

    local procedure ToJson(var RecRef: RecordRef) ReturnValue: JsonObject
    var
        FldRef: FieldRef;
        i: Integer;
        jValue: JsonValue;
        TempBlob: Codeunit "Temp Blob";
        TableDataBuffer: Record "TableData Buffer";
    begin
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            jValue := ToJsonValue(FldRef);
            case FldRef.Type of
                FieldType::BigInteger:
                    if jValue.AsBigInteger() <> 0 then
                        ReturnValue.Add(Format(FldRef.Number), jValue);
                Fieldtype::Blob:
                    if ExportBLOB then begin
                        FldRef.CalcField();
                        TempBlob.FromFieldRef(FldRef);
                        JObject.Add(Format(FldRef.Number()), Base64Convert.ToBase64(TempBlob.CreateInStream()));
                    end;
                FieldType::Boolean:
                    if jValue.AsBoolean() then
                        ReturnValue.Add(Format(FldRef.Number), jValue);
                FieldType::Code:
                    if jValue.AsCode() <> '' then
                        ReturnValue.Add(Format(FldRef.Number), jValue);
                FieldType::Date:
                    if jValue.AsDate() <> 0D then
                        ReturnValue.Add(Format(FldRef.Number), jValue);
                FieldType::DateFormula:
                    if jValue.AsText() <> '' then
                        ReturnValue.Add(Format(FldRef.Number), jValue);
                FieldType::DateTime:
                    if jValue.AsDateTime() <> 0DT then
                        ReturnValue.Add(Format(FldRef.Number), jValue);
                FieldType::Decimal:
                    if jValue.AsDecimal() <> 0 then
                        ReturnValue.Add(Format(FldRef.Number), jValue);
                FieldType::Duration:
                    if jValue.AsDuration() <> 0 then
                        ReturnValue.Add(Format(FldRef.Number), jValue);
                FieldType::Guid:
                    // if jValue.AsText() <> '{00000000-0000-0000-0000-000000000000}' then //TODO Review
                    if not IsNullGuid(FldRef.Value()) then
                        ReturnValue.Add(Format(FldRef.Number), jValue);
                FieldType::Integer:
                    if jValue.AsInteger() <> 0 then
                        ReturnValue.Add(Format(FldRef.Number), jValue);
                FieldType::Media,
                FieldType::MediaSet:
                    if ExportMedia then
                        // if not jValue.IsNull then begin
                        if not IsNullGuid(FldRef.Value()) then begin
                            TableDataBuffer."Some Media" := FldRef.Value();
                            JObject.Add(Format(FldRef.Number()), ConvertMediaToBase64(TableDataBuffer."Some Media".MediaId()));
                        end;
                FieldType::Option:
                    if jValue.AsOption() <> 0 then
                        ReturnValue.Add(Format(FldRef.Number), jValue);
                FieldType::RecordId:
                    if jValue.AsByte() <> 0 then
                        ReturnValue.Add(Format(FldRef.Number), jValue);
                FieldType::TableFilter:
                    ;
                FieldType::Text:
                    if jValue.AsText() <> '' then
                        ReturnValue.Add(Format(FldRef.Number), jValue);
                FieldType::Time:
                    if jValue.AsTime() <> 0T then
                        ReturnValue.Add(Format(FldRef.Number), jValue);
                else
                    Error('Unknown field : Table %1, Field %2, FieldType %3', RecRef.Name, FldRef.Name, FldRef.Type);
            end;
        end;
    end;

    local procedure ToJsonValue(FRef: FieldRef): JsonValue
    var
        V: JsonValue;
        D: Date;
        DT: DateTime;
        T: Time;
    begin
        case FRef.Type() of
            FieldType::Date:
                begin
                    D := FRef.Value;
                    V.SetValue(D);
                end;
            FieldType::Time:
                begin
                    T := FRef.Value;
                    V.SetValue(T);
                end;
            FieldType::DateTime:
                begin
                    DT := FRef.Value;
                    V.SetValue(DT);
                end;
            else
                V.SetValue(Format(FRef.Value, 0, 9));
        end;
        exit(v);
    end;

    procedure ConvertMediaToBase64(MediaId: Guid): Text
    var
        TenantMedia: Record "Tenant Media";
        Base64Convert: Codeunit "Base64 Convert";
        MediaInStream: InStream;
    begin
        TenantMedia.Get(MediaId);
        TenantMedia.CalcFields(Content);
        TenantMedia.Content.CreateInStream(MediaInStream);
        // MediaBase64 := Base64Convert.ToBase64(MediaInStream);
        // exit(MediaBase64);
        exit(Base64Convert.ToBase64(MediaInStream));
    end;

    var
        ExportBlob: Boolean;
        ExportMedia: Boolean;
        TableDataBuffer: Record "TableData Buffer";
        Base64Convert: Codeunit "Base64 Convert";
}
