pageextension 50005 "Sales Order Ext." extends "Sales Order"
{
    layout
    {
        // Add changes to page layout here

        addafter("Shipping Agent Code")
        {
            field("Shipping Agent Name"; GetShippingAgentName("Shipping Agent Code"))
            {
                ApplicationArea = All;
                Style = Strong;
                ShowCaption = false;
            }
        }
        addafter("Shipping Agent Service Code")
        {
            field("Shipping Agent Service Description"; GetShippingAgentServiceDescription("Shipping Agent Code", "Shipping Agent Service Code"))
            {
                ApplicationArea = All;
                Style = Strong;
                ShowCaption = false;
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
                field("ShipStation Tracking No."; "ShipStation Tracking No.")
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
            }
        }

    }
}