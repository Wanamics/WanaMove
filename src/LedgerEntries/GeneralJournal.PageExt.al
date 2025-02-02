pageextension 87990 "WanaMove General Journal" extends "General Journal"
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
                action(WanaMoveImport)
                {
                    Caption = 'Import WanaMove';
                    ApplicationArea = All;
                    Image = ImportChartOfAccounts;
                    trigger OnAction()
                    var
                        DeleteLines: Label 'Do you want to delete %1 previous lines?';
                        WanaMoveToGenJournalLine: XmlPort "WanaMove To Gen. Journal Line";
                    begin
                        if not Rec.IsEmpty then
                            if not Confirm(DeleteLines, false, Rec.Count) then
                                exit
                            else
                                Rec.DeleteAll(true);
                        WanaMoveToGenJournalLine.SetGenJournalLine(Rec);
                        WanaMoveToGenJournalLine.Run();
                        Message(WanaMoveToGenJournalLine.DoneMessage());
                    end;
                }
            }
        }
    }
}
