xmlport 87990 "WanaMove Reminder Entries"
{
    Caption = 'WanaMove Reminder Entries';
    Format = VariableText;
    FieldSeparator = '<TAB>';
    FieldDelimiter = '<None>';
    TableSeparator = '<NewLine><NewLine>';
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
                textelement(_01) { trigger OnBeforePassVariable() begin _01 := ReminderFinChargeEntry.FieldCaption("Entry No."); end; }
                textelement(_02) { trigger OnBeforePassVariable() begin _02 := ReminderFinChargeEntry.FieldCaption("No."); end; }
                textelement(_03) { trigger OnBeforePassVariable() begin _03 := ReminderFinChargeEntry.FieldCaption("Reminder Level"); end; }
                textelement(_04) { trigger OnBeforePassVariable() begin _04 := ReminderFinChargeEntry.FieldCaption("Posting Date"); end; }
                textelement(_05) { trigger OnBeforePassVariable() begin _05 := ReminderFinChargeEntry.FieldCaption("Document Date"); end; }
                textelement(_06) { trigger OnBeforePassVariable() begin _06 := ReminderFinChargeEntry.FieldCaption("Interest Posted"); end; }
                textelement(_07) { trigger OnBeforePassVariable() begin _07 := ReminderFinChargeEntry.FieldCaption("Interest Amount"); end; }
                textelement(_08) { trigger OnBeforePassVariable() begin _08 := ReminderFinChargeEntry.FieldCaption("Customer Entry No."); end; }
                textelement(_09) { trigger OnBeforePassVariable() begin _09 := ReminderFinChargeEntry.FieldCaption("Document Type"); end; }
                textelement(_10) { trigger OnBeforePassVariable() begin _10 := ReminderFinChargeEntry.FieldCaption("Document No."); end; }
                textelement(_11) { trigger OnBeforePassVariable() begin _11 := ReminderFinChargeEntry.FieldCaption("Remaining Amount"); end; }
                textelement(_12) { trigger OnBeforePassVariable() begin _12 := ReminderFinChargeEntry.FieldCaption("Customer No."); end; }
                textelement(_13) { trigger OnBeforePassVariable() begin _13 := ReminderFinChargeEntry.FieldCaption("User ID"); end; }
                textelement(_14) { trigger OnBeforePassVariable() begin _14 := ReminderFinChargeEntry.FieldCaption("Due Date"); end; }
                textelement(_15) { trigger OnBeforePassVariable() begin _15 := ReminderFinChargeEntry.FieldCaption(Canceled); end; }
            }

            tableelement(ReminderFinChargeEntry; "Reminder/Fin. Charge Entry")
            {
                fieldelement(_01; ReminderFinChargeEntry."Entry No.") { }
                fieldelement(_02; ReminderFinChargeEntry."No.") { }
                fieldelement(_03; ReminderFinChargeEntry."Reminder Level") { }
                fieldelement(_04; ReminderFinChargeEntry."Posting Date") { }
                fieldelement(_05; ReminderFinChargeEntry."Document Date") { }
                fieldelement(_06; ReminderFinChargeEntry."Interest Posted") { }
                fieldelement(_07; ReminderFinChargeEntry."Interest Amount") { }
                fieldelement(_08; ReminderFinChargeEntry."Customer Entry No.") { }
                fieldelement(_09; ReminderFinChargeEntry."Document Type") { }
                fieldelement(_10; ReminderFinChargeEntry."Document No.") { }
                fieldelement(_11; ReminderFinChargeEntry."Remaining Amount") { }
                fieldelement(_12; ReminderFinChargeEntry."Customer No.") { }
                fieldelement(_13; ReminderFinChargeEntry."User ID") { }
                fieldelement(_14; ReminderFinChargeEntry."Due Date") { }
                fieldelement(_15; ReminderFinChargeEntry.Canceled) { }

                trigger OnBeforeInsertRecord() // Import
                begin
                    CustLedgerEntry.SetCurrentKey("Document No.", "Customer No.", "Posting Date");
                    CustLedgerEntry.SetRange("Document No.", ReminderFinChargeEntry."Document No.");
                    CustLedgerEntry.SetRange("Customer No.", ReminderFinChargeEntry."Customer No.");
                    CustLedgerEntry.FindFirst();
                    NoOfLines += 1;
                    ReminderFinChargeEntry."Entry No." := NoOfLines;
                    ReminderFinChargeEntry."Customer Entry No." := CustLedgerEntry."Entry No.";
                end;

                trigger OnAfterGetRecord()
                begin
                    if CustLedgerEntry."Entry No." <> ReminderFinChargeEntry."Customer Entry No." then
                        if not CustLedgerEntry.Get(ReminderFinChargeEntry."Customer Entry No.") then // don't know why but there are some orphan reminder entries
                            CustLedgerEntry.Init();
                    if not CustLedgerEntry.Open then
                        currXMLport.Skip();
                end;
            }
        }
    }

    var
        NoOfLines: Integer;
        CustLedgerEntry: Record "Cust. Ledger Entry";
}
