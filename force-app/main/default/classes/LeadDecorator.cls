/**
 *   @author: Deep Diwakar
*    @date:   Nov-27-2023 
*    @description: Virtual class to create different lead decorators
*    @Test class: TestLeadDecorator
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Nov-27-2023          CMCM-4510: Initial version
*         Deep Diwakar       Dec-04-2023          CMCM-4510: Added test visible annotation to protected variable
*    --------------------------------------------------------------------------------------------------
 */

public with sharing virtual class LeadDecorator {

    // variable to hold list of lead records
    @TestVisible
    protected List<Lead> lstLead;

    /**
     * @author: Deep Diwakar
     * @date: Nov-27-2023 
     * @description: constructor to set lstLead variable
     * @param: List of Lead records
     */
    public LeadDecorator(List<Lead> lstIncomingLeads) {
        lstLead = lstIncomingLeads;
    }

    /**
     * @author: Deep Diwakar
     * @date: Nov-27-2023 
     * @description: virtual method for overriding to decorate lead records before insert
     * @param: none
     * @return: void
     */
    public virtual void decorateLeadBeforeInsert() { }

    /**
     * @author: Deep Diwakar
     * @date: Nov-27-2023 
     * @description: virtual method for overriding to decorate lead records after insert
     * @param: none
     * @return: void
     */
    public virtual void decorateLeadAfterInsert() { }

    /**
     * @author: Deep Diwakar
     * @date: Nov-27-2023 
     * @description: virtual method for overriding to decorate lead records before update
     * @param: Map for old values of lead records
     * @return: void
     */
    public virtual void decorateLeadBeforeUpdate(Map<Id, sObject> mapOfOldRecords) { }

    /**
     * @author: Deep Diwakar
     * @date: Nov-27-2023 
     * @description: virtual method for overriding to decorate lead records after update
     * @param: Map for old values of lead records
     * @return: void
     */
    public virtual void decorateLeadAfterUpdate(Map<Id, sObject> mapOfOldRecords) { }

}