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
    }

    var
        myInt: Integer;
}