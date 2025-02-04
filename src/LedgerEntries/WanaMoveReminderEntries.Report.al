report 87995 "WanaMove Reminder Entries"
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
                        ApplicationArea = All;
                        Caption = 'Direction';
                    }
                }
            }
        }
    }

    trigger OnPreReport()
    var
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
    begin
        if not ReminderFinChargeEntry.IsEmpty then
            if not Confirm('WARNING : %1 existing "%2" will be deleted.\Do you want to continue?', false, ReminderFinChargeEntry.Count, ReminderFinChargeEntry.TableCaption) then
                CurrReport.Quit()
            else
                ReminderFinChargeEntry.DeleteAll(true);
    end;

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
