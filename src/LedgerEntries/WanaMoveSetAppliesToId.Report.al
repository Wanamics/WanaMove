report 87994 "WanaMove Set Applies-to ID"
{
    ApplicationArea = All;
    Caption = 'WanaMove Set Applies-to ID';
    UsageCategory = Administration;
    ProcessingOnly = true;
    dataset
    {
        dataitem("Cust. Ledger Entry"; "Cust. Ledger Entry")
        {
            RequestFilterFields = "Document No.", "Posting Date", Description;
            DataItemTableView = sorting(Open) where(Open = const(true));
            trigger OnPreDataItem()
            begin
                if GetFilter("Document No.") = '' then
                    TestField("Document No.");
                if Confirm('Do you want to set %1 for %2 "%3"?', false, FieldCaption("Applies-to ID"), Count, TableCaption) then
                    ModifyAll("Applies-to ID", GetFilter("Document No."));
            end;
        }
        dataitem("Vendor Ledger Entry"; "Vendor Ledger Entry")
        {
            RequestFilterFields = "Document No.", "Posting Date", Description;
            DataItemTableView = sorting(Open) where(Open = const(true));
            trigger OnPreDataItem()
            begin
                if GetFilter("Document No.") = '' then
                    TestField("Document No.");
                if Confirm('Do you want to set %1 for %2 "%3"?', false, FieldCaption("Applies-to ID"), Count, TableCaption) then
                    ModifyAll("Applies-to ID", GetFilter("Document No."));
            end;
        }
    }
    requestpage
    {
        SaveValues = true;
    }
    trigger OnPostReport()
    begin
        Message('Done, you should now run "Apply Cust. ledger Entries" and "Apply Vendor ledger Entries" reports (WanApply)');
    end;
}
