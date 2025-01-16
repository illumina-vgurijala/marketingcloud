/***************************************************************************************************************************************
* NAME         : ServiceBOMDataReceiverWrapper
* DESCRIPTION  : Service BOM Synchronization to DCP(ServiceMax) 
*              : Wrapper class to hold JSON received. 
* @AUTHOR      : 
* @DATE        : 18-Sep-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
                                     
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public class ServiceBOMDataReceiverWrapper {

    /*Wrapper to hold data related to Parent object.*/
    public class ServiceBOM {

        /** External Id **/
        public String ERP_Service_BOM_Number;

        public String Name;
        public String Active;

        //list to hold all child records.
        public List < FRUList > FRUList = new List < FRUList > ();

        /*Instantiate the Service_Bill_Of_Materials__c Object with required information.*/
        public Service_Bill_Of_Materials__c getSObject() {
            Service_Bill_Of_Materials__c ServiceBOM = new Service_Bill_Of_Materials__c( ERP_Service_BOM_Number__c = this.ERP_Service_BOM_Number, Active__c = Boolean.ValueOf(this.Active));
            return ServiceBOM;
        }

    }


    /*Wrapper to hold data related to child object.(FRU List)*/
    public class FRUList {

        /** External Id **/
        //concatenation of product and parent product.
        public String SVMX_PS_External_ID;
        public String Parent_Product;
        public List < Product_Group > Product_Group = new List < Product_Group > ();

        /*Instantiate the FRU_List__c Object with required information.*/
        public FRU_List__c getSObject() {
            FRU_List__c fruList = new FRU_List__c();
            return fruList;
        }

    }

    /*As there can be multiple products associated to a parent product.*/
    public class Product_Group {
        public String Product;
    }



}

/*
SAMPLE INPUT RECIEVED

[{
    "Name": "FRU LIST, BASESPACE HT",
    "ERP_Service_BOM_Number": "20005785",
    "Active": true,
    "FRUList": [{
        "Parent_Product": "20001266",
        "Product_Group": [{
            "Product": "20028300"
        }, {
            "Product": "20022240"
        }]
    }, {
        "Parent_Product": "",
        "Product_Group": [{
            "Product": "20002063"
        }]
    }]
}]


*/