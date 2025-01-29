pageextension 87900 "WanaMove General Journal" extends "General Journal"
{
    layout
    {
        addlast(Control1)
        {
            field("Source Code"; Rec."Source Code")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Source Code field.';
                Visible = false;
            }
            field("Line No."; Rec."Line No.")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the value of the Line No. field.';
                Visible = false;
            }
        }
    }
    actions
    {
        addlast("Opening Balance")
        {
            group(WanaMove)
            {
                Caption = 'WanaMove';
                // action(WanaMoveExportOpenEntries)
                // {
                //     Caption = 'Export Open Entries';
                //     ApplicationArea = All;
                //     Image = OpenJournal;
                //     RunObject = report "WanaMove Export Open Entries";
                // }
                // action(WanaMoveExportFiscalYear)
                // {
                //     Caption = 'Export Fiscal Year';
                //     ApplicationArea = All;
                //     Image = ExportFile;
                //     RunObject = report "WanaMove Export Fiscal Year";
                // }
                action(WanaMoveImport)
                {
                    Caption = 'Import WanaMove';
                    ApplicationArea = All;
                    Image = ImportChartOfAccounts;
                    // RunObject = codeunit "WanaMove Import";
                    trigger OnAction()
                    var
                        DeleteLines: Label 'Do you want to delete %1 previous lines?';
                        WanaMove: XmlPort "WanaMove";
                    begin
                        if not Rec.IsEmpty then
                            if not Confirm(DeleteLines, false, Rec.Count) then
                                exit
                            else
                                Rec.DeleteAll(true);
                        WanaMove.SetGenJournalLine(Rec);
                        WanaMove.Run();
                        Message(WanaMove.DoneMessage());
                    end;
                }
                // action(WanaMoveIncomingDocuments)
                // {
                //     Caption = 'Insert Incoming Documents';
                //     ApplicationArea = All;
                //     Image = CreateDocuments;
                //     trigger OnAction()
                //     var
                //         lRec: Record "Gen. Journal Line";
                //         ConfirmLbl: Label 'Do you want to create/update %1 Incoming Documents(s)?', Comment = '%1:Count';
                //         WanaMoveImportGenJnlLines: Codeunit "WanaMove Incoming Document";
                //     begin
                //         CurrPage.SetSelectionFilter(lRec);
                //         // lRec.SetRange("Account Type", Rec."Account Type"::Vendor);
                //         lRec.SetFilter("Incoming Document Entry No.", '<>0');
                //         if not Confirm(ConfirmLbl, false, Rec.Count) then
                //             exit;
                //         if lRec.FindSet() then
                //             repeat
                //                 WanaMoveImportGenJnlLines.UpdateIncomingDocument(lRec);
                //             until lRec.Next() = 0;

                //     end;
                // }
            }
        }
    }
}
