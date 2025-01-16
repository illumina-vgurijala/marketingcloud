/**
*   @author Anisha Bharti
*   @date   25-Aug-2020
*   @description    Bulk update of Territory Plan lookup on Account Plan with Active Plan record
*
*   90% Code Coverage: TestPlans
*   75% Code Coverage: TestPlans
*
*   Modification Log:
*   ------------------------------------------------------------------------------------
*   Developer                   Date                Description       
*   Nishan Shetty               30-May-2022        Implementation of Batch Manager Framework DCP-50962
*   Sibin P Kuriakose           12-Sep-2022        [CMSI-212] Instrumentation of the Class.
*   ------------------------------------------------------------------------------------
**/
global without sharing class BatchUpdateAccountPlanWithActiveTP extends ilib_BatchDeferrable {
    
     //DCP-52588 Resolving Codecsan issues related to field visibility 
    Map<String, SObject> mapTerritorycodePlan = new Map<String, SObject>();
    Map<Id, String> mapAccountTerritoryCode = new Map<Id, String>();
    public static List<Database.SaveResult> lstSaveErrors = new List<Database.SaveResult>();
    public final static String LOG_TITLE = 'BatchUpdateAccountPlanWithActiveTP';
    /**
    *   @author KD
    *   @description  Constructor
    **/
    
     //DCP-50962 - implementation of batch manager
     private Inputs inputs;
    /*
    *  @Description : Parameter wrapper for easy serialization
    */
    public class Inputs {
        public Map<String,SObject> mapTerritorycodePlans;
        public Map<Id,String> mapAccountTerritoryCodes;
        
        /*Constructor*/
        public Inputs(Map<String,SObject> mapTerritorycodePlan, Map<Id, String> mapAccountTerritoryCode) {
            this.mapTerritorycodePlans = mapTerritorycodePlan;
            this.mapAccountTerritoryCodes = mapAccountTerritoryCode;
        }
    }
    
    /*Constructor*/
    public BatchUpdateAccountPlanWithActiveTP() {
        super();
    }
    
    /*Constructor*/
    public BatchUpdateAccountPlanWithActiveTP(Map<String,SObject> mapTerritorycodePlan, Map<Id, String> mapAccountTerritoryCode) {
        super();
        this.inputs= new Inputs(mapTerritorycodePlan,mapAccountTerritoryCode);
        this.mapTerritorycodePlan = inputs.mapTerritorycodePlans;
        this.mapAccountTerritoryCode = inputs.mapAccountTerritoryCodes;
    }
    /**
    *   @author KD
    *   @description Start Method For the Apex JOb
    **/
    global override Database.QueryLocator start(Database.BatchableContext objBC) {
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId); //CMSI-212
        ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES); //CMSI-212
        ilib_LogEvent.push(LOG_TITLE + '.start'); //CMSI-212
        Set<Id> idAccount = new Set<Id>();
        idAccount = inputs.mapAccountTerritoryCodes.keyset();
        String strQuery = 'SELECT Id,Name, Account_Name__c, Account_Name__r.id, Territory_Plan__c FROM Account_Plan__c where Account_Name__c IN :idAccount';
        ilib_LogEvent.info('idAccount' + idAccount); //CMSI-212
        ilib_LogEvent.info('strQuery' + strQuery); //CMSI-212
        ilib_LogEvent.pop(); //CMSI-212
        ilib_LogEvent.emit(); //CMSI-212
        return Database.getQueryLocator(strQuery);
    }
    /**
    *   @author KD
    *   @description : Execute method to update TP link
    **/
    global override void execute(Database.BatchableContext objBC, List<SObject> lstAccountPlan) {
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
        ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES); //CMSI-212
        ilib_LogEvent.push(LOG_TITLE+'.execute');
        List<Account_Plan__c> lstAccountPlans = new List<Account_Plan__c>();
        for(Account_Plan__c objAccountPlan : (List<Account_Plan__c>)lstAccountPlan) {
            SObject plan = mapTerritorycodePlan.get(mapAccountTerritoryCode.get(objAccountPlan.Account_Name__r.id));
            objAccountPlan.Territory_Plan__c = plan.id;
            lstAccountPlans.add(objAccountPlan);
        }    
        if(!lstAccountPlans.isEmpty()) {
            Database.SaveResult[] srList = Database.update(lstAccountPlans);
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    ilib_LogEvent.message('Successfully updated Account Plans: '+sr.getId());
                }
                else {
                    lstSaveErrors.add(sr);  
                }
            }
            Set<Id> accounIds = UtilsCollection.getSetOfIds(lstAccountPlans, 'Account_Name__c'); //CMSI-212
            ilib_LogEvent.info('accounIds: '+accounIds); //CMSI-212
        }

       
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    /**
    *   @author KD
    *   @description  Finish method
    **/
    global override void finish(Database.BatchableContext objBC) {
        ilib_LogEvent.setBatchTitle(LOG_TITLE, transactionId);
        ilib_LogEvent.setWorkstream(ilib_LogEvent.SALES); //CMSI-212
        ilib_LogEvent.push(LOG_TITLE+'.finish');
        if(!lstSaveErrors.isEmpty())
            ApexExceptions.emitSaveErrors(lstSaveErrors,'BatchUpdateAccountPlanWithActiveTP');
        
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }
    
    // ************************************************************************************************
    // Deferrable implementation
    // ************************************************************************************************
    
    /*
    
    *  @Description : Method to simple input serialization
    *  @Param       : None
    *  @Return      : String
    */
    public override String serializeInputs()
    {
        return JSON.serialize(inputs);
    }

    /*
    
    *  @Description : Method to simple input deserialization
    *  @Param       : String
    *  @Return      : void
    */
    public override void restoreInputs(String serializedInputs) {
        this.inputs = (BatchUpdateAccountPlanWithActiveTP.Inputs)JSON.deserialize(serializedInputs,BatchUpdateAccountPlanWithActiveTP.Inputs.class);
    }
    
}