report 87993 "WanaMove Export FA Entries"
{
    ApplicationArea = Basic, Suite;
    Caption = 'WanaMove Export FA Entries';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    // DataAccessIntent = ReadOnly; 

    dataset
    {
        dataitem("FA Depreciation Book"; "FA Depreciation Book")
        {
            RequestFilterFields = "FA No.";
            CalcFields = "Acquisition Cost", Depreciation;
            dataitem(FALedgerEntry; "FA Ledger Entry")
            {
                DataItemLink = "FA No." = field("FA No.");
                DataItemTableView =
                    sorting("FA No.", "Depreciation Book Code", "FA Posting Date")
                    where("FA Posting Type" = filter("Acquisition Cost" | "Depreciation" | Appreciation | "Write-Down" | "Proceeds on Disposal"));
                trigger OnPreDataItem()
                begin
                    FYStartingDepreciation := 0;
                    ProceedsOnDisposalAmount := 0;
                end;

                trigger OnAfterGetRecord()
                begin
                    if ("FA Posting Type" = "FA Posting Type"::"Depreciation") and ("Posting Date" < FYStartingDate) then
                        FYStartingDepreciation += "Amount (LCY)"
                    else
                        if "FA Posting Type" = "FA Posting Type"::"Proceeds on Disposal" then
                            ProceedsOnDisposalAmount := "Amount (LCY)"
                        else
                            if "FA Posting Category" = "FA Posting Category"::Disposal then begin
                                if "FA Posting Type" = "FA Posting Type"::"Acquisition Cost" then begin
                                    Helper.Set(TempGenJournalLine,
                                        "Source Code", "Posting Date", "Document Date", "Document Type", "Document No.",
                                        TempGenJournalLine."Account Type"::"Fixed Asset", "FA No.", BalAccount."Consol. Credit Acc.",
                                        Description, -ProceedsOnDisposalAmount, "External Document No.", "Reason Code", '',
                                        "Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");
                                    TempGenJournalLine."Depreciation Book Code" := "Depreciation Book Code";
                                    TempGenJournalLine."FA Posting Type" := TempGenJournalLine."FA Posting Type"::Disposal;
                                    TempGenJournalLine."Posting Group" := "FA Posting Group";
                                    //?? Amortir jusqu'à date cession ?
                                    OnBeforeInsertFALedgerEntry(TempGenJournalLine, FALedgerEntry);
                                    TempGenJournalLine.Insert(false); // Amount is null
                                end
                            end else begin
                                Helper.Set(TempGenJournalLine,
                                    "Source Code", "Posting Date", "Document Date", "Document Type", "Document No.",
                                    TempGenJournalLine."Account Type"::"Fixed Asset", "FA No.", BalAccount."Consol. Credit Acc.",
                                    Description, "Amount (LCY)", "External Document No.", "Reason Code", '',
                                    "Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");
                                TempGenJournalLine."Depreciation Book Code" := "Depreciation Book Code";

                                case "FA Posting Type" of
                                    "FA Posting Type"::"Acquisition Cost":
                                        TempGenJournalLine."FA Posting Type" := TempGenJournalLine."FA Posting Type"::"Acquisition Cost";
                                    "FA Posting Type"::"Appreciation":
                                        TempGenJournalLine."FA Posting Type" := TempGenJournalLine."FA Posting Type"::"Appreciation";
                                    "FA Posting Type"::Depreciation:
                                        TempGenJournalLine."FA Posting Type" := TempGenJournalLine."FA Posting Type"::Depreciation;
                                    "FA Posting Type"::"Write-Down":
                                        TempGenJournalLine."FA Posting Type" := TempGenJournalLine."FA Posting Type"::"Write-Down";
                                end;
                                TempGenJournalLine."Posting Group" := "FA Posting Group";
                                OnBeforeInsertFALedgerEntry(TempGenJournalLine, FALedgerEntry);
                                if TempGenJournalLine.Amount <> 0 then
                                    TempGenJournalLine.Insert(false);
                            end;
                end;

                trigger OnPostDataItem()
                begin
                    if FYStartingDepreciation <> 0 then begin
                        Helper.Set(TempGenJournalLine,
                            OpeningSourceCode, FYStartingDate - 1, 0D, 0, OpeningDocumentNo,
                            TempGenJournalLine."Account Type"::"Fixed Asset", "FA No.", BalAccount."Consol. Credit Acc.",
                            FixedAsset.Description, FYStartingDepreciation, '', '', '',
                            0, FixedAsset."Global Dimension 1 Code", FixedAsset."Global Dimension 2 Code");
                        TempGenJournalLine."Depreciation Book Code" := "Depreciation Book Code";
                        TempGenJournalLine."FA Posting Type" := TempGenJournalLine."FA Posting Type"::Depreciation;
                        TempGenJournalLine."Posting Group" := "FA Posting Group";
                        OnBeforeInsertFADepreciationBook(TempGenJournalLine, "FA Depreciation Book");
                        TempGenJournalLine.Insert(false);
                    end;
                end;
            }

            trigger OnPreDataItem()
            begin
                Window.Update(1, TableCaption);
                FASetup.Get();
                SetRange("Depreciation Book Code", FASetup."Default Depr. Book");
            end;

            trigger OnAfterGetRecord()
            begin
                if ("Disposal Date" <> 0D) and ("Disposal Date" < FYStartingDate) then
                    CurrReport.Skip();
                if "FA Posting Group" = '' then
                    CurrReport.Skip();
                if not FixedAsset.Get("FA No.") then
                    CurrReport.Skip();
                if "FA Posting Group" <> FAPostingGroup.Code then begin
                    FAPostingGroup.Get("FA Posting Group");
                    BalAccount.Get(FAPostingGroup."Acquisition Cost Account");
                end;
                if BalAccount."Consol. Credit Acc." = '' then
                    CurrReport.Skip();
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
                        ApplicationArea = All;
                        Caption = 'Opening Source Code';
                        TableRelation = "Source Code";
                    }
                    field(OpeningDate; OpeningDate)
                    {
                        ApplicationArea = All;
                        Caption = 'Opening Date';
                    }
                    field(OpeningDocumentNo; OpeningDocumentNo)
                    {
                        ApplicationArea = All;
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
        FASetup: Record "FA Setup";
        FixedAsset: Record "Fixed Asset";
        Window: Dialog;
        StartTime: DateTime;
        FAPostingGroup: Record "FA Posting Group";
        BalAccount: Record "G/L Account";
        FYStartingDepreciation: Decimal;
        ProceedsOnDisposalAmount: Decimal;

    // local procedure FYStartingOpenBalance(pAccountType: Integer; pAccountNo: Code[20]; pAmount: Decimal)
    // var
    //     AppliedOnFiscalYearLbl: Label 'WanaMove Reprise lettrage';
    // begin
    //     if pAmount = 0 then
    //         exit;
    //     Helper.Set(TempGenJournalLine,
    //         OpeningSourceCode, FYStartingDate - 1, 0D, 0, OpeningDocumentNo, pAccountType, pAccountNo, BalAccount."Consol. Credit Acc.",
    //         AppliedOnFiscalYearLbl, pAmount, '', '', '', 0, '', '');
    //     TempGenJournalLine."Applies-to ID" := OpeningDocumentNo;
    //     OnBeforeInsertFYStartingDateBalance(TempGenJournalLine);
    //     TempGenJournalLine.Insert(false);
    //     Helper.Set(TempGenJournalLine,
    //         OpeningSourceCode, OpeningDate - 1, 0D, 0, OpeningDocumentNo, pAccountType, pAccountNo, BalAccount."Consol. Credit Acc.",
    //         AppliedOnFiscalYearLbl, -pAmount, '', '', '', 0, '', '');
    //     TempGenJournalLine."Applies-to ID" := OpeningDocumentNo;
    //     OnBeforeInsertFYStartingDateBalance(TempGenJournalLine);
    //     TempGenJournalLine.Insert(false);
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeInsertCustLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; CustLedgerEntry: Record "Cust. Ledger Entry")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeInsertVendorLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; VendorLedgerEntry: Record "Vendor Ledger Entry")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeInsertBankAccountLedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; BankAccountLedgerEntry: Record "Bank Account Ledger Entry")
    // begin
    // end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFALedgerEntry(var GenJournalLine: Record "Gen. Journal Line"; FALedgerEntry: Record "FA Ledger Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertFADepreciationBook(var GenJournalLine: Record "Gen. Journal Line"; FADepreciationBook: Record "FA Depreciation Book")
    begin
    end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeInsertGLEntry(var GenJournalLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry")
    // begin
    // end;

    // [IntegrationEvent(false, false)]
    // local procedure OnBeforeInsertFYStartingDateBalance(var GenJournalLine: Record "Gen. Journal Line")
    // begin
    // end;
}
