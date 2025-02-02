Codeunit 87990 "WanaMove Export Helper"
{
    var
        AccountMap: Dictionary of [Code[20], Code[20]];
        FieldSeparator: Text[1];

    procedure Initialize(var pFYStartingDate: Date; pOpeningDate: Date)
    var
        AccountingPeriod: Record "Accounting Period";
        GLEntry: Record "G/L Entry";
        MustBeBeforeOpeningDateErr: Label 'must be before Opening Date';
    begin
        AccountingPeriod.SetRange("New Fiscal Year", true);
        AccountingPeriod.SetRange(Closed, false);
        AccountingPeriod.FindFirst();
        pFYStartingDate := AccountingPeriod."Starting Date";

        GLEntry.SetCurrentKey("Posting Date");
        GLEntry.FindLast();
        if GLEntry."Posting Date" >= pOpeningDate then
            GLEntry.FieldError("Posting Date", MustBeBeforeOpeningDateErr);

        InitializeAccountMap(AccountMap)
    end;

    local procedure InitializeAccountMap(var pAccountMap: Dictionary of [Code[20], Code[20]])
    var
        GLAccount: Record "G/L Account";
    begin
        GLAccount.SetFilter("Consol. Debit Acc.", '<>%', '');
        if GLAccount.FindSet() then
            repeat
                if GLAccount."Consol. Credit Acc." <> '' then
                    pAccountMap.Add(GLAccount."No.", GLAccount."Consol. Credit Acc.")
                else
                    pAccountMap.Add(GLAccount."No.", GLAccount."Consol. Debit Acc.");
            until GLAccount.Next() = 0;
        OnAfterInitializeAccountMap(pAccountMap);
        FieldSeparator[1] := 9; // Tab
    end;

    procedure Set(var pGenJournalLine: Record "Gen. Journal Line";
        pSourceCode: Code[10]; pPostingDate: Date; pDocumentDate: Date; pDocumentType: Integer; pDocumentNo: Code[20];
        pAccountType: Integer; pAccountNo: Code[20]; pBalAccount: Code[20];
        pDescription: Text[100]; pAmount: Decimal; pExternalDocumentNo: Code[35]; pReasonCode: Code[10]; pICPartnerCode: Code[20];
        pDimensionSetID: Integer; pGlobalDimension1Code: Code[20]; pGlobalDimension2Code: Code[20])
    begin
        pGenJournalLine.Init();
        pGenJournalLine."Line No." += 1;
        pGenJournalLine."Source Code" := pSourceCode;
        pGenJournalLine."Posting Date" := pPostingDate;
        pGenJournalLine."Document Date" := pDocumentDate;
        pGenJournalLine."Document Type" := pDocumentType;
        pGenJournalLine."Document No." := pDocumentNo;
        pGenJournalLine."Account Type" := pAccountType;
        if (pGenJournalLine."Account Type" = pGenJournalLine."Account Type"::"G/L Account") and (pBalAccount = '') then
            pGenJournalLine."Account No." := ToAccount(pAccountNo)
        else
            pGenJournalLine."Account No." := pAccountNo;
        pGenJournalLine.Description := DelChr(pDescription, '=', FieldSeparator);
        pGenJournalLine.Amount := pAmount;
        pGenJournalLine."External Document No." := pExternalDocumentNo;
        pGenJournalLine."Reason Code" := pReasonCode;
        pGenJournalLine."IC Partner Code" := pICPartnerCode;
        pGenJournalLine."Bal. Account No." := pBalAccount;
        pGenJournalLine."Dimension Set ID" := pDimensionSetID;
        pGenJournalLine."Shortcut Dimension 1 Code" := pGlobalDimension1Code;
        pGenJournalLine."Shortcut Dimension 2 Code" := pGlobalDimension2Code;
    end;

    local procedure ToAccount(pAccountNo: Code[20]): Code[20];
    begin
        if AccountMap.ContainsKey(pAccountNo) then
            exit(AccountMap.Get(pAccountNo))
        else
            exit(pAccountNo);
    end;

    procedure Export(var pGenJournalLine: Record "Gen. Journal Line"; pFileName: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        oStream: OutStream;
        iStream: InStream;
        WanaMoveToGenJournalLine: XmlPort "WanaMove To Gen. Journal Line";
    begin
        WanaMoveToGenJournalLine.ExportFrom(pGenJournalLine);
        TempBlob.CreateOutStream(oStream);
        WanaMoveToGenJournalLine.SetDestination(oStream);
        WanaMoveToGenJournalLine.Export();
        TempBlob.CreateInStream(iStream);
        CopyStream(oStream, iStream);
        DownloadFromStream(iStream, '', '', '', pFileName);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterInitializeAccountMap(var pAccountMap: Dictionary of [Code[20], Code[20]])
    begin
    end;
}
