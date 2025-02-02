xmlport 87901 "WanaMove To Gen. Journal Line"
{
    Caption = 'WanaMove To Gen. Journal Line';
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
                textelement(_01) { trigger OnBeforePassVariable() begin _01 := TempGenJournalLine.FieldCaption("Source Code"); end; }
                textelement(_02) { trigger OnBeforePassVariable() begin _02 := TempGenJournalLine.FieldCaption("Posting Date"); end; }
                textelement(_03) { trigger OnBeforePassVariable() begin _03 := TempGenJournalLine.FieldCaption("Document Date"); end; }
                textelement(_04) { trigger OnBeforePassVariable() begin _04 := TempGenJournalLine.FieldCaption("Document Type"); end; }
                textelement(_05) { trigger OnBeforePassVariable() begin _05 := TempGenJournalLine.FieldCaption("Document No."); end; }
                textelement(_06) { trigger OnBeforePassVariable() begin _06 := TempGenJournalLine.FieldCaption("Account Type"); end; }
                textelement(_07) { trigger OnBeforePassVariable() begin _07 := TempGenJournalLine.FieldCaption("Account No."); end; }
                textelement(_08) { trigger OnBeforePassVariable() begin _08 := TempGenJournalLine.FieldCaption("Description"); end; }
                textelement(_09) { trigger OnBeforePassVariable() begin _09 := TempGenJournalLine.FieldCaption("Amount"); end; }
                textelement(_10) { trigger OnBeforePassVariable() begin _10 := TempGenJournalLine.FieldCaption("External Document No."); end; }
                textelement(_11) { trigger OnBeforePassVariable() begin _11 := TempGenJournalLine.FieldCaption("Reason Code"); end; }
                textelement(_12) { trigger OnBeforePassVariable() begin _12 := TempGenJournalLine.FieldCaption("Due Date"); end; }
                textelement(_13) { trigger OnBeforePassVariable() begin _13 := TempGenJournalLine.FieldCaption("On Hold"); end; }
                textelement(_14) { trigger OnBeforePassVariable() begin _14 := TempGenJournalLine.FieldCaption("Payment Method Code"); end; }
                textelement(_15) { trigger OnBeforePassVariable() begin _15 := TempGenJournalLine.FieldCaption("Salespers./Purch. Code"); end; }
                textelement(_16) { trigger OnBeforePassVariable() begin _16 := TempGenJournalLine.FieldCaption("IC Partner Code"); end; }
                textelement(_17) { trigger OnBeforePassVariable() begin _17 := TempGenJournalLine.FieldCaption("Sales/Purch. (LCY)"); end; }
                textelement(_18) { trigger OnBeforePassVariable() begin _18 := TempGenJournalLine.FieldCaption("Source Type"); end; }
                textelement(_19) { trigger OnBeforePassVariable() begin _19 := TempGenJournalLine.FieldCaption("Source No."); end; }
                textelement(_20) { trigger OnBeforePassVariable() begin _20 := TempGenJournalLine.FieldCaption("Quantity"); end; }
                textelement(_21) { trigger OnBeforePassVariable() begin _21 := TempGenJournalLine.FieldCaption("Bal. Account No."); end; }
                textelement(_22) { trigger OnBeforePassVariable() begin _22 := TempGenJournalLine.FieldCaption("Depreciation Book Code"); end; }
                textelement(_23) { trigger OnBeforePassVariable() begin _23 := TempGenJournalLine.FieldCaption("FA Posting Type"); end; }
                textelement(_24) { trigger OnBeforePassVariable() begin _24 := TempGenJournalLine.FieldCaption("Incoming Document Entry No."); end; }
                textelement(_Dim1Code) { trigger OnBeforePassVariable() begin _Dim1Code := GLSetup."Shortcut Dimension 1 Code"; end; }
                textelement(_Dim2Code) { trigger OnBeforePassVariable() begin _Dim2Code := GLSetup."Shortcut Dimension 2 Code"; end; }
                textelement(_Dim3Code) { trigger OnBeforePassVariable() begin _Dim3Code := GLSetup."Shortcut Dimension 3 Code"; end; }
                textelement(_Dim4Code) { trigger OnBeforePassVariable() begin _Dim4Code := GLSetup."Shortcut Dimension 4 Code"; end; }
                textelement(_Dim5Code) { trigger OnBeforePassVariable() begin _Dim5Code := GLSetup."Shortcut Dimension 5 Code"; end; }
                textelement(_Dim6Code) { trigger OnBeforePassVariable() begin _Dim6Code := GLSetup."Shortcut Dimension 6 Code"; end; }
                textelement(_Dim7Code) { trigger OnBeforePassVariable() begin _Dim7Code := GLSetup."Shortcut Dimension 7 Code"; end; }
                textelement(_Dim8Code) { trigger OnBeforePassVariable() begin _Dim8Code := GLSetup."Shortcut Dimension 8 Code"; end; }
                textelement(_AppendHeader) { trigger OnBeforePassVariable() begin _AppendHeader := AppendHeader(TempGenJournalLine) end; }

                trigger OnPreXmlItem() // Export
                begin
                    OnAppendHeader(TempGenJournalLine, _AppendHeader);
                end;
            }

            tableelement(TempGenJournalLine; "Gen. Journal Line")
            {
                UseTemporary = true;
                AutoSave = false;
                fieldelement(_01; TempGenJournalLine."Source Code") { }
                fieldelement(_02; TempGenJournalLine."Posting Date") { }
                fieldelement(_03; TempGenJournalLine."Document Date") { }
                fieldelement(_04; TempGenJournalLine."Document Type") { }
                fieldelement(_05; TempGenJournalLine."Document No.") { }
                fieldelement(_06; TempGenJournalLine."Account Type") { }
                fieldelement(_07; TempGenJournalLine."Account No.") { }
                fieldelement(_08; TempGenJournalLine.Description) { }
                fieldelement(_09; TempGenJournalLine.Amount) { }
                fieldelement(_10; TempGenJournalLine."External Document No.") { }
                fieldelement(_11; TempGenJournalLine."Reason Code") { }
                fieldelement(_12; TempGenJournalLine."Due Date") { }
                fieldelement(_13; TempGenJournalLine."On Hold") { }
                fieldelement(_14; TempGenJournalLine."Payment Method Code") { }
                fieldelement(_15; TempGenJournalLine."Salespers./Purch. Code") { }
                fieldelement(_16; TempGenJournalLine."IC Partner Code") { }
                fieldelement(_17; TempGenJournalLine."Sales/Purch. (LCY)") { }
                fieldelement(_18; TempGenJournalLine."Source Type") { }
                fieldelement(_19; TempGenJournalLine."Source No.") { }
                fieldelement(_20; TempGenJournalLine.Quantity) { }
                fieldelement(_21; TempGenJournalLine."Bal. Account No.") { }
                fieldelement(_22; TempGenJournalLine."Depreciation Book Code") { }
                fieldelement(_23; TempGenJournalLine."FA Posting Type") { }
                fieldelement(_24; TempGenJournalLine."Incoming Document Entry No.") { }
                fieldelement(_Dim1; TempGenJournalLine."Shortcut Dimension 1 Code") { }
                fieldelement(_Dim2; TempGenJournalLine."Shortcut Dimension 2 Code") { }
                textelement(_Dim3) { trigger OnBeforePassVariable() begin _Dim3 := GetDimensionValueCode(TempGenJournalLine."Dimension Set ID", GLSetup."Shortcut Dimension 3 Code") end; }
                textelement(_Dim4) { trigger OnBeforePassVariable() begin _Dim4 := GetDimensionValueCode(TempGenJournalLine."Dimension Set ID", GLSetup."Shortcut Dimension 4 Code") end; }
                textelement(_Dim5) { trigger OnBeforePassVariable() begin _Dim5 := GetDimensionValueCode(TempGenJournalLine."Dimension Set ID", GLSetup."Shortcut Dimension 5 Code") end; }
                textelement(_Dim6) { trigger OnBeforePassVariable() begin _Dim6 := GetDimensionValueCode(TempGenJournalLine."Dimension Set ID", GLSetup."Shortcut Dimension 6 Code") end; }
                textelement(_Dim7) { trigger OnBeforePassVariable() begin _Dim7 := GetDimensionValueCode(TempGenJournalLine."Dimension Set ID", GLSetup."Shortcut Dimension 7 Code") end; }
                textelement(_Dim8) { trigger OnBeforePassVariable() begin _Dim8 := GetDimensionValueCode(TempGenJournalLine."Dimension Set ID", GLSetup."Shortcut Dimension 8 Code") end; }
                textelement(_AppendRecord) { trigger OnBeforePassVariable() begin _AppendRecord := AppendRecord(TempGenJournalLine) end; }

                trigger OnBeforeInsertRecord() // Import
                begin
                    ToGenJournalLine.TransferFields(TempGenJournalLine, false);
                    ToGenJournalLine."Line No." += 1;
                    ValidateFields(ToGenJournalLine);
                end;

                trigger OnAfterInsertRecord() // Import
                var
                    DimValue: Array[8] of Code[20];
                    i: integer;
                begin
                    ToGenJournalLine.Insert(true);
                    DimValue[3] := _Dim3;
                    DimValue[4] := _Dim4;
                    DimValue[5] := _Dim5;
                    DimValue[6] := _Dim6;
                    DimValue[7] := _Dim7;
                    DimValue[8] := _Dim8;
                    for i := 3 to 8 do
                        ToGenJournalLine.ValidateShortcutDimCode(i, DimValue[i]);
                    OnAfterImportRecord(ToGenJournalLine, _AppendRecord);
                    ToGenJournalLine.Modify(true);
                end;
            }
        }
    }
    trigger OnPreXmlPort()
    begin
        GLSetup.Get();
        StartDateTime := CurrentDateTime;
    end;

    var
        StartDateTime: DateTime;
        GLSetup: Record "General Ledger Setup";
        ToGenJournalLine: Record "Gen. Journal Line";

    local procedure GetDimensionValueCode(pDimensionSetId: Integer; pDimensionCode: Code[20]): Code[20]
    var
        DimSetEntry: Record "Dimension Set Entry";
    begin
        if DimSetEntry.Get(pDimensionSetId, pDimensionCode) then
            exit(DimSetEntry."Dimension Value Code")
        else
            exit('');
    end;

    local procedure ValidateFields(var ToGenJournalLine: Record "Gen. Journal Line")
    begin
        ToGenJournalLine.Validate(Amount);
    end;

    procedure ExportFrom(var GenJournalLine: Record "Gen. Journal Line")
    begin
        if GenJournalLine.FindSet() then
            repeat
                TempGenJournalLine := GenJournalLine;
                TempGenJournalLine.Insert(false);
            until GenJournalLine.Next() = 0;
    end;

    procedure SetGenJournalLine(var GenJournalLine: Record "Gen. Journal Line")
    begin
        ToGenJournalLine := GenJournalLine;
        ToGenJournalLine."Line No." := 0;
    end;

    procedure DoneMessage(): Text
    var
        ImportDoneMsg: Label '%1 lines imported in %2.';
    begin
        if CurrentDateTime <> 0DT then
            exit(StrSubstNo(ImportDoneMsg, ToGenJournalLine."Line No.", CurrentDateTime - StartDateTime));
    end;

    local procedure AppendHeader(var GenJournalLine: Record "Gen. Journal Line") ReturnValue: Text
    begin
        OnAppendHeader(GenJournalLine, ReturnValue);
    end;

    local procedure AppendRecord(var GenJournalLine: Record "Gen. Journal Line") ReturnValue: Text
    begin
        OnAppendRecord(GenJournalLine, ReturnValue);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAppendHeader(var GenJournalLine: Record "Gen. Journal Line"; var Append: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAppendRecord(var GenJournalLine: Record "Gen. Journal Line"; var Append: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnAfterImportRecord(var GenJournalLine: Record "Gen. Journal Line"; var Append: Text)
    begin
    end;
}
