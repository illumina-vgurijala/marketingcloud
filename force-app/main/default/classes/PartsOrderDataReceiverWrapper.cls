/***************************************************************************************************************************************
* NAME         : PartsOrderDataReceiverWrapper
* DESCRIPTION  : Parts Order Synchronization to DCP(ServiceMax) 
*              : Wrapper class to hold JSON received. 
* @AUTHOR      : 
* @DATE        : 12-Oct-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
                                     
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public class PartsOrderDataReceiverWrapper {

    //Wrapper to hold data related to Parent object.(Parts Order)

		/*
        * @description: Wrapper class holds data related to Parts Order object
        */	
    public class PartsOrder {

        /** External Id **/
        public String SVMXC_Sales_Order_Number;
        public String SVMXC_Order_Status;
        public String Integration_Error_Message;

        //holds all parts order line record associated with a parts order.
        public List<PartsOrderLine> PartsOrderLine = new List<PartsOrderLine>();

        /**
        * @description Instantiate the Parts Order Object with required information.
        * @author 
        * @return SVMXC__RMA_Shipment_Order__c 
        **/
        public SVMXC__RMA_Shipment_Order__c getSObject() {
            SVMXC__RMA_Shipment_Order__c partsOrder = new SVMXC__RMA_Shipment_Order__c(ERP_Sales_Order_Number__c = this.SVMXC_Sales_Order_Number/*,SVMXC__Order_Status__c = this.SVMXC_Order_Status, Integration_Error_Message__c = this.Integration_Error_Message*/);
            return partsOrder;
        }

    }


    //Wrapper to hold data related to child object.
	
    /*
    * @description: Wrapper class holds data related to Parts Order Line object
    */	
    public class PartsOrderLine {

        /** External Id = ERP_Sales_Order_Item + SVMXC_Serial_Number_List **/
        public String ERP_Sales_Order_Item;
        
        /** Lookup variables **/
        public String SVMXC_Product; // match the value coming with the material number on product object.
        public String From_Location; // match the value coming with the external id on location object.
        public String To_Location;// match the value coming with the external id on location object
        public String SVMXC_Serial_Number_List; // match the value coming with the product code of installed product.
        public String SVMXC_Equipment_Number; //added as part of Incident to avoid duplicate IP creation through equipment master interface (INC0214764)
        /** String variables **/
        public String SVMXC_Actual_Quantity2;
        //DCP-47694 start
        public String Shipped_Qty;
        public String Delivery;
        //DCP-47694 end
        public String Batch_Number;
        public String SVMXC_Line_Status;
        
        /** Date variables **/
        public String SVMXC_Expected_Ship_Date;
        public String Expected_Delivery_Date;
        public String Requested_Delivery_Date;
        public String Actual_Delivery_Date;
        public String SVMXC_Actual_Ship_Date;
        public String Batch_Expiration; //DCP-[31054]
        public String Tracking_Number;  // CMCM-4585
        public String Return_Reason_Code; // CMCM-4585
        public String MAC_Address; //CMCM-9541
        /** List **/
        public List <Tracking_Data> Tracking_Data = new List <Tracking_Data>(); //DCP-47007

        /*
        * @description: Instantiate the SVMXC__RMA_Shipment_Line__c Object with required information.
        * @return:SObject: returns Parts order line object records
        */	
        public SVMXC__RMA_Shipment_Line__c getSObject() {
            
            SVMXC__RMA_Shipment_Line__c partsOrderLine = new SVMXC__RMA_Shipment_Line__c();
            partsOrderLine.ERP_Sales_Order_Item__c = this.ERP_Sales_Order_Item;
            //DCP-47694 start
            //partsOrderLine.SVMXC__Actual_Quantity2__c =  (String.IsNotBlank(SVMXC_Actual_Quantity2) ? Decimal.valueOf(this.SVMXC_Actual_Quantity2.trim()) : 0); 
            partsOrderLine.Delivery__c = this.Delivery;
            //DCP-47694 end
            partsOrderLine.Batch_Number__c = this.Batch_Number;
            partsOrderLine.SVMXC__Serial_Number_List__c = this.SVMXC_Serial_Number_List;
            //partsOrderLine.SVMXC__Line_Status__c = String.valueOf(this.SVMXC_Line_Status);
            
            /** Date variables **/
            
             if (String.isNotBlank(SVMXC_Expected_Ship_Date)) {
                partsOrderLine.SVMXC__Expected_Ship_Date__c = date.valueOf(this.SVMXC_Expected_Ship_Date);
            }
            
            if (String.isNotBlank(Expected_Delivery_Date)) {
                partsOrderLine.Expected_Delivery_Date__c = date.valueOf(this.Expected_Delivery_Date);
            }
            
            if (String.isNotBlank(Requested_Delivery_Date)) {
                partsOrderLine.Requested_Delivery_Date__c = date.valueOf(this.Requested_Delivery_Date);
            }
            
            if (String.isNotBlank(Actual_Delivery_Date)) {
                partsOrderLine.Actual_Delivery_Date__c = date.valueOf(this.Actual_Delivery_Date);
            }
            
            if (String.isNotBlank(SVMXC_Actual_Ship_Date)) {
                partsOrderLine.SVMXC__Actual_Ship_Date__c = date.valueOf(this.SVMXC_Actual_Ship_Date);
            }
			 //DCP-[31054]
            if (String.isNotBlank(Batch_Expiration)) {
                partsOrderLine.Batch_Expiration__c = date.valueOf(this.Batch_Expiration);
            }
            //DCP-47007
			String strTrackingURL = '';
            if (Tracking_Data != null && !Tracking_Data.isEmpty()) {
                if(String.isNotBlank(String.valueOf(Tracking_Data[0].Public_Tracking_URL))){
                strTrackingURL ='<p>'+String.valueOf(Tracking_Data[0].Public_Tracking_URL);
               	for (integer i = 1 ; i < Tracking_Data.size() ; i++ ) {
                     strTrackingURL = strTrackingURL+ '<br/>' +String.valueOf(Tracking_Data[i].Public_Tracking_URL);      
                }
               strTrackingURL=strTrackingURL+'<p/>';
			if(String.isNotBlank(strTrackingURL)){  
                       partsOrderLine.Public_Tracking_URL__c = strTrackingURL;                  
                    }
            	}
            }
            return partsOrderLine;
        }

    }

		/*
        * @description: Wrapper class holds data assigned to Public_Tracking_URL variable
        */
    public class Tracking_Data {
        public String Public_Tracking_URL;
    }


}

/*
SAMPLE INPUT RECIEVED

[{
    "SVMXC_Order_Status": "Complete",
    "Integration_Error_Message": "Completed",
    "SVMXC_Sales_Order_Number": "1981520",
    "PartsOrderLine": [{
            "ERP_Sales_Order_Item": "000010",
            "SVMXC_Product": "15067093",
            "SVMXC_Actual_Quantity2": "1.000 ",
            "Shipped_qty":"1.000",
            "Delivery":"12345_6789",
            "SVMXC_Expected_Ship_Date": "2018-12-11",
            "Expected_Delivery_Date": "2018-12-11",
            "SVMXC_Actual_Ship_Date": "2018-12-11",
            "Actual_Delivery_Date": "2018-12-11",
            "Tracking_Data": [{
                    "Public_Tracking_URL": "https://tinyurl.com/trackpd?t=1Z2E032A0490756433"
                },
                {
                    "Public_Tracking_URL": "https://tinyurl.com/trackpd?t=1Z2E032A0492808829"
                },
                {
                    "Public_Tracking_URL": "https://tinyurl.com/trackpd?t=1Z2E032A0493186811"
                }
            ],
            "SVMXC_Line_Status": "Complete",
            "SVMXC_Serial_Number_List": "",
            "SVMXC_Equipment_Number": "",
            "To_Location": "TS200999",
            "Batch_Number": "",
            "Batch_Expiration": "",
            "Name": "LN 01147970",
            "Requested_Delivery_Date": "2018-12-11",
            "Log": "Log"
        },
        {
            "ERP_Sales_Order_Item": "000020",
            "SVMXC_Product": "15067092",
            "SVMXC_Actual_Quantity2": "1.000 ",
            "SVMXC_Expected_Ship_Date": "2018-12-11",
            "Expected_Delivery_Date": "2018-12-11",
            "SVMXC_Actual_Ship_Date": "2018-12-11",
            "Actual_Delivery_Date": "2018-12-11",
            "Tracking_Data": [{
                "Public_Tracking_URL": "https://tinyurl.com/trackpd?t=1Z2E032A0495488303"
            }],
            "SVMXC_Line_Status": "Complete",
            "SVMXC_Serial_Number_List": "",
            "SVMXC_Equipment_Number": "",
            "To_Location": "TS200999",
            "Batch_Number": "",
            "Batch_Expiration": "",
            "Name": "LN 01147971",
            "Requested_Delivery_Date": "2018-12-11"
        }
    ]
}]

*/