/**
 *    @author Kushagra Desai
 *    @date   11-Dec-2019
 *    @description    Class to get the Related Agreement records based on different conditions ,
 *    Modification Log:
 *   ---------------------------------------------------------------------------------------------------------------------------
 *    Developer                      Date                    Description
 *     Vishnu Kurra					 03-March-2020			 Updated as part of story 34995
 *     Adyasha Satapathy             27-Sep-2021             DCP-47727: Added new method getRelatedAgreementToForParentAgreements
 *     Bharath Varma                 28-Feb-2022             TASK0700485 : Added new method getRelatedAgreementForCurrentAgreement 
 *     Bharath Varma                 30-Mar-2022             TASK0718153 : Added new method getRelatedAgreementRecordsByIds
 *    --------------------------------------------------------------------------------------------------------------------------
 */ 
public with sharing class ApttusRelatedAgreementSelectors extends ilib_SObjectSelector{
    private static final string  LOG_TITLE = 'ApttusRelatedAgreementSelectors';
    private static final  string SALES_QUERY_LOGS = 'SalesQueryLogs';
    /**
    *  @author Kushagra Desai 
    *  @description  
    *  @return SObjectType The Schema.SObjectType of the Line Items
    **/
    public Schema.SObjectType getSObjectType()
    {
       return Apttus__APTS_Related_Agreement__c.sObjectType;
    }
    /**
     *  @author Kushagra Desai
     *  @description Retrieve list of fields for Line Item sObject 
     *  @return sObjectFieldList list of Schema.SObjectField
     **/
    public List<Schema.SObjectField> getSObjectFieldList()
    {
        return new List<Schema.SObjectField> {
            Apttus__APTS_Related_Agreement__c.id,
            Apttus__APTS_Related_Agreement__c.Apttus__APTS_Contract_From__c,
            Apttus__APTS_Related_Agreement__c.Apttus__Relationship_From_Type__c,
            Apttus__APTS_Related_Agreement__c.Apttus__APTS_Contract_To__c,
            Apttus__APTS_Related_Agreement__c.Apttus__Relationship_To_Type__c
        };
    }
    /**
    *  @author Kushagra Desai
    *  @description 
    *  @param 
    *  @return 
    **/
    public List<Apttus__APTS_Related_Agreement__c> getRelatedAgreementTo(Id idParentAgreementId) 
    {
        return (List<Apttus__APTS_Related_Agreement__c>) Database.query(
            newQueryFactory().setCondition('Apttus__APTS_Contract_To__c =: idParentAgreementId')
                            .addOrdering('LastModifiedDate', ilib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );
    }
    
      /**
    *  @author  : Umesh
    *  @description :DCP-32419.
    *  @param   : Agreement Id
    *  @return :  List of related Agreement
    **/
    public List<Apttus__APTS_Related_Agreement__c> getRelatedAgreementToAndFrom(Id idParentAgreementId)
         
    {
        return (List<Apttus__APTS_Related_Agreement__c>) Database.query(
            newQueryFactory().selectField('Apttus__APTS_Contract_From__r.Apttus__Status__c')
                            .selectField('Apttus__APTS_Contract_To__r.Apttus__Status__c')
                            .setCondition('(Apttus__APTS_Contract_From__c =: idParentAgreementId AND Apttus__APTS_Contract_To__c != NULL) OR (Apttus__APTS_Contract_To__c=: idParentAgreementId AND Apttus__APTS_Contract_From__c != NULL)')
                            .addOrdering('LastModifiedDate', ilib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );
    }

    /**
     *  @author Adyasha Satapathy
     *  @description  DCP-47727: Retrieve related agreements based on Parent Agreements for Contract To Field
     *  @return List<Apttus__APTS_Related_Agreement__c>
     **/
    public List<Apttus__APTS_Related_Agreement__c> getRelatedAgreementToForParentAgreements(Set<Id> setParentAgreementIds) 
    {
        return (List<Apttus__APTS_Related_Agreement__c>) Database.query(
            newQueryFactory().selectField('Apttus__APTS_Contract_To__r.Apttus__FF_Agreement_Number__c')
                            .selectField('Apttus__APTS_Contract_From__r.Apttus__FF_Agreement_Number__c')
                            .selectField('Apttus__APTS_Contract_To__r.Apttus__Status_Category__c')
                            .selectField('Apttus__APTS_Contract_From__r.Apttus__Status_Category__c')
                            .setCondition('Apttus__APTS_Contract_To__c IN :setParentAgreementIds OR Apttus__APTS_Contract_From__c IN :setParentAgreementIds')
                            .addOrdering('CreatedDate', ilib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );
    }

    /**
     *  @author Bharath Varma
     *  @description  TASK0700485: Retrieve the related agreement records where the Contract To Id matches the Set
     *  @return List<Apttus__APTS_Related_Agreement__c>
     **/
    public List<Apttus__APTS_Related_Agreement__c> getRelatedAgreementForCurrentAgreement(Set<Id> setParentAgreementIds) 
    {        
        return (List<Apttus__APTS_Related_Agreement__c>) Database.query(
            newQueryFactory().selectField('Apttus__APTS_Contract_From__r.Number_Of_Agreement_Line_Items__c')
                            .setCondition('Apttus__APTS_Contract_To__c IN :setParentAgreementIds AND Apttus__APTS_Contract_From__c != NULL')
                            .addOrdering('CreatedDate', ilib_QueryFactory.SortOrder.DESCENDING).toSOQL()
        );
    }

    /**
     *  @author Bharath Varma
     *  @description  TASK0718153: Retrieve the related agreement records given the Ids
     *  @return List<Apttus__APTS_Related_Agreement__c>
     **/
    public List<Apttus__APTS_Related_Agreement__c> getRelatedAgreementRecordsByIds(Set<Id> setRecordIds)
    {
        ilib_LogQuery logger=null;
        if(Feature.isOn(SALES_QUERY_LOGS)) {
            logger = new ilib_LogQuery(LOG_TITLE + '.getRelatedAgreementRecordsByIds', UtilsCollection.serializeIds(setRecordIds));
        }

        List<Apttus__APTS_Related_Agreement__c> res = (List<Apttus__APTS_Related_Agreement__c>) Database.query(
            newQueryFactory().setCondition('Id IN :setRecordIds AND Apttus__APTS_Contract_To__c != NULL AND Apttus__APTS_Contract_From__c != NULL')
                             .toSOQL()
        );

        if(Feature.isOn(SALES_QUERY_LOGS)) {
            logger.stop(res.size());
        }

        return res;
    }
}