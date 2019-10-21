codeunit 50001 "ShipStation Mgt."
{
    trigger OnRun()
    begin

    end;

    procedure SetTestMode(_testMode: Boolean)
    begin
        testMode := _testMode;
    end;

    procedure Connect2ShipStation(SPCode: Integer; Body2Request: Text; newURL: Text): Text
    var
        TempBlob: Record TempBlob;
        SourceParameters: Record "Source Parameters";
        RequestMessage: HttpRequestMessage;
        ResponseMessage: HttpResponseMessage;
        Headers: HttpHeaders;
        Client: HttpClient;
        JSText: Text;
        JSObject: JsonObject;
        errMessage: Text;
        errExceptionMessage: Text;
    begin
        SourceParameters.SetRange("FSp Event", SPCode);
        SourceParameters.FindSet(false, false);

        RequestMessage.Method := Format(SourceParameters."FSp RestMethod");
        if newURL = '' then
            RequestMessage.SetRequestUri(SourceParameters."FSp URL")
        else
            RequestMessage.SetRequestUri(StrSubstNo('%1%2', SourceParameters."FSp URL", newURL));

        RequestMessage.GetHeaders(Headers);
        Headers.Add('Accept', SourceParameters."FSp Accept");
        if (SourceParameters."FSp AuthorizationFrameworkType" = SourceParameters."FSp AuthorizationFrameworkType"::OAuth2)
            and (SourceParameters."FSp AuthorizationToken" <> '') then begin
            TempBlob.WriteAsText(SourceParameters."FSp AuthorizationToken", TextEncoding::Windows);
            Headers.Add('Authorization', TempBlob.ReadTextLine);
        end else
            if SourceParameters."FSp UserName" <> '' then begin
                TempBlob.WriteAsText(StrSubstNo('%1:%2', SourceParameters."FSp UserName", SourceParameters."FSp Password"), TextEncoding::Windows);
                Headers.Add('Authorization', StrSubstNo('Basic %1', TempBlob.ToBase64String()));
            end;

        Headers.Add('If-Match', SourceParameters."FSp ETag");

        if SourceParameters."FSp RestMethod" = SourceParameters."FSp RestMethod"::POST then begin
            RequestMessage.Content.WriteFrom(Body2Request);
            RequestMessage.Content.GetHeaders(Headers);
            if SourceParameters."FSp ContentType" <> 0 then begin
                Headers.Remove('Content-Type');
                Headers.Add('Content-Type', Format(SourceParameters."FSp ContentType"));
            end;
        end;

        Client.Send(RequestMessage, ResponseMessage);
        If not ResponseMessage.IsSuccessStatusCode() then begin
            ResponseMessage.Content.ReadAs(JSText);
            JSObject.ReadFrom(JSText);
            errMessage := GetJSToken(JSObject, 'Message').AsValue().AsText();
            errExceptionMessage := GetJSToken(JSObject, 'ExceptionMessage').AsValue().AsText();
            Error('Web service returned error:\\Status code: %1\Description: %2\Message: %3\Exception Message: %4\Body Request:\%5',
                ResponseMessage.HttpStatusCode(), ResponseMessage.ReasonPhrase(), errMessage, errExceptionMessage, Body2Request);
        end;

        ResponseMessage.Content().ReadAs(JSText);
        exit(JSText);
    end;

    procedure GetOrdersFromShipStation(): Text
    var
        JSText: Text;
        JSObject: JsonObject;
        OrdersJSArray: JsonArray;
        OrderJSToken: JsonToken;
        Counter: Integer;
        txtOrders: Text;
        txtCarrierCode: Text[50];
        txtServiceCode: Text[100];
        _SH: Record "Sales Header";
        txtMessage: TextConst ENU = 'Order(s) Updated:\ %1', RUS = 'Заказ(ы) обновлен(ы):\ %1';
    begin
        JSText := Connect2ShipStation(1, '', '');
        JSObject.ReadFrom(JSText);
        OrdersJSArray := GetJSToken(JSObject, 'orders').AsArray();

        for Counter := 0 to OrdersJSArray.Count - 1 do begin
            OrdersJSArray.Get(Counter, OrderJSToken);
            JSObject := OrderJSToken.AsObject();
            if _SH.Get(_SH."Document Type"::Order, GetJSToken(JSObject, 'orderNumber').AsValue().AsText()) then begin
                UpdateSalesHeaderFromShipStation(_SH."No.", JSObject);

                if txtOrders = '' then
                    txtOrders := GetJSToken(JSObject, 'orderNumber').AsValue().AsText()
                else
                    txtOrders += '|' + GetJSToken(JSObject, 'orderNumber').AsValue().AsText();
            end;

        end;
        Message(txtMessage, txtOrders);

        exit(txtOrders);
    end;

    procedure GetOrderFromShipStation(): Text
    var
        JSText: Text;
        JSObject: JsonObject;
        OrdersJSArray: JsonArray;
        OrderJSToken: JsonToken;
        Counter: Integer;
        txtOrders: Text;
        txtCarrierCode: Text[50];
        txtServiceCode: Text[100];
        _SH: Record "Sales Header";
        SourceParameters: Record "Source Parameters";
    begin
        // Get Order from Shipstation to Fill Variables
        JSText := Connect2ShipStation(1, '', StrSubstNo('/%1', _SH."ShipStation Order ID"));

        JSObject.ReadFrom(JSText);

        txtOrders := GetJSToken(JSObject, 'orderNumber').AsValue().AsText();
        if _SH.Get(_SH."Document Type"::Order, GetJSToken(JSObject, 'orderNumber').AsValue().AsText()) then
            UpdateSalesHeaderFromShipStation(_SH."No.", JSObject);
    end;

    local procedure GetShippingAgentService(_ServiceCode: Text[100]; _CarrierCode: Text[50]): Code[10]
    var
        _SAS: Record "Shipping Agent Services";
    begin
        _SAS.SetCurrentKey("SS Code", "SS Carrier Code");
        _SAS.SetRange("SS Carrier Code", _CarrierCode);
        _SAS.SetRange("SS Code", _ServiceCode);
        if _SAS.FindFirst() then
            exit(_SAS.Code);

        GetServicesFromShipStation(_CarrierCode);
        _SAS.FindFirst();
        exit(_SAS.Code);
    end;

    local procedure GetShippingAgent(_CarrierCode: Text[50]): Code[10]
    var
        _SA: Record "Shipping Agent";
    begin
        _SA.SetRange("SS Code", _CarrierCode);
        if _SA.FindFirst() then
            exit(_SA.Code)
        else
            exit(GetCarrierFromShipStation(_CarrierCode));
    end;

    procedure CreateOrderInShipStation(DocNo: Code[20]): Boolean
    var
        _SH: Record "Sales Header";
        _Cust: Record Customer;
        JSText: Text;
        JSObjectHeader: JsonObject;
        jsonTagsArray: JsonArray;
        txtAwaitingShipment: Label 'awaiting_shipment';
    begin
        if (DocNo = '') or (not _SH.Get(_SH."Document Type"::Order, DocNo)) then exit(false);

        _Cust.Get(_SH."Sell-to Customer No.");
        JSObjectHeader.Add('orderNumber', _SH."No.");
        JSObjectHeader.Add('orderKey', _SH."ShipStation Order Key");
        JSObjectHeader.Add('orderDate', Date2Text4JSON(_SH."Posting Date"));
        JSObjectHeader.Add('paymentDate', Date2Text4JSON(_SH."Prepayment Due Date"));
        JSObjectHeader.Add('shipByDate', Date2Text4JSON(_SH."Shipment Date"));
        JSObjectHeader.Add('orderStatus', txtAwaitingShipment);
        // JSObjectHeader.Add('customerId', _Cust."No.");
        JSObjectHeader.Add('customerUsername', _Cust."E-Mail");
        JSObjectHeader.Add('customerEmail', _Cust."E-Mail");
        JSObjectHeader.Add('billTo', jsonBillToFromSH(_SH."No."));
        JSObjectHeader.Add('shipTo', jsonShipToFromSH(_SH."No."));
        JSObjectHeader.Add('items', jsonItemsFromSL(_SH."No."));
        // uncomment when dimensions will be solution
        // JSObjectHeader.Add('dimensions', jsonDimentionsFromAttributeValue(_SH."No."));
        JSObjectHeader.Add('carrierCode', GetCarrierCodeByAgentCode(_SH."Shipping Agent Code"));
        JSObjectHeader.Add('serviceCode', GetServiceCodeByAgentServiceCode(_SH."Shipping Agent Code", _SH."Shipping Agent Service Code"));
        Clear(jsonTagsArray);
        JSObjectHeader.Add('tagIds', jsonTagsArray);
        JSObjectHeader.WriteTo(JSText);

        JSText := Connect2ShipStation(2, JSText, '');

        // update Sales Header from ShipStation
        JSObjectHeader.ReadFrom(JSText);
        UpdateSalesHeaderFromShipStation(DocNo, JSObjectHeader);

    end;

    local procedure GetCarrierCodeByAgentCode(ShippingAgentCode: Code[10]): Text[50]
    var
        _SA: Record "Shipping Agent";
        _jsonNull: JsonObject;
    begin
        if _SA.Get(ShippingAgentCode) then
            exit(_SA."SS Code")
        else
            exit('');
    end;

    local procedure GetServiceCodeByAgentServiceCode(ShippingAgentCode: Code[10]; ShippingAgentServiceCode: Code[10]): Text[50]
    var
        _SAS: Record "Shipping Agent Services";
        _jsonNull: JsonObject;
    begin
        if _SAS.Get(ShippingAgentCode, ShippingAgentServiceCode) then
            exit(_SAS."SS Code")
        else
            exit('');
    end;

    procedure UpdateSalesHeaderFromShipStation(DocNo: Code[20]; _jsonObject: JsonObject): Boolean
    var
        _SH: Record "Sales Header";
        txtCarrierCode: Text[50];
        txtServiceCode: Text[100];
        _jsonToken: JsonToken;
    begin
        if not _SH.Get(_SH."Document Type"::Order, DocNo) then exit(false);
        // update Sales Header from ShipStation

        _jsonToken := GetJSToken(_jsonObject, 'carrierCode');
        if not _jsonToken.AsValue().IsNull then
            txtCarrierCode := CopyStr(GetJSToken(_jsonObject, 'carrierCode').AsValue().AsText(), 1, MaxStrLen(txtCarrierCode));

        _jsonToken := GetJSToken(_jsonObject, 'serviceCode');
        if not _jsonToken.AsValue().IsNull then
            txtServiceCode := CopyStr(GetJSToken(_jsonObject, 'serviceCode').AsValue().AsText(), 1, MaxStrLen(txtServiceCode));

        _SH."ShipStation Order ID" := GetJSToken(_jsonObject, 'orderId').AsValue().AsInteger();
        _SH."ShipStation Order Key" := GetJSToken(_jsonObject, 'orderKey').AsValue().AsText();
        _SH."Shipping Agent Code" := GetShippingAgent(txtCarrierCode);
        _SH."Shipping Agent Service Code" := GetShippingAgentService(txtServiceCode, txtCarrierCode);
        _SH."ShipStation Status" := CopyStr(GetJSToken(_jsonObject, 'orderStatus').AsValue().AsText(), 1, MaxStrLen(_SH."ShipStation Status"));
        _SH."ShipStation Order Status" := _SH."ShipStation Order Status"::Sent;
        _SH.Modify();
    end;

    procedure CreateLabel2OrderInShipStation(DocNo: Code[20]): Boolean
    var
        _SH: Record "Sales Header";
        JSText: Text;
        JSObject: JsonObject;
        jsLabelObject: JsonObject;
        OrdersJSArray: JsonArray;
        OrderJSToken: JsonToken;
        Counter: Integer;
        notExistOrdersList: Text;
        OrdersListCreateLabel: Text;
        OrdersCancelled: Text;
        txtLabel: Text;
        txtTreckingNo: Text;
        WhseShipDocNo: Code[20];
    begin
        if (DocNo = '') or (not _SH.Get(_SH."Document Type"::Order, DocNo)) or (_SH."ShipStation Order ID" = 0) then exit(false);

        // Get Order from Shipstation to Fill Variables
        JSText := Connect2ShipStation(1, '', StrSubstNo('/%1', _SH."ShipStation Order ID"));

        JSObject.ReadFrom(JSText);
        JSText := Connect2ShipStation(3, FillValuesFromOrder(JSObject), '');

        // Update Order From Label
        UpdateOrderFromLabel(DocNo, JSText);

        // FindWarehouseSipment(DocNo, WhseShipDocNo); // comment to test Create Label and Attache to Warehouse Shipment
        WhseShipDocNo := '111'; // code to test attache

        // Add Lable to Shipment
        jsLabelObject.ReadFrom(JSText);
        txtLabel := GetJSToken(jsLabelObject, 'labelData').AsValue().AsText();
        txtTreckingNo := GetJSToken(jsLabelObject, 'trackingNumber').AsValue().AsText();
        // AddLabel2Shipment(txtLabel, WhseShipDocNo);

        SaveLabel2Shipment(txtTreckingNo, txtLabel, WhseShipDocNo);

        Message('Label Created and Attached to Warehouse Shipment %1', WhseShipDocNo);
    end;

    local procedure UpdateOrderFromLabel(DocNo: Code[20]; jsonText: Text);
    var
        _SH: Record "Sales Header";
        jsLabelObject: JsonObject;
    begin
        _SH.Get(_SH."Document Type"::Order, DocNo);
        jsLabelObject.ReadFrom(jsonText);
        _SH."ShipStation Insurance Cost" := GetJSToken(jsLabelObject, 'insuranceCost').AsValue().AsDecimal();
        _SH."ShipStation Shipment Cost" := GetJSToken(jsLabelObject, 'shipmentCost').AsValue().AsDecimal();
        _SH."ShipStation Tracking No." := GetJSToken(jsLabelObject, 'trackingNumber').AsValue().AsText();
        _SH.Modify();
    end;

    local procedure FindWarehouseSipment(_DocNo: Code[20]; var _WhseShipDcoNo: Code[20])
    var
        WhseShipLine: Record "Warehouse Shipment Line";
    begin
        with WhseShipLine do begin
            SetRange("Source Type", Database::"Sales Header");
            SetRange("Source Subtype", 1);
            SetRange("Source No.", _DocNo);
            FindFirst();
            _WhseShipDcoNo := "No.";
        end;
    end;

    local procedure SaveLabel2Shipment(_txtTreckingNo: Text; _txtLabelBase64: Text; _WhseShipDocNo: Code[20])
    var
        TempBlob: Record TempBlob;
        RecRef: RecordRef;
        WhseShipHeader: Record "Warehouse Shipment Header";
        lblOrder: TextConst ENU = 'labelWhseShmt', RUS = 'labelWhseShmt';
        DocumentAttachment: Record "Document Attachment";
        FileName: Text;
    begin
        RecRef.OPEN(DATABASE::"Warehouse Shipment Header");
        WhseShipHeader.Get(_WhseShipDocNo);
        RecRef.GETTABLE(WhseShipHeader);
        TempBlob.FromBase64String(_txtLabelBase64);
        FileName := StrSubstNo('%1-%2-%3.pdf', lblOrder, WhseShipHeader."No.", _txtTreckingNo);
        SaveAttachment2WhseShmt(RecRef, FileName, TempBlob);
    end;

    local procedure SaveAttachment2WhseShmt(RecRef: RecordRef; FileName: Text; TempBlob: Record TempBlob)
    var
        FieldRef: FieldRef;
        DocStream: InStream;
        RecNo: Code[20];
        DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        LineNo: Integer;
        DocumentAttachment: Record "Document Attachment";
        FileManagement: Codeunit "File Management";
        IncomingFileName: Text;
    begin
        with DocumentAttachment do begin
            IncomingFileName := FileName;
            Init();
            Validate("File Extension", FileManagement.GetExtension(IncomingFileName));
            Validate("File Name", CopyStr(FileManagement.GetFileNameWithoutExtension(IncomingFileName), 1, MaxStrLen("File Name")));
            TempBlob.Blob.CreateInStream(DocStream);
            "Document Reference ID".ImportStream(DocStream, IncomingFileName);
            Validate("Table ID", RecRef.Number);
            FieldRef := RecRef.Field(1);
            RecNo := FieldRef.Value;
            Validate("No.", RecNo);
            Insert(true);
        end;
    end;

    [EventSubscriber(ObjectType::Page, 1174, 'OnBeforeDrillDown', '', true, true)]
    local procedure BeforeDrillDownSetFilters(DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        RecNo: Code[20];
        WSHeader: Record "Warehouse Shipment Header";
    begin
        with DocumentAttachment do begin
            RecRef.OPEN(DATABASE::"Warehouse Shipment Header");
            IF WSHeader.GET("No.") THEN
                RecRef.GETTABLE(WSHeader);
        end;
    end;

    [EventSubscriber(ObjectType::Page, 1173, 'OnAfterOpenForRecRef', '', true, true)]
    local procedure AfterOpenForRecRefSetFilters(var DocumentAttachment: Record "Document Attachment"; var RecRef: RecordRef)
    var
        FieldRef: FieldRef;
        RecNo: Code[20];
    begin
        with DocumentAttachment do
            CASE RecRef.NUMBER OF
                DATABASE::"Warehouse Shipment Header":
                    BEGIN
                        SetRange("Table ID", Database::"Warehouse Shipment Header");
                        FieldRef := RecRef.FIELD(1);
                        RecNo := FieldRef.VALUE;
                        SETRANGE("No.", RecNo);
                    END;
            END;
    end;

    // local procedure AddLabel2Shipment(_txtLabelBase64: Text; _WhseShipDocNo: Code[20])
    // var
    //     TempBlob: Record TempBlob;
    //     WhseShipHeader: Record "Warehouse Shipment Header";
    //     lblOrder: TextConst ENU = 'labelWhseShmt', RUS = 'labelWhseShmt';
    //     IncomingDocumentAttachment: Record "Incoming Document Attachment";
    //     FileName: Text;
    // begin
    //     WhseShipHeader.Get(_WhseShipDocNo);
    //     TempBlob.FromBase64String(_txtLabelBase64);
    //     FileName := StrSubstNo('%1-%2-%3.pdf', lblOrder, WhseShipHeader."No.", WhseShipHeader."Posting Date");
    //     with IncomingDocumentAttachment do begin
    //         SetRange("Incoming Document Entry No.", GetLastIncomingDocumentEntryNo);
    //         SetRange("Document No.", WhseShipHeader."No.");
    //         SetRange("Posting Date", WhseShipHeader."Posting Date");
    //         Content := TempBlob.Blob;
    //     end;
    //     ImportAttachment(IncomingDocumentAttachment, FileName, TempBlob);
    // end;

    // local procedure GetLastIncomingDocumentEntryNo(): Integer
    // var
    //     IncomingDocumentAttachment: Record "Incoming Document Attachment";
    // begin
    //     IncomingDocumentAttachment.FindLast();
    //     exit(IncomingDocumentAttachment."Incoming Document Entry No." + 1);
    // end;

    // local procedure ImportAttachment(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; FileName: Text; _TempBlob: Record TempBlob): Boolean
    // var
    //     IncomingDocument: Record "Incoming Document";
    //     WhseShipHeader: Record "Warehouse Shipment Header";
    //     FileManagement: Codeunit "File Management";
    //     PostingDate: Date;
    //     DocNo: Code[20];
    // begin
    //     WITH IncomingDocumentAttachment DO BEGIN
    //         DocNo := GetFilter("Document No.");

    //         WhseShipHeader.Get(DocNo);
    //         WhseShipHeader.SetRange("No.", DocNo);
    //         WhseShipHeader.SetRange("Posting Date", WhseShipHeader."Posting Date");

    //         CreateIncomingDocument(IncomingDocumentAttachment, IncomingDocument, PostingDate, DocNo, WhseShipHeader.RecordId);
    //         IF IncomingDocument.Status IN [IncomingDocument.Status::"Pending Approval", IncomingDocument.Status::Failed] THEN
    //             IncomingDocument.TESTFIELD(Status, IncomingDocument.Status::New);
    //         "Incoming Document Entry No." := IncomingDocument."Entry No.";
    //         "Line No." := GetIncomingDocumentNextLineNo(IncomingDocument);
    //         Content := _TempBlob.Blob;

    //         VALIDATE("File Extension", LOWERCASE(COPYSTR(FileManagement.GetExtension(FileName), 1, MAXSTRLEN("File Extension"))));
    //         IF Name = '' THEN
    //             Name := COPYSTR(FileManagement.GetFileNameWithoutExtension(FileName), 1, MAXSTRLEN(Name));

    //         "Document No." := IncomingDocument."Document No.";
    //         "Posting Date" := IncomingDocument."Posting Date";
    //         IF IncomingDocument.Description = '' THEN BEGIN
    //             IncomingDocument.Description := COPYSTR(Name, 1, MAXSTRLEN(IncomingDocument.Description));
    //             IncomingDocument.MODIFY;
    //         END;

    //         INSERT(TRUE);
    //     END;
    //     EXIT(TRUE);
    // end;

    // local procedure CreateIncomingDocument(var IncomingDocumentAttachment: Record "Incoming Document Attachment"; var IncomingDocument: Record "Incoming Document"; PostingDate: Date; DocNo: Code[20]; RelatedRecordID: RecordID)
    // var
    //     DataTypeManagement: Codeunit "Data Type Management";
    //     RelatedRecordRef: RecordRef;
    //     RelatedRecord: Variant;
    // begin
    //     IncomingDocument.CreateIncomingDocument('', '');
    //     IncomingDocument."Document Type" := IncomingDocument."Document Type"::Journal;
    //     if RelatedRecordID.TableNo = 0 then
    //         if IncomingDocument.GetRecord(RelatedRecord) then
    //             if DataTypeManagement.GetRecordRef(RelatedRecord, RelatedRecordRef) then
    //                 RelatedRecordID := RelatedRecordRef.RecordId;
    //     IncomingDocument."Related Record ID" := RelatedRecordID;
    //     if IncomingDocument."Document Type" <> IncomingDocument."Document Type"::" " then begin
    //         if IncomingDocument.Posted then
    //             IncomingDocument.Status := IncomingDocument.Status::Posted
    //         else
    //             IncomingDocument.Status := IncomingDocument.Status::Created;
    //         IncomingDocument.Released := true;
    //         IncomingDocument."Released Date-Time" := CurrentDateTime;
    //         IncomingDocument."Released By User ID" := UserSecurityId;
    //         IncomingDocument."Document No." := IncomingDocumentAttachment.GetRangeMin("Document No.");
    //         IncomingDocument."Posting Date" := IncomingDocumentAttachment.GetRangeMin("Posting Date");
    //     end;
    //     IncomingDocument.Modify;
    // end;

    // local procedure GetIncomingDocumentNextLineNo(IncomingDocument: Record "Incoming Document"): Integer
    // var
    //     IncomingDocumentAttachment: Record "Incoming Document Attachment";
    // begin
    //     with IncomingDocumentAttachment do begin
    //         SetRange("Incoming Document Entry No.", IncomingDocument."Entry No.");
    //         if FindLast then;
    //         exit("Line No." + LineIncrement);
    //     end;
    // end;

    // local procedure LineIncrement(): Integer
    // begin
    //     exit(10000);
    // end;

    local procedure CreateListAsFilter(var _List: Text; _subString: Text)
    begin
        if _List = '' then
            _List += _subString
        else
            _List += '|' + _subString;
    end;

    local procedure FillValuesFromOrder(_JSObject: JsonObject): Text
    var
        JSObjectHeader: JsonObject;
        JSText: Text;
        jsonNull: JsonObject;
    begin
        JSObjectHeader.Add('orderId', GetJSToken(_JSObject, 'orderId').AsValue().AsInteger());
        JSObjectHeader.Add('carrierCode', GetJSToken(_JSObject, 'carrierCode').AsValue().AsText());
        JSObjectHeader.Add('serviceCode', GetJSToken(_JSObject, 'serviceCode').AsValue().AsText());
        JSObjectHeader.Add('packageCode', GetJSToken(_JSObject, 'packageCode').AsValue().AsText());
        JSObjectHeader.Add('confirmation', GetJSToken(_JSObject, 'confirmation').AsValue().AsText());
        JSObjectHeader.Add('shipDate', Date2Text4SS(Today));
        JSObjectHeader.Add('weight', GetJSToken(_JSObject, 'weight').AsObject());

        if not GetJSToken(_JSObject, 'dimensions').isValue() then
            JSObjectHeader.Add('dimensions', GetJSToken(_JSObject, 'dimensions').AsObject());
        if not GetJSToken(_JSObject, 'insuranceOptions').IsValue then
            JSObjectHeader.Add('insuranceOptions', GetJSToken(_JSObject, 'insuranceOptions').AsObject());
        if not GetJSToken(_JSObject, 'internationalOptions').IsValue then
            JSObjectHeader.Add('internationalOptions', GetJSToken(_JSObject, 'internationalOptions').AsObject());
        if not GetJSToken(_JSObject, 'advancedOptions').IsValue then
            JSObjectHeader.Add('advancedOptions', GetJSToken(_JSObject, 'advancedOptions').AsObject());

        JSObjectHeader.Add('testLabel', false);
        JSObjectHeader.WriteTo(JSText);
        // Message(JSText);
        exit(JSText);
    end;

    procedure jsonBillToFromSH(DocNo: Code[20]): JsonObject
    var
        JSObjectLine: JsonObject;
        txtBillTo: Text;
        _SH: Record "Sales Header";
        _Cust: Record Customer;
        _Contact: Record Contact;
    begin
        _SH.Get(_SH."Document Type"::Order, DocNo);
        _Cust.Get(_SH."Bill-to Customer No.");
        _Contact.Get(_SH."Bill-to Contact No.");

        JSObjectLine.Add('name', _SH."Bill-to Contact");
        JSObjectLine.Add('company', _Cust.Name);
        JSObjectLine.Add('street1', _SH."Bill-to Address");
        JSObjectLine.Add('street2', _SH."Bill-to Address 2");
        JSObjectLine.Add('street3', '');
        JSObjectLine.Add('city', _SH."Bill-to City");
        JSObjectLine.Add('state', _SH."Bill-to County");
        JSObjectLine.Add('postalCode', _SH."Bill-to Post Code");
        JSObjectLine.Add('country', _SH."Bill-to Country/Region Code");
        JSObjectLine.Add('phone', _Contact."Phone No.");
        JSObjectLine.Add('residential', false);
        exit(JSObjectLine);
    end;

    procedure jsonShipToFromSH(DocNo: Code[20]): JsonObject
    var
        JSObjectLine: JsonObject;
        txtShipTo: Text;
        _SH: Record "Sales Header";
        _Cust: Record Customer;
    begin
        _SH.Get(_SH."Document Type"::Order, DocNo);
        _Cust.Get(_SH."Sell-to Customer No.");

        JSObjectLine.Add('name', _SH."Sell-to Contact");
        JSObjectLine.Add('company', _SH."Sell-to Customer Name");
        JSObjectLine.Add('street1', _SH."Sell-to Address");
        JSObjectLine.Add('street2', _SH."Sell-to Address 2");
        JSObjectLine.Add('street3', '');
        JSObjectLine.Add('city', _SH."Sell-to City");
        JSObjectLine.Add('state', _SH."Sell-to County");
        JSObjectLine.Add('postalCode', _SH."Sell-to Post Code");
        JSObjectLine.Add('country', _SH."Ship-to Country/Region Code");
        JSObjectLine.Add('phone', _SH."Sell-to Phone No.");
        JSObjectLine.Add('residential', false);
        exit(JSObjectLine);
    end;

    procedure jsonItemsFromSL(DocNo: Code[20]): JsonArray
    var
        JSObjectLine: JsonObject;
        JSObjectArray: JsonArray;
        _SL: Record "Sales Line";
    // _ID: Record "Item Description";
    begin
        _SL.SetRange("Document Type", _SL."Document Type"::Order);
        _SL.SetRange("Document No.", DocNo);
        _SL.SetRange(Type, _SL.Type::Item);
        _SL.SetFilter(Quantity, '<>%1', 0);
        if _SL.FindSet(false, false) then
            repeat
                Clear(JSObjectLine);
                // _ID.Get(_SL."No.");
                JSObjectLine.Add('lineItemKey', _SL."Line No.");
                JSObjectLine.Add('sku', _SL."No.");
                JSObjectLine.Add('name', _SL.Description);
                // JSObjectLine.Add('imageUrl', _ID."Main Image URL");
                JSObjectLine.Add('weight', jsonWeightFromItem(_SL."No."));
                JSObjectLine.Add('quantity', Decimal2Integer(_SL.Quantity));
                JSObjectLine.Add('unitPrice', Round(_SL."Amount Including VAT" / _SL.Quantity, 0.01));
                JSObjectLine.Add('taxAmount', Round((_SL."Amount Including VAT" - _SL.Amount) / _SL.Quantity, 0.01));
                // JSObjectLine.Add('shippingAmount', 0);
                JSObjectLine.Add('warehouseLocation', _SL."Location Code");
                JSObjectLine.Add('productId', _SL."Line No.");
                JSObjectLine.Add('fulfillmentSku', '');
                JSObjectLine.Add('adjustment', false);
                JSObjectArray.Add(JSObjectLine);
            until _SL.Next() = 0;
        exit(JSObjectArray);
    end;

    local procedure Decimal2Integer(_Decimal: Decimal): Integer
    begin
        exit(Round(_Decimal, 1));
    end;

    procedure jsonWeightFromItem(ItemNo: Code[20]): JsonObject
    var
        JSObjectLine: JsonObject;
        txtWeight: Text;
        _Item: Record Item;
    begin
        _Item.Get(ItemNo);
        JSObjectLine.Add('value', _Item."Gross Weight");
        JSObjectLine.Add('units', 'ounces');
        exit(JSObjectLine);
    end;

    procedure jsonDimentionsFromAttributeValue(_No: Code[20]): JsonObject
    var
        JSObjectLine: JsonObject;
        lblInc: Label 'inches';
        lblCm: Label 'centimeters';
        txtUnits: Text;
        decDimension: Decimal;
    begin
        if Evaluate(decDimension, GetItemAttributeValue(Database::"Sales Header", _No, 'length', txtUnits)) then
            JSObjectLine.Add('length', decDimension);
        if Evaluate(decDimension, GetItemAttributeValue(Database::"Sales Header", _No, 'width', txtUnits)) then
            JSObjectLine.Add('width', decDimension);
        if Evaluate(decDimension, GetItemAttributeValue(Database::"Sales Header", _No, 'height', txtUnits)) then
            JSObjectLine.Add('height', decDimension);

        if txtUnits in [lblCm, lblInc] then
            JSObjectLine.Add('units', txtUnits)
        else
            JSObjectLine.Add('units', lblCm);
        exit(JSObjectLine);
    end;

    local procedure GetItemAttributeValue(TableID: Integer; ItemNo: Code[20]; TokenKey: Text; var _Units: Text): Text
    var
        _ItemAttr: Record "Item Attribute";
        _ItemAttrValue: Record "Item Attribute Value";
        _ItemAttrValueMapping: Record "Item Attribute Value Mapping";
        _UoM: Record "Unit of Measure";
    begin
        _ItemAttr.SetRange(Name, TokenKey);
        if _ItemAttr.FindFirst() then begin
            _Units := LowerCase(_ItemAttr."Unit of Measure");
            if _ItemAttrValueMapping.Get(TableID, ItemNo, _ItemAttr.ID) then begin
                _ItemAttrValue.Get(_ItemAttrValueMapping."Item Attribute ID", _ItemAttrValueMapping."Item Attribute Value ID");
                exit(_ItemAttrValue.Value);
            end;
        end;
        exit('');
    end;

    procedure GetJSToken(_JSONObject: JsonObject; TokenKey: Text) _JSONToken: JsonToken
    begin
        if not _JSONObject.Get(TokenKey, _JSONToken) then
            Error('Could not find a token with key %1', TokenKey);
    end;

    procedure SelectJSToken(_JSONObject: JsonObject; Path: Text) _JSONToken: JsonToken
    begin
        if not _JSONObject.SelectToken(Path, _JSONToken) then
            Error('Could not find a token with path %1', Path);
    end;

    local procedure Date2Text4SS(_Date: Date): Text
    var
        _Year: Text[4];
        _Month: Text[2];
        _Day: Text[2];
    begin
        EVALUATE(_Day, Format(Date2DMY(_Date, 1)));
        AddZero2String(_Day, 2);
        EVALUATE(_Month, Format(Date2DMY(_Date, 2)));
        AddZero2String(_Month, 2);
        EVALUATE(_Year, Format(Date2DMY(_Date, 3)));
        EXIT(_Year + '-' + _Month + '-' + _Day);
    end;

    local procedure GetDateFromJsonText(_DateText: Text): Date
    var
        Year: Integer;
        Month: Integer;
        Day: Integer;
    begin
        EVALUATE(Year, COPYSTR(_DateText, 1, 4));
        EVALUATE(Month, COPYSTR(_DateText, 6, 2));
        EVALUATE(Day, COPYSTR(_DateText, 9, 2));
        EXIT(DMY2DATE(Day, Month, Year));
    end;

    local procedure Date2Text4JSON(_Date: Date): Text
    var
        _Year: Text[4];
        _Month: Text[2];
        _Day: Text[2];
    begin
        EVALUATE(_Day, Format(Date2DMY(_Date, 1)));
        AddZero2String(_Day, 2);
        EVALUATE(_Month, Format(Date2DMY(_Date, 2)));
        AddZero2String(_Month, 2);
        EVALUATE(_Year, Format(Date2DMY(_Date, 3)));
        EXIT(_Year + '-' + _Month + '-' + _Day + 'T00:00:00.0000000');
    end;

    local procedure AddZero2String(var _String: Text; _maxLenght: Integer)
    begin
        while _maxLenght > StrLen(_String) do
            _String := StrSubstNo('%1%2', '0', _String);
    end;

    procedure GetCarrierFromShipStation(_SSAgentCode: Text[20]): Code[10]
    var
        JSText: Text;
        JSObject: JsonObject;
        CarrierToken: JsonToken;
        Counter: Integer;
        txtCarrierCode: Text[20];
        ShippingAgent: Record "Shipping Agent";
    begin
        JSText := Connect2ShipStation(6, '', _SSAgentCode);

        JSObject.ReadFrom(JSText);
        txtCarrierCode := CopyStr(GetJSToken(JSObject, 'code').AsValue().AsText(), 1, MaxStrLen(ShippingAgent."SS Code"));
        ShippingAgent.SetCurrentKey("SS Code");
        ShippingAgent.SetRange("SS Code", txtCarrierCode);
        if not ShippingAgent.FindFirst() then
            with ShippingAgent do begin
                Init();
                Code := GetLastCarrierCode();
                Name := CopyStr(GetJSToken(JSObject, 'name').AsValue().AsText(), 1, MaxStrLen(ShippingAgent.Name));
                "SS Code" := txtCarrierCode;
                "SS Provider Id" := GetJSToken(JSObject, 'shippingProviderId').AsValue().AsInteger();
                Insert();
            end;
        exit(ShippingAgent.Code);
    end;

    procedure GetCarriersFromShipStation(): Boolean
    var
        JSText: Text;
        JSObject: JsonObject;
        CarriersJSArray: JsonArray;
        CarrierToken: JsonToken;
        Counter: Integer;
        txtCarrierCode: Text[20];
        ShippingAgent: Record "Shipping Agent";
    begin
        JSText := Connect2ShipStation(4, '', '');

        CarriersJSArray.ReadFrom(JSText);
        foreach CarrierToken in CarriersJSArray do begin
            txtCarrierCode := CopyStr(GetJSToken(CarrierToken.AsObject(), 'code').AsValue().AsText(), 1, MaxStrLen(ShippingAgent."SS Code"));
            ShippingAgent.SetRange("SS Code", txtCarrierCode);
            if not ShippingAgent.FindFirst() then
                with ShippingAgent do begin
                    Init();
                    Code := '';
                    Name := CopyStr(GetJSToken(CarrierToken.AsObject(), 'name').AsValue().AsText(), 1, MaxStrLen(ShippingAgent.Name));
                    "SS Code" := txtCarrierCode;
                    "SS Provider Id" := GetJSToken(CarrierToken.AsObject(), 'shippingProviderId').AsValue().AsInteger();
                    Insert();
                end;
        end;
        exit(true);
    end;

    local procedure GetLastCarrierCode(): Code[10]
    var
        ShippingAgent: Record "Shipping Agent";
        lblSA_Code: Label 'SA-0001';
        lblSA_CodeFilter: Label 'SA-*';
    begin
        ShippingAgent.SetFilter(Code, '%1', lblSA_CodeFilter);
        if ShippingAgent.FindLast() then exit(IncStr(ShippingAgent.Code));
        exit(lblSA_Code);
    end;

    procedure GetServicesFromShipStation(_SSAgentCode: Text[20]): Boolean
    var
        JSText: Text;
        JSObject: JsonObject;
        CarriersJSArray: JsonArray;
        CarrierToken: JsonToken;
        Counter: Integer;
        ShippingAgentServices: Record "Shipping Agent Services";
        _SSCode: Text[50];
    begin
        JSText := Connect2ShipStation(5, '', _SSAgentCode);

        CarriersJSArray.ReadFrom(JSText);
        foreach CarrierToken in CarriersJSArray do begin
            _SSAgentCode := CopyStr(GetJSToken(CarrierToken.AsObject(), 'carrierCode').AsValue().AsText(), 1, MaxStrLen(ShippingAgentServices."SS Carrier Code"));
            _SSCode := CopyStr(GetJSToken(CarrierToken.AsObject(), 'code').AsValue().AsText(), 1, MaxStrLen(ShippingAgentServices."SS Code"));
            with ShippingAgentServices do begin
                SetCurrentKey("SS Carrier Code", "SS Code");
                SetRange("SS Carrier Code", _SSAgentCode);
                SetRange("SS Code", _SSCode);
                if FindFirst() then exit(true);

                Init();
                "Shipping Agent Code" := GetCarrierCodeBySSAgentCode(_SSAgentCode);
                Code := GetLastCarrierServiceCode();
                Insert();
                "SS Carrier Code" := _SSAgentCode;
                "SS Code" := _SSCode;
                Description := CopyStr(GetJSToken(CarrierToken.AsObject(), 'name').AsValue().AsText(), 1, MaxStrLen(ShippingAgentServices.Description));
                Modify();
            end;
        end;
        exit(true);
    end;

    local procedure GetCarrierCodeBySSAgentCode(_SSAgentCode: Text[20]): Code[10]
    var
        ShippingAgent: Record "Shipping Agent";
    begin
        with ShippingAgent do begin
            SetRange("SS Code", _SSAgentCode);
            FindFirst();
            exit(Code);
        end;
    end;

    local procedure GetLastCarrierServiceCode(): Code[10]
    var
        _SAS: Record "Shipping Agent Services";
        lblSASCode: Label 'SAS-0001';
        lblSASCodeFilter: Label 'SAS-*';
    begin
        _SAS.SetFilter(Code, '%1', lblSASCodeFilter);
        if _SAS.FindLast() then exit(IncStr(_SAS.Code));
        exit(lblSASCode);
    end;

    var
        testMode: Boolean;
}