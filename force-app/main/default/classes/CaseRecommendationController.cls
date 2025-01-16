/****************************************************************************************************************************************
* NAME         : CaseRecommendationController
* DESCRIPTION  : Controller class for Case ENBA Strategy
*                    
* @AUTHOR : Sheikh Shahnawaz
* @DATE   : 03-Jun-2022
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                 DATE                DESCRIPTION 
* --------------------------------------------------------------------------------------------------------------------------------------
* Sheikh Shahnawaz         03-Jun-2022          DCP-51725 Initial Version. Filters case recommendations for ENBA on case layout
* Gladis                   03-Jun-2022          DCP-54039 Added recommendation billable process flow if an Installed Product has no active contracts
* Rohan                    07-Jun-2022          DCP-54039 Added recommendation Loop Local Team if case open for >7 days
* Gladis                   09-Jun-2022          DCP-54039 Added recommendation case follow up if case not updated for 48 hours
--------------------------------------------------------------------------------------------------------------------------------------
****************************************************************************************************************************************/
public with sharing class CaseRecommendationController {
    private static final String LOG_TITLE = 'CaseRecommendationController';
    public final static Set<String> FOUR_OPEN_STATUSES = new Set<String>{'Initiated', 'In Progress', 'Awaiting Response - Internal', 'Awaiting Response - Customer' };  
    public final static Set<String> SIX_OPEN_STATUSES = new Set<String>{'Initiated', 'In Progress', 'Awaiting Response - Internal', 'Awaiting Response - Customer','Pending Logistics Review','Pending QA Review' };  
    public static List<List<Recommendation>> lstFinalRecommendations = new List<List<Recommendation>>();
    public static List<Recommendation> lstRecommendations = new List<Recommendation>();  
    /**
    *  @AUTHOR - Sheikh Shahnawaz
    *  @RETURN - List<List<Recommendation>>
    *  @DESCRIPTION - Invocable method called from ENBA strategy flow
                    Filter recommendations passed from strategy builder and returns only those which meets the criteria
    **/
    @InvocableMethod(label='Filter Recommendation'
    description='This function is meant to be used in an Enhance node in Einstein Next Best Action')
    public static List<List<Recommendation>> generateRecommendation(List<CaseRecommendationRequest> inputRequests) {

        ilib_LogEvent.push(LOG_TITLE + '.generateRecommendation()');
        try {
            Recommendation inputRecommendationToAdd;
            Set<Id> setCaseIds = new Set<Id>();
            setCaseIds.add(inputRequests[0].recordId);
            String strCondition = 'Id IN : setCaseIds ';
            Set<String> setFieldUpdate = new Set<String>();
            setFieldUpdate.add('SVMXC__Component__c');
            setFieldUpdate.add('AccountId');
            setFieldUpdate.add('ContactId');
            setFieldUpdate.add('Status');
            setFieldUpdate.add('SVMXC__Product__c');
            setFieldUpdate.add('CreatedDate');
            setFieldUpdate.add('LastModifiedDate');
            setFieldUpdate.add('Id');
            setFieldUpdate.add('SVMXC__Component__r.Currently_Active_Service_Contract__c');
            List<Case> listCase =  new CasesSelector().selectCasesWithDynamicFieldsAndCondition(setCaseIds,null,setFieldUpdate,null,strCondition,null,null);
            
            for (Recommendation inputRecommendation : inputRequests[0].recommendations) {
                String recommendationName = inputRecommendation.Name;
                switch on recommendationName {
                    when 'This account is a hot site with at least one open elevation' {
                        inputRecommendationToAdd = checkAccountIsElevated(listCase[0],inputRecommendation);
                        lstRecommendations.add(inputRecommendationToAdd);
                    }
                   when 'This Contact and or Installed Product has another Open Case' {
                       inputRecommendationToAdd = checkCaseHasOtherOpenCases(listCase[0],inputRecommendation);
                       lstRecommendations.add(inputRecommendationToAdd);
                   }
                   when 'Potential Duplicate This Account has another Opened Case within the last 8 hour'  {
                        inputRecommendationToAdd = checkAccountHasDuplicateOpenCases(listCase[0],inputRecommendation);
                        lstRecommendations.add(inputRecommendationToAdd);
                   }
                   when 'This Installed Product does not have an Active Service Contract Associated with'  {
                       inputRecommendationToAdd = installedProductsWithNoActiveContracts(listCase[0],inputRecommendation);
                       lstRecommendations.add(inputRecommendationToAdd);
                   }
                   when 'This Case has a Product that may be related to a FAN'  {
                        inputRecommendationToAdd = checkForPotentialMatchedFans(listCase[0],inputRecommendation);
                        lstRecommendations.add(inputRecommendationToAdd);
                    }
                    when 'This Case has not been updated in two days'  {
                        inputRecommendationToAdd = caseNotUpdatedForTwoDays(listCase[0],inputRecommendation);
                        lstRecommendations.add(inputRecommendationToAdd);
                    }
                    when 'This Case has been opened for longer than seven days.'  {
                        inputRecommendationToAdd = caseNotUpdatedForSevenDays(listCase[0],inputRecommendation);
                        lstRecommendations.add(inputRecommendationToAdd);
                    }
                    when 'This Account has a specialized Replacement Process per the Field Comments'  {
                        inputRecommendationToAdd = associatedAccountCommentsReview(listCase[0],inputRecommendation);
                        lstRecommendations.add(inputRecommendationToAdd);
                    }
                }
            }    
            lstFinalRecommendations.add(lstRecommendations);
            ilib_LogEvent.message('lstFinalRecommendations: ' + lstFinalRecommendations.size()); 
            ilib_LogEvent.pop();
            ilib_LogEvent.emit();
            return lstFinalRecommendations;
        } catch (Exception e) {
            ApexExceptions.emit(LOG_TITLE,e);
            throw new AuraHandledException(e.getMessage());
        }     
    }
  
    /**
    *  @AUTHOR Sheikh Shahnawaz
    *  @DESCRIPTION - This account is a hot site with at least one open elevation.
    *  @PARAM -  String
    *  @RETURN - Boolean
    **/
    private static Recommendation checkAccountIsElevated(Case caseRecord,Recommendation inputRecommendation) {
        ilib_LogEvent.push(LOG_TITLE + 'checkAccountIsElevated()');
        Recommendation inputRecommendationToAdd;
        Set<Id> setWOIds = new Set<Id>();
        if(caseRecord.AccountId!=null && SIX_OPEN_STATUSES.contains(caseRecord.Status)) {
            Set<Id> setAccountIds = new Set<Id>();
            setAccountIds.add(caseRecord.AccountId);
            setWOIds = selectWorkOrdersRelatedToAccount(setAccountIds);
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return setWOIds!=null && !setWOIds.isEmpty() ? inputRecommendation:inputRecommendationToAdd;
    }
     /**
    *  @AUTHOR Sheikh Shahnawaz
    *  @DESCRIPTION - Private method to avoid complexity
    *  @PARAM -  Set<Id>
    *  @RETURN - Set<Id>
    **/
    private static Set<Id> selectWorkOrdersRelatedToAccount(Set<Id> setAccountIds) {
        ilib_LogEvent.push(LOG_TITLE + 'selectWorkOrdersRelatedToAccount()');
        Set<Id> setWOIds = new Set<Id>();
        for(SVMXC__Service_Order__c objWO : new WorkOrdersSelector().selectElevatedWorkOrdersOnAccount(setAccountIds)) {
            setWOIds.add(objWO.Id);
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return setWOIds;
    }

      /**
    *  @AUTHOR Sheikh Shahnawaz
    *  @DESCRIPTION - This Contact and/or
    *  Installed Product has another Open Case.
    *  @PARAM -  String
    *  @RETURN - Boolean
    **/
    private static Recommendation checkCaseHasOtherOpenCases(Case caseRecord,Recommendation inputRecommendation) {
        
        ilib_LogEvent.push(LOG_TITLE + 'checkCaseHasOtherOpenCases()');
        Recommendation inputRecommendationToAdd;
        Set<String> setFieldUpdate = new Set<String>();
        setFieldUpdate.add('SVMXC__Component__c');
        setFieldUpdate.add('ContactId');
        Boolean hasOtherOpenCaseOnIpOrContact = false;
        Set<Id> setCaseIds = new Set<Id>();
        setCaseIds.add(caseRecord.Id);
        hasOtherOpenCaseOnIpOrContact = selectDuplicateCasesOnContact(caseRecord,setCaseIds,setFieldUpdate);
        if(!hasOtherOpenCaseOnIpOrContact) {
            hasOtherOpenCaseOnIpOrContact = selectDuplicateCasesOnIP(caseRecord,setCaseIds,setFieldUpdate);
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return hasOtherOpenCaseOnIpOrContact ? inputRecommendation : inputRecommendationToAdd;
    }
     /**
    *  @AUTHOR Sheikh Shahnawaz
    *  @DESCRIPTION - Private method to avoid complexity
    *  @RETURN - Boolean
    **/
    private static Boolean selectDuplicateCasesOnContact(Case caseRecord,Set<Id> setCaseIds,Set<String> setFieldUpdate) {
        ilib_LogEvent.push(LOG_TITLE + 'selectDuplicateCasesOnContact()');
        Set<Id> setAccConIPIds =  new Set<Id>();
        List<Case> lstOpenCasesOnContactOrIP = new List<Case>();
        String strCondition;
        if(caseRecord.ContactId!=null && SIX_OPEN_STATUSES.contains(caseRecord.Status)) { 
            setAccConIPIds.add(caseRecord.ContactId);   
            strCondition = 'Id NOT IN : setCaseIds AND ContactId IN :setAccConIPIds And Status IN : setStatus';
            lstOpenCasesOnContactOrIP =  new CasesSelector().selectCasesWithDynamicFieldsAndCondition(setCaseIds,setAccConIPIds,setFieldUpdate,SIX_OPEN_STATUSES,strCondition,null,null);
       
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return lstOpenCasesOnContactOrIP!=null && !lstOpenCasesOnContactOrIP.isEmpty() ? true:false;
    }

    /**
    *  @AUTHOR Sheikh Shahnawaz
    *  @DESCRIPTION - Private method to avoid complexity
    *  @RETURN - Boolean
    **/
    private static Boolean selectDuplicateCasesOnIP(Case caseRecord,Set<Id> setCaseIds,Set<String> setFieldUpdate) {
        ilib_LogEvent.push(LOG_TITLE + 'selectDuplicateCasesOnIP()');
        Set<Id> setAccConIPIds =  new Set<Id>();
        List<Case> lstOpenCasesOnContactOrIP = new List<Case>();
        String strCondition;
        if(caseRecord.SVMXC__Component__c!=null &&  SIX_OPEN_STATUSES.contains(caseRecord.Status)) { 
            setAccConIPIds.add(caseRecord.SVMXC__Component__c); 
            strCondition = 'Id NOT IN : setCaseIds AND SVMXC__Component__c IN :setAccConIPIds And Status IN :setStatus';
            lstOpenCasesOnContactOrIP =  new CasesSelector().selectCasesWithDynamicFieldsAndCondition(setCaseIds,setAccConIPIds,setFieldUpdate,SIX_OPEN_STATUSES,strCondition,null,null);
       
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return lstOpenCasesOnContactOrIP!=null && !lstOpenCasesOnContactOrIP.isEmpty() ? true:false;
    }

    /**
    *  @AUTHOR Sheikh Shahnawaz
    *  @DESCRIPTION - Potential Duplicate: This Account
    *  has another Opened Case within the last 8 hours
    *  @PARAM -  String
    *  @RETURN - Boolean
    **/
    private static Recommendation checkAccountHasDuplicateOpenCases(Case caseRecord,Recommendation inputRecommendation) {
        
        ilib_LogEvent.push(LOG_TITLE + 'checkAccountHasDuplicateOpenCases()');
        Recommendation inputRecommendationToAdd;
        Set<Id> setAccConIPIds =  new Set<Id>();
        Set<String> setFieldUpdate = new Set<String>();
        setFieldUpdate.add('CreatedDate');
        setFieldUpdate.add('AccountId');
        Set<Id> setCaseIds = new Set<Id>();
        setCaseIds.add(caseRecord.Id);
        String strCondition ='';
        List<Case> listOfDuplicateCasesOnAccount  =  new List<Case>();
        if(caseRecord.AccountId!=null && FOUR_OPEN_STATUSES.contains(caseRecord.Status)) {
            DateTime createdDateOfCase = caseRecord.CreatedDate;
            DateTime eightHoursPastDate =  createdDateOfCase.addHours(-8);
            DateTime eightHoursFutureDate =  createdDateOfCase.addHours(8);
            setAccConIPIds.add(caseRecord.AccountId);
            strCondition = 'AccountId IN : setAccConIPIds AND Id NOT IN : setCaseIds And Status IN : setStatus And CreatedDate>= :eightHoursPastDate And  CreatedDate <=:eightHoursFutureDate';
            listOfDuplicateCasesOnAccount = new CasesSelector().selectCasesWithDynamicFieldsAndCondition(setCaseIds,setAccConIPIds,setFieldUpdate,FOUR_OPEN_STATUSES,strCondition,eightHoursPastDate,eightHoursFutureDate);
         
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return listOfDuplicateCasesOnAccount!=null && !listOfDuplicateCasesOnAccount.isEmpty() ? inputRecommendation :inputRecommendationToAdd;
    }
     /**
    *  @AUTHOR Sheikh Shahnawaz
    *  @DESCRIPTION - Checks if case has potential matched FAN records found for Product
    *  @PARAM - String
    *  @RETURN - Boolean
    **/
    private static Recommendation checkForPotentialMatchedFans(Case caseRecord,Recommendation inputRecommendation) {
        
        ilib_LogEvent.push(LOG_TITLE + 'checkForPotentialMatchedFans()');
        Recommendation inputRecommendationToAdd;
        Boolean hasPotentialMatchedFan = false;
        Set<Id> setCaseIds = new Set<Id>();
        setCaseIds.add(caseRecord.Id);
        List<Impacted_Products_Serials_Lots__c> lstImpactedProds = new  List<Impacted_Products_Serials_Lots__c>();
        List<Field_Action_Item__c> lstFieldActionItem = new List<Field_Action_Item__c>();
        lstFieldActionItem = new FieldActionItemsSelector().selectFieldActionItemsByCaseId(setCaseIds);
        if(caseRecord.SVMXC__Product__c!=null && FOUR_OPEN_STATUSES.contains(caseRecord.Status) && (lstFieldActionItem==null || lstFieldActionItem.isEmpty())) { 
            String productId  = caseRecord.SVMXC__Product__c;  
            lstImpactedProds  = new ImpactedProductSerialLotsSelector().selectImpactedProductByProductId(productId);
        }
        hasPotentialMatchedFan = getImpactedProductsWithFAN(lstImpactedProds);
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return hasPotentialMatchedFan?inputRecommendation:inputRecommendationToAdd;
    }

    
    /**
    *  @AUTHOR Sheikh Shahnawaz
    *  @DESCRIPTION - Private method to avoid complexity
    *  @RETURN - Boolean
    **/
    private static Boolean getImpactedProductsWithFAN(List<Impacted_Products_Serials_Lots__c> lstImpactedProds) {
        ilib_LogEvent.push(LOG_TITLE + 'getImpactedProductsWithFAN()');
        Boolean hasPotentialMatchedFan = false;
        for(Impacted_Products_Serials_Lots__c impactedProduct : lstImpactedProds) {
            if(impactedProduct.Field_Action_Notification__c!=null) {
               hasPotentialMatchedFan = true;
               break;
  
            }
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return hasPotentialMatchedFan;
    }
    /**
    *  @AUTHOR Gladis
    *  @DESCRIPTION - separting into new method to fix codescan npath complexity
                      check for Active Service Contract of IP on a Case
    *  @PARAM - Recommendation
    *  @RETURN - Recommendation
    **/
    private static Recommendation installedProductsWithNoActiveContracts(Case caseRecord, Recommendation inputRecommendation) {
        ilib_LogEvent.push(LOG_TITLE + 'installedProductsWithNoActiveContracts()');
        Recommendation objInputRecommendation;
        if(caseRecord.SVMXC__Component__c != null && caseRecord.SVMXC__Component__r.Currently_Active_Service_Contract__c == null && FOUR_OPEN_STATUSES.contains(caseRecord.Status)) {
            objInputRecommendation = inputRecommendation;
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return objInputRecommendation;
    }

    /**
    *  @AUTHOR Gladis
    *  @DESCRIPTION - separting into new method to fix codescan npath complexity
                      check if Case is not updated for equals/more than 48 hours
    *  @PARAM - Recommendation
    *  @RETURN - Recommendation
    **/
    private static Recommendation caseNotUpdatedForTwoDays(Case caseRecord, Recommendation inputRecommendation) {
        ilib_LogEvent.push(LOG_TITLE + 'caseNotUpdatedForTwoDays()');
        Recommendation objInputRecommendation;
        if(FOUR_OPEN_STATUSES.contains(caseRecord.Status) && dateToHours(caseRecord.LastModifiedDate) >= 48) {
            objInputRecommendation = inputRecommendation;
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit(); 
        return objInputRecommendation;
    }

    /**
    *  @AUTHOR Gladis
    *  @DESCRIPTION - Converts DateTime to Hours
    *  @PARAM - DateTime
    *  @RETURN - Long
    **/
    private static Long dateToHours(Datetime lastModifiedDate) {

        ilib_LogEvent.push(LOG_TITLE + 'dateToHours()');
        Long hours;
        if(lastModifiedDate!=null) {
            Long milliseconds = DateTime.now().getTime() - lastModifiedDate.getTime();
            Long seconds = milliseconds / 1000;
            Long minutes = seconds / 60;
            hours = minutes / 60;
        }
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
        return hours;
    }

  /**
    *  @AUTHOR Rohan
    *  @DESCRIPTION - Load recommendation case has not been updated in 7 days
    *  @PARAM - List<CaseRecommendationRequest>
    *  @RETURN - Boolean
    **/
    private static Recommendation caseNotUpdatedForSevenDays(Case caseRecord,Recommendation inputRecommendation) {
        
        ilib_LogEvent.push(LOG_TITLE + 'caseNotUpdatedForSevenDays()');
        ilib_LogEvent.message('Case Record Id: ' + caseRecord.Id);
        Recommendation objInputRecommendation;
        if(caseRecord.AccountId!=null && FOUR_OPEN_STATUSES.contains(caseRecord.Status) ){
            Date startDate = Date.valueOf(caseRecord.CreatedDate);    
            Integer numberDaysDue = startDate.daysBetween(Date.today());
                if( numberDaysDue > 7) {
                    objInputRecommendation = inputRecommendation;
                }
        }        
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();    
        return objInputRecommendation;
    }
     /**
    *  @AUTHOR Rohan
    *  @DESCRIPTION - Load recommendation Review Related Account's FIELD REVIEW Comments
    *  @PARAM - List<CaseRecommendationRequest>
    *  @RETURN - Boolean
    **/
    private static Recommendation associatedAccountCommentsReview(Case caseRecord,Recommendation inputRecommendation){
        ilib_LogEvent.push(LOG_TITLE + 'associatedAccountCommentsReview()');
        ilib_LogEvent.message('Case Record Id: ' + caseRecord.Id);
        Recommendation objInputRecommendation;
        Set<Id> setAccId = new Set<Id>();
        setAccId.add(caseRecord.AccountId);
        if(caseRecord.AccountId!=null && FOUR_OPEN_STATUSES.contains(caseRecord.Status)){
            for (Account acc : new AccountsSelector().selectAccounts(setAccId)) {
                if(String.isnotblank(acc.Field_Comments__c) && acc.Field_Comments__c.contains('TS do not process replacements')) {
                    objInputRecommendation = inputRecommendation;
                }
            }   
        }               
        ilib_LogEvent.pop();
        ilib_LogEvent.emit();    
        return objInputRecommendation;
    }

    /**
    *  @AUTHOR - Sheikh Shahnawaz
    *  @DESCRIPTION - Case Recommendation wrapper for holding case recordId and list of loaded recommendation from strategy builder.
    **/
    public class CaseRecommendationRequest {
        /** holds case record Id, passed from strategy builder  */
        @InvocableVariable(label='Record Id')
        public String recordId;
        /** holds list of all the recommendations loaded the case object */
        @InvocableVariable
        public List<Recommendation> recommendations;
    }
}