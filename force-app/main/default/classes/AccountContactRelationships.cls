/****************************************************************************************************************************************
* NAME         : AccountContactRelationships
* DESCRIPTION  : Domain class for AccountContactRelationship Trigger
*                    
* @AUTHOR : Saddam
* @DATE   : 22-Feb-2022 
* 
* MODIFICATION LOG:  
* -------------------------------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------------------------------
  Saddam                22-Feb-2022           Initial Version.PM-33
  Saddam                09-Mar-2022           Modified updateRQContactCompliant() ,invoked RqEligibleAccountLogic class for logic to check acr and contact records
  Maruthi               09-Mar-2022           PM-54 created new method createHistoryTracking
  Saddam                09-Mar-2022           Modified updateRQContactCompliant() ,calling AccountContactRelationshipsService class for logic to check acr and contact records
  Avina                 13-Jun-2022           CMSI-68,Added Instrumentation 
  Preetha               08-July-2022          CMSI-51 added WorkStream
 -----------------------------------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class AccountContactRelationships extends ilib_SObjectDomain {
   
    private static final String CODEPARAMETERACRHISTORYTRACKINGFIELDS = 'ACR_History_Tracking_Fields';
    
    /*Parameterised Constructor */
    public AccountContactRelationships(List<AccountContactRelation> sObjectList) {
        super(sObjectList);
    }

    /*@author: saddam 
    * Constructor method
    * Boilerplate which is required for base class instantiation logic
    */
    public class Constructor implements ilib_SObjectDomain.IConstructable {

    /*
    * Constructor method
    * params: List<sobject>
    */
        public ilib_SObjectDomain construct(List<SObject> sObjectList) {
            return new AccountContactRelationships(sObjectList);
        }
    }

  /* Method Afterinsert trigger event */
    public override void onAfterInsert() {
        List<AccountContactRelation> lstTempAcc = (List<AccountContactRelation>) records;
        AccountContactRelationshipsService.updateRQContactCompliant(lstTempAcc);
    }

    /* Method Afterupdate trigger event */
    public override void onAfterUpdate(Map<Id, SObject> oldrecords) {
        List<AccountContactRelation> lstTempAcc = (List<AccountContactRelation>) records;
        AccountContactRelationshipsService.updateRQContactCompliant(lstTempAcc);
        //PM-54
       UtilsObject.createHistoryTracking(trigger.newMap, trigger.oldMap, CODEPARAMETERACRHISTORYTRACKINGFIELDS);
    }
    /*CMSI-51
    * method will return the workstream
    */
    public override string getWorkstream(){
        return ilib_LogEvent.SALES;
    }

}
