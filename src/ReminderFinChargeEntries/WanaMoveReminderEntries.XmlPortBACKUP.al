/*
xmlport 87990 "WanaMove Reminder Entries"
{
    Caption = 'WanaMove Reminder Entries';
    Format = VariableText;
    FieldSeparator = '<TAB>';
    FieldDelimiter = '<None>';
    // TableSeparator = '<NewLine><NewLine>';
    TextEncoding = UTF8;
    UseRequestPage = false;
    DefaultFieldsValidation = false;
    FormatEvaluate = Xml;

    schema
    {
        textelement(Root)
        {
            tableelement(Header; Integer)
            {
                SourceTableView = sorting(Number) where(Number = const(1));
                AutoReplace = false;
                AutoUpdate = false;
                AutoSave = false;
                textelement(_01) { trigger OnBeforePassVariable() begin _01 := TempReminderFinChargeEntry.FieldCaption("Entry No."); end; }
                textelement(_02) { trigger OnBeforePassVariable() begin _02 := TempReminderFinChargeEntry.FieldCaption("No."); end; }
                textelement(_03) { trigger OnBeforePassVariable() begin _03 := TempReminderFinChargeEntry.FieldCaption("Reminder Level"); end; }
                textelement(_04) { trigger OnBeforePassVariable() begin _04 := TempReminderFinChargeEntry.FieldCaption("Posting Date"); end; }
                textelement(_05) { trigger OnBeforePassVariable() begin _05 := TempReminderFinChargeEntry.FieldCaption("Document Date"); end; }
                textelement(_06) { trigger OnBeforePassVariable() begin _06 := TempReminderFinChargeEntry.FieldCaption("Interest Posted"); end; }
                textelement(_07) { trigger OnBeforePassVariable() begin _07 := TempReminderFinChargeEntry.FieldCaption("Interest Amount"); end; }
                textelement(_08) { trigger OnBeforePassVariable() begin _08 := TempReminderFinChargeEntry.FieldCaption("Customer Entry No."); end; }
                textelement(_09) { trigger OnBeforePassVariable() begin _09 := TempReminderFinChargeEntry.FieldCaption("Document Type"); end; }
                textelement(_10) { trigger OnBeforePassVariable() begin _10 := TempReminderFinChargeEntry.FieldCaption("Document No."); end; }
                textelement(_11) { trigger OnBeforePassVariable() begin _11 := TempReminderFinChargeEntry.FieldCaption("Remaining Amount"); end; }
                textelement(_12) { trigger OnBeforePassVariable() begin _12 := TempReminderFinChargeEntry.FieldCaption("Customer No."); end; }
                textelement(_13) { trigger OnBeforePassVariable() begin _13 := TempReminderFinChargeEntry.FieldCaption("User ID"); end; }
                textelement(_14) { trigger OnBeforePassVariable() begin _14 := TempReminderFinChargeEntry.FieldCaption("Due Date"); end; }
                textelement(_15) { trigger OnBeforePassVariable() begin _15 := TempReminderFinChargeEntry.FieldCaption(Canceled); end; }
            }

            tableelement(CustLedgerEntry; "Cust. Ledger Entry")
            {
                SourceTableView = where(Open = const(true));
                tableelement(TempReminderFinChargeEntry; "Reminder/Fin. Charge Entry")
                {
                    LinkTable = Custledgerentry;
                    LinkFields = "Customer Entry No." = field("Entry No.");
                    UseTemporary = true;
                    AutoSave = false;
                    fieldelement(_01; TempReminderFinChargeEntry."Entry No.") { }
                    fieldelement(_02; TempReminderFinChargeEntry."No.") { }
                    fieldelement(_03; TempReminderFinChargeEntry."Reminder Level") { }
                    fieldelement(_04; TempReminderFinChargeEntry."Posting Date") { }
                    fieldelement(_05; TempReminderFinChargeEntry."Document Date") { }
                    fieldelement(_06; TempReminderFinChargeEntry."Interest Posted") { }
                    fieldelement(_07; TempReminderFinChargeEntry."Interest Amount") { }
                    fieldelement(_08; TempReminderFinChargeEntry."Customer Entry No.") { }
                    fieldelement(_09; TempReminderFinChargeEntry."Document Type") { }
                    fieldelement(_10; TempReminderFinChargeEntry."Document No.") { }
                    fieldelement(_11; TempReminderFinChargeEntry."Remaining Amount") { }
                    fieldelement(_12; TempReminderFinChargeEntry."Customer No.") { }
                    fieldelement(_13; TempReminderFinChargeEntry."User ID") { }
                    fieldelement(_14; TempReminderFinChargeEntry."Due Date") { }
                    fieldelement(_15; TempReminderFinChargeEntry.Canceled) { }

                    trigger OnAfterGetRecord()
                    begin
                        TempReminderFinChargeEntry.SetCurrentKey("Customer Entry No.");
                        TempReminderFinChargeEntry.SetRange("Customer Entry No.", CustLedgerEntry."Entry No.");
                        if TempReminderFinChargeEntry.IsEmpty then
                            currXMLport.Skip();
                    end;

                    trigger OnBeforeInsertRecord() // Import
                    var
                        CustLedgerEntry: Record "Cust. Ledger Entry";
                    begin
                        if not HeaderSkipped then begin
                            HeaderSkipped := true;
                            currXMLport.Skip();
                        end;
                        ReminderFinChargeEntry.TransferFields(TempReminderFinChargeEntry, false);
                        ReminderFinChargeEntry."Entry No." += 1;
                        CustLedgerEntry.SetCurrentKey("Document No.", "Customer No.", "Posting Date");
                        CustLedgerEntry.SetRange("Document No.", ReminderFinChargeEntry."Document No.");
                        CustLedgerEntry.SetRange("Customer No.", ReminderFinChargeEntry."Customer No.");
                        CustLedgerEntry.SetRange("Posting Date", ReminderFinChargeEntry."Posting Date");
                        CustLedgerEntry.FindFirst();
                        ReminderFinChargeEntry."Customer Entry No." := CustLedgerEntry."Entry No.";
                        // ValidateFields(ReminderFinChargeEntry);
                        ReminderFinChargeEntry.Insert(true);
                        NoOfLines += 1;
                    end;
                }
            }
        }
    }
    // requestpage
    // {
    //     layout
    //     {
    //         area(Content)
    //         {
    //             group(Options)
    //             {
    //             }
    //         }
    //     }
    // }
    trigger OnPreXmlPort()
    begin
        StartDateTime := CurrentDateTime;
    end;

    var
        StartDateTime: DateTime;
        ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry";
        NoOfLines: Integer;
        HeaderSkipped: Boolean;

    procedure ExportFrom(var ReminderFinChargeEntry: Record "Reminder/Fin. Charge Entry")
    begin
        if ReminderFinChargeEntry.FindSet() then
            repeat
                TempReminderFinChargeEntry := ReminderFinChargeEntry;
                TempReminderFinChargeEntry.Insert(false);
            until ReminderFinChargeEntry.Next() = 0;
    end;

    // procedure DoneMessage(): Text
    // var
    //     ImportDoneMsg: Label '%1 lines imported in %2.';
    // begin
    //     if CurrentDateTime <> 0DT then
    //         exit(StrSubstNo(ImportDoneMsg, NoOfLines, CurrentDateTime - StartDateTime));
    // end;
}
*/
