page 50001 "Shipping Rates"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Shipping Agent";
    // SourceTableTemporary = true;
    SourceTableView = where("SS Code" = filter('<>'''''));
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

    trigger OnOpenPage()
    begin
        // CurrPage.subpageShippingRates.Page.InitPage(recSAS);
        // CurrPage.subpageShippingRates.Page.SetTableView(recSAS);
    end;

    trigger OnClosePage()
    begin
        CurrPage.subpageShippingRates.Page.GetAgentServiceCodes(AgentCode, ServiceCode);
    end;

    procedure GetAgentServiceCodes(var _SAS: Record "Shipping Agent Services")
    begin
        _SAS.Get(AgentCode, ServiceCode);
    end;

    procedure InitPage(_SA: Record "Shipping Agent"; _SAS: Record "Shipping Agent Services")
    begin
        Rec := _SA;
        recSAS := _SAS;
    end;

    var
        recSAS: Record "Shipping Agent Services";
        AgentCode: Code[10];
        ServiceCode: Code[10];
}