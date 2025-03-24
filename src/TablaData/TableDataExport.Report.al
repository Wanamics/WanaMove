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
            DataItemTableView =
                where(
                    DataPerCompany = const(true),
                    TableType = const(TableType::Normal),
                    DataIsExternal = const(false),
                    ObsoleteState = const(ObsoleteState::No));
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
                if not (ID in [Database::"Change Log Entry", 1990 /*Database::"Guided Experience Item"*/, 6126 /*Database::"E-Doc. Mapping Log"*/]) then
                    if not Child.Contains(ID) then
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
                    field(EntityCode; EntityCode)
                    {
                        ApplicationArea = All;
                        Caption = 'Entity Code';
                        // TableRelation = Entity;
                    }
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
        TempBlob: Codeunit "Temp Blob";
        iStream: InStream;
        DialogTitleLbl: Label 'Export Table Data';
        ToFilterLbl: Label 'yaml files (*.yaml)|*.yaml|All files (*.*)|*.*';
        oStream: OutStream;
        FileName: Text;
        YamlText: Text;
        StartDateTime: DateTime;
    begin
        StartDateTime := CurrentDateTime;
        jObject.WriteToYaml(YamlText);
        TempBlob.CreateOutStream(oStream, TextEncoding::UTF8);
        TempBlob.CreateInStream(iStream, TextEncoding::UTF8);
        oStream.WriteText(YamlText);
        CopyStream(oStream, iStream);
        FileName := StrSubstNo('TableData_%1_%2.yaml', CompanyName, EntityCode);
        if DownloadFromStream(iStream, DialogTitleLbl, '', ToFilterLbl, FileName) then
            Message('%1 records exported from %2 tables in %3', CountRecords, CountTables, CurrentDateTime - StartDateTime);
    end;

    local procedure ExportTable(pTableID: Integer)
    var
        RecRef: RecordRef;
        jRecordArray: JsonArray;
    // RecordLink: Record "Record Link";
    // RecordLinkManagement: Codeunit "Record Link Management";
    begin
        RecRef.Open(pTableID);
        OnSetFilters(RecRef, EntityCode);
        if RecRef.IsEmpty() then
            exit;
        if RecRef.FindSet() then
            repeat
                jRecordArray.Add(ToJsonObject(RecRef));
                CountRecords += 1;
            // //TODO +RecordLinks (2000000068) (Type Note, Link)
            // if RecRef.HasLinks then begin
            //     jLinkArray.Add(ToJson) :=;
            // RecordLinkManagement. .GetRecordLinks(RecRef.RecordID);
            // end;
            // RecordLink.SetCurrentKey("Record ID");
            // RecordLink.SetRange("Record ID", RecRef.RecordID);
            // if RecordLink.FindSet() then
            //     repeat
            //     //TODO
            //     until RecordLink.Next() = 0;
            until RecRef.Next() = 0;
        jObject.Add(Format(RecRef.Number), jRecordArray);
        CountTables += 1;
    end;

    local procedure ToJsonObject(var RecRef: RecordRef) ReturnValue: JsonObject
    var
        FldRef: FieldRef;
        i: Integer;
        Base64Text: Text;
    // jChildren: JsonObject;
    begin
        for i := 1 to RecRef.FieldCount() do begin
            FldRef := RecRef.FieldIndex(i);
            case FldRef.Type of
                FieldType::Blob:
                    if ExportBlob then begin
                        Base64Text := ToBase64(FldRef);
                        if Base64Text <> '' then
                            ReturnValue.Add(Format(FldRef.Number), Base64Text);
                    end;
                FieldType::Media:
                    if ExportMedia then
                        if not IsNullGuid(FldRef.Value()) then begin
                            TableDataBuffer."Some Media" := FldRef.Value();
                            ReturnValue.Add(Format(FldRef.Number()), ToBase64(TableDataBuffer."Some Media".MediaId()));
                        end;
                FieldType::MediaSet:
                    ; //TODO MediaSet
                else
                    if HasValue(FldRef) then
                        ReturnValue.Add(Format(FldRef.Number), ToJsonValue(FldRef));
            end;
        end;
        // ReturnValue.Add('Children', AddChildren(RecRef));
        AddChildren(RecRef, ReturnValue);
    end;

    local procedure AddChildren(var pParentRecRef: RecordRef; pReturnValue: JsonObject)
    var
        ChildField: Record Field;
        // ChildRecRef: RecordRef;
        // ParentField, 
        // ParentFieldRef, ChildFieldRef : FieldRef;
        jChildren: JsonObject;
        HasChildren: Boolean;
    begin
        ChildField.SetRange(RelationTableNo, pParentRecRef.Number);
        ChildField.SetRange(IsPartOfPrimaryKey, true);
        ChildField.SetRange(ObsoleteState, ChildField.ObsoleteState::No);
        if ChildField.FindSet() then begin
            repeat
                // ChildRecRef.Open(ChildField.TableNo);

                // ParentField.SetRange(TableNo, pParentRecRef.Number);
                // ParentField.SetRange(IsPartOfPrimaryKey, true);
                // if ParentField.FindSet() then begin
                //     repeat
                //         ParentFieldRef := pParentRecRef.Field(ParentField."No.");
                //         ChildFieldRef := ChildRecRef.Field(ParentField."No.");
                //         ChildFieldRef.SetRange(ParentFieldRef.Value());
                //     until ParentField.Next() = 0;
                //     ReturnValue.Add(Format(ChildRecRef.Number), AddChild(ChildRecRef));
                // end;

                // ChildRecRef.Close();
                ExportChildren(pParentRecRef, ChildField.TableNo, jChildren, HasChildren);
            until ChildField.Next() = 0;
            if HasChildren then
                pReturnValue.Add('Children', jChildren);
        end;
    end;

    local procedure ExportChildren(var pParentRecRef: RecordRef; pChildTableNo: Integer; pReturnValue: JsonObject; var HasChildren: Boolean)
    var
        ChildRecRef: RecordRef;
        ParentField: Record Field;
        ParentFieldRef, ChildFieldRef : FieldRef;
        jChildren: JsonArray;
    begin
        ChildRecRef.Open(pChildTableNo);
        ParentField.SetRange(TableNo, pParentRecRef.Number);
        ParentField.SetRange(IsPartOfPrimaryKey, true);
        if ParentField.FindSet() then begin
            repeat
                ParentFieldRef := pParentRecRef.Field(ParentField."No.");
                ChildFieldRef := ChildRecRef.Field(ParentField."No.");
                ChildFieldRef.SetRange(ParentFieldRef.Value());
            until ParentField.Next() = 0;
            jChildren := AddChild(ChildRecRef);
            if jChildren.Count > 0 then begin
                pReturnValue.Add(Format(ChildRecRef.Number), jChildren);
                HasChildren := true;
            end;
        end;


        // ChildRecRef.Close();

    end;

    local procedure AddChild(var pChildRecRef: RecordRef) ReturnValue: JsonArray
    var
        jArray: JsonArray;
    begin
        if pChildRecRef.FindSet() then begin
            repeat
                jArray.Add(ToJsonObject(pChildRecRef));
            until pChildRecRef.Next() = 0;
            ReturnValue.Add(/*Format(pChildRecRef.Number),*/ jArray);
        end;
        if not Child.Contains(pChildRecRef.Number) then
            Child.Add(pChildRecRef.Number);
    end;

    // local procedure IsDocument(TableID: Integer): Boolean
    // begin
    //     exit(TableID in [
    //         Database::"Sales Header", Database::"Sales Line", Database::"Sales Header Archive", Database::"Sales Line Archive",
    //         Database::"Sales Shipment Header", Database::"Sales Shipment Line", Database::"Return Shipment Header", Database::"Return Shipment Line",
    //         Database::"Sales Invoice Header", Database::"Sales Invoice Line", Database::"Sales Cr.Memo Header", Database::"Sales Cr.Memo Line",
    //         Database::"Purchase Header", Database::"Purchase Line", Database::"Purchase Header Archive", Database::"Purchase Line Archive",
    //         Database::"Purch. Rcpt. Header", Database::"Purch. Rcpt. Line", Database::"Return Receipt Header", Database::"Return Receipt Line",
    //         Database::"Purch. Inv. Header", Database::"Purch. Inv. Line", Database::"Purch. Cr. Memo Hdr.", Database::"Purch. Cr. Memo Line",
    //         Database::"Service Header", Database::"Service Line", Database::"Service Header Archive", Database::"Service Line Archive",
    //         Database::"Service Contract Header", Database::"Service Contract Line",
    //         Database::"Service Invoice Header", Database::"Service Invoice Line", Database::"Service Cr.Memo Header", Database::"Service Cr.Memo Line",
    //         Database::"Production Order", Database::"Prod. Order Line"
    //         ]);
    // end;

    // local procedure DocumentAttachments(var RecRef: RecordRef) ReturnValue: JsonArray
    // var
    //     DocumentAttachment: Record "Document Attachment";
    //     DocumentAttachmentRef: RecordRef;
    // begin
    //     DocumentAttachment.SetCurrentKey("Table ID", "No.", "Document Type", "Line No.", ID);
    //     RecRef.GetTable(DocumentAttachment);
    //     if RecRef.FindSet() then
    //         repeat
    //             ReturnValue.Add(ToJson(RecRef));
    //         until DocumentAttachment.Next() = 0;
    // end;

    local procedure ToBase64(FldRef: FieldRef): Text
    var
        TempBlob: Codeunit "Temp Blob";
        TableDataBuffer: Record "TableData Buffer";
    begin
        FldRef.CalcField();
        TempBlob.FromFieldRef(FldRef);
        exit(Base64Convert.ToBase64(TempBlob.CreateInStream(TextEncoding::UTF8)));
    end;

    local procedure HasValue(var pFldRef: FieldRef): Boolean
    var
        jValue: JsonValue;
        Duration: Duration;
    begin
        jValue := ToJsonValue(pFldRef);
        case pFldRef.Type of
            FieldType::BigInteger:
                exit(jValue.AsBigInteger() <> 0);
            FieldType::Boolean:
                exit(jValue.AsBoolean());
            FieldType::Code:
                exit(jValue.AsCode() <> '');
            FieldType::Date:
                exit(jValue.AsDate() <> 0D);
            FieldType::DateFormula:
                exit(jValue.AsText() <> '');
            FieldType::DateTime:
                exit(jValue.AsDateTime() <> 0DT);
            FieldType::Decimal:
                exit(jValue.AsDecimal() <> 0);
            FieldType::Duration:
                exit(jValue.AsText() <> '');
            FieldType::Guid:
                exit(not IsNullGuid(jValue.AsText()));
            FieldType::Integer:
                exit(jValue.AsInteger() <> 0);
            FieldType::Option:
                exit(jValue.AsOption() <> 0);
            FieldType::RecordId:
                exit(jValue.AsText() <> '');
            FieldType::TableFilter:
                exit(jValue.AsText() <> ''); //???????????????
            FieldType::Text:
                exit(jValue.AsText() <> '');
            FieldType::Time:
                exit(jValue.AsTime() <> 0T);
            else
                Error('Unknown field : Table %1, Field %2, FieldType %3', pFldRef.Record().Number, pFldRef.Name, pFldRef.Type);
        end;
    end;

    local procedure ToJsonValue(FldRef: FieldRef): JsonValue
    var
        jValue: JsonValue;
        D: Date;
        DT: DateTime;
        T: Time;
    begin
        case FldRef.Type() of
            FieldType::Date:
                begin
                    D := FldRef.Value;
                    jValue.SetValue(D);
                end;
            FieldType::Time:
                begin
                    T := FldRef.Value;
                    jValue.SetValue(T);
                end;
            FieldType::DateTime:
                begin
                    DT := FldRef.Value;
                    jValue.SetValue(DT);
                end;
            else
                jValue.SetValue(Format(FldRef.Value, 0, 9));
        end;
        exit(jValue);
    end;

    procedure ToBase64(MediaId: Guid): Text
    var
        TenantMedia: Record "Tenant Media";
        Base64Convert: Codeunit "Base64 Convert";
        MediaInStream: InStream;
    begin
        TenantMedia.Get(MediaId);
        TenantMedia.CalcFields(Content);
        TenantMedia.Content.CreateInStream(MediaInStream, TextEncoding::UTF8);
        exit(Base64Convert.ToBase64(MediaInStream));
    end;

    var
        EntityCode: Code[20];
        ProgressDialog: Codeunit "Progress Dialog";
        jObject: JsonObject;
        ExportBlob: Boolean;
        ExportMedia: Boolean;
        TableDataBuffer: Record "TableData Buffer";
        Base64Convert: Codeunit "Base64 Convert";
        CountRecords, CountTables : integer;
        Child: list of [Integer];

    [BusinessEvent(false)]
    local procedure OnSetFilters(var pRecRef: RecordRef; var EntityCode: Code[20])
    begin
    end;
}
