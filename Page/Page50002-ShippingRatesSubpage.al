page 50002 "Shipping Rates Subpage"
{
    PageType = ListPart;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Shipping Agent Services";
    // SourceTableTemporary = true;
    SourceTableView = where("Shipment Cost" = filter('<>0'));

    InsertAllowed = false;
    DeleteAllowed = false;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(RepeaterName)
            {
                field("SS Code"; "SS Code")
                {
                    ApplicationArea = All;
                }
                field(Description; Description)
                {
                    ApplicationArea = All;
                }
                field("Shipment Cost"; "Shipment Cost")
                {
                    ApplicationArea = All;
                }
                field("Other Cost"; "Other Cost")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    procedure GetAgentServiceCodes(var AgentCode: Code[10]; var ServiceCode: Code[10])
    begin
        AgentCode := "Shipping Agent Code";
        ServiceCode := Code;
    end;

    procedure InitPage(_SAS: Record "Shipping Agent Services")
    begin
        Rec := _SAS;
    end;
}