/**
*    @author: Deep Diwakar
*    @date:   Sep-05-2024
*    @description: Controller class for ideaKnowledgeComponent LWC
*    @Test Class: TestIdeaKnowledgeController
*    Modification Log:
*    --------------------------------------------------------------------------------------------------
*          Developer           Date                 Description
*         Deep Diwakar       Sep-05-2024       CMCM-10147: Controller class for ideaKnowledgeComponent LWC
*    --------------------------------------------------------------------------------------------------
*/
public with sharing class IdeaKnowledgeController {

    private static final String LOG_TITLE = 'IdeaKnowledgeController';

    // Added for test coverage of catch block. It is getting updated through its test class
    @TestVisible
    private static Boolean testCodeCoverage = false;

    private static final string TEST_CUSTOM_EXCEPTION = 'Test exception to cover catch block';

    /**
     * @author: Deep Diwakar
     * @date: Sep-05-2024
     * @description: this method finds existing ideas matching user input search text
     * @param: User input search string
     * @return: List of idea records
     */
    @AuraEnabled(cacheable=true)
    public static List<innohub__Innovation_Idea__c> findIdeas(String searchText) {
        ilib_LogEvent.push(LOG_TITLE + '.findIdeas');

        ilib_LogEvent.info('searchText: ' + searchText);

        String finalSearchText = searchText;

        List<innohub__Innovation_Idea__c> resultList = new List<innohub__Innovation_Idea__c>();

        try {

            if (String.isBlank(searchText)) {
                return resultList;
            }
            
            ilib_LogEvent.info('testCodeCoverage: ' + testCodeCoverage);
            // Added for covering catch block in test class
            if (testCodeCoverage && Test.isRunningTest()) {
                throw new CustomException(TEST_CUSTOM_EXCEPTION);
            }
    
            // check for special character and add backslash
            List<String> lstReservedChar = new List<String>{'?', '&', ':', '!', '*', '|', '{', '}', '[', ']', '(', ')'};
            for (String reservedChar : lstReservedChar) {
                if (searchText.contains(reservedChar)) {
                    finalSearchText = searchText.replace(reservedChar, '\\' + reservedChar);
                }
            }

            ilib_LogEvent.info('updated finalSearchText: ' + finalSearchText);

            ilib_LogEvent.info('starting sosl query');

            List<List<sObject>> searchResult = [FIND :finalSearchText IN NAME FIELDS RETURNING
                                                 innohub__Innovation_Idea__c(Id, Name, Sub_Category__c, Category__c, CreatedDate, CreatedBy.Name) LIMIT 2000];
    
            resultList = (List<innohub__Innovation_Idea__c>) searchResult[0];

            ilib_LogEvent.info('resultList: ' + resultList);

            return resultList;

        } catch(Exception ex) {
            ilib_LogEvent.error('exception message: ' + ex.getMessage());
            ApexExceptions.emit(LOG_TITLE + '.findIdeas', ex, 'Marketing');
            throw new AuraHandledException( ex.getMessage());
        } finally {
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }

    }

    /**
     * @author: Deep Diwakar
     * @date: Sep-05-2024
     * @description: this method returns existing ideas linked to given KAV
     * @param: KAV id
     * @return: List of idea records
     */
    @AuraEnabled(cacheable=true)
    public static List<innohub__Innovation_Idea__c> getLinkedIdeas(String kavId) {

        ilib_LogEvent.push(LOG_TITLE + '.getLinkedIdeas');

        ilib_LogEvent.info('call received with kavId: ' + kavId);
        try {

            // Added for covering catch block in test class
            if (testCodeCoverage && Test.isRunningTest()) {
                throw new CustomException(TEST_CUSTOM_EXCEPTION);
            }

            List<innohub__Innovation_Idea__c> lstLinkedIdeas = new List<innohub__Innovation_Idea__c>();
            List<IdeaArticle__c> lstIdeaArticle = new List<IdeaArticle__c>();
            
            // get all IdeaArticles linked to this KAV
            lstIdeaArticle = new IdeaArticlesSelector().selectIdeaArticlesByKavId(new Set<Id>{kavId});

            if (lstIdeaArticle.isEmpty()) {
                return lstLinkedIdeas;
            }
    
            Set<Id> setIdeaIds = UtilsCollection.getSetOfIds(lstIdeaArticle, 'Idea_Innohub__c');
    
            // get all ideas using idea ids from ideaArticle records
            lstLinkedIdeas = new InnovationIdeasSelector().selectIdeasById(setIdeaIds);
            
            ilib_LogEvent.info('lstLinkedIdeas: ' + lstLinkedIdeas);
            return lstLinkedIdeas;

        } catch (Exception ex) {
            ilib_LogEvent.error('exception message: ' + ex.getMessage());
            ApexExceptions.emit(LOG_TITLE + '.getLinkedIdeas', ex, 'Marketing');
            throw new AuraHandledException(ex.getMessage());
        } finally {
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }


    }

    /**
     * @author: Deep Diwakar
     * @date: Sep-05-2024
     * @description: this method finds existing ideas matching user input search text
     * @param: kavId: Knowledge Article version id
     * @param: lstIdeaIds: List of Idea ids that needs to be linked to this KAV
     * @return: List of idea records
     */
    @AuraEnabled
    public static Boolean attachIdeaToKnowledge(String kavId, List<Id> lstIdeaIds) {

        ilib_LogEvent.push(LOG_TITLE + '.attachIdeaToKnowledge');

        ilib_LogEvent.info('kavId: ' + kavId);
        ilib_LogEvent.info('lstIdeaIds: ' + lstIdeaIds);

        Boolean result = false;

        List<Id> filteredIdeaList = new List<Id>();

        // copying all values first
        filteredIdeaList = lstIdeaIds;

        try {

            ilib_LogEvent.info('testCodeCoverage: ' + testCodeCoverage);

            // Added for covering catch block in test class
            if (testCodeCoverage && Test.isRunningTest()) {
                throw new CustomException(TEST_CUSTOM_EXCEPTION);
            }

            // filter any idea that is already linked with given KAV. Case linking is not checked as that is managed
            // seperately. 
            for (IdeaArticle__c iaObj : new IdeaArticlesSelector().selectIdeaArticlesByKavAndIdeaIds(new Set<Id>{kavId}, new Set<Id>(lstIdeaIds))) {

                // removing ideas that are already connected to given KAV
                if (filteredIdeaList.contains(iaObj.Idea_Innohub__c)) {
                    ilib_LogEvent.message('removing already linked idea');
                    Integer linkedIdeaIndex = filteredIdeaList.indexOf(iaObj.Idea_Innohub__c);
                    filteredIdeaList.remove(linkedIdeaIndex);
                }
            }

            ilib_LogEvent.info('filteredIdeaList size: ' + filteredIdeaList.size());

            if (filteredIdeaList.isEmpty()) {
                ilib_LogEvent.info('This idea is already attached to this KAV');
                ilib_LogEvent.pop();
                ilib_LogEvent.emit();
                return result;
            }
            
            // get active/online knowledge article version
            List<Knowledge__kav> lstKavList  = [SELECT KnowledgeArticleId FROM Knowledge__kav Where Id =: kavId AND PublishStatus = 'Online'];
            ilib_LogEvent.info('lstKavList: ' + lstKavList);

            // get knowledge article Id
            Id knowledgeArticleId = lstKavList.get(0).KnowledgeArticleId;
            ilib_LogEvent.info('knowledgeArticleId: ' + knowledgeArticleId);
            
            // get linked case-article records
            List<CaseArticle> lstCaseArticle = [Select Id, CaseId, KnowledgeArticleId From CaseArticle
                                                    Where KnowledgeArticleId =: knowledgeArticleId];

            ilib_LogEvent.info('lstCaseArticle: ' + lstCaseArticle);

            List<IdeaArticle__c> lstIdeaArticle = new List<IdeaArticle__c>();
            createIdeaArticleRecords(kavId, lstIdeaArticle, lstCaseArticle, filteredIdeaList);

            ilib_LogEvent.info('lstIdeaArticle: ' + lstIdeaArticle);
            // inserting list records
            if (!lstIdeaArticle.isEmpty()) {
                ilib_LogEvent.info('inserting records');
                insert lstIdeaArticle;
                result = true;
            }

            return result;


        } catch(exception ex) {
            ilib_LogEvent.error('exception message: ' + ex.getMessage());
            ApexExceptions.emit(LOG_TITLE + '.attachIdeaToKnowledge', ex, 'Marketing');
            result = false;
            throw new AuraHandledException(ex.getMessage());
            
        } finally {
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
        }

    }

    /**
     * @author: Deep Diwakar
     * @date: Oct-15-2024
     * @description: this method adds idea article records to the list for insertion
     * @param: kavId: Knowledge Article version id
     * @param: lstIdeaArticle: List of Idea Article records that needs to be inserted, initially zero records
     * @param: lstCaseArticle: List of Case article records currently linked to this KAV
     * @param: filteredIdeaList: List of Idea ids that needs to linked to given KAV
     * @return: void
     */
    private static void createIdeaArticleRecords(String kavId, List<IdeaArticle__c> lstIdeaArticle, List<CaseArticle> lstCaseArticle, List<Id> filteredIdeaList) {

        if (lstCaseArticle.isEmpty()) {
            // looping to create IdeaArticle records using kav id and idea ids
            for (Id ideaId : filteredIdeaList) {
                // creating idea-article object records
                IdeaArticle__c ideaArticle = new IdeaArticle__c();
                ideaArticle.Knowledge__c = kavId;
                ideaArticle.Idea_Innohub__c =  ideaId;
                lstIdeaArticle.add(ideaArticle);

            }

        } else {
            // looping to create IdeaArticle records using kav id, case id and idea ids
            for (Id ideaId : filteredIdeaList) {
                for (CaseArticle caseArticle : lstCaseArticle) {
                    // creating idea-article object records
                    IdeaArticle__c ideaArticle = new IdeaArticle__c();
                    ideaArticle.Knowledge__c = kavId;
                    ideaArticle.Idea_Innohub__c =  ideaId;
                    ideaArticle.Case__c = caseArticle.CaseId;
                    lstIdeaArticle.add(ideaArticle);
                }

            }

        }

    }

    /*
    @Description: To throw custom exception for covering catch block in test class execution
   */
   public class CustomException extends Exception {}


}