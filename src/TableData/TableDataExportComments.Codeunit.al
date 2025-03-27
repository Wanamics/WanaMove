Codeunit 87993 "WanaMove TableData Comments"
{
    procedure GetComments(var pParentRecRef: RecordRef; var jChildren: JsonObject)
    begin
        case pParentRecRef.Number of
            // Master Data
            Database::"G/L Account", Database::Customer, Database::Vendor, Database::Item, Database::Resource, Database::Job, Database::"Resource Group",
            Database::"Bank Account", Database::Campaign, Database::"Fixed Asset", Database::Insurance, Database::"Nonstock Item", Database::"IC Partner":
                // Database::"Vendor Agreement",Database::"Customer Agreement",Database::"Sustainability Account":
                AddCommentLines(pParentRecRef, Database::"Comment Line", jChildren);

            // Sales
            Database::"Sales Header":
                AddDocumentCommentLines(pParentRecRef, Database::"Sales Comment Line", ToSalesCommentDocumentType(pParentRecRef), 0, jChildren);
            Database::"Sales Line":
                AddDocumentCommentLines(pParentRecRef, Database::"Sales Comment Line", ToSalesCommentDocumentType(pParentRecRef), pParentRecRef.Field(4).Value, jChildren);
            Database::"Sales Shipment Header", Database::"Sales Shipment Line", Database::"Return Receipt Header", Database::"Return Receipt Line",
            Database::"Sales Invoice Header", Database::"Sales Invoice Line", Database::"Sales Cr.Memo Header", Database::"Sales Cr.Memo Line":
                AddPostedDocumentCommentLines(pParentRecRef, Database::"Sales Comment Line", pParentRecRef.Field(4).Value, jChildren);
            Database::"Sales Header archive":
                AddArchiveDocumentCommentLines(pParentRecRef, Database::"Sales Comment Line Archive", ToSalesCommentDocumentType(pParentRecRef), pParentRecRef.Field(4).Value, jChildren);
            Database::"Sales Line Archive":
                AddArchiveDocumentCommentLines(pParentRecRef, Database::"Sales Comment Line Archive", ToSalesCommentDocumentType(pParentRecRef), pParentRecRef.Field(4).Value, jChildren);

            // Purchase
            Database::"Purchase Header":
                AddDocumentCommentLines(pParentRecRef, Database::"Purch. Comment Line", ToPurchaseCommentDocumentType(pParentRecRef), 0, jChildren);
            Database::"Purchase Line":
                AddDocumentCommentLines(pParentRecRef, Database::"Purch. Comment Line", ToPurchaseCommentDocumentType(pParentRecRef), pParentRecRef.Field(4).Value, jChildren);
            Database::"Purch. Rcpt. Header", Database::"Return Shipment Header", Database::"Purch. Inv. Header", Database::"Purch. Cr. Memo Hdr.":
                AddPostedDocumentCommentLines(pParentRecRef, Database::"Purch. Comment Line", 0, jChildren);
            Database::"Purch. Rcpt. Line", Database::"Return Shipment Line", Database::"Purch. Inv. Line", Database::"Purch. Cr. Memo Line":
                AddPostedDocumentCommentLines(pParentRecRef, Database::"Purch. Comment Line", pParentRecRef.Field(4).Value, jChildren);
            Database::"Purchase Header archive":
                AddArchiveDocumentCommentLines(pParentRecRef, Database::"Sales Comment Line", ToPurchaseCommentDocumentType(pParentRecRef), 0, jChildren);
            Database::"Purchase Line Archive":
                AddArchiveDocumentCommentLines(pParentRecRef, Database::"Sales Comment Line", ToPurchaseCommentDocumentType(pParentRecRef), pParentRecRef.Field(4).Value, jChildren);
        end;
    end;

    local procedure AddCommentLines(var pParentRecRef: RecordRef; pCommentTableID: Integer; pReturnValue: JsonObject)
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        RecRef.Open(pCommentTableID);
        FldRef := RecRef.Field(1);
        FldRef.SetRange(ToTableName(pParentRecRef.Number));
        RecRef.Field(2).SetRange(pParentRecRef.Field(1));
        if RecRef.FindSet() then
            pReturnValue.Add(Format(RecRef.Number), Helper.jArray(RecRef));
    end;

    local procedure ToTableName(pTableID: Integer): Enum "Comment Line Table Name"
    var
        CaseErr: Label 'ToTableName case defined for table ID %1';
    begin
        case pTableID of
            Database::"G/L Account":
                exit("Comment Line Table Name"::"G/L Account");
            Database::Customer:
                exit("Comment Line Table Name"::Customer);
            Database::Vendor:
                exit("Comment Line Table Name"::Vendor);
            Database::Item:
                exit("Comment Line Table Name"::Item);
            Database::Resource:
                exit("Comment Line Table Name"::Resource);
            Database::Job:
                exit("Comment Line Table Name"::Job);
            Database::"Resource Group":
                exit("Comment Line Table Name"::"Resource Group");
            Database::"Bank Account":
                exit("Comment Line Table Name"::"Bank Account");
            Database::Campaign:
                exit("Comment Line Table Name"::Campaign);
            Database::"Fixed Asset":
                exit("Comment Line Table Name"::"Fixed Asset");
            Database::Insurance:
                exit("Comment Line Table Name"::Insurance);
            Database::"Nonstock Item":
                exit("Comment Line Table Name"::"Nonstock Item");
            Database::"IC Partner":
                exit("Comment Line Table Name"::"IC Partner");
            else
                Error(CaseErr, pTableID);
        end;

    end;

    local procedure AddDocumentCommentLines(var pParentRecRef: RecordRef; pCommentTableID: Integer; pDocumentType: enum "Sales Document Type"; pLineNo: Integer; pReturnValue: JsonObject)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(pCommentTableID);
        RecRef.Field(1).SetRange(pDocumentType);
        RecRef.Field(2).SetRange(pParentRecRef.Field(3).Value);
        RecRef.Field(3).SetRange(pLineNo);
        if RecRef.FindSet() then
            pReturnValue.Add(Format(RecRef.Number), Helper.jArray(RecRef));
    end;

    local procedure AddPostedDocumentCommentLines(var pParentRecRef: RecordRef; pCommentTableID: Integer; pLineNo: Integer; pReturnValue: JsonObject)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(pCommentTableID);
        RecRef.Field(1).SetRange(ToTableName(pParentRecRef.Number));
        RecRef.Field(2).SetRange(pParentRecRef.Field(3).Value);
        RecRef.Field(3).SetRange(pLineNo);
        if RecRef.FindSet() then
            pReturnValue.Add(Format(RecRef.Number), Helper.jArray(RecRef));
    end;

    local procedure AddArchiveDocumentCommentLines(var pParentRecRef: RecordRef; pCommentTableID: Integer; pDocumentType: enum "Sales Document Type"; pLineNo: Integer; pReturnValue: JsonObject)
    var
        RecRef: RecordRef;
    begin
        RecRef.Open(pCommentTableID);
        RecRef.Field(1).SetRange(ToTableName(pParentRecRef.Number));
        RecRef.Field(2).SetRange(pParentRecRef.Field(3).Value);
        RecRef.Field(2).SetRange(pParentRecRef.Field(3).Value);
        RecRef.Field(2).SetRange(pParentRecRef.Field(3).Value);
        RecRef.Field(3).SetRange(pLineNo);
        if RecRef.FindSet() then
            pReturnValue.Add(Format(RecRef.Number), Helper.jArray(RecRef));
    end;

    local procedure ToSalesCommentDocumentType(pRecordRef: RecordRef): Enum "Sales Comment Document Type"
    var
        DocumentType: enum "Sales Document Type";
    begin
        DocumentType := pRecordRef.Field(1).Value;
        Case DocumentType of
            "Sales Document Type"::Quote:
                exit("Sales Comment Document Type"::Quote);
            "Sales Document Type"::Order:
                exit("Sales Comment Document Type"::Order);
            "Sales Document Type"::Invoice:
                exit("Sales Comment Document Type"::Invoice);
            "Sales Document Type"::"Credit Memo":
                exit("Sales Comment Document Type"::"Credit Memo");
            "Sales Document Type"::"Blanket Order":
                exit("Sales Comment Document Type"::"Blanket Order");
            "Sales Document Type"::"Return Order":
                exit("Sales Comment Document Type"::"Return Order");
            else
        end;
    end;

    local procedure ToSalesCommentDocumentType(pTableID: Integer): Enum "Sales Comment Document Type"
    begin
        case pTableID of
            Database::"Sales Shipment Header", Database::"Sales Shipment Line":
                exit("Sales Comment Document Type"::Shipment);
            Database::"Return Shipment Header", Database::"Return Shipment Line":
                exit("Sales Comment Document Type"::"Posted Return Receipt");
            Database::"Sales Invoice Header", Database::"Sales Invoice Line":
                exit("Sales Comment Document Type"::"Posted Invoice");
            Database::"Sales Cr.Memo Header", Database::"Sales Cr.Memo Line":
                exit("Sales Comment Document Type"::"Posted Credit Memo");
        end;
    end;

    local procedure ToPurchaseCommentDocumentType(pRecordRef: RecordRef): Enum "Purchase Comment Document Type"
    var
        DocumentType: enum "Purchase Document Type";
    begin
        DocumentType := pRecordRef.Field(1).Value;
        Case DocumentType of
            "Purchase Document Type"::Quote:
                exit("Purchase Comment Document Type"::Quote);
            "Purchase Document Type"::Order:
                exit("Purchase Comment Document Type"::Order);
            "Purchase Document Type"::Invoice:
                exit("Purchase Comment Document Type"::Invoice);
            "Purchase Document Type"::"Credit Memo":
                exit("Purchase Comment Document Type"::"Credit Memo");
            "Purchase Document Type"::"Blanket Order":
                exit("Purchase Comment Document Type"::"Blanket Order");
            "Purchase Document Type"::"Return Order":
                exit("Purchase Comment Document Type"::"Return Order");
            else
        end;
    end;

    local procedure ToPurchaseCommentDocumentType(pTableID: Integer): Enum "Purchase Comment Document Type"
    begin
        case pTableID of
            Database::"Purch. Rcpt. Header", Database::"Purch. Rcpt. Line":
                exit("Purchase Comment Document Type"::Receipt);
            Database::"Return Shipment Header", Database::"Return Shipment Line":
                exit("Purchase Comment Document Type"::"Posted Return Shipment");
            Database::"Purch. Inv. Header", Database::"Purch. Inv. Line":
                exit("Purchase Comment Document Type"::"Posted Invoice");
            Database::"Purch. Cr. Memo Hdr.", Database::"Purch. Cr. Memo Line":
                exit("Purchase Comment Document Type"::"Posted Credit Memo");
        end;
    end;

    var
        Helper: Codeunit "WanaMove TableData Helper";
}
