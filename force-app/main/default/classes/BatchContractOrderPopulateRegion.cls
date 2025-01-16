/*@ author       : Deepesh Malhotra
* @ date         : 12-12-2018
* @ Description  : Batch update to sync the territory region from Sold To and Ultimate cionsignee accounts into CORS records
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Deepesh Malhotra          07-04-2018                 Initial version
* Koustubh M                09-Dec-2021                TASK0679416 Added code for error logging
* Aman Tyagi                31-Mar-2022                Codescan Fixes
* Nishan Shetty             24-May-2022                Ilib Batch Deferrable Implementation.
* Nishan Shetty             22-Aug-2022                [TASK0802266] Constructor added to fix ilib_BatchRunner runtime instantiation issue of no-arg constructor.
* Adyasha Satapathy         13-Dec-2022                POL- 188: Update the batch to exclude CORS with completed status for region update
*/

global class BatchContractOrderPopulateRegion extends ilib_BatchDeferrable {

  private final static String SOURCE = 'BatchContractOrderPopulateRegion'; //Koustubh - TASK0679416, 9th Dec 2021 - Added for error logging
  private Inputs inputs;
  public static final String STRING_STATUS_COMPLETED = System.Label.Completed; //POL-188

  /*
  *  @Author      : Nishan Shetty
  *  @Description : Parameter wrapper for easy serialization
  */
  public class Inputs {
      public Set<Id> setAccountId;
      /*Constructor*/
      public Inputs(Set<Id> setAccountIds) {
          this.setAccountId = setAccountIds;
      }
  }

  
  /*
  * @Author : Nishan Shetty[TASK0802266]
  * @Description : Constructor added to fix ilib_BatchRunner runtime instantiation issue of no-arg constructor.
  */
  global BatchContractOrderPopulateRegion() {
    super();
  }
  
 // public Set<String> setOppStage = new Set<String>{Label.OpportunityStageClosedWon,Label.OpportunityStageClosedLost,Label.OpportunityStageClosedAbandoned};

  /*
  * @Author: Deepesh Malhotra 
  * @Description : parameterized constructor of class BatchContractOrderPopulateRegion and instantiating Id
  * @param :Set<Id> setAccountIds Set of Ids
  */ 
  global BatchContractOrderPopulateRegion(Set<Id> setAccountIds) {
    super();
    this.inputs = new Inputs(setAccountIds);
  }
  
   /*
  * @author Deepesh Malhotra
  * @date   12-12-2018
  * @description  Schedule method override
  * in schedule method start the batch
  *
  */
  global override Database.QueryLocator start(Database.BatchableContext bc) {
      Set<Id> setAccountIds = inputs.setAccountId;
      String query = 'SELECT Id, Name, Account__c, Contract_Review_Status__c, Sold_To_Account_Region__c, Ultimate_Consignee_Region__c, Ultimate_Consignee__c  FROM Contract_Order_Routing_Sheet__c WHERE (Contract_Review_Status__c != :STRING_STATUS_COMPLETED AND (Account__c IN :setAccountIds OR Ultimate_Consignee__c IN :setAccountIds))'; //POL-188
      return Database.getQueryLocator(query);
  }
  /*
  * @author Deepesh Malhotra
  * @date   12-12-2018
  * @description    Batch method override
  * Excute Logic to populate Territory region Information on CORS Detail Page
  *
  */
  global override void execute(Database.BatchableContext bc, List<sObject> scope) {
      ilib_LogEvent.setBatchTitle(SOURCE, transactionId);
      ilib_LogEvent.push(SOURCE+'.execute');
      Set<Id> accounIds = new Set<Id>();
      List<Contract_Order_Routing_Sheet__c> lstContractOrder = (List<Contract_Order_Routing_Sheet__c>)scope;
      Map<Id,String> accountIdToRegion = new Map<Id,String>();

      List<Contract_Order_Routing_Sheet__c> lstContractOrderToUpdate = new List<Contract_Order_Routing_Sheet__c>();
      //List<Opportunity> lstUCOpportunity = new List<Opportunity>();
      // Iterating through contract order list to for setof AccountIds 
      if(!lstContractOrder.isEmpty()){
          for(Contract_Order_Routing_Sheet__c cors: lstContractOrder){
              accounIds.add(cors.Account__c);
              accounIds.add(cors.Ultimate_Consignee__c);
          }
      }
      for(Account objAccount : [Select Id,Territory_Region__c FROM Account where Id IN :accounIds]){
        accountIdToRegion.put(objAccount.Id,objAccount.Territory_Region__c);
      }
      for(Contract_Order_Routing_Sheet__c objContract : lstContractOrder){
        if(objContract.Sold_To_Account_Region__c != accountIdToRegion.get(objContract.Account__c)){
          objContract.Sold_To_Account_Region__c = accountIdToRegion.get(objContract.Account__c);
        } 
        if(objContract.Ultimate_Consignee_Region__c != accountIdToRegion.get(objContract.Ultimate_Consignee__c)){
          objContract.Ultimate_Consignee_Region__c = accountIdToRegion.get(objContract.Ultimate_Consignee__c);          
        }
        lstContractOrderToUpdate.add(objContract);
      }
      if(!lstContractOrderToUpdate.isEmpty()){
        List<Database.SaveResult> lstSaveErrors = Database.update(lstContractOrderToUpdate, false); //Koustubh - TASK0679416, 9th Dec 2021 - Added for error logging
        if(!lstSaveErrors.isEmpty()){ //Koustubh - TASK0679416, 9th Dec 2021 - Added error logging
          ApexExceptions.emitSaveErrors(lstSaveErrors, SOURCE); //Koustubh - TASK0679416, 9th Dec 2021 - Added for error logging
        }
      }

      ilib_LogEvent.pop();
      ilib_LogEvent.emit();
  }

    /*
  * @Author Deepesh Malhotra
  * @Description  overriding the finish method
  * @param Database.BatchableContext BC
  * @return  void
  */
  global override void finish(Database.BatchableContext bc) {
      
  }

  // ************************************************************************************************
  // Deferrable implementation
  // ************************************************************************************************
  
  /*
  *  @Author      : Nishan Shetty
  *  @Description : Method to simple input serialization
  *  @Param       : None
  *  @Return      : String
  */
  public override String serializeInputs() {
      return JSON.serialize(inputs);
  }

  /*
  *  @Author      : Nishan Shetty
  *  @Description : Method to simple input deserialization
  *  @Param       : String
  *  @Return      : void
  */
  public override void restoreInputs(String serializedInputs) {
      this.inputs = (BatchContractOrderPopulateRegion.Inputs)JSON.deserialize(serializedInputs, BatchContractOrderPopulateRegion.Inputs.class);
  }

}