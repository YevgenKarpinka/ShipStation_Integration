pageextension 50005 "Sales Order Ext." extends "Sales Order"
{
    layout
    {
        // Add changes to page layout here
        addafter("Shipping Agent Code")
        {
            field("Agent Name"; GetShippingAgentName("Shipping Agent Code"))
            {
                ApplicationArea = All;
                Style = Strong;
                // ShowCaption = false;
            }
        }
        addafter("Shipping Agent Service Code")
        {
            field("Service Description"; GetShippingAgentServiceDescription("Shipping Agent Code", "Shipping Agent Service Code"))
            {
                ApplicationArea = All;
                Style = Strong;
                // ShowCaption = false;
            }
        }
        addafter(Control1900201301)
        {
            group(groupShipStation)
            {
                CaptionML = ENU = 'ShipStation', RUS = 'ShipStation';

                field("ShipStation Order ID"; "ShipStation Order ID")
                {
                    ApplicationArea = All;

                }
                field("ShipStation Order Key"; "ShipStation Order Key")
                {
                    ApplicationArea = All;

                }
                field("ShipStation Order Status"; "ShipStation Order Status")
                {
                    ApplicationArea = All;

                }
                field("ShipStation Status"; "ShipStation Status")
                {
                    ApplicationArea = All;

                }
                field("ShipStation Shipment Amount"; "ShipStation Shipment Amount")
                {
                    ApplicationArea = All;

                }
                field("ShipStation Shipment Cost"; "ShipStation Shipment Cost")
                {
                    ApplicationArea = All;

                }
                field("ShipStation Insurance Cost"; "ShipStation Insurance Cost")
                {
                    ApplicationArea = All;

                }
                field("ShipStation Shipment ID"; "ShipStation Shipment ID")
                {
                    ApplicationArea = All;

                }
            }
        }
    }

    actions
    {
        // Add changes to page actions here
        addbefore("F&unctions")
        {
            group(actionShipStation)
            {
                CaptionML = ENU = 'ShipStation', RUS = 'ShipStation';
                Image = ReleaseShipment;

                // action("Get Order")
                // {
                //     ApplicationArea = All;
                //     Image = OrderList;

                //     trigger OnAction()
                //     var
                //         ShipStationMgt: Codeunit "ShipStation Mgt.";
                //     begin
                //         ShipStationMgt.GetOrdersFromShipStation();
                //     end;
                // }
                action("Create/Update Order")
                {
                    ApplicationArea = All;
                    Image = CreateDocuments;

                    trigger OnAction()
                    var
                        ShipStationMgt: Codeunit "ShipStation Mgt.";
                        _SH: Record "Sales Header";
                        lblOrdersList: TextConst ENU = 'List of Processed Orders:', RUS = 'Список обработанных Заказов:';
                        txtOrdersList: Text;
                    begin
                        CurrPage.SetSelectionFilter(_SH);
                        // ShipStationMgt.SetTestMode(true);
                        if _SH.FindSet(false, false) then
                            repeat
                                ShipStationMgt.CreateOrderInShipStation(_SH."No.");
                                if txtOrdersList = '' then
                                    txtOrdersList := _SH."No."
                                else
                                    txtOrdersList += '\' + _SH."No.";
                            until _SH.Next() = 0;
                        Message('%1 \%2', lblOrdersList, txtOrdersList);
                    end;
                }
                action("Get Rates")
                {
                    ApplicationArea = All;
                    Image = CalculateShipment;

                    trigger OnAction()
                    var
                        // recSAS: Record "Shipping Agent Services" temporary;
                        // recSA: Record "Shipping Agent" temporary;
                        recSAS: Record "Shipping Agent Services";
                        pageShippingRates: Page "Shipping Rates";
                        SSMgt: Codeunit "ShipStation Mgt.";
                    begin
                        // SSMgt.GetShippingRatesByCarrier(Rec, recSA, recSAS);
                        SSMgt.GetShippingRatesByCarrier(Rec);
                        // pageShippingRates.InitPage(recSA, recSAS);
                        // pageShippingRates.SetTableView(recSA);
                        Commit();
                        pageShippingRates.LookupMode(true);
                        if pageShippingRates.RunModal() = Action::LookupOK then begin
                            pageShippingRates.GetAgentServiceCodes(recSAS);
                            UpdateAgentServiceRateSalesHeader(recSAS);
                            Message('Service %1', recSAS."SS Code");
                        end;
                    end;
                }
                action("Create Label to Order")
                {
                    ApplicationArea = All;
                    Image = PrintReport;

                    trigger OnAction()
                    var
                        ShipStationMgt: Codeunit "ShipStation Mgt.";
                        _SH: Record "Sales Header";
                    begin
                        CurrPage.SetSelectionFilter(_SH);
                        ShipStationMgt.SetTestMode(true);
                        if _SH.FindSet(false, false) then
                            repeat
                                ShipStationMgt.CreateLabel2OrderInShipStation(_SH."No.");
                            until _SH.Next() = 0;
                    end;
                }
                action("Void Label to Order")
                {
                    ApplicationArea = All;
                    Image = VoidCreditCard;

                    trigger OnAction()
                    var
                        ShipStationMgt: Codeunit "ShipStation Mgt.";
                        _SH: Record "Sales Header";
                    begin
                        CurrPage.SetSelectionFilter(_SH);
                        ShipStationMgt.SetTestMode(true);
                        if _SH.FindSet(false, false) then
                            repeat
                                ShipStationMgt.VoidLabel2OrderInShipStation(_SH."No.");
                            until _SH.Next() = 0;
                    end;
                }
            }
        }

    }
}