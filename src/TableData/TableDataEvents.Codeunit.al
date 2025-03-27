codeunit 87991 "TableData Events"
{
    [EventSubscriber(ObjectType::Report, Report::"WanaMove TableData Export", OnSetFilters, '', false, false)]
    local procedure OnSetFilters(var pRecRef: RecordRef; pFilters: Text)
    var
        Field: Record Field;
        FldRef: FieldRef;
    begin
        if pFilters = '' then
            exit;
        if Field.Get(pRecRef.Number, 90400) then begin
            FldRef := pRecRef.Field(90400); // Entity Code
            FldRef.SetRange(pFilters);
        end;
    end;
}
