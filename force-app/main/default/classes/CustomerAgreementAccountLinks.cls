/**
 * Created by tnewman on 11/20/18.
 */

//DCP-32828 - Commenting as a part of Deprecating Legacy Agreement object.
//public with sharing class CustomerAgreementAccountLinks extends ilib_SObjectDomain {
public with sharing class CustomerAgreementAccountLinks{

    public CustomerAgreementAccountLinks(){}

    /*
    public CustomerAgreementAccountLinks(List<Customer_Agreement_Account_Link__c> sObjectList)
    {
        super(sObjectList);
    } 
    
    
    * Boilerplate which is required for base class instantiation logic
    */
    /*public class Constructor implements ilib_SObjectDomain.IConstructable
    {
        public ilib_SObjectDomain construct(List<SObject> sObjectList)
        {
            return new CustomerAgreementAccountLinks(sObjectList);
        }
    }

    public override void onAfterInsert()
    {
        TAPS_Orchestrator.recalculateRecordChanges(UtilsCollection.getSetOfIds(records, 'Customer_Agreement__c'), Customer_Agreement__c.SObjectType);
    }

    public override void onAfterUpdate(Map<Id, sObject> existingRecords)
    {
        // determine which agreements have a sharing impact
        // this could move to TAPS_Orchestrator method
        // there currently is not a utility method for changes in junction objects
        Set<Id> affectedAgreementIds = new Set<Id>();
        for (Customer_Agreement_Account_Link__c rec : (List<Customer_Agreement_Account_Link__c>)records)
        {
            Customer_Agreement_Account_Link__c oldRec = (Customer_Agreement_Account_Link__c)existingRecords.get(rec.Id);

            if (rec.Account__c != oldRec.Account__c)
                affectedAgreementIds.add(rec.Customer_Agreement__c);

            if (rec.Customer_Agreement__c != oldRec.Customer_Agreement__c)
            {
                affectedAgreementIds.add(rec.Customer_Agreement__c);
                affectedAgreementIds.add(oldRec.Customer_Agreement__c);
            }
        }

        if (affectedAgreementIds.size() > 0)
            TAPS_Orchestrator.recalculateRecordChanges(affectedAgreementIds, Customer_Agreement__c.SObjectType);
    }*/

}