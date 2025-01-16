/**
 *    @author Avina
 *    @date   24-Aug-2022
 *    @description: Controller Class for LWC insertQuickText
 *    Modification Log:
 *    --------------------------------------------------------------------------------------------------- 
 *    Developer                      Date                Description
 *    Avina                          24-Aug-2022         QACM-88 Created QaReviewTemplateController class
 *    ---------------------------------------------------------------------------------------------------
 *                    
 */
public with sharing class QaReviewTemplateController {
    private static final String LOG_TITLE = 'QaReviewTemplateController';
    public static final Integer CHARACTER_LIMIT = 32000;
    public static final String CASE_OBJECT_API = 'Case';
    public static final String SUCCESS_MESSAGE = 'Successfully Updated';
    public static final String LIMIT_EXCEED = 'Limit Exceed' ;
    public static final String QA_REVIEW_IS_EMPTY = 'QA Review Field Is Empty' ;
    public static final String QA_REVIEW = 'In Progress' ;

    /**
    *  @author Avina
    *  @description - QACM-88 Method to retieve Custom Quick Text records.
    *                 
    *  @PARAM :  Map<string,string> getTemplateData
    *  @RETURN:  String
    */ 

    @AuraEnabled(cacheable=true)
    public static Map<string,string> getTemplateData(string objectName) {
        ilib_LogEvent.push(LOG_TITLE + '.getTemplateData()');
        Map<String,string> templateDataMap = new Map<string,string>();
        try {
            List<Custom_Quick_Text__c> quickTextList = new CustomQuickTextSelector().selectCustomQuickTextbyObject(objectName);
            ilib_LogEvent.info('quickTextList-->:'+quickTextList);
            for ( Custom_Quick_Text__c quicText : quickTextList) {
                templateDataMap.put(quicText.Name,quicText.Template__c);
            }
            ilib_LogEvent.pop();
            return templateDataMap; 
        } Catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }         
    }

    /**
    *  @author Avina
    *  @description - QACM-88 Method to Update Investigation Summary field with search template value.
    *                 
    *  @PARAM :  Id recordId,String impactValue,String objectAPI
    *  @RETURN:  Boolean
    */ 
    @AuraEnabled
    public static String upsertSummaryField(Id recordId,String impactValue,String objectAPI) {
        String isUpdated;
        ilib_LogEvent.push(LOG_TITLE + '.upsertSummaryField()');
        String templateDataWithNewLine;
        String templateDataWithoutNewLine;
        Set<Id> caseId = new Set<Id>();
        caseId.add(recordId);
        try {
            Date todayDate = date.today();
            String currentDateFormat = DateTime.newInstance(todayDate.year(),todayDate.month(),todayDate.day()).format('dd-MMM-YYYY');
            String[] currentDateArray = currentDateFormat.split('-');
            String currentDate = currentDateArray[0]+'-'+currentDateArray[1].toUpperCase()+'-'+currentDateArray[2];
            
            if(objectAPI == CASE_OBJECT_API) {
                List<Case> caseRecord = new CasesSelector().selectCases(caseId);
                if(caseRecord[0].QA_Review__c == null || caseRecord[0].QA_Review__c == '' || String.isBlank(caseRecord[0].QA_Review__c)) {
                    ilib_LogEvent.pop();
                    return QA_REVIEW_IS_EMPTY;
                }
                templateDataWithNewLine = caseRecord[0].Investigation_Summary_Comments__c+'\n'+currentDate+' '+(UserInfo.getFirstName()).substring(0,1)+'.'+UserInfo.getLastName()+': '+impactValue;
                templateDataWithoutNewLine = currentDate+' '+(UserInfo.getFirstName()).substring(0,1)+'.'+UserInfo.getLastName()+': '+impactValue;

                if(caseRecord[0].Investigation_Summary_Comments__c!=null && templateDataWithNewLine.length()<=CHARACTER_LIMIT) {
                    isUpdated = updateSummaryField(caseRecord[0].Id,templateDataWithNewLine);
                } else if(caseRecord[0].Investigation_Summary_Comments__c==null && templateDataWithoutNewLine.length()<=CHARACTER_LIMIT) {
                    isUpdated = updateSummaryField(caseRecord[0].Id,templateDataWithoutNewLine);
                } else {
                    isUpdated = LIMIT_EXCEED;
                }
            }
            
            ilib_LogEvent.pop();
            return isUpdated;
        } Catch(Exception e) {
           throw new AuraHandledException(e.getMessage());
        }
    }

    /**
    *  @author Avina
    *  @description - QACM-88 Method to Update Investigation Summary field with search template value.
    *                 
    *  @PARAM :  Id caseId,String summaryValue
    *  @RETURN:  Boolean
    */ 
    public static String updateSummaryField(Id caseId,String summaryValue) {
        ilib_LogEvent.push(LOG_TITLE + '.upsertSummaryField()');
        Case updateCase = new Case();
        String status;
        try {
            updateCase.id=caseId;
            updateCase.Investigation_Summary_Comments__c = summaryValue;
            if(updateCase!=null) {
                    update updateCase;
                    ilib_LogEvent.info('updateCase-->:'+updateCase);
                    status = SUCCESS_MESSAGE;                    
            }
            
            ilib_LogEvent.pop();
            return status;
        } Catch(Exception e) {
           throw new StringException(e);
        }
        
    }

}
