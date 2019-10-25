page 50001 "Shipping Rates"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Shipping Agent";
    // SourceTableTemporary = true;
    SourceTableView = sorting(Code) order(ascending);
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
                field(Name; Name)
                {
                    ApplicationArea = All;
                }
            }
            part(subpageShippingRates; "Shipping Rates Subpage")
            {
                ApplicationArea = All;
                Editable = false;
                Enabled = "SS Code" <> '';
                SubPageLink = "Shipping Agent Code" = FIELD(Code);
                UpdatePropagation = Both;
            }
        }
    }

    trigger OnClosePage()
    begin
        CurrPage.subpageShippingRates.Page.GetAgentServiceCodes(AgentCode, ServiceCode);
    end;

    procedure GetAgentServiceCodes(var _SAS: Record "Shipping Agent Services")
    begin
        _SAS.Get(AgentCode, ServiceCode);
    end;

    var
        AgentCode: Code[10];
        ServiceCode: Code[10];
}