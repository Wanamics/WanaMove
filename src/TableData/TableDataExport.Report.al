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
            var
                RecRef: RecordRef;
            begin
                ProgressDialog.UpdateCopyCount();
                if not (ID in [Database::"Change Log Entry", 1990 /*Database::"Guided Experience Item"*/, 6126 /*Database::"E-Doc. Mapping Log"*/]) then begin
                    RecRef.Open(ID);
                    OnSetFilters(RecRef, Filters);
                    if Helper.ExportTable(RecRef, jObject, CountRecords) then
                        CountTables += 1;
                end;
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
                    field(Filters; Filters)
                    {
                        ApplicationArea = All;
                        Caption = 'Filters';
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
        FileName := StrSubstNo('TableData_%1_%2.yaml', CompanyName); //, EntityCode);
        if DownloadFromStream(iStream, DialogTitleLbl, '', ToFilterLbl, FileName) then
            Message('%1 records exported from %2 tables in %3', CountRecords, CountTables, CurrentDateTime - StartDateTime);
    end;

    var
        ProgressDialog: Codeunit "Progress Dialog";
        Helper: Codeunit "WanaMove TableData Helper";
        ExportBlob: Boolean;
        ExportMedia: Boolean;
        CountRecords, CountTables : integer;
        jObject: JsonObject;
        Filters: Text;

    [BusinessEvent(false)]
    local procedure OnSetFilters(var pRecRef: RecordRef; pFilters: Text)
    begin
    end;
}
