/***************************************************************************************************************************************
* NAME         : PartsOrderDataSender
* DESCRIPTION  : Parts Order creation in SAP (Inbound to SAP from SVMX)
*                    
* @AUTHOR      : 
* @DATE        : 21-Aug-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public class PartsOrderDataSender extends ilib_RestSender {

    //Please note: Since these 2 are different endpoints shared by SAP. 2 custom metadata records are created.
    public static final String INTERFACE_NAME_HEAD = 'Outgoing_PartsOrder_Head'; //http "Head" method endpoint : This is required to get xcrsf token from SAP.
    public static final String INTERFACE_NAME_POST = 'Outgoing_PartsOrder_Post'; //http "POST" method endpoint : This is required to POST JSON body to SAP. 
    
    //Variables to hold the object name from where this interface is triggered.
    public static final String INTERFACE_TRIGGERED_FROM_PARTS_ORDER = 'Parts Order';
    public static final String INTERFACE_TRIGGERED_FROM_PARTS_REQUEST = 'Parts Request';
    public static final String INTERFACE_TRIGGERED_FROM_STOCK_TRANSFER = 'Stock Transfer';
    
    //Parts Order and Parts Order Line status
    public static final String STATUS_ON_HOLD = 'On Hold';
    public static final String STATUS_OPEN = 'Open';
    public static final String STATUS_SHIPPED = 'Shipped';

    //Order Type 
    public static final String SHIPMENT = 'Shipment'; // G2022-171

     /**
        * @description Set Http Method with required information 
        * @author         
        **/
    public enum HttpMethod {HEAD,POST} //hold http actions.
    public Map < Id, SVMXC__RMA_Shipment_Order__c > idToPartsOrder; //create a map to hold PartsOrder and its all child records (PartOrderLine)
    public Map < Id, SVMXC__Service_Order__c > idToWorkOrder; //map to hold WorkOrder data.
    public Map < Id, Case > idToCase; //map to hold Case data
    public set < Id > setPartsOrderId = new set < Id > (); //holds a set of partsOrder ids reieved from trigger.
    public set < Id > setWorkOrderId = new set < Id > (); //holds a set of workOrder ids reieved from trigger.
    public set < Id > setCaseId = new set < Id > (); //holds a set of case ids reieved from trigger.
    public string triggeredFrom = ''; //triggered from - Parts Order or Stock Transfer or Parts Request.
    public string partsOrderId = ''; //store the parts order id in context
    public Map < String, Map < String, String >> objectToPicklistValueMap = UtilsSettings.getCustomMetadataPicklistMap('SVMXC__RMA_Shipment_Line__c', 'ERP', true); //Picklist mapping - Parts Order Line (Return Reason)
    public Map < Integer, String > integerToSAPVariable = new Map < Integer, String > {0 => 'SH',1 => 'SP',2 => 'SB',3 => 'Z3'}; //Map to hold special SAP transalation logic.
    public Map < Integer, String > integerToSAPStockVariable = new Map < Integer, String > {0 => 'SB',1 => 'TO'};
    public Set < Id > setStockTransferId = new Set < Id > ();//holds a set of stockTransfer ids reieved from trigger.
    public Map < Id, SVMXC__Stock_Transfer__c > idToStockTransfer;//create a map to hold Stock Transfer and its all child records (Stock Transfer Lines)
    public Map < Id, SVMXC__Parts_Request__c > idToPartsRequest; //create a map to hold Parts Request and its all child records (Parts Request Lines)
    public set < Id > setAccountId  = new set < Id > (); //holds a set of Account ids attached to WO received from trigger - G2022-171
    public Map <Id, List<SVMXC__Service_Contract__c>> accountIdToServiceContract = new Map <Id, List<SVMXC__Service_Contract__c>>(); //Maps each Account Id with its related list of Active Dedicated Service Plans - G2022-171
    public Set <String> setServPlanItemNum = new Set <String>(); //holds the service plans item numbers - G2022-171
    public Set <String> setProductCode = new Set <String>(); // G2022-171
    public Map <Id, SVMXC__Service_Contract__c> idToServContract = new Map <Id, SVMXC__Service_Contract__c>(); // G2022-171
    public Map<Id, Product2> idToProduct2 = new Map<Id, Product2>(); // G2022-171
    public Map<Id, SVMXC__Service_Contract__c> filteredServContract = new Map<Id, SVMXC__Service_Contract__c>(); // G2022-171
    public String dedicate = 'DEDICATE'; // G2022-171


    /*
    *  Class to send data to external system
    */
    private class CalloutData extends ilib_CalloutData {

        SVMXC__RMA_Shipment_Order__c partOrderRecs;
		
		/*******************************************************************************************************
        * @description Constructor
        * @param partOrderRecs SVMXC__RMA_Shipment_Order__c
        */		
        public CalloutData(SVMXC__RMA_Shipment_Order__c partOrderRecs) {
            this.partOrderRecs = partOrderRecs;
        }

        SVMXC__Stock_Transfer__c stockTransferRecs;
		
		/*******************************************************************************************************
        * @description Constructor
        * @param stockTransferRecs SVMXC__Stock_Transfer__c
        */		
        public CalloutData(SVMXC__Stock_Transfer__c stockTransferRecs) {
            this.stockTransferRecs = stockTransferRecs;
        }

        SVMXC__Parts_Request__c partsRequestRecs;
		
		/*******************************************************************************************************
        * @description Constructor
        * @param partsRequestRecs SVMXC__Parts_Request__c
        */		
        public CalloutData(SVMXC__Parts_Request__c partsRequestRecs) {
            this.partsRequestRecs = partsRequestRecs;
        }

    }

    /*******************************************************************************************************
    * @description Variable for Class CalloutData
    */		
    private CalloutData data {
        get {
            return (CalloutData) idata;
        }
    }

    // this class uses selectors to populate CalloutData
	
    /*******************************************************************************************************
    * @description Overrided method definition for retrieveCalloutData
    * @return ilib_CalloutData 
    */	
    protected override ilib_CalloutData retrieveCalloutData() {

        if (recordId.getSObjectType().getDescribe().getName() == 'SVMXC__RMA_Shipment_Order__c') {
            PartsOrdersSelector partsOrderSelector = new PartsOrdersSelector();
            SVMXC__RMA_Shipment_Order__c partOrderRecs = partsOrderSelector.selectPartsOrders(new Set < Id > {
                recordId
            })[0];

            triggeredFrom = INTERFACE_TRIGGERED_FROM_PARTS_ORDER;
            CalloutData data = new CalloutData(partOrderRecs);
            partsOrderId = data.partOrderRecs.Id;
            system.debug('partsOrderId ' +partsOrderId);
            return data;
        } else if (recordId.getSObjectType().getDescribe().getName() == 'SVMXC__Parts_Request__c') {

            PartsRequestSelector partsRequestSelector = new PartsRequestSelector();

            SVMXC__Parts_Request__c partsRequestRecs = partsRequestSelector.selectPartsRequestById(new Set < Id > {
                recordId
            })[0];


            triggeredFrom = INTERFACE_TRIGGERED_FROM_PARTS_REQUEST;
            CalloutData data = new CalloutData(partsRequestRecs);
            return data;


        } else {
            StockTransfersSelector stockTransferSelector = new StockTransfersSelector();

            SVMXC__Stock_Transfer__c stockTransferRecs = stockTransferSelector.selectStockTransferById(new Set < Id > {
                recordId
            })[0];


            triggeredFrom = INTERFACE_TRIGGERED_FROM_STOCK_TRANSFER;
            CalloutData data = new CalloutData(stockTransferRecs);

            return data;
        }
    }

    // this method is the last line of defense to make sure we don't send garbage to
    // the target system.  Some validation will occur before the interface is called
    // but we may allow retriggers by admins so we need these sanity checks here
    // it builds a list of errors which are thrown to the caller
    // NOTE: a return might be a better choice, will think about that for hardening (or handle in ancestor)
	
	/*******************************************************************************************************
    * @description Overrided method definition for validateFields
    * @return void
    */
    protected override void validateFields() {

    }

    /**
     *  @AUTHOR Vaibhav Parashar
     *  @DESCRIPTION - Parts Order creation in SAP (Inbound to SAP from SVMX)
     *              - This Method will return String body in JSON format which will be used in HTTP request method.
     *  @PARAM : 
     *  @RETURN : void
     **/
    public override String createJSON() {
    
        //wrapper object holder.
        PartsOrderWrapper objINWListPartsOrder;

        /*********                        PARTS ORDER | START             **********/
        if (triggeredFrom.equals(INTERFACE_TRIGGERED_FROM_PARTS_ORDER)) {
        
            // holds parent and child data in a map.
            idToPartsOrder = new Map < Id, SVMXC__RMA_Shipment_Order__c > ([Select Id, Name, Sales_Area__c,Sales_Area__r.Distribution_Channel__c,Sales_Area__r.Sales_Organization__c,Sales_Area__r.Division__c,
                SVMXC__Priority__c, Shipping_Location__c, Shipping_Location__r.SVMX_PS_External_ID__c, Sold_To__r.ERP_Customer_Id__c,
                SVMXC__Destination_Location__c, SVMXC__Destination_Location__r.SVMX_PS_External_ID__c, SVMXC__Source_Location__c, SVMXC__Source_Location__r.SVMX_PS_External_ID__c,
                SVMXC__Company__r.ERP_Customer_Id__c, Special_Shipping_Instructions__c, Customer_Packing_Slip_Notes__c, SVMXC__Service_Order__r.ERP_Order_Number__c, Reason__c,
                SVMXC__Service_Order__r.PO_Number__c, SVMXC__Order_Type__c, SVMXC__Service_Order__c, SVMXC__Service_Order__r.Name,
                SVMXC__Case__r.CaseNumber, Care_Of__c, ERP_Sales_Order_Number__c, SVMXC__Case__c, Contact_Name__c, Contact_Phone__c, Ship_To_Company__c,
                Ship_To_Company_2__c, Shipping_Street__c, /*DCP-28844*/Send_Order_Notification_to_Contact_Email__c,Contact_Email__c,Shipping_Street_2__c, Shipping_Country__c, Shipping_State_Province__c, Shipping_State_Province_2__c, Shipping_City__c,
                Shipping_Postal_Code__c,Work_Detail_Line_Number__c,Cost_Center__c,
                (Select Id , Name,Parts_Order_Type__c,Stocked_Serial__c,Work_Detail_Line_Number__c , Stocked_Serial__r.Name, ERP_Contract_Number__c, Return_Reason__c, ERP_Contract_Line_Number__c, Reason__c, Is_Billable__c, Tracking_Number__c ,
                    SVMXC__Product__r.ProductCode, SVMXC__Actual_Quantity2__c, Batch_Number__c, SVMXC__Serial_Number__c, SVMXC__Serial_Number__r.SVMXC__Serial_Lot_Number__c, ERP_Sales_Order_Item__c, No_Substitute_Parts__c, Cost_Center__c, Actual_Delivery_Date__c, Requested_Delivery_Date__c, SVMXC__Shipped_On__c From SVMXC__RMA_Shipment_Line__r where SVMXC__Line_Status__c!='Canceled')

                From SVMXC__RMA_Shipment_Order__c Where Id =: data.partOrderRecs.Id
            ]);


            //iterate over the parts order and get work order and case id.
            for (Id partsOrderId: idToPartsOrder.keyset()) {
                //store work Order Ids
                if (idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c != null)
                    setWorkOrderId.add(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c);
                //store case Ids
                if (idToPartsOrder.get(partsOrderId).SVMXC__Case__c != null)
                    setCaseId.add(idToPartsOrder.get(partsOrderId).SVMXC__Case__c);
            }

            //populate work order map
            if (setWorkOrderId != null && !setWorkOrderId.isEmpty())
                idToWorkOrder = new Map < Id, SVMXC__Service_Order__c > (new WorkOrdersSelector().selectWorkOrders(setWorkOrderId));

            //G2022-171 - Start
            if(idToWorkOrder != null){
                for (Id workOrderId: idToWorkOrder.keyset()) {
                    //store Account Ids
                    if (idToWorkOrder.get(workOrderId).SVMXC__Company__c != null)
                        setAccountId.add(idToWorkOrder.get(workOrderId).SVMXC__Company__c);
                }
            }

            idToServContract = new Map < Id, SVMXC__Service_Contract__c > (new ServiceContractSelector().selectServContractsByAccountId(setAccountId));

            for (Id servContractId: idToServContract.keyset()) {
                if (idToServContract.get(servContractId).SVMXC__Service_Plan__r.Item_Number__c != null)
                    setServPlanItemNum.add(idToServContract.get(servContractId).SVMXC__Service_Plan__r.Item_Number__c );
            }

            idToProduct2 = 
            new Map < Id, Product2 > (new ProductsSelector().selectProductWithServLevel(setServPlanItemNum, dedicate));

            for (Id product2Id: idToProduct2.keyset()) {
                if (idToProduct2.get(product2Id).ProductCode != null)
                    setProductCode.add(idToProduct2.get(product2Id).ProductCode);
            }

            for(SVMXC__Service_Contract__c servContract : idToServContract.values()) {
                if(setProductCode.contains(servContract.SVMXC__Service_Plan__r.Item_Number__c)) {
                    filteredServContract.put(servContract.Id, servContract);
                }
            }

            for (SVMXC__Service_Contract__c serviceContract : filteredServContract.values()) { 
                Id accountId = serviceContract.SVMXC__Company__c; 
                if (!accountIdToServiceContract.containsKey(accountId)) { 
                    accountIdToServiceContract.put(accountId, new List<SVMXC__Service_Contract__c>()); 
                }
                    accountIdToServiceContract.get(accountId).add(serviceContract); 
            }
            //G2022-171 - End

            //populate case map
            if (setCaseId != null && !setCaseId.isEmpty())
                idToCase = new Map < Id, Case > (new CasesSelector().selectCasesFromSetIds(setCaseId));

            //Iterate over the ids recieved from PartsOrderClass.
            if (idToPartsOrder != null && !idToPartsOrder.isEmpty()) {
                for (Id partsOrderId: idToPartsOrder.keyset()) {
                    //create a new parts order wrapper data type record.
                    objINWListPartsOrder = new PartsOrderWrapper();

                    Map < Integer, String > integerPartsOrderInfo = new Map < Integer, String > {
                        0 => (idToPartsOrder.get(partsOrderId).Shipping_Location__r.SVMX_PS_External_ID__c != null ? idToPartsOrder.get(partsOrderId).Shipping_Location__r.SVMX_PS_External_ID__c : ''),
                        1 => (idToPartsOrder.get(partsOrderId).Sold_To__r.ERP_Customer_Id__c != null ? idToPartsOrder.get(partsOrderId).Sold_To__r.ERP_Customer_Id__c : ''),
                        2 => (idToPartsOrder.get(partsOrderId).SVMXC__Destination_Location__r.SVMX_PS_External_ID__c != null ? idToPartsOrder.get(partsOrderId).SVMXC__Destination_Location__r.SVMX_PS_External_ID__c : ''),
                        3 => (idToPartsOrder.get(partsOrderId).SVMXC__Company__r.ERP_Customer_Id__c != null ? idToPartsOrder.get(partsOrderId).SVMXC__Company__r.ERP_Customer_Id__c : ''),
                        4 => (idToPartsOrder.get(partsOrderId).SVMXC__Source_Location__r.SVMX_PS_External_ID__c != null ? idToPartsOrder.get(partsOrderId).SVMXC__Source_Location__r.SVMX_PS_External_ID__c : '')
                    };

                    //populate the fields for header.
                    objINWListPartsOrder.PackSlipNotes = (idToPartsOrder.get(partsOrderId).Customer_Packing_Slip_Notes__c != null ? idToPartsOrder.get(partsOrderId).Customer_Packing_Slip_Notes__c.replaceall('\\r\\n',' ').replaceall('\n',' ') : '');
                    objINWListPartsOrder.InternalNotes = (idToPartsOrder.get(partsOrderId).Special_Shipping_Instructions__c != null ? idToPartsOrder.get(partsOrderId).Special_Shipping_Instructions__c : '');
                    objINWListPartsOrder.ServiceOrd = (setWorkOrderId != null && !setWorkOrderId.isEmpty() && idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c).SVMX_PS_External_ID__c != null ? idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c).SVMX_PS_External_ID__c : '');
                    objINWListPartsOrder.PurchNoC = (setWorkOrderId != null && !setWorkOrderId.isEmpty() && idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c).PO_Number__c != null ? idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c).PO_Number__c : '');
                    objINWListPartsOrder.SvmxPartOrdTyp = (idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c != null ? idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c : '');
                    objINWListPartsOrder.SvmxPartOrd = (idToPartsOrder.get(partsOrderId).Name != null ? idToPartsOrder.get(partsOrderId).Name : '');
                    objINWListPartsOrder.SvmxWorkOrd = (setWorkOrderId != null && !setWorkOrderId.isEmpty() && idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c) != null ? idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c).Name : '');
                    objINWListPartsOrder.Caseid = (setCaseId != null && !setCaseId.isEmpty() && idToCase.get(idToPartsOrder.get(partsOrderId).SVMXC__Case__c) != null ? idToCase.get(idToPartsOrder.get(partsOrderId).SVMXC__Case__c).CaseNumber : '');
                    objINWListPartsOrder.Priority = (idToPartsOrder.get(partsOrderId).SVMXC__Priority__c != null ? idToPartsOrder.get(partsOrderId).SVMXC__Priority__c : '');
                    objINWListPartsOrder.PartOrder = (idToPartsOrder.get(partsOrderId).ERP_Sales_Order_Number__c != null ? idToPartsOrder.get(partsOrderId).ERP_Sales_Order_Number__c : '');
					
                    //DCP-25278 - Start
                    objINWListPartsOrder.SalesOrg = (idToPartsOrder.get(partsOrderId).Sales_Area__c != null ? idToPartsOrder.get(partsOrderId).Sales_Area__r.Sales_Organization__c : '');
                    objINWListPartsOrder.DistrChan = (idToPartsOrder.get(partsOrderId).Sales_Area__c != null ? idToPartsOrder.get(partsOrderId).Sales_Area__r.Distribution_Channel__c : '');
                    objINWListPartsOrder.Division = (idToPartsOrder.get(partsOrderId).Sales_Area__c != null ? idToPartsOrder.get(partsOrderId).Sales_Area__r.Division__c : '');
                    //DCP-25278 - End
					
                    //G2022-171 - Start
                     objINWListPartsOrder.CaseCategory = (setCaseId != null && !setCaseId.isEmpty() && idToCase.get(idToPartsOrder.get(partsOrderId).SVMXC__Case__c) != null 
                     && idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c != null && idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c == SHIPMENT && idToCase.get(idToPartsOrder.get(partsOrderId).SVMXC__Case__c).Category__c != null ? 
                     idToCase.get(idToPartsOrder.get(partsOrderId).SVMXC__Case__c).Category__c : '');
                     
                     objINWListPartsOrder.CaseSubType = (setCaseId != null && !setCaseId.isEmpty() && idToCase.get(idToPartsOrder.get(partsOrderId).SVMXC__Case__c) != null  
                     && idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c != null  && idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c == SHIPMENT && idToCase.get(idToPartsOrder.get(partsOrderId).SVMXC__Case__c).Sub_Type__c != null ?
                     idToCase.get(idToPartsOrder.get(partsOrderId).SVMXC__Case__c).Sub_Type__c : '');
 
                     objINWListPartsOrder.WORecordType= (idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c != null  && idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c == SHIPMENT && setWorkOrderId != null && !setWorkOrderId.isEmpty()
                     && idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c) != null && idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c).SVMX_PS_External_ID__c != null
                     && idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c).RecordType.Name != null ? idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c).RecordType.Name : '');
                     
                     objINWListPartsOrder.WOOrderType= (idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c != null  && idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c == SHIPMENT && setWorkOrderId != null && !setWorkOrderId.isEmpty()
                     && idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c) != null && idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c).SVMX_PS_External_ID__c != null
                     && idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c).SVMXC__Order_Type__c != null ? idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c).SVMXC__Order_Type__c : '');
                     
                     objINWListPartsOrder.DedicatedOnsiteCnt= (idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c != null  && idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c == SHIPMENT && idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c) != null
                     && idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c).SVMX_PS_External_ID__c != null && idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c).SVMXC__Company__c != null 
                     && accountIdToServiceContract.get(idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c).SVMXC__Company__c) != null ? 'X' : '');
                    //G2022-171 - End  

					//DCP-31970
                    objINWListPartsOrder.CostCenter = (idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c == 'Replenishment' && idToPartsOrder.get(partsOrderId).Cost_Center__c != null ? String.valueOf(idToPartsOrder.get(partsOrderId).Cost_Center__c) : '');
                    

                    if (setWorkOrderId != null && !setWorkOrderId.isEmpty() && String.isNotBlank(idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c).Opportunity__c)) {
                        objINWListPartsOrder.OpportunityId = idToWorkOrder.get(idToPartsOrder.get(partsOrderId).SVMXC__Service_Order__c).Opportunity__r.Id;
                    }


                    //Iterate over the child records (Parts Order Line) and populate the parent wrapper.
                    if (idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c.EqualsIgnoreCase('Return') || idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c.EqualsIgnoreCase('Scrap')
					 || idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c.EqualsIgnoreCase('Stock Transfer')) {
                        Integer j = 10;
                        for (SVMXC__RMA_Shipment_Line__c partsOrderLine: idToPartsOrder.get(partsOrderId).SVMXC__RMA_Shipment_Line__r) {
                            //populating NAVHDRTOITM object.
                            objINWListPartsOrder.NAVHDRTOITM.add(new PartsOrderWrapper.NAVHDRTOITM(partsOrderLine, j, objectToPicklistValueMap.get('Return_Reason__c').get(partsOrderLine.Return_Reason__c)))    ;
                            //populate NAVHDRTOSER object.
                            objINWListPartsOrder.NAVHDRTOSER.add(new PartsOrderWrapper.NAVHDRTOSER(partsOrderLine, j));

                            j += 10;
                        }
                    } else {
                        for (SVMXC__RMA_Shipment_Line__c partsOrderLine: idToPartsOrder.get(partsOrderId).SVMXC__RMA_Shipment_Line__r) {
                            //populating NAVHDRTOITM object.
                            objINWListPartsOrder.NAVHDRTOITM.add(new PartsOrderWrapper.NAVHDRTOITM(partsOrderLine,objectToPicklistValueMap.get('Return_Reason__c').get(partsOrderLine.Return_Reason__c)))    ;
                            //populate NAVHDRTOSER object.
                            objINWListPartsOrder.NAVHDRTOSER.add(new PartsOrderWrapper.NAVHDRTOSER(partsOrderLine));
                        }
                    }

                    //populating NAVHDRTOPTR object.
                    //Iterate 4 times to create 4 array records for NAVHDRTOPTR, each for different SAP variable.
                    for (Integer i = 0; i < 4; i++) {
                        if(!idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c.EqualsIgnoreCase('Stock Transfer')){
                            if (i == 2 && (idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c.EqualsIgnoreCase('Return') || idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c.EqualsIgnoreCase('Scrap')) ) {
                                objINWListPartsOrder.NAVHDRTOPTR.add(new PartsOrderWrapper.NAVHDRTOPTR(integerToSAPVariable.get(i), integerPartsOrderInfo.get(4)));
                            } 
                            else{
                                objINWListPartsOrder.NAVHDRTOPTR.add(new PartsOrderWrapper.NAVHDRTOPTR(integerToSAPVariable.get(i), integerPartsOrderInfo.get(i))); 
                            }
                            
                        }else{
                            if(i==0 && idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c.EqualsIgnoreCase('Stock Transfer')){
                                objINWListPartsOrder.NAVHDRTOPTR.add(new PartsOrderWrapper.NAVHDRTOPTR(integerToSAPVariable.get(i), integerPartsOrderInfo.get(2))); 
                                
                            } 
                            else if (i == 2 && idToPartsOrder.get(partsOrderId).SVMXC__Order_Type__c.EqualsIgnoreCase('Stock Transfer')) {
                                objINWListPartsOrder.NAVHDRTOPTR.add(new PartsOrderWrapper.NAVHDRTOPTR(integerToSAPVariable.get(i), integerPartsOrderInfo.get(4)));
                            }
                            else{
                                objINWListPartsOrder.NAVHDRTOPTR.add(new PartsOrderWrapper.NAVHDRTOPTR(integerToSAPVariable.get(i), ''));
                            }
                        }
                    }

                    //populate NAVHDRTOITMOUT object.
                    objINWListPartsOrder.NAVHDRTOITMOUT.add(new PartsOrderWrapper.NAVHDRTOITMOUT());

                    //populate NAVHDRTOHDROUT object.
                    objINWListPartsOrder.NAVHDRTOHDROUT = new PartsOrderWrapper.NAVHDRTOHDROUT();

                    //populate NAVHDRTORET object.
                    objINWListPartsOrder.NAVHDRTORET.add(new PartsOrderWrapper.NAVHDRTORET());

                     //DCP-28844 - Start
                    objINWListPartsOrder.Svmxextemail = idToPartsOrder.get(partsOrderId).Send_Order_Notification_to_Contact_Email__c  ? 'X' : '';
                    if(String.isNotBlank(idToPartsOrder.get(partsOrderId).Contact_Email__c) && idToPartsOrder.get(partsOrderId).Contact_Email__c.Contains(';')){
                    //split the semicolon values
                    List<String> lstContactEmail = idToPartsOrder.get(partsOrderId).Contact_Email__c.split(';');
                    for(String contactEmail : lstContactEmail){
                    //populate NAVHDRTOADDR object.
                    objINWListPartsOrder.NAVHDRTOADDR.add(new PartsOrderWrapper.NAVHDRTOADDR(idToPartsOrder.get(partsOrderId),contactEmail));
                    }
                    } else if(String.isNotBlank(idToPartsOrder.get(partsOrderId).Contact_Email__c) && !idToPartsOrder.get(partsOrderId).Contact_Email__c.Contains(';')){
                    //populate NAVHDRTOADDR object.
                    objINWListPartsOrder.NAVHDRTOADDR.add(new PartsOrderWrapper.NAVHDRTOADDR(idToPartsOrder.get(partsOrderId),idToPartsOrder.get(partsOrderId).Contact_Email__c));
                    } else {
                    objINWListPartsOrder.NAVHDRTOADDR.add(new PartsOrderWrapper.NAVHDRTOADDR(idToPartsOrder.get(partsOrderId),''));
                    }
                    //DCP-28844 - End

                }
            }
        }

        /*********                        PARTS ORDER | END             **********/


        /*********                        STOCK TRANSFER | START             **********/
        if (triggeredFrom.Equals(INTERFACE_TRIGGERED_FROM_STOCK_TRANSFER)) {
            
            // holds parent and child data in a map.
            idToStockTransfer = new Map < Id, SVMXC__Stock_Transfer__c > ([Select Id, SVMXC__Source_Location__c, SVMXC__Source_Location__r.SVMX_PS_External_ID__c, SVMXC__Destination_Location__r.SVMX_PS_External_ID__c, SVMXC__Destination_Location__c, (Select Id, Name, SVMXC__Product__c, SVMXC__Product__r.ProductCode, SVMXC__Quantity_Transferred2__c, SVMX_PS_VS_Serial_Number__c, Batch_Number__c FROM SVMXC__Stock_Transfer_Line__r) FROM SVMXC__Stock_Transfer__c Where Id =: data.stockTransferRecs.Id]);

            //Iterate over the ids recieved from PartsOrderClass.
            if (idToStockTransfer != null && !idToStockTransfer.isEmpty()) {

                for (Id stockTransferId: idToStockTransfer.keyset()) {

                    //create a new parts order wrapper data type record.
                    objINWListPartsOrder = new PartsOrderWrapper();

                    Map < Integer, String > integerStockTransferInfo = new Map < Integer, String > {
                        0 => (idToStockTransfer.get(stockTransferId).SVMXC__Source_Location__r.SVMX_PS_External_ID__c != null ? idToStockTransfer.get(stockTransferId).SVMXC__Source_Location__r.SVMX_PS_External_ID__c : ''),
                        1 => (idToStockTransfer.get(stockTransferId).SVMXC__Destination_Location__r.SVMX_PS_External_ID__c != null ? idToStockTransfer.get(stockTransferId).SVMXC__Destination_Location__r.SVMX_PS_External_ID__c : '')
                    };

                    objINWListPartsOrder.PackSlipNotes = '';
                    objINWListPartsOrder.InternalNotes = '';
                    objINWListPartsOrder.ServiceOrd = '';
                    objINWListPartsOrder.PurchNoC = '';
                    objINWListPartsOrder.SvmxPartOrdTyp = 'Transfer';
                    objINWListPartsOrder.SvmxPartOrd = '';
                    objINWListPartsOrder.SvmxWorkOrd = '';
                    objINWListPartsOrder.Caseid = '';
                    objINWListPartsOrder.Priority = '';
                    objINWListPartsOrder.PartOrder = '';

                    //Iterate over the child records (Parts Order Line) and populate the parent wrapper.
                    for (SVMXC__Stock_Transfer_Line__c stockTransferLine: idToStockTransfer.get(stockTransferId).SVMXC__Stock_Transfer_Line__r) {

                        //populating NAVHDRTOITM object.
                        objINWListPartsOrder.NAVHDRTOITM.add(new PartsOrderWrapper.NAVHDRTOITM(stockTransferLine));

                        //populate NAVHDRTOSER object.
                        objINWListPartsOrder.NAVHDRTOSER.add(new PartsOrderWrapper.NAVHDRTOSER(stockTransferLine));

                    }

                    //populating NAVHDRTOPTR object.
                    //Iterate 2 times to create 4 array records for NAVHDRTOPTR, each for different SAP variable.
                    for (Integer i = 0; i < 2; i++) {
                        objINWListPartsOrder.NAVHDRTOPTR.add(new PartsOrderWrapper.NAVHDRTOPTR(integerToSAPStockVariable.get(i), integerStockTransferInfo.get(i)));
                    }

                    //populate NAVHDRTOITMOUT object.
                    objINWListPartsOrder.NAVHDRTOITMOUT.add(new PartsOrderWrapper.NAVHDRTOITMOUT());

                    //populate NAVHDRTOHDROUT object.
                    objINWListPartsOrder.NAVHDRTOHDROUT = new PartsOrderWrapper.NAVHDRTOHDROUT();

                    //populate NAVHDRTORET object.
                    objINWListPartsOrder.NAVHDRTORET.add(new PartsOrderWrapper.NAVHDRTORET());

                    //populate NAVHDRTORET object.
                    objINWListPartsOrder.NAVHDRTOADDR.add(new PartsOrderWrapper.NAVHDRTOADDR());


                }

            }



        }

        /*********                        STOCK TRANSFER | END             **********/
        

        /*********                        PARTS REQUEST | START             **********/
        if (triggeredFrom.Equals(INTERFACE_TRIGGERED_FROM_PARTS_REQUEST)) {
            
            // holds parent and child data in a map.
            idToPartsRequest = new Map < Id, SVMXC__Parts_Request__c > ([Select Id, SVMXC__Requested_From__c, SVMXC__Requested_From__r.SVMX_PS_External_ID__c, SVMXC__Required_At_Location__r.SVMX_PS_External_ID__c, SVMXC__Required_At_Location__c, (Select Id, Name, SVMXC__Product__c, Batch_Number__c, SVMXC__Serial_Number_List__c, SVMXC__Product__r.ProductCode, SVMXC__Quantity_Required2__c FROM SVMXC__Parts_Request_Line__r) FROM SVMXC__Parts_Request__c Where Id =: data.partsRequestRecs.Id]);

            //Iterate over the ids recieved from PartsOrderClass.
            if (idToPartsRequest != null && !idToPartsRequest.isEmpty()) {

                for (Id partsRequestId: idToPartsRequest.keyset()) {

                    //create a new parts order wrapper data type record.
                    objINWListPartsOrder = new PartsOrderWrapper();

                    Map < Integer, String > integerPartsRequestInfo = new Map < Integer, String > {
                        0 => (idToPartsRequest.get(partsRequestId).SVMXC__Requested_From__r.SVMX_PS_External_ID__c != null ? idToPartsRequest.get(partsRequestId).SVMXC__Requested_From__r.SVMX_PS_External_ID__c : ''),
                        1 => (idToPartsRequest.get(partsRequestId).SVMXC__Required_At_Location__r.SVMX_PS_External_ID__c != null ? idToPartsRequest.get(partsRequestId).SVMXC__Required_At_Location__r.SVMX_PS_External_ID__c : '')
                    };

                    objINWListPartsOrder.PackSlipNotes = '';
                    objINWListPartsOrder.InternalNotes = '';
                    objINWListPartsOrder.ServiceOrd = '';
                    objINWListPartsOrder.PurchNoC = '';
                    objINWListPartsOrder.SvmxPartOrdTyp = 'Transfer';
                    objINWListPartsOrder.SvmxPartOrd = '';
                    objINWListPartsOrder.SvmxWorkOrd = '';
                    objINWListPartsOrder.Caseid = '';
                    objINWListPartsOrder.Priority = '';
                    objINWListPartsOrder.PartOrder = '';

                    //Iterate over the child records (Parts Order Line) and populate the parent wrapper.
                    for (SVMXC__Parts_Request_Line__c partsRequestLine: idToPartsRequest.get(partsRequestId).SVMXC__Parts_Request_Line__r) {

                        //populating NAVHDRTOITM object.
                        objINWListPartsOrder.NAVHDRTOITM.add(new PartsOrderWrapper.NAVHDRTOITM(partsRequestLine));

                        //populate NAVHDRTOSER object.
                        objINWListPartsOrder.NAVHDRTOSER.add(new PartsOrderWrapper.NAVHDRTOSER(partsRequestLine));

                    }

                    //populating NAVHDRTOPTR object.
                    //Iterate 2 times to create 4 array records for NAVHDRTOPTR, each for different SAP variable.
                    for (Integer i = 0; i < 2; i++) {
                        objINWListPartsOrder.NAVHDRTOPTR.add(new PartsOrderWrapper.NAVHDRTOPTR(integerToSAPStockVariable.get(i), integerPartsRequestInfo.get(i)));
                    }

                    //populate NAVHDRTOITMOUT object.
                    objINWListPartsOrder.NAVHDRTOITMOUT.add(new PartsOrderWrapper.NAVHDRTOITMOUT());

                    //populate NAVHDRTOHDROUT object.
                    objINWListPartsOrder.NAVHDRTOHDROUT = new PartsOrderWrapper.NAVHDRTOHDROUT();

                    //populate NAVHDRTORET object.
                    objINWListPartsOrder.NAVHDRTORET.add(new PartsOrderWrapper.NAVHDRTORET());

                    //populate NAVHDRTORET object.
                    objINWListPartsOrder.NAVHDRTOADDR.add(new PartsOrderWrapper.NAVHDRTOADDR());

                }

            }
        }
        /*********                        PARTS REQUEST | END             **********/

        //create the JSON structure of the data present in partsOrder wrapper.
        String strJson = JSON.serializePretty(objINWListPartsOrder);
        System.debug(LoggingLevel.INFO, 'JSON Output:\n' + strJson);
        return strJson;
    }

	/*******************************************************************************************************
    * @description Overrided method definition for executeCallout
    * @param strJson String
    * @return HttpResponse
    */
    public override HttpResponse executeCallout(String strJson) {

        //get the authenticated response.
        HttpResponse authResponse = authenticate();
        HttpResponse response;

        //update the parts order if we get an error during authentication / connection.
        List < SVMXC__RMA_Shipment_Order__c > lstPartOrderToUpdate = new List < SVMXC__RMA_Shipment_Order__c > ();

        //if the authResponse is "Ok" proceed ahead to extract the information.
        if (authResponse.getStatuscode() == 200) {

            //extract the csrf token from the header.
            String csrfToken = authResponse.getHeader('x-csrf-token');

            //set cookies.
            String cookie = authResponse.getHeader('set-cookie');

            if (cookie.indexOf(';') > -1) cookie = cookie.substring(0, cookie.indexOf(';'));
            Map < String, String > headerKeyToValue = new Map < String, String > {
                'x-csrf-token' => csrfToken,
                'content-type' => 'application/json',
                'cookie' => cookie,
                'accept' => 'application/json'
            };

            //populate the body by created JSON.
            String body = createJSON();

            //make final request with token in header.
            HttpRequest request = UtilsRest.createHttpRequest(INTERFACE_NAME_POST, HttpMethod.POST.name(), headerKeyToValue);
            System.debug('request ===> ' + request);
            
            //set time of the callout to 120000
            request.setTimeout(2 * 60 * 1000);
            
            //set the body to the json created.
            request.setBody(body);
            
            //send the request and capture the response.
            response = UtilsRest.send(request);

             //DCP-47700 - Added this line to 
             ilib_LogInterface.addMessageToLog(log, 'SAP Response : '+response.getBody());

            //check if the status code is not 400 or a bad request.
            if (String.valueOf(response.getStatuscode()).startsWith('2')) {
                
                //get the response body
                String result = response.getBody();
                System.debug('result ===> ' + result);
                
                // process the response in order to make updates on parts order. No other object response will be processed.
                if (triggeredFrom.Equals(INTERFACE_TRIGGERED_FROM_PARTS_ORDER)) {
                    //deserialize the response received into a wrapper class and make updates to parts order / parts order line as required.
                    deserializeInputs(result);
                }

            } else {
                 
                system.debug('Error Body ' +response.getBody());    
                //Its an error of some kind. Update the error on parts order.
                lstPartOrderToUpdate.add(new SVMXC__RMA_Shipment_Order__c(Id = partsOrderId, Submit_to_SAP__c = false, Integration_Error_Message__c = 'Status Code : ' +response.getStatuscode() + ' \r\n' +'Error Message : '  +response.getBody(), Integration_Status__c = 'E'));
            }

        } else {

            //Authentication Issue. Update the error on parts order.
            lstPartOrderToUpdate.add(new SVMXC__RMA_Shipment_Order__c(Id = partsOrderId, Submit_to_SAP__c = false,Integration_Error_Message__c = 'Authentication Issue', Integration_Status__c = 'E'));

        }

        if (lstPartOrderToUpdate != null && !lstPartOrderToUpdate.isEmpty()){
		  //DCP-26515:populate the integration message into a text field.
        for(SVMXC__RMA_Shipment_Order__c  partsOrder : lstPartOrderToUpdate){
        if(String.isNotBlank(partsOrder.Integration_Error_Message__c))
        partsOrder.Integration_Message_Details_Text__c = partsOrder.Integration_Error_Message__c.length() > 255 ? (partsOrder.Integration_Error_Message__c).substring(0,255) : partsOrder.Integration_Error_Message__c;
        partsOrder.Request_All_Part_Order_Lines_CS_Override__c = false;
        }
		update lstPartOrderToUpdate;		
		}
            

        return response;
    }

    /**
     *  @AUTHOR Vaibhav Parashar
     *  @DESCRIPTION - Get the access token from the SAP endpoint first.
     *  @PARAM : 
     *  @RETURN : void
     **/
    private static HttpResponse authenticate() {
        Map < String, String > headerKeyToValue = new Map < String, String > {
            'x-csrf-token' => 'fetch'
        };

        //make a request to SAP endpoint by using named credential, custom metadata type recrods.
        HttpRequest request = UtilsRest.createHttpRequest(INTERFACE_NAME_HEAD, HttpMethod.HEAD.name(), headerKeyToValue);
        return UtilsRest.send(request);
    }

    /**
     *  @AUTHOR Vaibhav Parashar
     *  @DESCRIPTION - Updates SAP Ids to SVMX Parts Order and SVMX Part Order line object.
     *  @PARAM : Response from SAP.
     *  @RETURN : void
     **/
    private void deserializeInputs(String jsonInput) {

        //this wrapper holds the JSON data recieved in response.
        PartsOrderResponseReceiver wrapContract = new PartsOrderResponseReceiver();
        wrapContract = (PartsOrderResponseReceiver) System.JSON.deserialize(jsonInput, PartsOrderResponseReceiver.class); //deserialize the json received into a wrapper class.

        //check status of response recieved from SAP.
        Boolean errorStatusCheck = true;
        String errorMessage = '';
        String errorType = '';
        Boolean hasXMessageType = false;
        Boolean hasEMessageType = false;
        

        //Parts Order Variables
        Map < String, String > partOrderNameToPartOrderExtId = new Map < String, String > ();
        Map < String, String > partOrderNameToPartOrderId = new Map < String, String > ();
        List < SVMXC__RMA_Shipment_Order__c > lstPartOrder = new List < SVMXC__RMA_Shipment_Order__c > ();
        List < SVMXC__RMA_Shipment_Order__c > lstPartOrderToUpdate = new List < SVMXC__RMA_Shipment_Order__c > ();
        List < String > lstPartOrderOrderType = new List < String > ();

        //Parts Order Line Variables
        Map < String, String > partOrderLineNameTopartOrderLineExtId = new Map < String, String > ();
        Map < String, String > partOrderLineNameToExpdShipDate = new Map < String, String > (); //Expected Ship Date
        Map < String, String > partOrderLineNameToExdDelDate = new Map < String, String > (); //Expected Delievery Date
        Map < String, String > partOrderLineNameToPartOrderLineId = new Map < String, String > ();
        List < SVMXC__RMA_Shipment_Line__c > lstPartOrderLine = new List < SVMXC__RMA_Shipment_Line__c > ();
        List < SVMXC__RMA_Shipment_Line__c > lstPartOrderLineToUpdate = new List < SVMXC__RMA_Shipment_Line__c > ();
		//bypass validation
        Map < String, Boolean > partOrderLineNameToBypassValidationCheck = new Map < String, Boolean > ();
        Map < String, Boolean > partOrderNameToBypassValidationCheck = new Map < String, Boolean > ();

        String partOrderExternalId = '';
           /********************************* Store SAP Part Order Number **********************************************/
        if (wrapContract.d.NAVHDRTOHDROUT != null && String.isNotBlank(wrapContract.d.NAVHDRTOHDROUT.SvmxPartOrd)) {
            lstPartOrder = [Select Id, SVMXC__Order_Type__c, Name,Bypass_Validation_Rules_for_Integration__c from SVMXC__RMA_Shipment_Order__c where Name =: wrapContract.d.NAVHDRTOHDROUT.SvmxPartOrd];
        } else {
            lstPartOrder = [Select Id, SVMXC__Order_Type__c, Name,Bypass_Validation_Rules_for_Integration__c from SVMXC__RMA_Shipment_Order__c where Name =: wrapContract.d.SvmxPartOrd];
        }

        //Store the salesforce id of partsOrder based on Name.
        if (lstPartOrder != null && !lstPartOrder.isEmpty()) {
            for (SVMXC__RMA_Shipment_Order__c partsOrd: lstPartOrder) {
                partOrderNameToPartOrderId.put(partsOrd.Name, partsOrd.Id);
				 //bypass validation
                partOrderNameToBypassValidationCheck.put(partsOrd.Name,partsOrd.Bypass_Validation_Rules_for_Integration__c);
                //Return type - Line Status
                lstPartOrderOrderType.add(partsOrd.SVMXC__Order_Type__c);
            }
        }



        if (wrapContract.d.NAVHDRTORET != null) {
            for (PartsOrderResponseReceiver.results wrapServContract: wrapContract.d.NAVHDRTORET.results) {

                if (wrapServContract.Type == 'X')
                    hasXMessageType = true;

                if (wrapServContract.Type == 'E')
                    hasEMessageType = true;


                errorType = wrapServContract.Type; //store the error type

                if (wrapServContract.Type != 'E' && wrapServContract.Type != 'X') {
                    errorStatusCheck = true;
                    errorMessage += wrapServContract.Type + ' : ' + wrapServContract.Message + ' \r\n';
                } else {
                    errorMessage += wrapServContract.Type + ' : ' + wrapServContract.Message + ' \r\n';
                    errorStatusCheck = false;
                }

            }
        }

        /****************** Store Information needed from Item records ***********************/
        if (wrapContract.d.NAVHDRTOITMOUT != null) {

            Set < string > partOrderLineNames = new Set < string > ();

            for (PartsOrderResponseReceiver.results itemRecords: wrapContract.d.NAVHDRTOITMOUT.results) {

                partOrderLineNames.add(itemRecords.PartOrdLn);
                partOrderLineNameTopartOrderLineExtId.put(itemRecords.PartOrdLn, itemRecords.ItmNumber);
                //store the dates
                partOrderLineNameToExpdShipDate.put(itemRecords.PartOrdLn, itemRecords.ExpShpDt);
                partOrderLineNameToExdDelDate.put(itemRecords.PartOrdLn, itemRecords.ExpDelDt);

            }

            if (partOrderLineNames != null && !partOrderLineNames.isEmpty())
                lstPartOrderLine = [Select Id, Name,Bypass_Validation_Rules_for_Integration__c from SVMXC__RMA_Shipment_Line__c where Name IN: partOrderLineNames];

            for (SVMXC__RMA_Shipment_Line__c partsOrdLine: lstPartOrderLine) {
                partOrderLineNameToPartOrderLineId.put(partsOrdLine.Name, partsOrdLine.Id);
				 //bypass validation
                partOrderLineNameToBypassValidationCheck.put(partsOrdLine.Name,partsOrdLine.Bypass_Validation_Rules_for_Integration__c);
            }

        }
        /****************** / Store Information needed from Item records ***********************/

        /****************** Store Information needed from Parent records ***********************/
        if (wrapContract.d.NAVHDRTOHDROUT != null) {
                        if(!lstPartOrderOrderType.isEmpty() && lstPartOrderOrderType[0] == 'Stock Transfer'){
            partOrderNameToPartOrderExtId.put(wrapContract.d.NAVHDRTOHDROUT.SvmxPartOrd, wrapContract.d.NAVHDRTOHDROUT.DocNumber);
            } else {
            partOrderNameToPartOrderExtId.put(wrapContract.d.NAVHDRTOHDROUT.SvmxPartOrd, wrapContract.d.NAVHDRTOHDROUT.PartOrder);
            }
        }


        //UPDATE: PARTS ORDER
        if (partOrderNameToPartOrderExtId.keyset() != null && errorStatusCheck) {
            for (String partOrderIds: partOrderNameToPartOrderExtId.keyset()) {
                if (String.isNotBlank(partOrderNameToPartOrderId.get(partOrderIds)) && String.isNotBlank(partOrderNameToPartOrderExtId.get(partOrderIds))){
                    lstPartOrderToUpdate.add(new SVMXC__RMA_Shipment_Order__c(Id = partOrderNameToPartOrderId.get(partOrderIds),Bypass_Validation_Rules_for_Integration__c = !partOrderNameToBypassValidationCheck.get(partOrderIds),Submit_to_SAP__c = false, Integration_Status__c = String.isBlank(errorType) ? 'S' : errorType, SVMXC__Order_Status__c = (errorStatusCheck || hasXMessageType ? STATUS_OPEN : STATUS_ON_HOLD), Integration_Error_Message__c = errorStatusCheck && String.isBlank(errorMessage) ? 'Success' : errorMessage, ERP_Sales_Order_Number__c = partOrderNameToPartOrderExtId.get(partOrderIds)));
                    partOrderExternalId =  partOrderNameToPartOrderExtId.get(partOrderIds);
                }
            }
        }

        //If there is an error update the Parts Order with the error message.
        
                        
        if (!errorStatusCheck) {

            for (String partOrderName: partOrderNameToPartOrderId.keyset()) {
                lstPartOrderToUpdate.add(new SVMXC__RMA_Shipment_Order__c(Id = partOrderNameToPartOrderId.get(partOrderName),Submit_to_SAP__c = false,
				Bypass_Validation_Rules_for_Integration__c = !partOrderNameToBypassValidationCheck.get(partOrderName),
				Integration_Status__c = String.isBlank(errorType) ? 'S' : errorType, SVMXC__Order_Status__c = (errorStatusCheck || hasXMessageType  ? STATUS_OPEN : STATUS_ON_HOLD), Integration_Error_Message__c = errorStatusCheck && String.isBlank(errorMessage) ? 'Success' : errorMessage, ERP_Sales_Order_Number__c = partOrderNameToPartOrderExtId.get(partOrderName)));
                partOrderExternalId = partOrderNameToPartOrderExtId.get(partOrderName);
            }
        }

        //Update Parts Order Line - If E = On Hold, If X = Open Else Requested
         if((hasXMessageType || hasEMessageType) && partOrderLineNameTopartOrderLineExtId == null || partOrderLineNameTopartOrderLineExtId.isEmpty()){
        
        lstPartOrderLine = [Select Id, Name,SVMXC__Line_Status__c,Bypass_Validation_Rules_for_Integration__c from SVMXC__RMA_Shipment_Line__c where SVMXC__RMA_Shipment_Order__r.Name IN: partOrderNameToPartOrderId.Keyset()];
		
        if (lstPartOrderLine != null && !lstPartOrderLine.isEmpty()) {

            for (SVMXC__RMA_Shipment_Line__c rmaShipmentLine: lstPartOrderLine) {

                if (hasXMessageType)
                    rmaShipmentLine.SVMXC__Line_Status__c = STATUS_OPEN;

                //DCP-47700 - Added a condition to make the corresponding lines to hold when PO is in hold status for Archived      
                if (hasEMessageType || errorMessage.contains(System.Label.PartsOrderArchieved)){
                    rmaShipmentLine.SVMXC__Line_Status__c = STATUS_ON_HOLD;
                }


				//bypass validation
                rmaShipmentLine.Bypass_Validation_Rules_for_Integration__c = !rmaShipmentLine.Bypass_Validation_Rules_for_Integration__c;

                lstPartOrderLineToUpdate.add(rmaShipmentLine);

            }

        }
    }


        //iterate over part order line and update SAP id in SFDC.
        //UPDATE: PARTS ORDER LINE
        if (partOrderLineNameTopartOrderLineExtId.keyset() != null) {

            for (String partOrderLineIds: partOrderLineNameTopartOrderLineExtId.keyset()) {

                if (String.isNotBlank(partOrderLineNameToPartOrderLineId.get(partOrderLineIds)) && String.isNotBlank(partOrderLineNameTopartOrderLineExtId.get(partOrderLineIds))) {

                    SVMXC__RMA_Shipment_Line__c rmaShipmentLine = new SVMXC__RMA_Shipment_Line__c();

                    rmaShipmentLine.Id = partOrderLineNameToPartOrderLineId.get(partOrderLineIds);
                    rmaShipmentLine.ERP_Sales_Order_Item__c = partOrderLineNameTopartOrderLineExtId.get(partOrderLineIds);

                    //Return type - Line Status
                    if (lstPartOrderOrderType != null && !lstPartOrderOrderType.isEmpty() && (lstPartOrderOrderType[0] == 'Return' || lstPartOrderOrderType[0] == 'Stock Transfer')){
                        rmaShipmentLine.SVMXC__Line_Status__c = STATUS_SHIPPED;
                        if(lstPartOrderOrderType[0] == 'Return'){
                            rmaShipmentLine.External_ID__c = partOrderExternalId + partOrderLineNameTopartOrderLineExtId.get(partOrderLineIds);
                        }
                    }

                    //if SAP returns an X message : Update the line status to Open.
                    if (hasXMessageType)
                        rmaShipmentLine.SVMXC__Line_Status__c = STATUS_OPEN;

                    //DCP-47700 - Added a condition to make the corresponding lines to hold when PO is in hold status for Archived 
                    if (hasEMessageType || errorMessage.contains(System.Label.PartsOrderArchieved)){
                        rmaShipmentLine.SVMXC__Line_Status__c = STATUS_ON_HOLD;
                    }


                    if (String.isNotBlank(partOrderLineNameToExdDelDate.get(partOrderLineIds))) {
                        rmaShipmentLine.Expected_Delivery_Date__c = Date.valueOf(DateTime.newInstance(Long.valueOf(partOrderLineNameToExdDelDate.get(partOrderLineIds).substringBetween('(', ')'))));
                    }

                    if (String.isNotBlank(partOrderLineNameToExpdShipDate.get(partOrderLineIds))) {
                        rmaShipmentLine.SVMXC__Expected_Ship_Date__c = Date.valueOf(DateTime.newInstance(Long.valueOf(partOrderLineNameToExpdShipDate.get(partOrderLineIds).substringBetween('(', ')'))));
                    }
					
					//bypass validation
                    rmaShipmentLine.Bypass_Validation_Rules_for_Integration__c = !partOrderLineNameToBypassValidationCheck.get(partOrderLineIds);

                    lstPartOrderLineToUpdate.add(rmaShipmentLine);

                }

            }
        }



        
        if (lstPartOrderToUpdate != null && !lstPartOrderToUpdate.isEmpty()){
		  //DCP-26515:populate the integration message into a text field.
        for(SVMXC__RMA_Shipment_Order__c  partsOrder : lstPartOrderToUpdate){
        if(String.isNotBlank(partsOrder.Integration_Error_Message__c))
        partsOrder.Integration_Message_Details_Text__c = partsOrder.Integration_Error_Message__c.length() > 255 ? (partsOrder.Integration_Error_Message__c).substring(0,255) : partsOrder.Integration_Error_Message__c;
         partsOrder.Request_All_Part_Order_Lines_CS_Override__c = false;

         //DCP-47700 - Added a condition to check if the error message have the archived message in it. Checking here since there are multiple
        //            messages coming as part of the response.
        if(errorMessage.contains(System.Label.PartsOrderArchieved)){
            partsOrder.SVMXC__Order_Status__c = STATUS_ON_HOLD;
            } 

        }
        system.debug('lstPartOrderToUpdate ==> ' + lstPartOrderToUpdate);
		update lstPartOrderToUpdate;		
		}
            

        system.debug('lstPartOrderLineToUpdate ==> ' + lstPartOrderLineToUpdate);
        if (lstPartOrderLineToUpdate != null && !lstPartOrderLineToUpdate.isEmpty())
            update lstPartOrderLineToUpdate;

    }

	/*******************************************************************************************************
    * @description Overrided method definition for handleResult
    * @param res HTTPResponse
    * @return void
    */
    protected override void handleResult(HTTPResponse res) {
        System.debug('res: ' + res);
    }

}