page 50000 "Source Parameters"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = Administration;
    SourceTable = "Source Parameters";
    SourceTableView = sorting (Code) order(descending);

    layout
    {
        area(Content)
        {
            repeater(RepeaterName)
            {
                field("FSp Event"; "FSp Event")
                {
                    ApplicationArea = All;
                }
                field(Code; Code)
                {
                    ApplicationArea = All;
                }
                field("FSp RestMethod"; "FSp RestMethod")
                {
                    ApplicationArea = All;
                }
                field("FSp URL"; "FSp URL")
                {
                    ApplicationArea = All;
                }
                field("FSp UserName"; "FSp UserName")
                {
                    ApplicationArea = All;
                }
                field("FSp Password"; "FSp Password")
                {
                    ApplicationArea = All;
                }
                field("FSp AuthorizationFrameworkType"; "FSp AuthorizationFrameworkType")
                {
                    ApplicationArea = All;
                }
                field("FSp AuthorizationToken"; "FSp AuthorizationToken")
                {
                    ApplicationArea = All;
                }
                field("FSp ContentType"; "FSp ContentType")
                {
                    ApplicationArea = All;
                }
                field("FSp ETag"; "FSp ETag")
                {
                    ApplicationArea = All;
                }
                field("FSp Accept"; "FSp Accept")
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action("Test Connection")
            {
                ApplicationArea = All;
                CaptionML = ENU = 'Test Connection', RUS = 'Тестовое подключение';

                trigger OnAction()
                var
                    ShipStationMgt: Codeunit "ShipStation Mgt.";
                begin
                    ShipStationMgt.Connect2ShipStation(1, '', '');
                    Message('Connection Ok!');
                end;
            }
        }
    }

    var
        myInt: Integer;
}