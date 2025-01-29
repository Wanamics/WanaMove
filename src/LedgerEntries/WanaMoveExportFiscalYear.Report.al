report 87902 "WanaMove Export Fiscal Year"
{
    ApplicationArea = Basic, Suite;
    Caption = 'WanaMove Export Fiscal Year';
    ProcessingOnly = true;
    UsageCategory = ReportsAndAnalysis;
    // DataAccessIntent = ReadOnly; 

    dataset
    {
        dataitem("G/L Account"; "G/L Account")
        {
            RequestFilterFields = "No.", "Income/Balance";
            DataItemTableView = where("Account Type" = const(Posting), "Balance at Date" = filter('<>0'));
            CalcFields = "Balance at Date";
            trigger OnPreDataItem()
            begin
                Window.Update(1, TableCaption);
                SetRange("Date Filter", 0D, FYStartingDate - 1);
            end;

            trigger OnAfterGetRecord()
            begin
                Helper.Set(TempGenJournalLine,
                    Opening."Source Code", FYStartingDate - 1, 0D, 0, Opening."Document No.",
                    TempGenJournalLine."Account Type"::"G/L Account", "No.", '',
                    Name, "Balance at Date", '', '', '',
                    0, '', '');
                OnBeforeInsertOpeningBalance(TempGenJournalLine, "G/L Account");
                TempGenJournalLine.Insert(false);
            end;
        }
        dataitem(SourceCodeDetails; "Source Code")
        {
            RequestFilterFields = Code;
            RequestFilterHeading = 'SourceCode Details';
            dataitem("G/L Entry"; "G/L Entry")
            {
                DataItemTableView = sorting("Source Code", "Posting Date", "Document No.");
                DataItemLinkReference = SourceCodeDetails;
                DataItemLink = "Source Code" = field(Code);
                trigger OnPreDataItem()
                begin
                    SetFilter("Posting Date", '>=%1', FYStartingDate);
                end;

                trigger OnAfterGetRecord()
                begin
                    Helper.Set(TempGenJournalLine,
                        "Source Code", "Posting Date", "Document Date", "Document Type", "Document No.",
                        TempGenJournalLine."Account Type"::"G/L Account", "G/L Account No.", '',
                        Description, Amount, "External Document No.", "Reason Code", "IC Partner Code",
                        "Dimension Set ID", "Global Dimension 1 Code", "Global Dimension 2 Code");
                    TempGenJournalLine."Source Type" := "Source Type";
                    TempGenJournalLine."Source No." := "Source No.";
                    TempGenJournalLine.Quantity := Quantity;
                    OnBeforeInsertSourceCodeDetails(TempGenJournalLine, "G/L Entry");
                    TempGenJournalLine.Insert(false);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if not SourceCodeWithDetails.Contains(Code) then
                    CurrReport.Skip()
                else
                    Window.Update(1, TableCaption + ' ' + Description + ' Details');
            end;
        }
        dataitem(SourceCodeCompression; "Source Code")
        {
            RequestFilterFields = Code;
            RequestFilterHeading = 'SourceCode Compression';
            dataitem(Income; Integer)
            {
                DataItemTableView = sorting(Number);
                trigger OnPreDataItem()
                begin
                    CompressIncome.SetRange(SourceCode, SourceCodeCompression.Code);
                    CompressIncome.SetFilter(GLAccountNo, '6..');
                    CompressIncome.SetFilter(PostingDateFilter, '>=%1', FYStartingDate);
                    CompressIncome.Open();
                end;

                trigger OnAfterGetRecord()
                begin
                    if not CompressIncome.Read() then
                        CurrReport.Break();
                    Helper.Set(TempGenJournalLine,
                        CompressIncome.SourceCode, PostingDate(CompressIncome.PostingDateMonth, CompressIncome.PostingDateYear), 0D, 0, AppendYearMonth(Opening."Document No.", CompressIncome.PostingDateYear, CompressIncome.PostingDateMonth),
                        TempGenJournalLine."Account Type"::"G/L Account", CompressIncome.GLAccountNo, '',
                        StrSubstNo('Compression %1', CompressIncome.GLAccountNo), CompressIncome.Amount, '', '', '',
                        CompressIncome.DimensionSetID, CompressIncome.GlobalDimension1Code, CompressIncome.GlobalDimension2Code);
                    OnBeforeInsertSourceCodeCompressIncome(TempGenJournalLine, CompressIncome);
                    If TempGenJournalLine.Amount <> 0 then
                        TempGenJournalLine.Insert(false);
                end;
            }
            dataitem(Balance; Integer)
            {
                DataItemTableView = sorting(Number);
                trigger OnPreDataItem()
                begin
                    CompressBalance.SetRange(SourceCode, SourceCodeCompression.Code);
                    CompressBalance.SetFilter(GLAccountNo, '..599999');
                    CompressBalance.SetFilter(PostingDateFilter, '>=%1', FYStartingDate);
                    CompressBalance.Open();
                end;

                trigger OnAfterGetRecord()
                begin
                    if not CompressBalance.Read() then
                        CurrReport.Break();
                    Helper.Set(TempGenJournalLine,
                        CompressBalance.SourceCode, PostingDate(CompressBalance.PostingDateMonth, CompressBalance.PostingDateYear), 0D, 0, AppendYearMonth(Opening."Document No.", CompressBalance.PostingDateYear, CompressBalance.PostingDateMonth),
                        TempGenJournalLine."Account Type"::"G/L Account", CompressBalance.GLAccountNo, '',
                        StrSubstNo('Compression %1', CompressBalance.GLAccountNo), CompressBalance.Amount, '', '', '',
                        0, '', '');
                    OnBeforeInsertSourceCodeCompressBalance(TempGenJournalLine, CompressBalance);
                    If TempGenJournalLine.Amount <> 0 then
                        TempGenJournalLine.Insert(false);
                end;
            }

            trigger OnAfterGetRecord()
            begin
                if SourceCodeWithDetails.Contains(Code) then
                    CurrReport.Skip()
                else
                    if ApplicationSourceCode(Code) then
                        CurrReport.Skip()
                    else
                        Window.Update(1, TableCaption + ' ' + Description + ' Compression');
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
                    field(OpeningSourceCode; Opening."Source Code")
                    {
                        Caption = 'Opening Source Code';
                        TableRelation = "Source Code";
                    }
                    field(OpeningDate; Opening."Posting Date")
                    {
                        Caption = 'Opening Date';
                    }
                    field(OpeningDocumentNo; Opening."Document No.")
                    {
                        Caption = 'Opening DocumentNo';
                    }
                }
            }
        }
    }

    trigger OnPreReport()
    begin
        StartTime := CurrentDateTime;
        Window.Open('#1############################');
        Helper.Initialize(FYStartingDate, Opening."Posting Date");
        SourceCodeSetup.Get();
        OnInitializeSourceCodeWithDetails(SourceCodeWithDetails);
    end;

    trigger OnPostReport()
    var
        DoneMsg: Label 'Process Time : %1';
    begin
        Helper.Export(TempGenJournalLine, CurrReport.ObjectId(true).Substring(8) + '.txt');
        Window.Close();
        Message(DoneMsg, CurrentDateTime - StartTime);
    end;

    var
        Helper: Codeunit "WanaMove Export Helper";
        FYStartingDate: Date;
        Opening: Record "Gen. Journal Line";
        SourceCodeWithDetails: list of [Code[10]];
        CompressIncome: Query "WanaMove Compress Income";
        CompressBalance: Query "WanaMove Compress Balance";
        Window: Dialog;
        StartTime: DateTime;
        TempGenJournalLine: Record "Gen. Journal Line" temporary;
        SourceCodeSetup: Record "Source Code Setup";

    local procedure ApplicationSourceCode(pSourceCode: Code[10]): Boolean
    begin
        exit(pSourceCode in [
            SourceCodeSetup."Sales Entry Application",
            SourceCodeSetup."Employee Entry Application",
            SourceCodeSetup."Purchase Entry Application",
            SourceCodeSetup."Unapplied Sales Entry Appln.",
            SourceCodeSetup."Unapplied Purch. Entry Appln.",
            SourceCodeSetup."Unapplied Empl. Entry Appln."]);
    end;

    local procedure AppendYearMonth(pDocumentNo: Code[20]; pYear: Integer; pMonth: Integer): Code[20]
    begin
        exit(pDocumentNo + format(DMY2Date(1, pMonth, pYear), 0, '<Year><Month,2>'));
    end;

    local procedure PostingDate(pPostingDateMonth: Integer; pPostingDateYear: Integer) ReturnValue: Date
    begin
        ReturnValue := CalcDate('<+CM>', DMY2Date(1, pPostingDateMonth, pPostingDateYear));
        if ReturnValue >= Opening."Posting Date" then
            ReturnValue := Opening."Posting Date" - 1;
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertOpeningBalance(var GenJournalLine: Record "Gen. Journal Line"; GLAccount: Record "G/L Account")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSourceCodeDetails(var GenJournalLine: Record "Gen. Journal Line"; GLEntry: Record "G/L Entry")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSourceCodeCompressIncome(var GenJournalLine: Record "Gen. Journal Line"; GLEntries: Query "WanaMove Compress Income")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeInsertSourceCodeCompressBalance(var GenJournalLine: Record "Gen. Journal Line"; GLEntries: Query "WanaMove Compress Balance")
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnInitializeSourceCodeWithDetails(var SourceCodeWithDetails: List of [Code[10]])
    begin
    end;

    // [IntegrationEvent(false, false)]
    // local procedure OnInitializeIndirectPostingAccounts(var IndirectPostingAccounts: Dictionary of [Code[20], Code[20]])
    // begin
    // end;
}
