/***************************************************************************************************************************************
* NAME         : ProactiveDataReceiverWrapper
* DESCRIPTION  : Proactive Synchronization to DCP(ServiceMax) 
*              : Wrapper class to hold JSON received. 
* @AUTHOR      : 
* @DATE        : 18-Nov-2018  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Dhairya Shah       11-Oct-2024             CMCM-5165            
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public class ProactiveDataReceiverWrapper {

	//Constants to store Order type values
    public static final String WO_API_NAME = 'SVMXC__Service_Order__c';
    //Wrapper to hold data related to Parent object.
	
	    /*
		* @description:Wrapper class which hold data related to Proactive information
		*/
    public class Proactive {

        /* Unique Id */
        //Salesforce Record Id in case updation of existing case or a work order.
        public String RecordId;

        /*** Lookup Variables ***/
        //Installed product serial/lot number
        public String InstrumentSerial;
        //Account ERP Customer Id.
        public String Account;
        //Fetch the case based on case number.
        public String AssociatedCase;

        //Subject
        public String Summary;
        //Illumina specific error code.
        public String SWErrorCode;

        //These 3 information goes in Description Field.
        public String Component;
        public String Detail;
        public String Severity;

       
		/* 
        * @description: Instantiate Work Order Object with required information.
        * @return: SObject - SVMXC__Service_Order__c 
        */		
        public SVMXC__Service_Order__c getWorkOrderObject() {
            SVMXC__Service_Order__c workOrder = new SVMXC__Service_Order__c();
            workOrder.Notes__c = (String.isNotBlank(this.Component) ? 'Component Information: ' + this.Component : '') + (String.isNotBlank(this.Detail) ? ' | Detail: ' + this.Detail : '') + (String.isNotBlank(this.Severity) ? ' | Severity: ' + this.Severity : ''); // CMCM-5165 Changes
            workOrder.SVMX_PS_Subject__c = this.Summary;
			workOrder.Is_Auto_Created__c = true;
            if(this.Severity == 'Warning'){// INC0223867 when severity is warning, create WO of type Remote Support and route it to 'TS - Instrumentation' queue
                workOrder.OwnerId = getTSInstrumentationQueueId();
                workOrder.SVMXC__Order_Status__c = System.label.WorkOrderStatusInProgress;
                workOrder.RecordTypeId = ServiceUtilityCollection.getRecordTypeId(WO_API_NAME, System.Label.WorkOrderRecordTypeRemoteSupport); 
                workOrder.SVMXC__Order_Type__c = System.Label.WorkOrderTypeRemoteSupport;
            } else if(this.Severity == 'Critical'){//INC0223867 when severity is Critical, create WO of type Service Activities and auto route it to available technician
                workOrder.Is_Auto_Dispatch__c = true;
                workOrder.ProActive_Account_ERP_Customer_Id__c = String.isNotBlank(this.Account) ? this.Account : 'NA';
                workOrder.RecordTypeId = ServiceUtilityCollection.getRecordTypeId(WO_API_NAME, System.Label.WorkOrderRecordTypeFieldService);
                workOrder.SVMXC__Order_Type__c = System.Label.WorkOrderTypeServiceActivities;
            }
            
            return workOrder;
        }


        
		
		/*
		* @description:Wrapper class to Instantiate Case Object with required information.
		*/			
        public Case getCaseObject() {
        
            Case cases = new Case();
            cases.Description = (String.isNotBlank(this.Component) ? 'Component Information: ' + this.Component : '') + (String.isNotBlank(this.Detail) ? ' | Detail: ' + this.Detail : '') + (String.isNotBlank(this.Severity) ? ' | Severity: ' + this.Severity : '');
            cases.Subject = this.Summary;
            cases.Category__c = 'SQ Instrument & Control Software';
            cases.Origin = 'Email - ProActive - TS';
            cases.Date_of_Issue_Awareness__c = date.today();
            cases.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Business Issue').getRecordTypeId();
            cases.Sub_Type__c = 'Complaint';

            return cases;
        }
		
		/* 
        * @description: To intantiate required information TS Instrumentation Queue
        * @return: Id
        */		
		public Id getTSInstrumentationQueueId(){
    Group tsInstrumentationQueue = [Select ID from Group where Type = 'Queue' and name='TS - Instrumentation' limit 1];
    return tsInstrumentationQueue.Id;
    }

    }




}

/*
SAMPLE INPUT RECIEVED

[{
 "InstrumentSerial":"6543",
 "Account":"66161",
 "Component":"1123",
 "Summary":"Test Summary",
 "SWErrorCode":"",
 "Detail":"Test Detail",
 "Severity":"Critical",
 "AssociatedCase":""
}]

*/