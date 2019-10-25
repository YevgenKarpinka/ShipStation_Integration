tableextension 50005 "Shipping Agent Services Ext." extends "Shipping Agent Services"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "SS Carrier Code"; Text[20])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(50001; "SS Code"; Text[50])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(50002; "Shipment Cost"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(50003; "Other Cost"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
    }

    keys
    {
        key(SK1; "SS Carrier Code", "SS Code")
        {

        }
    }
    procedure InsertServicesFromShipStation(CarrierCode: Code[10]; ServiceCode: Code[10]; SS_CarrierCode: Text[20]; SS_ServiceCode: Text[50]; SS_ServiceName: Text[100])
    begin
        Init();
        "Shipping Agent Code" := CarrierCode;
        Code := ServiceCode;
        Insert();
        "SS Carrier Code" := SS_CarrierCode;
        "SS Code" := SS_ServiceCode;
        Description := SS_ServiceName;
        Modify();
    end;
}