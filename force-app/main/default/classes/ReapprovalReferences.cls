/**
*    @author Kumar Gaurav
*    @date   
*    @description   
*    @Test class for 90% coverage -  
*    Modification Log:  
*    ------------------------------------------------------------------------------------
*      Developer                      Date                 Description
*      Kumar Gaurav                 21-Jun-2024            Initial Commit
*/
public with sharing class ReapprovalReferences extends ilib_SObjectDomain{
    /*
Super method for class
*/
public ReapprovalReferences(List<Reapproval_Reference__c> sObjectList) {
    super(sObjectList);
}

/**
* Boilerplate which is required for base class instantiation logic
**/
public class Constructor implements ilib_SObjectDomain.IConstructable {
    /*
Constructor class
*/
    public ilib_SObjectDomain construct(List<SObject> sObjectList) {
        return new ReapprovalReferences(sObjectList);
    }
}
        /**
     *  @author Kumar Gaurav 
     *  @description [DGP-31] On insert update proposal with reapproval reference id
     **/
public override void onAfterInsert()
    {  

        Map <id,String> quotetoreapprovalReferenceMap = new Map<id,String>();
        List <Apttus_Proposal__Proposal__c> quoteList = new List <Apttus_Proposal__Proposal__c>();
        List <Apttus_Proposal__Proposal__c> quoteUpdateList = new List <Apttus_Proposal__Proposal__c>();
        for (Reapproval_Reference__c  rr : (List<Reapproval_Reference__c>)records)
        {
            if (rr.Quote_Proposal_Id__c != null)
            {
                quotetoreapprovalReferenceMap.put(rr.Quote_Proposal_Id__c,rr.id);
                
            }
        }
        ilib_LogEvent.info('quotetoreapprovalReferenceMap'+quotetoreapprovalReferenceMap);
        if (!quotetoreapprovalReferenceMap.isEmpty())
        {
            quoteList = new  ApttusProposalsSelector().selectReapprovalReferenceByQuotationIds(quotetoreapprovalReferenceMap.keyset());
            ilib_LogEvent.info('quoteList'+quoteList);
            For (Apttus_Proposal__Proposal__c quote : quoteList)
            {
                ilib_LogEvent.info(quote.Reapproval_Reference__c);
                if (quotetoreapprovalReferenceMap.containsKey(quote.id) && quotetoreapprovalReferenceMap.get(quote.id) != null && 
                    (quote.Reapproval_Reference__c != quotetoreapprovalReferenceMap.get(quote.id) || String.isblank(quote.Reapproval_Reference__c))){
                    quoteUpdateList.add(new Apttus_Proposal__Proposal__c(id = quote.id,
                        Reapproval_Reference__c = quotetoreapprovalReferenceMap.get(quote.id)));
                }
            }
            ilib_LogEvent.info('quoteUpdateList'+quoteUpdateList);
        }
        if(!quoteUpdateList.isEmpty()){
            update quoteUpdateList;
        }
    }
}