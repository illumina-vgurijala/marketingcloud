/**
* @ author       : Nishan Shetty
* @ date         : 27-June-2022
* @ Description  : DCP-52703 Batch Class for updating Priority Field on Agreement Line Item.
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Nishan Shetty        27-June-2022               Initial version
**********************************************************************************************************************/
public without sharing class BatchUpdateAgreementLineItemPriority extends ilib_BatchDeferrable {

  //Class Variables.
  public final static String LOG_TITLE = 'BatchUpdateAgreementLineItemPriority';
  public final static String STRING_BATCH_SIZE_PARAMETER ='BatchUpdateAgreementLineItemPrioritySize';
  Map<String,Material_Group__mdt> mapMaterialGroupMetaData = new Map<String,Material_Group__mdt>();
 
  /*Constructor.*/
  public BatchUpdateAgreementLineItemPriority() {
    super();
    this.mapMaterialGroupMetaData=Material_Group__mdt.getAll();
  }
 
  /* Batch Start Method to query records */
  public override Database.QueryLocator start(Database.BatchableContext bc) {
     String query = 'Select Id,Apttus_Approval__Approval_Status__c,Apttus__AgreementId__r.Apttus_Approval__Approval_Status__c,Material_Group_1__c,Priority__c from Apttus__AgreementLineItem__c where Apttus_Approval__Approval_Status__c = \'Approval Required\' and Apttus__AgreementId__r.Apttus_Approval__Approval_Status__c =\'Approval Required\' and Material_Group_1__c!=null ';
     return Database.getQueryLocator(query);
  }
 
  /* Batch Execute Method to process records */
  public override void execute(Database.BatchableContext bc, List<sobject> lstAgreementLineItems) { 
     ilib_LogEvent.setBatchTitle(LOG_TITLE,transactionId);
     ilib_LogEvent.push('BatchUpdateAgreementLineItemPriority.execute');

     for(Apttus__AgreementLineItem__c objAgreementLineItem:(List<Apttus__AgreementLineItem__c>)lstAgreementLineItems) {
      if(mapMaterialGroupMetaData.containsKey(objAgreementLineItem.Material_Group_1__c) 
      && mapMaterialGroupMetaData.get(objAgreementLineItem.Material_Group_1__c).Priority__c!=null) {
          objAgreementLineItem.Priority__c=mapMaterialGroupMetaData.get(objAgreementLineItem.Material_Group_1__c).Priority__c;
      }
      }
      ilib_LogEvent.message('lstAgreementLineItems:'+lstAgreementLineItems);
      List<Database.SaveResult> lstSaveErrors = Database.update(lstAgreementLineItems,false);
      ApexExceptions.emitSaveErrors(lstSaveErrors,LOG_TITLE);
     ilib_LogEvent.pop();
 
  }
 
   /* Batch Finish Method for post execute logic */ 
   public override void finish(Database.BatchableContext bc) {
 
   }
 
 /************************************************************************************************
   Deferrable implementation
 *************************************************************************************************/
   
   /*
   *  @Author      : Nishan Shetty
   *  @Description : Method to simple input serialization
   *  @Param       : None
   *  @Return      : String
   */
   public override String serializeInputs() {
     return JSON.serialize('No input for this class');
 }
 /*
 *  @Author      : Nishan Shetty
 *  @Description : Method to simple input deserialization
 *  @Param       : String
 *  @Return      : void
 */
 public override void restoreInputs(String serializedInputs) { }   
 
 /*
 *  @Author      : Nishan Shetty
 *  @Description : Method to get default val
 *  @Param       : None
 *  @Return      : Integer
 */
 public override Integer getDefaultBatchSize() {
 List<Code_Parameter__mdt> lstCodeParameter = new CodeParametersSelector().selectCodeParameterByDeveloperName(
      new Set<String> {STRING_BATCH_SIZE_PARAMETER}
  );
  return Integer.valueOf(lstCodeParameter[0].Value__c);
 }
      
}
 