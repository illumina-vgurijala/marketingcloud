/***************************************************************************************************************************************
* NAME         : WorkOrderDataReceiverWrapper
* DESCRIPTION  : Work Order Synchronization to DCP(ServiceMax) 
*              : Wrapper class to hold JSON received. 
* @AUTHOR      : 
* @DATE        : 14-Sep-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
                                     
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public class WorkOrderDataReceiverWrapper {

    /*Wrapper to hold data related to Parent object.(Work Order)*/
    public class WorkOrders {

        //Unique id based on which work order record will be updated is determined.
        public String WorkOrderNumber;

        //SAP Id which needs to be synced back to SFDC work order record.
        public String ErpServiceOrder;

        // Previous ERP Service Order Id CMCM-7849
        public String PrevErpServiceOrder; 

        //holds all work details record associated with a work order.
        public List < WorkDetails > WorkDetails = new List < WorkDetails >();
        
        public List <ErrorEntity> ErrorEntity = new list<ErrorEntity>();

        /*Instantiate the Work Order Object with required information.*/
        public SVMXC__Service_Order__c getSObject() {
            SVMXC__Service_Order__c workOrder = new SVMXC__Service_Order__c(Id = this.WorkOrderNumber, SVMX_PS_External_ID__C = this.ErpServiceOrder);
            return workOrder;
        }

    }


    /*Wrapper to hold data related to child object.(Work Detail)*/
    public class WorkDetails {

        //holds work detail svmx record id. This helps to identify which record needs to be updated.
        public String ConfirmationId;

        //holds unique SAP id which is synced back to svmx.
        public String ConfirmationERPId;
		public String IndirectConfirmationId;
        public String TravelConfirmationId;

        /*Instantiate the Work Detail Object with required information.*/
        public SVMXC__Service_Order_Line__c getSObject() {
            SVMXC__Service_Order_Line__c workDetail = new SVMXC__Service_Order_Line__c(Id = this.ConfirmationId, SVMX_PS_External_ID__C = this.ConfirmationERPId, Indirect_Confirmation_ERP_ID__c = this.IndirectConfirmationId, Travel_Confirmation_ERP_ID__c = this.TravelConfirmationId);
            return workDetail;
        }

    }
    
    /** Added by DP**/
    public class ErrorEntity{
        public string Id;
        public string status;
        public string Details;
		    /** Added by DP**/
        public ErrorEntity(string idd,string statuss,string Detailss){
            this.Id= idd;
            this.status=statuss;
            this.Details=Detailss;
        }
    }




}

/*
SAMPLE INPUT RECIEVED

[
   {
      "WorkOrderNumber": "a2B2F000000zOYq",
      "ErpServiceOrder": "786876",
      "WorkDetails": [
         {
            "ConfirmationId": "a2A2F000000LXEl",
            "ConfirmationERPId": "ADF546546"
         }
      ],
      "ErrorEntity": [
         {
            "Id": "a2A2F000000LXEl",
            "Status": "E",
            "Details": "Work Order Number WO-00000079 is assigned to ERP Service Order Number 000004000234."
         },
         {
            "Id": "a2B2F000000zOYq",
            "Status": "S",
            "Details": "No Error Received."
         }
      ]
   }
]


*/