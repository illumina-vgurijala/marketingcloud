/***************************************************************************************************************************************
* NAME         : InventoryDataReceiverWrapper
* DESCRIPTION  : Inventory Synchronization to DCP(ServiceMax) 
*              : Wrapper class to hold JSON received. 
* @AUTHOR      : 
* @DATE        : 14-Oct-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* KD                    25-June-2021           DCP-46257 : Refactored code to include incremental sync
                                     
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public class InventoryDataReceiverWrapper {
    //Wrapper to hold data related to Parent object.
		/*
         * description - Wrapper to hold data related to Parent object.
         */ 
    public class Location {
        // DCP-46257
        public String Action;
        public String SalesOrderNumber;
        //Unique id based on which Location record will be identified.
        /** External Id **/
        public String Location;
        //List to hold product stock records.
        public List < ProductStock > ProductStock = new List < ProductStock > ();
        //Instantiate the Parts Order Object with required information.

        /*
         * description - Instantiate the Parts Order Object with required information.
         */ 		
        public SVMXC__Site__c getSObject() {
            SVMXC__Site__c location = new SVMXC__Site__c(SVMX_PS_External_ID__c = this.Location);
            return location;
        }
    }
    //Wrapper to hold data related to child object.

        /*
         * description - Wrapper to hold data related to child object.
         */	
    public class ProductStock {
        /** External Id **/
        /* Combination of Location and Product acts as an external Id */
        /** Lookup variables **/
        public String SVMXC_Product;
        /** String variables **/
        public String SVMXC_Quantity2;
        public String SVMXC_Status;
        /** List variables **/
        public List < StockedSerial > StockedSerial = new List < StockedSerial > ();
        public List < StockedBatch > StockedBatch = new List < StockedBatch > ();
        //Instantiate child Object with required information.

		/* 
        * @description: To intantiate required information related to object product Stock
        * @return: SObject - SVMXC__Product_Stock__c 
        */	
        public SVMXC__Product_Stock__c getSObject() {
            SVMXC__Product_Stock__c productStock = new SVMXC__Product_Stock__c(SVMXC__Quantity2__c = (String.IsNotBlank(SVMXC_Quantity2) ? Decimal.valueOf(this.SVMXC_Quantity2) : 0), SVMXC__Status__c = this.SVMXC_Status);
            return productStock;
        }
    }
    

		/*
		* @description:Wrapper to hold data related to subchild object.
		*/	
    public class StockedSerial {
        /** External Id **/
        /* Location + Name act as an external Id */
        /** String variables **/
        public String Name;
        public String Batch_Number; //[DCP-31054]
        public String Batch_Expiration; //[DCP-31054]
		public String Equipment_ID; //INC0214764										
        

		/*
		* @description:Instantiate subchild Object with required information.
        * @return: SObject- SVMXC__Product_Serial__c
		*/	
        public SVMXC__Product_Serial__c getSObject() {
            //populate all fields except lookup fields.
            SVMXC__Product_Serial__c stockedSerial = new SVMXC__Product_Serial__c();
            stockedSerial.Name = this.Name;
            stockedSerial.SVMXC__Active__c = true;
            stockedSerial.Batch_Number__c = this.Batch_Number; //[DCP-31054]
            if (String.isNotBlank(Batch_Expiration)) { //[DCP-31054]
                stockedSerial.Batch_Expiration__c = date.valueOf(this.Batch_Expiration);
            }
            return stockedSerial;
        }
    }
    //Wrapper class for StockedBatch array [DCP-31054]
    //Note: We are not storing these values in any object in SFDC. The fields are being read directly.

		/*
		* @description:Wrapper to hold data related to Stocked Batch
		*/
    public class StockedBatch {
        public String Batch_Number;
        public Decimal Quantity;
        public String Batch_Expiration;
		public String Equipment_ID; //INC0214764	
		
		/*
		* @description:Instantiate Stocked Batch with required information.
		*/
        public SVMXC__Product_Serial__c getSObject() {
            //populate all fields except lookup fields.
            SVMXC__Product_Serial__c stockedSerial = new SVMXC__Product_Serial__c();
            stockedSerial.Name = this.Batch_Number;
            stockedSerial.SVMXC__Active__c = true;
            stockedSerial.Quantity__c = this.Quantity;
            stockedSerial.Batch_Number__c = this.Batch_Number; //[DCP-31054]
            if (String.isNotBlank(Batch_Expiration)) { //[DCP-31054]
                stockedSerial.Batch_Expiration__c = date.valueOf(this.Batch_Expiration);
            }
            return stockedSerial;
        }									
    }
}
/*
SAMPLE INPUT RECIEVED

[{
    "Action": "",
    "Indicator": "",
    "Location": "10021",
    "ProductStock": [{
        "SVMXC_Product": "20002063",
        "SVMXC_Quantity2": "10",
        "SVMXC_Status": "Available",
        "StockedSerial": [{
            "Name": "1",
            "Batch_Number": "1",
            "Batch_Expiration": "2019-11-20",
			"Equipment_ID":"1234567" 
        }, {
            "Name": "2",
            "Batch_Number": "2",
            "Batch_Expiration": "2019-11-20",
			"Equipment_ID":"1234567" 
        }],
        "StockedBatch": [{
            "Batch_Number": "1",
            "Quantity": "1",
            "Batch_Expiration": "2019-11-20",
			"Equipment_ID":"1234567" 
        }, {
            "Batch_Number": "1",
            "Quantity": "1",
            "Batch_Expiration": "2019-11-20",
			"Equipment_ID":"1234567" 
        }]
    }]
}]

*/