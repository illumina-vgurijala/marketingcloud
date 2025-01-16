/***************************************************************************************************************************************
* NAME   : BatchBulkEmailMaskUpdate
* DESCRIPTION  : Batch class to mask emails in contacts,leads,service contract and workorder records with .invalid
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
public with sharing class BatchBulkEmailMaskUpdate extends ilib_BatchDeferrable {

    
	private Inputs inputs;
    private static final integer EMAILCHARLIMIT = 72;
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
		private final set<string> setEmailFieldAPINames;
        /***************************************************************************************************************************************
        *METHOD NAME   : Inputs
        * DESCRIPTION  : Parameter wrapper for easy serialization. This methos is from batch framework(https://illumina.quip.com/QLaUAKz7FNqu/Batch-Manager-Framework)
        *
        * @DATE   : 09-May-2021
        *
    ****************************************************************************************************************************************/   
        public Inputs(string strQuery,set<string> setEmailFieldAPINames)
        {
            this.strQuery= strQuery;
			this.setEmailFieldAPINames= setEmailFieldAPINames;
        }
    }
    
	
	/* required to reinstantiate after deferral */
    public BatchBulkEmailMaskUpdate() { 
        super();
    }
     
    
    /***************************************************************************************************************************************
        *METHOD NAME   : Constructor with the SOQL query parameter and emails parameters
        * DESCRIPTION  : Constructor with the SOQL query parameter and emails parameters
        *
        * @DATE   : 09-May-2021
        *
    ****************************************************************************************************************************************/ 
    public BatchBulkEmailMaskUpdate (string strQuery,set<string> setEmailFieldAPINames) {
        super();
        this.inputs = new Inputs(strQuery,setEmailFieldAPINames);
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
        * DESCRIPTION  : Method to mask the email data with .invalid
        *
        * @DATE   : 09-May-2021
        *
    ****************************************************************************************************************************************/
    public override void execute(Database.BatchableContext bc, list<Sobject> scope)
    {  
        List<sObject> lstObjs = new List<sObject>();
        for(sobject obj:scope){
            for(string strField : inputs.setEmailFieldAPINames){
                string strEmail=(String)Obj.get(strField);
                if(String.isNotBlank(strEmail) && !strEmail.endsWith('.invalid')){
                    if(strEmail.length()<EMAILCHARLIMIT){
                        obj.put(strField,strEmail+'.invalid');   
                    }else{
                        obj.put(strField,'test@illumina.com.invalid');
                    }                
                }
                 
            } 
            lstObjs.add(obj); 
        }
           
        if(!lstObjs.isEmpty()) {
            List<Database.SaveResult> srListProposalReturned = Database.update(lstObjs, false);
			ApexExceptions.emitSaveErrors(srListProposalReturned, 'BatchBulkEmailMaskUpdate');
		
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