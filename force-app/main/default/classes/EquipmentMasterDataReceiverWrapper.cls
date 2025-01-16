/***************************************************************************************************************************************
* NAME         : EquipmentMasterDataReceiverWrapper
* DESCRIPTION  : DCP-904:Equipment Master Synchronization to DCP(ServiceMax) (INT_C-370-001) 
*              : Wrapper class to hold JSON received. 
* @AUTHOR      : 
* @DATE        : 28-June-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Vaibhav Parashar         30 Aug 2018         Added changes related to Work Order Debrief. Added a child wrapper.                                      
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public class EquipmentMasterDataReceiverWrapper {

    //Wrapper to hold data related to Parent header.
		/*
         * Wrapper to hold data related to Parent header.
         */  	
    public class InstalledProducts {

        public String ERP_Equipment_Id;
        public String SVMXC_Product;
        public String SVMXC_Serial_Lot_Number;
        public String SVMXC_Sales_Order_Number;
        public String Asset_Type;
        public String SVMXC_Company;
		public String SVMXC_Location;
        public String SVMXC_Status;
        public String SVMXC_Top_Level;
        public String SVMXC_Parent;
        public String Service_BOM;
        public String SVMXC_Date_Ordered;
        public String SVMXC_Date_Shipped;
        public String SVMXC_Requested_Delivery_Date;
        public String Cost_Center;
        public String Country_of_Origin;
        public String Plant_of_Origin;
        public String Previous_Equipment_Number;
        public String Next_Equipment_Number;
        public String SVMXC_Site;
        
        //lookup SFDC Ids
        public String SVMXC_Company_SFDC_Id;
        public String SVMXC_Product_SFDC_Id;
        public String SVMXC_Top_Level_SFDC_Id;
        public String SVMXC_Parent_SFDC_Id;
        public String SVMXC_Site_SFDC_Id;
        public String Service_BOM_SFDC_Id;
		
		//CMCM-6817
		public String MAC_Address;
        
        public List < InstallBase > InstallBase = new List < InstallBase > ();

		
		/* 
        * @description: To intantiate required information Partent Installed Product
        * @return: SObject - SVMXC__Installed_Product__c 
        */
        public SVMXC__Installed_Product__c getSObject() {
        
        //transition map to hold values for Asset Type.
        Map<String,String> SAPValueToSFDCValues = new Map<String,String>{
        'CUSTOMER' => 'Customer Owned',
        'CUST-3PTY' => 'Customer 3rd Party Owned',
        'DEMO-SALES' => 'Demo Sales',
        'DEMO-MKTG' => 'Demo Marketing',
        'RENT-INSTR' => 'Rental Instrument',
        'RENT-CONS' => 'Reagent Rental',
        'LOAN-SERV' => 'Service Loaner',
        'LOAN-SALES' => 'Sales Loaner',
        'COLLABRN' => 'Collaboration',
        'BETA' => 'Beta',
        'TRIAL' => 'Clinical Trial Systems',
        'INTERNAL' => 'Internal',
        'INT-SERV' => 'Internal Service',
        'CUST-DONA' => 'Customer-owned Donation'
        };
        
            SVMXC__Installed_Product__c parentInstalledProduct = new SVMXC__Installed_Product__c(
            Name=this.SVMXC_Serial_Lot_Number+'-'+this.SVMXC_Product, 
            ERP_Equipment_Id__c = this.ERP_Equipment_Id, 
            SVMXC__Serial_Lot_Number__c = this.SVMXC_Serial_Lot_Number, 
            Asset_Type__c = SAPValueToSFDCValues.get(this.Asset_Type), 
            SVMXC__Sales_Order_Number__c = this.SVMXC_Sales_Order_Number, 
            Cost_Center__c = this.Cost_Center, 
            Country_of_Origin__c = this.Country_of_Origin, 
            Plant_of_Origin__c = this.Plant_of_Origin, 
            Previous_Equipment_Number__c = this.Previous_Equipment_Number,
            Next_Equipment_Number__c = this.Next_Equipment_Number,
            SVMXC__Company__c = SVMXC_Company_SFDC_Id,
            SVMXC__Product__c = SVMXC_Product_SFDC_Id,
            SVMXC__Top_Level__c = SVMXC_Top_Level_SFDC_Id,
            SVMXC__Parent__c = SVMXC_Parent_SFDC_Id,
            SVMXC__Site__c = SVMXC_Site_SFDC_Id,
            Service_Bill_Of_Materials__c = Service_BOM_SFDC_Id,
            Product_Code1__c = this.SVMXC_Product,
			Mac_Address__c = this.MAC_Address//CMCM-6817
            /*, SVMXC__Status__c = this.SVMXC_Status*/);

            if (SVMXC_Date_Ordered != null) {
                parentInstalledProduct.SVMXC__Date_Ordered__c = date.valueOf(this.SVMXC_Date_Ordered);
            }
            if (SVMXC_Date_Shipped != null) {
                parentInstalledProduct.SVMXC__Date_Shipped__c = date.valueOf(this.SVMXC_Date_Shipped);
            }
            if (SVMXC_Requested_Delivery_Date != null) {
                parentInstalledProduct.SVMXC__Date_Ordered__c = date.valueOf(this.SVMXC_Requested_Delivery_Date);
            }
            /*//Ritika - INC0258121 Changes
            if (SVMXC_Status != null && SVMXC_Status == 'ESTO') {
            	parentInstalledProduct.SVMXC__Status__c = 'Returned';
            }*/
            return parentInstalledProduct;
        }
    }


   
		/* 
        * @description: Wrapper to hold data related to child arrays.
        */
    public class InstallBase {

        public String ERP_Equipment_Id;
        public String SVMXC_Serial_Lot_Number;
        public String SVMXC_Product; 
        public String SVMXC_Top_Level;
        public String SVMXC_Parent;
        
        //lookup SFDC Ids
        public String SVMXC_Product_SFDC_Id;
        public String SVMXC_Top_Level_SFDC_Id;
        public String SVMXC_Parent_SFDC_Id;
        public String MAC_Address; //CMCM-9541
		/* 
        * @description: Intintiate Installed product data
        * @return: SObject- SVMXC__Installed_Product__c
        */
        public SVMXC__Installed_Product__c getSObject() {
            SVMXC__Installed_Product__c childInstalledProduct = new SVMXC__Installed_Product__c(
            ERP_Equipment_Id__c = this.ERP_Equipment_Id, 
            SVMXC__Serial_Lot_Number__c = this.SVMXC_Serial_Lot_Number,
             SVMXC__Product__c = SVMXC_Product_SFDC_Id,
            SVMXC__Top_Level__c = SVMXC_Top_Level_SFDC_Id,
            SVMXC__Parent__c = SVMXC_Parent_SFDC_Id,
            Product_Code1__c = this.SVMXC_Product,
            Mac_Address__c = this.MAC_Address
            );
            return childInstalledProduct;
        }

    }


}

/*
SAMPLE INPUT RECIEVED

[{
    "ERP_Equipment_Id": "47631",
    "SVMXC_Serial_Lot_Number": "200131",
    "Asset_Type": "INTERNAL",
    "SVMXC_Sales_Order_Number": "?",
    "SVMXC_Company": "6000000293",
	"SVMXC_Location": "TS100214",
    "SVMXC_Product": "47631",
    "SVMXC_Top_Level": "",
    "SVMXC_Parent": "",
    "Service_BOM": "",
    "SVMXC_Date_Ordered": "2018-10-18",
    "SVMXC_Date_Shipped": "2018-10-18",
    "Cost_Center": "3044100",
    "Country_of_Origin": "?",
    "Plant_of_Origin": "3310",
    "Previous_Equipment_Number": "12344",
    "Next_Equipment_Number": "1233445",
    "SVMXC_Status": "Shipped",
    "InstallBase": [{
            "ERP_Equipment_Id": "47632",
            "SVMXC_Serial_Lot_Number": "200132",
            "SVMXC_Product": "47632",
            "SVMXC_Top_Level": "47631",
            "SVMXC_Parent": "47631"
        },
        {
            "ERP_Equipment_Id": "47633",
            "SVMXC_Serial_Lot_Number": "200133",
            "SVMXC_Product": "47633",
            "SVMXC_Top_Level": "47631",
            "SVMXC_Parent": "47632"
        }
    ]
}]


*/