/**
 *   @author: Deep Diwakar
*    @date:   Dec-01-2023 
*    @description: Virtual class to create different object decorators
*    @Test class: ilib_SObjectDecoratorTest
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Dec-01-2023          CMCM-4856: Initial version
*         Deep Diwakar       Dec-08-2023          CMCM-4856: Removed before and after method and made it more generic
*    --------------------------------------------------------------------------------------------------
 */

 public virtual with sharing class ilib_SObjectDecorator {

    // variable to hold list of records
    @TestVisible
    protected List<SObject> lstRecords;

    /**
     * @author: Deep Diwakar
     * @date: Dec-01-2023 
     * @description: constructor to set lstLead variable
     * @param: List of Lead records
     */
    public ilib_SObjectDecorator(List<SObject> lstIncomingSObjects) {
        lstRecords = lstIncomingSObjects;
    }

    /**
     * @author: Deep Diwakar
     * @date: Dec-01-2023 
     * @description: virtual method to decorate records
     * @param: none
     * @return: void
     */
    public virtual void decorate() { }

    /**
     * @author: Deep Diwakar
     * @date: Dec-01-2023 
     * @description: overloaded virtual method to decorate records 
     * @param: Map for old values of lead records
     * @return: void
     */
    public virtual void decorate(Map<Id, sObject> mapOfOldRecords) { }


}