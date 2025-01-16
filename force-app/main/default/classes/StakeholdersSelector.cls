/**
*    @author Vaibhav Sirohi
*    @date   2018-09-29
*    @description    DCP-2745: Stakeholder Selector class
*    Modification Log:
*    ------------------------------------------------------------------------------------ 
*             Developer                      Date                Description
*    ------------------------------------------------------------------------------------ 
*     1.    Bharath Varma                  26-11-2020         Added Department field as part of DCP-31208              
*/

public with sharing class StakeholdersSelector extends ilib_SObjectSelector{
    private Boolean removeDefaultOrderBy=false;
    /*
     * Method to return SObjectType
     */
    public Schema.SObjectType getSObjectType()
    {
        return Key_Stakeholder_Analysis__c.sObjectType;
    }
    
    /**
    *  @author  Vaibhav Sirohi
    *  @description Retrieve list of fields for stakeholder Object 
    *  @return sObjectFieldList list of Schema.SObjectField
    **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
         removeDefaultOrderBy=TRUE;
        return new List<Schema.SObjectField> {
            Key_Stakeholder_Analysis__c.id,
                Key_Stakeholder_Analysis__c.Name,
               	Key_Stakeholder_Analysis__c.Influence__c,
                Key_Stakeholder_Analysis__c.Buying_Role__c,
                Key_Stakeholder_Analysis__c.Priority_Interests_Objectives__c,
                Key_Stakeholder_Analysis__c.Level_of_Support__c,
                Key_Stakeholder_Analysis__c.Pain_Points_Concerns__c,
                Key_Stakeholder_Analysis__c.Status__c,
                Key_Stakeholder_Analysis__c.Contact__c,
                Key_Stakeholder_Analysis__c.Contact__r.Name,
                Key_Stakeholder_Analysis__c.Account_Plan__c,
                Key_Stakeholder_Analysis__c.Ranking__c,
                Key_Stakeholder_Analysis__c.Ranking_in_Number__c,
                Key_Stakeholder_Analysis__c.Current_Access__c,
                Key_Stakeholder_Analysis__c.Support_Quotient__c,
                // DCP-31208
                Key_Stakeholder_Analysis__c.Department__c
                }; 
                    }
    /**
    *  @author Vaibhav Sirohi
    *  @description Override Default name Ordering
    *  
    *  @return String for Ordering  
    **/
    
    public override String getOrderBy() {
        if(removeDefaultOrderBy){
            return 'Support_Quotient__c Desc';
        }else{
            return super.getOrderBy();
        }
        
    }   
    
     /*
    *  @AUTHOR:  Vaibhav Sirohi
    *  @DESCRIPTION: selectStakeholders method to fetch all the Stakeholder records   
    *  @PARAM :  String accountPlanRecordId
    *  @RETURN:  List<Key_Stakeholder_Analysis__c>
    */
    
     public List<Key_Stakeholder_Analysis__c> selectStakeholders(String accountPlanRecordId) 
    {
        String activeState = 'Active';
        return (List<Key_Stakeholder_Analysis__c>) Database.query(
                                    newQueryFactory()
             						.selectField('Contact__r.FirstName')
            						.selectField('Contact__r.LastName')
                                    .setCondition('Account_Plan__c =: accountPlanRecordId AND Status__c= :activeState').toSOQL()
        );
    }   


}