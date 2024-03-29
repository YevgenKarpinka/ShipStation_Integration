tableextension 50003 "Sales Header Ext." extends "Sales Header"
{

    fields
    {

        // Add changes to table fields here
        field(50000; "ShipStation Order ID"; Text[20])
        {
            CaptionML = ENU = 'ShipStation Order ID', RUS = 'Идентификатор Заказа ShipStation';
            // Editable = false;
        }
        field(50001; "ShipStation Order Key"; Text[50])
        {
            CaptionML = ENU = 'ShipStation Order Key', RUS = 'Ключ Заказа ShipStation';
            // Editable = false;
        }
        field(50002; "ShipStation Order Status"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = "Not Sent",Sent,Updated;
            OptionCaptionML = ENU = 'Not Sent,Sent,Updated', RUS = 'Не отправлен,Отправлен,Обновлен';
            CaptionML = ENU = 'ShipStation Order Status', RUS = 'Статус Заказа ShipStation';
            Editable = false;
        }
        field(50003; "ShipStation Status"; Text[50])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'ShipStation Status', RUS = 'Статус ShipStation';
            Editable = false;
        }
        field(50004; "ShipStation Shipment Cost"; Decimal)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'ShipStation Shipment Cost', RUS = 'Стоимость отгрузки ShipStation';
            Editable = false;
        }
        field(50005; "ShipStation Insurance Cost"; Decimal)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'ShipStation Insurance Cost', RUS = 'Стоимость страховки ShipStation';
            Editable = false;
        }
        field(50006; "ShipStation Shipment ID"; Text[30])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'ShipStation Shipment ID', RUS = 'ID Отгрузки ShipStation';
            Editable = false;
        }
        field(50007; "ShipStation Shipment Amount"; Decimal)
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'ShipStation Shipment Amount', RUS = 'Сума отгрузки ShipStation';
            Editable = false;
        }
    }

    keys
    {
        key(SK1; "ShipStation Order ID", "ShipStation Order Key", "ShipStation Order Status", "ShipStation Status")
        {

        }
    }

    procedure GetShippingAgentName(ShippingAgentCode: Code[10]): Text[50]
    var
        _SA: Record "Shipping Agent";
    begin
        if _SA.Get(ShippingAgentCode) then
            exit(_SA.Name)
        else
            exit('')
    end;

    procedure GetShippingAgentServiceDescription(ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10]): Text[100]
    var
        _SAS: Record "Shipping Agent Services";
    begin
        if _SAS.Get(ShippingAgentCode, ShippingAgentServiceCode) then
            exit(_SAS.Description)
        else
            exit('')
    end;

    procedure UpdateAgentServiceRateSalesHeader(SAS: Record "Shipping Agent Services")
    begin
        Validate("Shipping Agent Code", SAS."Shipping Agent Code");
        Validate("Shipping Agent Service Code", SAS.Code);
        "ShipStation Shipment Cost" := SAS."Shipment Cost";
        "ShipStation Insurance Cost" := SAS."Other Cost";
        Modify(true);
    end;
}