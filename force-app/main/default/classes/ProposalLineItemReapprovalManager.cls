/**
*    @author Rohan Chandarana
*    @date   06-06-2014
*    @description   Handler class for ApttusProposalLineItemTrigger
*    @Test class for 87% coverage - TestApttusApprovals
*    Modification Log:
*    ------------------------------------------------------------------------------------
*      Developer                      Date                 Description
*      Rohan                          06-June-2024         Initial Version
*  
*/

public with sharing class ProposalLineItemReapprovalManager
{
   // line item types
    private static final String LINETYPE_PRODUCT = 'Product/Service';
    private static final String LINETYPE_OPTION = 'Option';
    private static final String LOG_TITLE = 'ProposalLineItemReapprovalManager';
    // proposal
  private static final String PROPOSAL_SOBJECT_TYPE = 'Apttus_Proposal__Proposal__c';
    private static Set<ID> quoteId = new Set<ID>();

    // associated process instance
  //private static Apttus_Approval__ApprovalProcessInstance__c quoteProcessInstance = null;   

    // map of old line item ids to attribute key
    private static Map<ID,String> oldLineId2KeyMap = new Map<ID,String>();

    // map of new line item attribute key to id
    private static Map<String,ID> newLineKey2IdMap = new Map<String,ID>();

    // map of old line item ids to new line item ids
    private static Map<ID,ID> lineOldId2NewIdMap = new Map<ID,ID>();

    /**
     * Process old ProposalLineItems before they are deleted when a cart is finalized
     *  @param oldLineItems - a list of the old versions of the sObject records
     *  @param oldLineItemsMap - a map of IDs to the old versions of the sObject records
     */

    public static void processOldLineItemsBeforeDelete( Map<ID, Apttus_Proposal__Proposal_Line_Item__c> oldLineItemsMap){      
        // iterate over line items about to deleted
        system.debug('oldLineItemsMap  '+oldLineItemsMap);
        if(oldLineItemsMap!=null && !oldLineItemsMap.isEmpty()){
        for (Apttus_Proposal__Proposal_Line_Item__c oldLineItem : oldLineItemsMap.values() ){
            
            // get quote from line item
            // quoteId.add(oldLineItem.Apttus_Proposal__Proposal__c);
            // get line item attributes
            String lineNumber = String.valueOf(oldLineItem.Apttus_QPConfig__PrimaryLineNumber__c);
            String lineType = oldLineItem.Apttus_QPConfig__LineType__c;       
            String productId = null;
    
            if (lineType == LINETYPE_PRODUCT)
              { 
                productId = oldLineItem.Apttus_Proposal__Product__c;         
              }
            else if (lineType == LINETYPE_OPTION)
              {        
                productId = oldLineItem.Apttus_QPConfig__OptionId__c;
      
                //productId = oldLineItem.Apttus_QPConfig__ProductOptionId__c;
              } 
    
              String chargeType = oldLineItem.Apttus_QPConfig__ChargeType__c;
              // create attribute key
              String oldLineKey = lineNumber + ':' + productId + ':' + chargeType;
              // save in map  
              oldLineId2KeyMap.put(oldLineItem.Id, oldLineKey);
      }
    }
  } 
/**
* Process new ProposalLineItems after they are inserted when a cart is finalized
* @param newLineItems - a list of the new versions of the sObject records
* @param newLineItemsMap - a map of IDs to the new versions of the sObject records
*/
  public static void processNewLineItemsForReapproval(Map<ID, Apttus_Proposal__Proposal_Line_Item__c> newLineItemsMap)
  {      
    ilib_LogEvent.push(LOG_TITLE + '.processNewLineItemsForReapproval()');
    // iterate over line items about to deleted
    system.debug('newLineItemsMap '+newLineItemsMap);

    if(newLineItemsMap!=null && !newLineItemsMap.isEmpty()){
    for (Apttus_Proposal__Proposal_Line_Item__c newLineItem : newLineItemsMap.values()){        
      
      // get quote from line item
        quoteId.add(newLineItem.Apttus_Proposal__Proposal__c);
      
      // get line item attributes
        String lineNumber = String.valueOf(newLineItem.Apttus_QPConfig__PrimaryLineNumber__c);
        String lineType = newLineItem.Apttus_QPConfig__LineType__c;
        String productId = null;
      
        if (lineType == LINETYPE_PRODUCT)
          {
            productId = newLineItem.Apttus_Proposal__Product__c;
          }
          else if(lineType == LINETYPE_OPTION)
            {
              productId = newLineItem.Apttus_QPConfig__OptionId__c;       
              //productId = newLineItem.Apttus_QPConfig__ProductOptionId__c;
            }
          String chargeType = newLineItem.Apttus_QPConfig__ChargeType__c;

          // create attribute key
          String newLineKey = lineNumber + ':' + productId + ':' + chargeType; 
          // save in map  
          newLineKey2IdMap.put(newLineKey, newLineItem.Id);

        }
      }

       // create map of old line item ids to new line item ids
        Set<ID> oldLineItemIds = oldLineId2KeyMap.keySet();
        List<ID> newLineItemIds = new List<ID>();
        for (String oldLineItemId : oldLineItemIds){      
          // get attribute key
          String attrKey = oldLineId2KeyMap.get(oldLineItemId);
          // lookup key in new line items map
          String newLineItemId = null;
          if(newLineKey2IdMap.containsKey(attrKey))
        {
          newLineItemId = newLineKey2IdMap.get(attrKey);
          newLineItemIds.add(newLineItemId);
          // associate old key with new one
          lineOldId2NewIdMap.put(oldLineItemId, newLineItemId);
        }    

      }

      // update reapprovals data by calling API in approvals package
     
    List<ID> oldContextObjIds = new List<ID>(oldLineItemIds);
    List<ID> newContextObjIds = new List<ID>(newLineItemIds);

        ilib_LogEvent.info('sObjectType : '+PROPOSAL_SOBJECT_TYPE);
        ilib_LogEvent.info('contextObjId : '+quoteId);
        ilib_LogEvent.info('oldContextObjIds : '+oldContextObjIds);
        ilib_LogEvent.info('newContextObjIds : '+newContextObjIds);

        if (!oldContextObjIds.isEmpty() && !newContextObjIds.isEmpty() && oldContextObjIds.size() == newContextObjIds.size())
        {
            // get process instance associated with the old quote
            
            Map<ID,Apttus_Approval__ApprovalProcessInstance__c> instanceSO = getProcessInstance(quoteId);
            system.debug('instanceSO  '+instanceSO);
                 ilib_LogEvent.info('instanceSO='+instanceSO);
                  for(ID quoteIdTemp : quoteId){
                       // call API to update reapproval data
                          If(instanceSO.containsKey(quoteIdTemp)&&instanceSO.get(quoteIdTemp)!=null&&instanceSO.get(quoteIdTemp).Id!=null){
                              Boolean ok = Apttus_Approval.ApprovalsWebService.updateApprovalData(instanceSO.get(quoteIdTemp).Id, PROPOSAL_SOBJECT_TYPE, quoteIdTemp, oldContextObjIds, newContextObjIds);
                              ilib_LogEvent.info('Apttus_Approval.ApprovalsWebService.updateApprovalData='+ok);
                           }
                  }
            

        }
        
        ilib_LogEvent.pop();
    }

/**
* Get process instance for the given proposal id
* @param proposalId
* @return process instance object
*/

  private static Map<ID,Apttus_Approval__ApprovalProcessInstance__c> getProcessInstance(Set<ID> proposalId)
  {
    List<Apttus_Approval__ApprovalProcessInstance__c> instanceList = new ApttusApprovalProcessInstancesSelector().selectbyApprovalBusinessObjectId(proposalId);
    Map<ID,Apttus_Approval__ApprovalProcessInstance__c> returnInstanceMap = new Map<ID,Apttus_Approval__ApprovalProcessInstance__c>();
       
      for(Apttus_Approval__ApprovalProcessInstance__c tempInstance : instanceList){
        
        if(returnInstanceMap.containsKey(tempInstance.Apttus_Approval__BusinessObjectId__c)){
                  continue;
        }
        returnInstanceMap.put(tempInstance.Apttus_Approval__BusinessObjectId__c,tempInstance);

      }

      return returnInstanceMap;
    
  }
    
 
/**
* Checks if the given string value is null or empty.
* @param strValue the string to check
* @return <code>true</code> if the string value is null or empty, <code>false</code> otherwise
*/
/*
  public static Boolean nullOrEmpty(String strValue)
  { 
    // check if null or zero length string
    return (strValue == null || String.isEmpty(strValue));
    }
    */

/**
* Checks if the given list of objects is null or empty.
* @param objList the list of objects to check
* @return <code>true</code> if the list is null or empty, <code>false</code> otherwise
*/
/*
  public static Boolean nullOrEmpty(List<Object> objList)
  {
    // check if null or empty
    return (objList == null || objList.isEmpty());
  }
    */
}