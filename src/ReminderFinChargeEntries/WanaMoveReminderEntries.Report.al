report 87900 "WanaMove Reminder Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'WanaMove Reminder Entries';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    // DataAccessIntent = ReadOnly; 

    // dataset
    // {
    // }
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
                    field(Direction; Direction)
                    {
                        Caption = 'Direction';
                    }
                }
            }
        }
    }

    // trigger OnPreReport()
    // begin
    //     Window.Open('#1############################');
    //     StartTime := CurrentDateTime;
    // end;

    trigger OnPostReport()
    var
        Window: Dialog;
        StartTime: DateTime;
        DoneMsg: Label 'Process Time : %1';
    begin
        Window.Open('#1############################');
        StartTime := CurrentDateTime;
        if Direction = Direction::Export then
            Export(CurrReport.ObjectId(true).Substring(8) + '.txt')
        else
            Xmlport.Run(Xmlport::"WanaMove Reminder Entries", false, true);
        Window.Close();
        Message(DoneMsg, CurrentDateTime - StartTime)
    end;

    var
        // Window: Dialog;
        // StartTime: DateTime;
        Direction: Option Import,Export;

    local procedure Export(pFileName: Text)
    var
        WanaMoveToReminderEntries: XmlPort "WanaMove Reminder Entries";
        TempBlob: Codeunit "Temp Blob";
        oStream: OutStream;
        iStream: InStream;
    begin
        TempBlob.CreateOutStream(oStream);
        WanaMoveToReminderEntries.SetDestination(oStream);
        WanaMoveToReminderEntries.Export();
        TempBlob.CreateInStream(iStream);
        CopyStream(oStream, iStream);
        DownloadFromStream(iStream, '', '', '', pFileName);
    end;
}
