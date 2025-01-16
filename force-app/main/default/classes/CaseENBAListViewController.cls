/****************************************************************************************************************************************
* NAME         : CaseENBAListViewController
* DESCRIPTION  : Controller class CaseENBAListViewController lwc
*                    
* @AUTHOR : Sheikh Shahnawaz
* @DATE   : 03-Jun-2022
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                 DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Sheikh Shahnawaz         03-Jun-2022          DCP-51725 Initial Version. List View for Case,Work Order and FAN object records
* Gladis                   09-Jun-2022          DCP-54039 Added method getPublishedKnwArticles will return list of published knowledge articles 
* Rohan Rathod             09-Jun-2022          DCP-54039 Added logic for review Field comments
--------------------------------------------------------------------------------------------------------------------------------------
****************************************************************************************************************************************/

public with sharing class CaseENBAListViewController {
    private static final String LOG_TITLE = 'CaseENBAListViewController';
    public static final String  CONTACTAPINAME = 'Contact';
    public static final String  INSTALLEDPRODUCTAPINAME = 'SVMXC__Installed_Product__c';
    public final static String CONTACT_OR_IP_WITH_ANOTHER_OPEN_CASE = 'This Contact and/or Installed Product has another Open Case';
    public final static String ACCOUNT_WITH_DUPLICATE_CASES = 'Potential Duplicate: This Account has another Opened Case within the last 8 hour';
      
    /**
    *  @AUTHOR - Sheikh Shahnawaz
    *  @RETURN - List<Case>
    *  @DESCRIPTION -- this method will return list of other open cases on contact/installed Product , 
    * list of other open cases created within 8 hours of created date of reference case. 
    **/
    @AuraEnabled(cacheable=true)
    public static List<Case> getCaseList(String caseId,String conIPId, String recommendationName) {
        ilib_LogEvent.push(LOG_TITLE + 'getCaseList()');
        ilib_LogEvent.info('caseId: ' + caseId);
        ilib_LogEvent.info('conIPId: ' + conIPId);
        ilib_LogEvent.info('recommendationName: ' + recommendationName);
       try {
            Id objectRecordId = conIPId;
            String sObjectName = objectRecordId.getSObjectType().getDescribe().getName();
            List<Case> lstCasesToDisplay = new   List<Case>();
            Set<Id> setCaseIds = new Set<Id>();
            Set<Id> setAccConIPIds =  new Set<Id>();
            Set<String> setFieldUpdate = new Set<String>{'Id','CaseNumber','Owner.Name','Subject','Status','Record_Type__c','Contact.Name','ContactId','Account.Name','AccountId','CreatedDate','SVMXC__Component__c' };
            String strCondition = '';
            strCondition = 'Id IN : setCaseIds And Status IN (\'Initiated\',\'In Progress\',\'Awaiting Response - Internal\',\'Awaiting Response - Customer\',\'Pending Logistics Review\',\'Pending QA Review\')';
            setCaseIds.add(caseId);
            List<Case> objCaseWithAccount = new CasesSelector().selectCasesWithDynamicFieldsAndCondition(setCaseIds,null,setFieldUpdate,null,strCondition,null,null);
            if(recommendationName == CONTACT_OR_IP_WITH_ANOTHER_OPEN_CASE) {
                setAccConIPIds.add(conIPId);
                if(sObjectName ==CONTACTAPINAME) {
                    strCondition = 'Id NOT IN : setCaseIds And Status IN (\'Initiated\',\'In Progress\',\'Awaiting Response - Internal\',\'Awaiting Response - Customer\',\'Pending Logistics Review\',\'Pending QA Review\') AND contactId IN : setAccConIPIds ';
                } else if(sObjectName ==INSTALLEDPRODUCTAPINAME) {
                    String notInContact = objCaseWithAccount!=null && !objCaseWithAccount.isEmpty() && objCaseWithAccount[0].ContactId!=null ? ' AND contactId!= \''+objCaseWithAccount[0].ContactId+'\'':'';
                    strCondition = 'Id NOT IN : setCaseIds And Status IN (\'Initiated\',\'In Progress\',\'Awaiting Response - Internal\',\'Awaiting Response - Customer\',\'Pending Logistics Review\',\'Pending QA Review\') AND SVMXC__Component__c IN : setAccConIPIds'+notInContact;
                }
                lstCasesToDisplay = new CasesSelector().selectCasesWithDynamicFieldsAndCondition(setCaseIds,setAccConIPIds,setFieldUpdate,null,strCondition,null,null);
                
            } else if(recommendationName == ACCOUNT_WITH_DUPLICATE_CASES) {
               if(objCaseWithAccount!=null && !objCaseWithAccount.isEmpty()) {
                    DateTime caseCreatedDate = objCaseWithAccount[0].CreatedDate;
                    DateTime eightHoursPastDate =  caseCreatedDate.addHours(-8);
                    DateTime eightHoursFutureDate =  caseCreatedDate.addHours(8);
                    ilib_LogEvent.info('eightHoursPastDate  '+eightHoursPastDate);
                    ilib_LogEvent.info('eightHoursFutureDate '+eightHoursFutureDate);
                    Id accountId = objCaseWithAccount[0].AccountId;
                    setAccConIPIds.add(accountId);
                    strCondition = 'AccountId IN : setAccConIPIds AND Id NOT IN : setCaseIds And Status IN (\'Initiated\',\'In Progress\',\'Awaiting Response - Internal\',\'Awaiting Response - Customer\') AND CreatedDate>=:eightHoursPastDate  AND CreatedDate <=: eightHoursFutureDate  ';
                    lstCasesToDisplay = new CasesSelector().selectCasesWithDynamicFieldsAndCondition(setCaseIds,setAccConIPIds,setFieldUpdate,null,strCondition,eightHoursPastDate,eightHoursFutureDate);
                   
                }
            }
            return lstCasesToDisplay;
        } catch (Exception e) {
            ilib_LogEvent.message('Error Message: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    
    /**
    *  @AUTHOR - Sheikh Shahnawaz
    *  @RETURN - List<SVMXC__Service_Order__c>
    *  @DESCRIPTION -- this method will return list elevated work orders on if account is elevated , 
    **/
    @AuraEnabled(cacheable=true)
    public static List<SVMXC__Service_Order__c> getWorkOrderList(String accountId) {
       ilib_LogEvent.push(LOG_TITLE + 'getWorkOrderList()');
       try { 
            Set<Id> setAccountIds = new Set<Id>();
            setAccountIds.add(accountId);
            Set<Id> setWOIds = new Set<Id>();
            List<SVMXC__Service_Order__c> lstWOsToDisplay = new List<SVMXC__Service_Order__c>();
            for(SVMXC__Service_Order__c objWO : new WorkOrdersSelector().selectElevatedWorkOrdersOnAccount(setAccountIds)) {
                setWOIds.add(objWO.Id);
                lstWOsToDisplay.add(objWO);
            }
            return lstWOsToDisplay;
        } catch (Exception e) {
            ilib_LogEvent.message('Error Message: ' + e.getMessage());
            throw new AuraHandledException(e.getMessage()); 
        }
    }
    /**  
    *  @AUTHOR - Sheikh Shahnawaz
    *  @RETURN - List<String>
    *  return  addresses for sending emails to Primary FAS and Primart FSE roles on elevated account 
    */
    @InvocableMethod(label='Get To Addresses'
        description='This function is meant to be used in a flow to get to addresses for email sent to elevated case account team')
    public static List<String> getToAddresses(List<Id> accountId) {
        ilib_LogEvent.push(LOG_TITLE + 'getToAddresses()');
        ilib_LogEvent.info('accountId: ' + accountId[0]);
        String query = 'select Id , owner.Email , (select Id,User_Role__c,User__r.SVMXC__Email__c from Account_Field_Support_Roles__r where User__r.SVMXC__Email__c!=null AND (User_Role__c = \'Primary Field Application Scientist\' OR User_Role__c = \'Primary Field Service Engineer\')) from Account where Id IN :accountId  ' ;
        List<Account> listAccounts  = Database.query(query);
        List<String> listOfToAddresses = new List<String>();
        if(listAccounts!=null && !listAccounts.isEmpty()) {
            String toAddresses = listAccounts[0].owner.Email;
            if(listAccounts[0].Account_Field_Support_Roles__r.size()>0) {
                for(Account_to_Field_Support__c objFieldSupport : listAccounts[0].Account_Field_Support_Roles__r) {
                    toAddresses = toAddresses +','+objFieldSupport.User__r.SVMXC__Email__c;
                }
            }
            ilib_LogEvent.info('toAddresses '+toAddresses);
            listOfToAddresses.add(toAddresses);
        }
        return listOfToAddresses;
    }

    /**
    *  @AUTHOR - Gladis
    *  @RETURN - List<Knowledge__kav>
    *  @DESCRIPTION - DCP-54039 this method will return list of published knowledge articles.
    **/
    @AuraEnabled
    public static List<Knowledge__kav> getPublishedKnwArticles(String recordId) {
        system.debug('inside method'+ recordId);
        ilib_LogEvent.push(LOG_TITLE + 'getPublishedKnwArticles()');
        List<Knowledge__kav> lstKnwArticles = new List<Knowledge__kav>();
        List<Knowledge__kav> lstArticlesToDisplay = new List<Knowledge__kav>();
        String strKeyWord ='Billable';
        try { 
            lstKnwArticles = new KnowledgeArticlesSelector().selectPublishedKnowledgeArticles(strKeyWord);

            if(!lstKnwArticles.isEmpty()) {   
                lstArticlesToDisplay.addAll(lstKnwArticles);
            }
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();   
            return lstArticlesToDisplay;
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE, e);
            throw new AuraHandledException(LOG_TITLE+'-getPublishedKnwArticles-'+ e.getMessage());
        }
    }

    /**
    *  @AUTHOR - Rohan
    *  @RETURN - List<Account>
    *  @DESCRIPTION - DCP-54039 this method will return list of account detail.
    **/
    @AuraEnabled
    public static List<Account> getAccountFieldDetails(String recordId) {
        system.debug('inside method'+ recordId);
        ilib_LogEvent.push(LOG_TITLE + 'getAccountFieldDetails()');
        List<Account> lstAccDetails = new List<Account>();
        Set<Id> setAccIds = new Set<Id>();
        setAccIds.add(recordId);
        try {              
            for (Account acc : new AccountsSelector().selectAccounts(setAccIds)) {
                if(String.isnotblank(acc.Field_Comments__c) && acc.Field_Comments__c.contains('TS do not process replacements')) { 
                    acc.Field_Comments__c = acc.Field_Comments__c.stripHtmlTags();
                    lstAccDetails.add(acc);
                }
            }                                  
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return lstAccDetails;
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE, e);
            throw new AuraHandledException(LOG_TITLE+'-getAccountFieldDetails-'+ e.getMessage());
        }
    }
}