tableextension 50004 "Shipping Agent Ext." extends "Shipping Agent"
{
    fields
    {
        // Add changes to table fields here
        field(50000; "SS Code"; Text[20])
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
        field(50001; "SS Provider Id"; Integer)
        {
            DataClassification = ToBeClassified;
            Editable = false;
        }
    }

    keys
    {
        key(SK1; "SS Code", "SS Provider Id")
        {

        }
    }
}