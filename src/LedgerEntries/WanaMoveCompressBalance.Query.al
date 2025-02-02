query 87990 "WanaMove Compress Balance"
{
    QueryType = Normal;

    elements
    {
        dataitem(GLEntry; "G/L Entry")
        {
            filter(PostingDateFilter; "Posting Date") { }
            column(SourceCode; "Source Code") { }
            column(PostingDateYear; "Posting Date") { Method = Year; }
            column(PostingDateMonth; "Posting Date") { Method = Month; }
            column(GLAccountNo; "G/L Account No.") { }
            column(IC_Partner_Code; "IC Partner Code") { }
            // column(DimensionSetID; "Dimension Set ID") { }
            // column(GlobalDimension1Code; "Global Dimension 1 Code") { }
            // column(GlobalDimension2Code; "Global Dimension 2 Code") { }
            column(Amount; Amount) { Method = Sum; }
        }
    }
}
