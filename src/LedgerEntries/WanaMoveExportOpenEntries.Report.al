// Notes:
//  No Currency used
//  Mono posting group per customer/vendor
report 87901 "WanaMove Export Open Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'WanaMove Export Open Entries';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;

    dataset
    {
        dataitem(Customer; Customer)
        {
            RequestFilterFields = "No.";
            CalcFields = "Balance (LCY)", "Net Change (LCY)";
            dataitem(CustLedgerEntry; "Cust. Ledger Entry")
            {
                DataItemLinkReference = Customer;
                DataItemLink = "Customer No." = field("No.");
                DataItemTableView = sorting("Customer No.", Open) where(Open = const(true));
                CalcFields = "Remaining Amt. (LCY)";

                trigger OnAfterGetRecord()
                begin
                    Helper.Set(TempGenJournalLine,
                        "Source Code", "Posting Date", "Document Date", "Document Type", "Document No.",
                        TempGenJournalLine."Account Type"::Customer, "Customer No.", BalAccount."Consol. Credit Acc.",
                        Description, "Remaining Amt. (LCY)", "External Document No.", "Reason Code", "IC Partner Code",
                        "Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");
                    TempGenJournalLine."Due Date" := "Due Date";
                    TempGenJournalLine."Payment Method Code" := "Payment Method Code";
                    TempGenJournalLine."On Hold" := "On Hold";
                    TempGenJournalLine."Salespers./Purch. Code" := "Salesperson Code";
                    TempGenJournalLine."Sales/Purch. (LCY)" := "Sales (LCY)";
                    OnBeforeInsertCustLedgerEntry(TempGenJournalLine, CustLedgerEntry);
                    if TempGenJournalLine.Amount <> 0 then
                        TempGenJournalLine.Insert(false);
                    if "Posting Date" < FYStartingDate then
                        Customer."Net Change (LCY)" -= TempGenJournalLine.Amount;
                end;

                trigger OnPostDataItem()
                begin
                    FYStartingOpenBalance(TempGenJournalLine."Account Type"::Customer, Customer."No.", Customer."Net Change (LCY)");
                end;
            }
            trigger OnPreDataItem()
            begin
                SetRange("Date Filter", 0D, FYStartingDate - 1);
                Window.Update(1, TableCaption);
            end;

            trigger OnAfterGetRecord()
            begin
                if ("Balance (LCY)" = 0) and ("Net Change (LCY)" = 0) then
                    CurrReport.Skip();
                if CustomerPostingGroup.Code <> "Customer Posting Group" then begin
                    CustomerPostingGroup.Get("Customer Posting Group");
                    BalAccount.Get(CustomerPostingGroup."Receivables Account");
                    BalAccount.TestField("Consol. Credit Acc.");
                end;
            end;
        }
        dataitem(Vendor; Vendor)
        {
            RequestFilterFields = "No.";
            CalcFields = "Balance (LCY)", "Net Change (LCY)";
            dataitem(VendorLedgerEntry; "Vendor Ledger Entry")
            {
                DataItemLinkReference = Vendor;
                DataItemLink = "Vendor No." = field("No.");
                DataItemTableView = sorting("Vendor No.", Open) where(Open = const(true));
                CalcFields = "Remaining Amt. (LCY)";

                trigger OnAfterGetRecord()
                begin
                    Helper.Set(TempGenJournalLine,
                        "Source Code", "Posting Date", "Document Date", "Document Type", "Document No.",
                        TempGenJournalLine."Account Type"::Vendor, "Vendor No.", BalAccount."Consol. Credit Acc.",
                        Description, "Remaining Amt. (LCY)", "External Document No.", "Reason Code", "IC Partner Code",
                        "Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");
                    TempGenJournalLine."Due Date" := "Due Date";
                    TempGenJournalLine."Payment Method Code" := "Payment Method Code";
                    TempGenJournalLine."On Hold" := "On Hold";
                    TempGenJournalLine."Salespers./Purch. Code" := "Purchaser Code";
                    TempGenJournalLine."Sales/Purch. (LCY)" := "Purchase (LCY)";
                    OnBeforeInsertVendorLedgerEntry(TempGenJournalLine, VendorLedgerEntry);
                    if TempGenJournalLine.Amount <> 0 then
                        TempGenJournalLine.Insert(false);
                    if "Posting Date" < FYStartingDate then
                        Vendor."Net Change (LCY)" -= TempGenJournalLine.Amount;
                end;

                trigger OnPostDataItem()
                begin
                    FYStartingOpenBalance(TempGenJournalLine."Account Type"::Vendor, Vendor."No.", Vendor."Net Change (LCY)");
                end;
            }
            trigger OnPreDataItem()
            begin
                SetRange("Date Filter", 0D, FYStartingDate - 1);
                Window.Update(1, TableCaption);
            end;

            trigger OnAfterGetRecord()
            begin
                if ("Balance (LCY)" = 0) and ("Net Change (LCY)" = 0) then
                    CurrReport.Skip();
                if VendorPostingGroup.Code <> "Vendor Posting Group" then begin
                    VendorPostingGroup.Get("Vendor Posting Group");
                    BalAccount.Get(VendorPostingGroup."Payables Account");
                end;
                "Net Change (LCY)" *= -1; // because calcfomula reverse sign : - sum(...))
            end;
        }
        dataitem(GLAccount; "G/L Account")
        {
            DataItemTableView = where("Consol. Credit Acc." = filter('<>'''''));
            RequestFilterFields = "No.", "Consol. Credit Acc.";
            CalcFields = Balance, "Net Change";
            dataitem(GLEntry; "G/L Entry")
            {
                DataItemLink = "G/L Account No." = field("No.");
                DataItemTableView = sorting("G/L Account No.", "Letter") where(Letter = filter(''));

                trigger OnAfterGetRecord()
                begin
                    Helper.Set(TempGenJournalLine,
                        "Source Code", "Posting Date", "Document Date", "Document Type", "Document No.",
                        TempGenJournalLine."Account Type"::"G/L Account", GLAccount."Consol. Debit Acc.", BalAccount."Consol. Credit Acc.",
                        Description, Amount, "External Document No.", "Reason Code", '',
                        "Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");
                    OnBeforeInsertGLEntry(TempGenJournalLine, GLEntry);
                    if TempGenJournalLine.Amount <> 0 then
                        TempGenJournalLine.Insert(false);

                    if "Posting Date" < FYStartingDate then
                        GLAccount."Net Change" -= TempGenJournalLine.Amount;
                end;

                trigger OnPostDataItem()
                begin
                    FYStartingOpenBalance(TempGenJournalLine."Account Type"::"G/L Account", GLAccount."Consol. Debit Acc.", GLAccount."Net Change");
                end;
            }
            trigger OnPreDataItem()
            begin
                SetRange("Date Filter", 0D, FYStartingDate - 1);
                Window.Update(1, TableCaption);
            end;

            trigger OnAfterGetRecord()
            begin
                if ("Balance" = 0) and ("Net Change" = 0) then
                    CurrReport.Skip();
                BalAccount := GLAccount;
            end;
        }
        dataitem(BankAccount; "Bank Account")
        {
            RequestFilterFields = "No.";
            CalcFields = "Balance (LCY)", "Net Change (LCY)";

            dataitem(BankAccountLedgerEntry; "Bank Account Ledger Entry")
            {
                DataItemLinkReference = BankAccount;
                DataItemLink = "Bank Account No." = field("No.");
                DataItemTableView = sorting("Bank Account No.", Open) where(Open = const(true));

                trigger OnAfterGetRecord()
                begin
                    Helper.Set(TempGenJournalLine,
                        "Source Code", "Posting Date", "Document Date", "Document Type", "Document No.",
                        TempGenJournalLine."Account Type"::"Bank Account", "Bank Account No.", BalAccount."Consol. Credit Acc.",
                        Description, "Amount (LCY)", "External Document No.", "Reason Code", '',
                        "Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");
                    OnBeforeInsertBankAccountLedgerEntry(TempGenJournalLine, BankAccountLedgerEntry);
                    if TempGenJournalLine.Amount <> 0 then
                        TempGenJournalLine.Insert(false);

                    if "Posting Date" < FYStartingDate then
                        BankAccount."Net Change (LCY)" -= TempGenJournalLine.Amount;
                    BankAccount."Balance (LCY)" -= TempGenJournalLine.Amount;
                end;

                trigger OnPostDataItem()
                var
                    PostedReconciliationLbl: Label 'WanaMove Reprise rapprochement';
                begin
                    Helper.Set(TempGenJournalLine,
                        OpeningSourceCode, FYStartingDate - 1, 0D, "Document Type"::" ", OpeningDocumentNo,
                        TempGenJournalLine."Account Type"::"Bank Account", BankAccount."No.", BalAccount."Consol. Credit Acc.",
                        PostedReconciliationLbl, BankAccount."Net Change (LCY)", '', '', '',
                        0, '', '');
                    if TempGenJournalLine.Amount <> 0 then
                        TempGenJournalLine.Insert(false);
                    Helper.Set(TempGenJournalLine,
                        OpeningSourceCode, OpeningDate - 1, 0D, "Document Type"::" ", OpeningDocumentNo,
                        TempGenJournalLine."Account Type"::"Bank Account", BankAccount."No.", BalAccount."Consol. Credit Acc.",
                        PostedReconciliationLbl, BankAccount."Balance (LCY)" - BankAccount."Net Change (LCY)", '', '', '',
                        0, '', '');
                    if TempGenJournalLine.Amount <> 0 then
                        TempGenJournalLine.Insert(false);
                end;
            }
            trigger OnPreDataItem()
            begin
                SetRange("Date Filter", 0D, FYStartingDate - 1);
                Window.Update(1, TableCaption);
            end;

            trigger OnAfterGetRecord()
            begin
                if ("Balance (LCY)" = 0) and ("Net Change (LCY)" = 0) then
                    CurrReport.Skip();
                if "Bank Acc. Posting Group" <> BankAccountPostingGroup.Code then begin
                    BankAccountPostingGroup.Get("Bank Acc. Posting Group");
                    BalAccount.Get(BankAccountPostingGroup."G/L Account No.");
                    BalAccount.TestField("Consol. Credit Acc.");
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
                    field(OpeningSourceCode; OpeningSourceCode)
                    {
                        Caption = 'Opening Source Code';
                        TableRelation = "Source Code";
                    }
                    field(OpeningDate; OpeningDate)
                    {
                        Caption = 'Opening Date';
                    }
                    field(OpeningDocumentNo; OpeningDocumentNo)
                    {
                        Caption = 'Opening DocumentNo';
                    }
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        Window.Open('#1############################');
        Helper.Initialize(FYStartingDate, OpeningDate);
        StartTime := CurrentDateTime;
        TempGenJournalLine."Line No." := 0;
    end;

    trigger OnPostReport()
    var
        DoneMsg: Label 'Process Time : %1';
    begin
        Helper.Export(TempGenJournalLine, CurrReport.ObjectId(true).Substring(8) + '.txt');
        Window.Close();
        Message(DoneMsg, CurrentDateTime - StartTime)
    end;

    var
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        Helper: Codeunit "WanaMove Export Helper";
        FYStartingDate: Date;
        OpeningSourceCode: Code[10];
        OpeningDate: Date;
        OpeningDocumentNo: Code[20];
        Window: Dialog;
        StartTime: DateTime;
        CustomerPostingGroup: Record "Customer Posting Group";
        VendorPostingGroup: Record "Vendor Posting Group";
        BankAccountPostingGroup: Record "Bank Account Posting Group";
        BalAccount: Record "G/L Account";

    local procedure FYStartingOpenBalance(pAccountType: Integer; pAccountNo: Code[20]; pAmount: Decimal)
    var
        AppliedOnFiscalYearLbl: Label 'WanaMove Reprise lettrage';
    begin
        if pAmount = 0 then
            exit;
        Helper.Set(TempGenJournalLine,
            OpeningSourceCode, FYStartingDate - 1, 0D, 0, OpeningDocumentNo, pAccountType, pAccountNo, BalAccount."Consol. Credit Acc.",
            AppliedOnFiscalYearLbl, pAmount, '', '', '', 0, '', '');
        TempGenJournalLine."Applies-to ID" := OpeningDocumentNo;
        OnBeforeInsertFYStartingDateBalance(TempGenJournalLine);
        TempGenJournalLine.Insert(false);
        Helper.Set(TempGenJournalLine,
            OpeningSourceCode, OpeningDate - 1, 0D, 0, OpeningDocumentNo, pAccountType, pAccountNo, BalAccount."Consol. Credit Acc.",
            AppliedOnFiscalYearLbl, -pAmount, '', '', '', 0, '', '');
        TempGenJournalLine."Applies-to ID" := OpeningDocumentNo;
        OnBeforeInsertFYStartingDateBalance(TempGenJournalLine);
        TempGenJournalLine.Insert(false);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertCustLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertVendorLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertGLEntry(var GenJournalLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertBankAccountLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFYStartingDateBalance(var GenJournalLine: Record "Gen. Journal Line")
    begin
    end;
}
