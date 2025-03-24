Report 87996 "WanaMove TableData Import"
{
    Caption = 'TableData Import';
    ProcessingOnly = true;
    UsageCategory = Administration;
    ApplicationArea = All;
    Permissions =
        tabledata "Vendor Ledger Entry" = I, tabledata "FA Ledger Entry" = I, tabledata "Job Ledger Entry" = I, tabledata "Item Ledger Entry" = I,
        tabledata "Res. Ledger Entry" = I, tabledata "Check Ledger Entry" = I, tabledata "Cust. Ledger Entry" = I, tabledata "Service Ledger Entry" = I,
        tabledata "Capacity Ledger Entry" = I, tabledata "Employee Ledger Entry" = I, tabledata "Warranty Ledger Entry" = I, tabledata "Maintenance Ledger Entry" = I,
        tabledata "Bank Account Ledger Entry" = I, tabledata "Ins. Coverage Ledger Entry" = I, tabledata "Payable Vendor Ledger Entry" = I, tabledata "Phys. Inventory Ledger Entry" = I,
        tabledata "Payable Employee Ledger Entry" = I, tabledata "Detailed Employee Ledger Entry" = I, tabledata "Detailed Cust. Ledg. Entry" = I, tabledata "Detailed Vendor Ledg. Entry" = I,
        tabledata "Sales Invoice Header" = I, tabledata "Sales Invoice Line" = I, tabledata "Sales Shipment Header" = I, tabledata "Sales Shipment Line" = I,
        tabledata "Sales Cr.Memo Header" = I, tabledata "Sales Cr.Memo Line" = I, tabledata "Purch. Cr. Memo Hdr." = I, tabledata "Purch. Cr. Memo Line" = I,
        tabledata "Purch. Inv. Header" = I, tabledata "Purch. Inv. Line" = I, tabledata "Purch. Rcpt. Header" = I, tabledata "Purch. Rcpt. Line" = I,
        tabledata "Purchase Header Archive" = I, tabledata "Sales Line Archive" = I, tabledata "Sales Header Archive" = I, tabledata "Purchase Line Archive" = I,
        tabledata "Sales Comment Line Archive" = I, tabledata "Purch. Comment Line Archive" = I, tabledata "Workflow Step Argument Archive" = I, tabledata "Workflow Record Change Archive" = I,
        tabledata "Workflow Step Instance Archive" = I, tabledata "G/L Entry" = I, tabledata "Approval Entry" = I, tabledata "Warehouse Entry" = I,
        tabledata "Value Entry" = I, tabledata "Item Register" = I, tabledata "G/L Register" = RIMD, tabledata "Vat Entry" = I, tabledata "Dimension Set Entry" = RIMD,
        tabledata "Service Invoice Header" = I, TableData "Service Cr.Memo Header" = I, TableData "Issued Reminder Header" = I, TableData "Issued Fin. Charge Memo Header" = I,
        tabledata "G/L Entry - VAT Entry Link" = I, tabledata "Item Application Entry" = I, tabledata "Item Application Entry History" = I,
        tabledata "Return Shipment Header" = I, tabledata "Return Shipment Line" = I, tabledata "Return Receipt Header" = I, tabledata "Return Receipt Line" = I,
        tabledata "Invt. Receipt Header" = I, tabledata "Invt. Receipt Line" = I, tabledata "Invt. Shipment Header" = I, tabledata "Invt. Shipment Line" = I,
        tabledata "Pstd. Phys. Invt. Record Hdr" = I, tabledata "Pstd. Phys. Invt. Record Line" = I, tabledata "Pstd. Phys. Invt. Order Hdr" = I, tabledata "Pstd. Phys. Invt. Order Line" = I,
        tabledata "Bank Account Statement Line" = I, tabledata "Change Log Entry" = RIMD, tabledata "Posted Approval Entry" = RIMD, tabledata "FA Register" = RIMD, tabledata "Post Value Entry to G/L" = RIMD;

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
                    field(Replace; Replace)
                    {
                        ApplicationArea = All;
                        Caption = 'Replace existing records';
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
        jObject: JsonObject;
        YamlText: Text;
        TempBlob: Codeunit "Temp Blob";
        oStream: OutStream;
        iStream: InStream;
        FileName: Text;
        DialogTitleLbl: Label 'Select the file to import';
        FromFolderLbl: Label ''; //'C:\Temp';
        FromFilterLbl: Label 'yaml files (*.yaml)|*.yaml|All files (*.*)|*.*';
    begin
        TempBlob.CreateInStream(iStream);
        if UploadIntoStream(DialogTitleLbl, FromFolderLbl, FromFilterLbl, FileName, iStream) then begin
            iStream.Read(YamlText);
            jObject.ReadFromYaml(YamlText);
            ImportTableData(jObject);
        end;
    end;

    local procedure ImportTableData(var jObject: JsonObject)
    var
        Table: Text;
        jRecordToken: JsonToken;
        RecRef: RecordRef;
        RecRef2: RecordRef;
    begin
        foreach Table in jObject.Keys do begin
            RecRef2.Open(ToID(Table));
            JObject.Get(Table, jRecordToken);
            foreach jRecordToken in jRecordToken.AsArray() do begin
                RecRef := ToRecordRef(jRecordToken.AsObject(), ToID(Table));
                RecRef2.Copy(RecRef);
                if not RecRef2.Find() then
                    RecRef.Insert(false)
                else if Replace then begin
                    RecRef2.Copy(RecRef);
                    RecRef2.Modify(false);
                end;
            end;
            RecRef2.Close();
        end;
    end;

    local procedure ToID(var Table: Text) ReturnValue: Integer
    begin
        evaluate(ReturnValue, Table);
    end;

    local procedure ToRecordRef(jObject: JsonObject; TableID: Integer) ReturnValue: RecordRef
    var
        FldRef: FieldRef;
        i: Integer;
        Field: Text;
        jToken: JsonToken;
        oStream: OutStream;
        iStream: InStream;
    begin
        ReturnValue.Open(TableID);
        foreach Field in jObject.Keys() do begin
            jObject.Get(Field, jToken);
            FldRef := ReturnValue.Field(ToID(Field));
            case FldRef.Type of
                FieldType::BigInteger:
                    FldRef.Value := jToken.AsValue().AsBigInteger();
                FieldType::Blob:
                    begin
                        TableDataBuffer."Some BLOB".CreateOutStream(oStream);
                        Base64Convert.FromBase64(jToken.AsValue().AsText(), oStream);
                    end;
                FieldType::Boolean:
                    FldRef.Value := jToken.AsValue().AsBoolean();
                FieldType::Code:
                    FldRef.Value := jToken.AsValue().AsText();
                FieldType::Date:
                    FldRef.Value := jToken.AsValue().AsDate();
                FieldType::DateFormula:
                    FldRef.Value := jToken.AsValue().AsText();
                FieldType::DateTime:
                    FldRef.Value := jToken.AsValue().AsDateTime();
                FieldType::Decimal:
                    FldRef.Value := jToken.AsValue().AsDecimal();
                FieldType::Duration:
                    FldRef.Value := jToken.AsValue().AsDuration();
                FieldType::Guid:
                    FldRef.Value := jToken.AsValue().AsText();
                FieldType::Integer:
                    FldRef.Value := jToken.AsValue().AsInteger();
                FieldType::Media,
                FieldType::MediaSet:
                    begin
                        TempBlob.CreateOutStream(oStream);
                        Base64Convert.FromBase64(jToken.AsValue().AsText(), oStream);
                        TempBlob.CreateInStream(iStream);
                        TableDataBuffer."Some Media".ImportStream(iStream, '');
                    end;
                FieldType::Option:
                    FldRef.Value := jToken.AsValue().AsOption();
                FieldType::RecordId:
                    ;
                FieldType::TableFilter:
                    ;
                FieldType::Text:
                    FldRef.Value := jToken.AsValue().AsText();
                FieldType::Time:
                    FldRef.Value := jToken.AsValue().AsTime();
                else
                    Error('Unknown field : Table %1, Field %2, FieldType %3', ReturnValue.Name, FldRef.Name, FldRef.Type);
            end;
        end;
    end;

    var
        Replace: Boolean;
        TableDataBuffer: Record "TableData Buffer";
        Base64Convert: Codeunit "Base64 Convert";
        TempBlob: Codeunit "Temp Blob";

}
