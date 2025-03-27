// Thak's to Volodymir for the idea and the code : https://vld-bc.com/table-data-editor-general
table 87990 "TableData Buffer"
{
    Caption = 'TableData Buffer';
    DataClassification = CustomerContent;
    TableType = Temporary;

    fields
    {
        field(1; "Primary Key"; Code[10])
        {
            Caption = 'Primary Key';
        }
        field(2; "Some BLOB"; Blob)
        {
            Caption = 'Some BLOB';
        }
        field(3; "Some Media"; Media)
        {
            Caption = 'Some Media';
        }
        field(4; "Some Media Set"; MediaSet)
        {
            Caption = 'Some Media Set';
        }
    }
    keys
    {
        key(PK; "Primary Key")
        {
            Clustered = true;
        }
    }
}
