/***************************************************************************************************************************************
 * NAME   : AddArticletoCaseController
 * DESCRIPTION  : Used to Query Case and attach Atricle to a Case
 *    
 * @AUTHOR : Digvijay
 * @DATE   : 25-09-2019  
 *
 * MODIFICATION LOG:  
 * --------------------------------------------------------------------------------------------------------------------------------------
 * DEVELOPER                DATE                DESCRIPTION 
 * Digvijay                 25-09-2019          Created
 * --------------------------------------------------------------------------------------------------------------------------------------
  ****************************************************************************************************************************************/ 



public with sharing class AddArticletoCaseController {

/**
    *    @author Digvijay Singh    
    *    @description method to Query Cases as per the search Keyword
    */

    @AuraEnabled(cacheable = true)
    public static List<SObject> findRecords(String searchKey, String objectName, String searchField,String queryFields){
        String key = '%' + searchKey + '%';
        List<String> lstFieldsTobeSearched=new List<String>();

        if(searchField.contains(',')){
         lstFieldsTobeSearched=searchField.split(',');
        }
         else {
           lstFieldsTobeSearched.add(searchField);  
         }
       System.debug('lstFieldsTobeSearched..'+lstFieldsTobeSearched);
         String whereClause='';
         if(lstFieldsTobeSearched!=null && !lstFieldsTobeSearched.IsEmpty()){
             for(String sval:lstFieldsTobeSearched){
                 if(whereClause=='')
                    whereClause= sval + ' LIKE '+'\''+key+'\'' ;
                 else 
                     whereClause=whereClause+' Or '+sval + ' LIKE '+'\''+key+'\'' ;
             }
         }
        //String QUERY = 'Select Id,Subject, '+searchField+' From '+objectName +' Where '+searchField +' LIKE '+'\''+key+'\'' +' Or Subject'+' LIKE '+'\''+key+'\'';
        String strQUERY = 'Select Id, '+queryFields+' From '+objectName +' Where '+whereClause;
        System.debug(System.LoggingLevel.DEBUG, strQUERY);
        List<SObject> sObjectList = Database.query(strQUERY);
        return sObjectList;
    }
    
    
    /**
    *    @author Digvijay Singh    
    *    @description method to Attach Article to Case.
    */

    @AuraEnabled
    public static Boolean  attachCase(String articleId, String caseId){
    
    //Get the KnowledgeArticleId 
      knowledge__kav k = [SELECT KnowledgeArticleId FROM knowledge__kav WHERE Id = :Id.ValueOf(articleId)];
      
    //check is the article is already attached to the Case
      List<CaseArticle> lstCaseArticle=[Select Id from CaseArticle where CaseId=: Id.ValueOf(caseId) and KnowledgeArticleId=:k.KnowledgeArticleId];

     //Create Association between Article and the Case.
      if(lstCaseArticle==null || lstCaseArticle.IsEmpty()){
        CaseArticle newCaseArticle=new CaseArticle();
        if(!String.isBlank(articleId) && !String.isBlank(caseId)){
        newCaseArticle.KnowledgeArticleId=k.KnowledgeArticleId;
        newCaseArticle.CaseId=Id.ValueOf(caseId);
        insert newCaseArticle;
        System.debug('here'+lstCaseArticle);
        return true;
    }
 
    }
    System.debug('here..2'+lstCaseArticle);
    return false;
    }

    

}