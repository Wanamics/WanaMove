codeunit 87991 "TableData Events"
{
    [EventSubscriber(ObjectType::Report, Report::"WanaMove TableData Export", OnSetFilters, '', false, false)]
    local procedure OnSetFilters(var pRecRef: RecordRef; var EntityCode: Code[20])
    var
        Field: Record Field;
        FldRef: FieldRef;
    begin
        if Field.Get(pRecRef.Number, 90400) then begin
            FldRef := pRecRef.Field(90400); // Entity Code
            FldRef.SetRange(EntityCode);
        end;
    end;
}
