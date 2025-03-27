Codeunit 87992 "WanaMove TableData Helper"
{
    procedure ExportTable(pRecordRef: RecordRef; pJsonObject: JsonObject; var pCountRecords: Integer): Boolean
    var
        // RecRef: RecordRef;
        jRecordArray: JsonArray;
        // RecordLink: Record "Record Link";
        // RecordLinkManagement: Codeunit "Record Link Management";
        Filters: Text;
    begin
        if IsChildren.Contains(pRecordRef.Number) then
            exit;
        // RecRef.Open(pTableID);
        // if RecRef.IsEmpty() then
        //     exit;
        if pRecordRef.FindSet() then
            repeat
                jRecordArray.Add(ToJsonObject(pRecordRef));
                pCountRecords += 1;
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
            until pRecordRef.Next() = 0;
        // if not IsEmpty(jRecordArray) then
        pJsonObject.Add(Format(pRecordRef.Number), jRecordArray);
        Exit(true);
    end;

    local procedure ToJsonObject(var RecRef: RecordRef) ReturnValue: JsonObject
    var
        FldRef: FieldRef;
        i: Integer;
        Base64Text: Text;
        jChildren: JsonObject;
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
        if not (RecRef.Number in [Database::"G/L Entry"]) then // Avoid 253: G/L Entry - VAT Entry Link, 5823: G/L - Item Ledger Relation
            GetExplicitChildren(RecRef, jChildren);
        GetImplicitChildren(RecRef, jChildren);
        if not IsEmpty(jChildren) then
            ReturnValue.Add('Children', jChildren);
    end;

    local procedure GetExplicitChildren(var pParentRecRef: RecordRef; var jChildren: JsonObject)
    var
        TableRelationField: Record Field;
    begin
        TableRelationField.SetRange(RelationTableNo, pParentRecRef.Number);
        TableRelationField.SetRange(IsPartOfPrimaryKey, true);
        TableRelationField.SetRange(ObsoleteState, TableRelationField.ObsoleteState::No);
        if TableRelationField.FindSet() then begin
            repeat
                AddChildren(pParentRecRef, TableRelationField.TableNo, jChildren);
            until TableRelationField.Next() = 0;
        end;
    end;

    local procedure GetImplicitChildren(var pParentRecRef: RecordRef; var jChildren: JsonObject)
    begin
        ExportComments.GetComments(pParentRecRef, jChildren);

        if pParentRecRef.Number in [Database::"Sales Header", Database::"Purchase Header", Database::"Service Header"] then
            AddApprovalEntries(pParentRecRef, jChildren);
    end;

    local procedure AddChildren(var pParentRecRef: RecordRef; pChildTableNo: Integer; pReturnValue: JsonObject)
    var
        ChildRecRef: RecordRef;
        // ParentField, ChildField : Record Field;
        ParentFieldRef, ChildFieldRef : FieldRef;
        ParentKeyRef, ChildKeyRef : KeyRef;
        jChildren: JsonArray;
        i: Integer;
    begin
        ParentKeyRef := pParentRecRef.KeyIndex(1);
        ChildRecRef.Open(pChildTableNo);
        ChildKeyRef := ChildRecRef.KeyIndex(1);
        if ChildKeyRef.FieldCount <= ParentKeyRef.FieldCount then
            exit;
        for i := 1 to ParentKeyRef.FieldCount do begin
            ParentFieldRef := pParentRecRef.Field(ParentKeyRef.FieldIndex(i).Number);
            ChildFieldRef := ChildRecRef.Field(ChildKeyRef.FieldIndex(i).Number);
            if (ChildFieldRef.Type <> ParentFieldRef.Type) or (ChildFieldRef.Length <> ParentFieldRef.Length) then
                exit;
            ChildFieldRef.SetRange(ParentFieldRef.Value);
        end;
        jChildren := AddChild(ChildRecRef);
        if jChildren.Count > 0 then
            pReturnValue.Add(Format(ChildRecRef.Number), jChildren);
        // ParentField.SetRange(TableNo, pParentRecRef.Number);
        // ParentField.SetRange(IsPartOfPrimaryKey, true);
        // if ParentField.FindSet() then begin
        //     repeat
        //         if ChildField.Get(pChildTableNo, ParentField."No.") and ChildField.IsPartOfPrimaryKey then begin
        //             ParentFieldRef := pParentRecRef.Field(ParentField."No.");
        //             ChildFieldRef := ChildRecRef.Field(ParentField."No.");
        //             ChildFieldRef.SetRange(ParentFieldRef.Value());
        //         end;
        //     until ParentField.Next() = 0;
        //     jChildren := AddChild(ChildRecRef);
        //     if jChildren.Count > 0 then
        //         pReturnValue.Add(Format(ChildRecRef.Number), jChildren);
        // end;
    end;

    local procedure AddChild(var pChildRecRef: RecordRef) ReturnValue: JsonArray
    var
        jArray: JsonArray;
    begin
        if pChildRecRef.FindSet() then begin
            repeat
                jArray.Add(ToJsonObject(pChildRecRef));
            until pChildRecRef.Next() = 0;
            ReturnValue.Add(jArray);
        end;
        if not IsChildren.Contains(pChildRecRef.Number) then
            IsChildren.Add(pChildRecRef.Number);
    end;

    local procedure AddApprovalEntries(var pParentRecRef: RecordRef; var pReturnValue: JsonObject)
    var
        ApprovalEntry: Record "Approval Entry";
        // ApprovalCommentLine: Record "Approval Comment Line";
        RecRef: RecordRef;
    begin
        ApprovalEntry.SetCurrentKey("Table ID", "Document Type", "Document No.");
        ApprovalEntry.SetRange("Table ID", pParentRecRef.Number);
        ApprovalEntry.SetRange("Document Type", pParentRecRef.Field(1).Value);
        ApprovalEntry.SetRange("Document No.", pParentRecRef.Field(3).Value);
        RecRef.GetTable(ApprovalEntry);
        if RecRef.FindSet() then
            pReturnValue.Add(Format(RecRef.Number), jArray(RecRef));
    end;

    procedure jArray(pRecRef: RecordRef) ReturnValue: JsonArray
    begin
        repeat
            ReturnValue.Add(ToJsonObject(pRecRef));
        until pRecRef.Next() = 0;
    end;

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

    local procedure IsEmpty(jObject: JsonObject): Boolean
    var
        AsText: Text;
    begin
        jObject.WriteTo(AsText);
        exit(AsText = '{}');
    end;

    var
        // jObject: JsonObject;
        ExportBlob: Boolean;
        ExportMedia: Boolean;
        TableDataBuffer: Record "TableData Buffer";
        Base64Convert: Codeunit "Base64 Convert";
        // CountRecords, CountTables : integer;
        IsChildren: list of [Integer];
        ExportComments: Codeunit "WanaMove TableData Comments";

    [BusinessEvent(false)]
    local procedure OnSetFilters(var pRecRef: RecordRef; var EntityCode: Code[20])
    begin
    end;
}
