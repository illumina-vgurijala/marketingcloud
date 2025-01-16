/***************************************************************************************************************************************
* NAME   : BatchBulkDeleteOperationalLogsData
* DESCRIPTION  : Batch class to delete operational records like  exception logs, interfacelogs,charket logs, dupeblocker logs, and apex jobs
*
* @AUTHOR : Goutham Ramireddy (Release Team)
* @DATE   : 20-July-2021
*
* MODIFICATION LOG:
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION
* --------------------------------------------------------------------------------------------------------------------------------------
* Goutham                 20th July 2021        Initial Version

****************************************************************************************************************************************/
public with sharing class BatchBulkDeleteOperationalLogsData extends ilib_BatchDeferrable {


    private Inputs inputs;

    /***************************************************************************************************************************************
        *CLASS NAME   : Inputs
        * DESCRIPTION  : Parameter wrapper for easy serialization. This methos is from batch framework(https://illumina.quip.com/QLaUAKz7FNqu/Batch-Manager-Framework)
        *
        * @DATE   : 09-May-2021
        *
    ****************************************************************************************************************************************/    

    
    public class Inputs
    {
        private final String strQuery;
        /***************************************************************************************************************************************
        *METHOD NAME   : Inputs
        * DESCRIPTION  : Parameter wrapper for easy serialization. This methos is from batch framework(https://illumina.quip.com/QLaUAKz7FNqu/Batch-Manager-Framework)
        *
        * @DATE   : 09-May-2021
        *
    ****************************************************************************************************************************************/   
        public Inputs(string strQuery)
        {
            this.strQuery= strQuery;
        }
    }
    
	
	/* required to reinstantiate after deferral */
    public BatchBulkDeleteOperationalLogsData() {
        super();
    }
     
     
    /***************************************************************************************************************************************
        *METHOD NAME   : Constructor with the SOQL query parameter and emails parameters
        * DESCRIPTION  : Constructor with the SOQL query parameter and emails parameters
        *
        * @DATE   : 09-May-2021
        *
    ****************************************************************************************************************************************/
    public BatchBulkDeleteOperationalLogsData (string strQuery) {
        super();
        this.inputs = new Inputs(strQuery);
        
    }

    /***************************************************************************************************************************************
        *METHOD NAME   : start
        * DESCRIPTION  : This method start method of this batch class. It bypasses the triggers and validation rules for executing user
        *
        * @DATE   : 09-May-2021
        *
    ****************************************************************************************************************************************/
    public override Database.QueryLocator start(Database.BatchableContext bc)
    {
        
        //Following snippet makes sure the context user who is running the batch has triggers and validation rules bypassed
        cs_Apex_Settings__c setting = cs_Apex_Settings__c.getInstance(UserInfo.getUserId());
        if(setting.Bypass_All_Validations__c != true || setting.Bypass_All_Triggers__c!=true){
            setting.Bypass_All_Validations__c = true;
            setting.Bypass_All_Triggers__c=true;
            upsert setting;  
        } 
        
        return Database.getQueryLocator(inputs.strQuery);
    }
    /***************************************************************************************************************************************
        *METHOD NAME   : execute
        * DESCRIPTION  : Method to delete records of object specified
        *
        * @DATE   : 09-May-2021
        *
    ****************************************************************************************************************************************/
    public override void execute(Database.BatchableContext bc, list<Sobject> scope)
    {  
        List<sObject> lstObjs = new List<sObject>(scope);
                
        if(!lstObjs.isEmpty()) {
            Database.DeleteResult[] srList = Database.delete(lstObjs,false);
            ApexExceptions.emitDeleteErrors(srList,'BatchBulkDeleteOperationalLogsData');
        }
        
    }
    /***************************************************************************************************************************************
        *METHOD NAME   : finish
        * DESCRIPTION  : No finish actions defined for this method
        *
        * @DATE   : 09-May-2021
        *
    ****************************************************************************************************************************************/
    public override void finish(Database.BatchableContext bc) {
        //There are no finish actions required for this batch class         
    }
}