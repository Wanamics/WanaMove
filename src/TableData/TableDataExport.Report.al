Report 87990 "WanaMove TableData Export"
{
    // 19893 records exported from 1182 tables in 38 minutes 10 secondes 812 millisecondes
    // 6836 Ko (TableData_Sakara_%2 (27).yaml)
    // 13700 Ko for entries (TableData_Sakara_%2 (31).yaml)

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
                DialogLbl: Label 'Exporting table data...\#1##################################\    #2##################################';
            begin
                if not Confirm(ConfirmMsg, false, Count) then
                    CurrReport.Quit();
                if GuiAllowed then
                    Dialog.Open(DialogLbl);
            end;

            trigger OnAfterGetRecord()
            var
                RecRef: RecordRef;
            begin
                if not SkipTable(ID) then begin
                    if GuiAllowed then
                        Dialog.Update(1, Format(ID) + ' ' + Name);
                    RecRef.Open(ID);
                    OnSetFilters(RecRef, Filters);
                    if Helper.ExportTable(RecRef, jObject, CountRecords) then
                        CountTables += 1;
                end;
            end;

            trigger OnPostDataItem()
            begin
                if GuiAllowed then
                    Dialog.Close();
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
                    field(SkipComments; SkipComments)
                    {
                        ApplicationArea = All;
                        Caption = 'Skip Comments';
                    }
                    field(SkipBlob; SkipBlob)
                    {
                        ApplicationArea = All;
                        Caption = 'Skip Blob';
                    }
                    field(SkipMedia; SkipMedia)
                    {
                        ApplicationArea = All;
                        Caption = 'Skip Media';
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

    trigger OnPreReport()
    begin
        Helper.SetGlobals(SkipComments, SkipBlob, SkipMedia);
        StartDateTime := CurrentDateTime;
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
    begin
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
        StartDateTime: DateTime;
        Dialog: Dialog;
        Helper: Codeunit "WanaMove TableData Helper";
        SkipComments, SkipBlob, SkipMedia : Boolean;
        CountRecords, CountTables : integer;
        jObject: JsonObject;
        Filters: Text;

    local procedure SkipTable(pID: Integer): Boolean
    // var
    //     UserPermissions: Codeunit "User Permissions";
    //     TempDummyExpandedPermission: Record "Expanded Permission" temporary;
    begin
        if pID in [
            // Avoid useless tables
            Database::"G/L Entry - VAT Entry Link", // 253
            Database::"Customer Amount", // 266
            Database::"Vendor Amount", // 267
            Database::"Item Amount", // 268
            Database::"G/L - Item Ledger Relation", // 5823
                                                    // Database::"Config. Package Record", // 8614
                                                    // Database::"Config. Package Data", // 8615
                                                    // Database::"Config. Package Error", // 8617
                                                    // Database::"Config. Template Header", // 8618
                                                    // Database::"Config. Template Line", // 8619
            8610 .. 8650 // Config. Package
        ] then
            exit(true);

        exit(pId in [
        // Avoid "Your license does not grant you the following permissions on TableData ... : Read"
        1990, // Guided Experience Item
        1997, // Spotlight Tour Text
        1998, // Primary Guided Experience 
        3712, // Translation
        3903, // Retention Policy Allowed Table
        3905, // Retention Policy Log Entry
        4511, // SMTP Account
        6126, // Database::"E-Doc. Mapping Log"
        8703, // Feature Uptake
        8887, // Email Connector Logo
        8888, // Email Outbox
        8889, // Sent Email
        8900, // Email Message 
        8901, // Email Error
        8903, // Email Recipient 
        8906, // Email Scenario
        8909, // Email Related
        8912, // Email Rate Limit
        9008  // User Login
    ]);
        // TempDummyExpandedPermission := UserPermissions.GetEffectivePermission(TempDummyExpandedPermission."Object Type"::"Table Data", pId);
        // exit(TempDummyExpandedPermission."Read Permission" = TempDummyExpandedPermission."Read Permission"::" ");
    end;

    [BusinessEvent(false)]
    local procedure OnSetFilters(var pRecRef: RecordRef; pFilters: Text)
    begin
    end;
}
