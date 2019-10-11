tableextension 50003 "Sales Header Ext." extends "Sales Header"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "ShipStation Order ID"; Integer)
        {
            CaptionML = ENU = 'ShipStation Order ID', RUS = 'Идентификатор Заказа ShipStation ';
        }
        field(50001; "ShipStation Order Key"; Guid)
        {
            CaptionML = ENU = 'ShipStation Order Key', RUS = 'Ключ Заказа ShipStation';
        }
        field(50002; "ShipStation Order Status"; Option)
        {
            DataClassification = ToBeClassified;
            OptionMembers = "Not Sent",Sent,Received;
            OptionCaptionML = ENU = 'Not Sent,Sent,Received', RUS = 'Не отправлен,Отправлен,Получен';
            CaptionML = ENU = 'ShipStation Order Status', RUS = 'Статус Заказа ShipStation';
            Editable = false;
        }
        field(50003; "ShipStation Status"; Text[50])
        {
            DataClassification = ToBeClassified;
            CaptionML = ENU = 'ShipStation Status', RUS = 'Статус ShipStation';
            Editable = false;
        }
    }

    var
        myInt: Integer;
}