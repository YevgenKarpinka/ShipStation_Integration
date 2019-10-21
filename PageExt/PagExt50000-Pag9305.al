pageextension 50003 "Sales Order List Ext." extends "Sales Order List"
{
    layout
    {
        // Add changes to page layout here
        addlast(Control1)
        {
            field("ShipStation Status"; "ShipStation Status")
            {
                ApplicationArea = All;

            }
            field("ShipStation Order Status"; "ShipStation Order Status")
            {
                ApplicationArea = All;

            }
            field("ShipStation Order ID"; "ShipStation Order ID")
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

    actions
    {
        // Add changes to page actions here
        addbefore("F&unctions")
        {
            group(actionShipStation)
            {
                CaptionML = ENU = 'ShipStation', RUS = 'ShipStation';
                Image = ReleaseShipment;

                action("Get Orders")
                {
                    ApplicationArea = All;
                    Image = OrderList;

                    trigger OnAction()
                    var
                        ShipStationMgt: Codeunit "ShipStation Mgt.";
                    begin
                        ShipStationMgt.GetOrdersFromShipStation();
                    end;
                }
                action("Create Orders")
                {
                    ApplicationArea = All;
                    Image = CreateDocuments;

                    trigger OnAction()
                    var
                        ShipStationMgt: Codeunit "ShipStation Mgt.";
                        _SH: Record "Sales Header";
                        lblOrdersList: TextConst ENU = 'Orders List:', RUS = 'Список Заказов:';
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
                action("Create Label to Orders")
                {
                    ApplicationArea = All;
                    Image = PrintReport;

                    trigger OnAction()
                    var
                        ShipStationMgt: Codeunit "ShipStation Mgt.";
                        _SH: Record "Sales Header";
                    begin
                        CurrPage.SetSelectionFilter(_SH);
                        // ShipStationMgt.SetTestMode(true);
                        if _SH.FindSet(false, false) then
                            repeat
                                ShipStationMgt.CreateLabel2OrderInShipStation(_SH."No.");
                            until _SH.Next() = 0;
                    end;
                }
            }
        }

    }

    var
        myInt: Integer;
}