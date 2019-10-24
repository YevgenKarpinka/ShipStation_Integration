table 50003 "ShipStation Rate"
{
    DataClassification = ToBeClassified;
    CaptionML = ENU = 'Carrier Services Rate', RUS = 'Стоимость Услуги Перевозчика';

    fields
    {
        field(1; "Carrier Code"; Text[20])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(2; "Service Code"; Text[50])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(3; "Service Name"; Text[100])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(4; "Shipment Cost"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(5; "Other Cost"; Decimal)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
    }

    keys
    {
        key(PK; "Carrier Code", "Service Code")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "Service Code", "Service Name", "Shipment Cost")
        {
        }
    }

    var
        myInt: Integer;

    trigger OnInsert()
    begin

    end;

    trigger OnModify()
    begin

    end;

    trigger OnDelete()
    begin

    end;

    trigger OnRename()
    begin

    end;
}