/*@ author       : Shaik Moulali
* @ date         : 27-08-2018
* @ Description  : Class created for managing Instructor Led Training Course Registrations.
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Shaik Moulali          27-08-2018                 US-4252             Initial version
* 
*/
public with sharing class InstructorLedTrainingController {
    /*
     * Fetching logged in User's Region
     */ 
    @AuraEnabled
    public static String getRegion(){
        String strUserRegion;
        
        UsersSelector usr=new UsersSelector();
        AccountsSelector accObj=new AccountsSelector();
        String strId=UserInfo.getUserId();
        System.debug('LoggedIn ID=='+strId);
        List<User> objUser=usr.getLoggedInPortalUser(strId);
        String strObj = objUser[0].Contact.AccountId;
        List<Account> lstAccount=accObj.selectLoggedInAccountForUser(strObj);
        strUserRegion = lstAccount[0].Territory_Region__c;
                
        return strUserRegion;
    }
    
    /*
     * Fetching Instructor Training Catalog list
     */ 
    @AuraEnabled
    public static List<Instructor_Training_Catalog__c> getTrainingList(){ 
        String strUserRegion=getRegion();
        InstructorTrainingCatalogsSelector catalog = new InstructorTrainingCatalogsSelector();
        
        // Get active training catalog records based on user's account region
        List<Instructor_Training_Catalog__c> lstTrainingCatalogs = catalog.selectInstructorLedTrainingCourses(strUserRegion);
        
        return lstTrainingCatalogs;      
    }
    
    /*
     * Saving Instructor Training Catalog list opted by channel partner user.
     */ 
    @AuraEnabled
    public static String saveTrainingCourses(String strCoursesSelected,String strTimeForAttendance, String strCourseJustification,
                                            String strObjApiName, String strRecordTypeName){ 
        System.debug('hieeee');                                                
        Partner_Request__c objPartnerRequest = new Partner_Request__c();
        String strUserRegion=getRegion();
        String strErrorMsg = '';
        objPartnerRequest.Requested_Courses__c = strCoursesSelected;
        objPartnerRequest.Timeframe_for_Attendance__c = strTimeForAttendance;
        objPartnerRequest.Course_Justification__c = strCourseJustification;
        try{
            //fetching record type information from partner requet
            Id recordType = [Select Id,Name From RecordType where sobjecttype = :strObjApiName and Name= :strRecordTypeName LIMIT 1].Id;
            objPartnerRequest.RecordTypeId = recordType;
            insert objPartnerRequest;
            
            PartnerRequestsSelector partnerSelector = new PartnerRequestsSelector();
            List<Partner_Request__c> lstPartnerRequest = partnerSelector.selectInstructorLedTrainingCourses(objPartnerRequest.Id);
            System.debug('lst of results:'+lstPartnerRequest);
                       
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> lstToList = new List<String>();
            List<String> lstCCList = new List<String>();
            
            //getting emailContent from Custom Lable : InstructorLedTrainingRequestEmailBody
            String strEmailContent = System.Label.InstructorLedTrainingRequestEmailBody;
            strEmailContent = strEmailContent.replace('$$UserName$$', UserInfo.getFirstName()+' '+UserInfo.getLastName());
            strEmailContent = strEmailContent.replace('$$UserLink$$', URL.getSalesforceBaseUrl().toExternalForm() + '/DCPCI/s/partner-request/' + objPartnerRequest.Id);
            strEmailContent = strEmailContent.replace('$$courseJustification$$', lstPartnerRequest.get(0).Course_Justification__c);
            strEmailContent = strEmailContent.replace('$$timeline$$', lstPartnerRequest.get(0).Timeframe_for_Attendance__c);
            strEmailContent = strEmailContent.replace('$$requestedCourses$$', lstPartnerRequest.get(0).Requested_Courses__c);
            
            //getting emailSubject from Custom Label : InstructorLedTrainingRequestEmailSubject
            String strEmailSubject = System.Label.InstructorLedTrainingRequestEmailSubject;
            strEmailSubject = strEmailSubject.replace('$$UserName$$',UserInfo.getFirstName()+' '+UserInfo.getLastName());
            
            //getting emailList from Apex Custom Settings
            cs_Instructor_Training_Email_Settings__c emailList = cs_Instructor_Training_Email_Settings__c.getValues(strUserRegion);
            lstToList = emailList.To_Email_Address__c.split(';');
            lstCCList = emailList.CC_Email_Address__c.split(';');
                       
            email.setToAddresses(lstToList);
            email.setCcAddresses(lstCCList);
                     
            email.setSubject(strEmailSubject);
            email.setHtmlBody(strEmailContent);
            
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            
        }catch(Exception e){
            System.debug('Error Message=>'+e.getMessage());
            strErrorMsg = 'Error occured during Insertion in Instructor Led Training Request Object';   
        }
        return strErrorMsg;
    }   
	
    /*
    * description - getListViewId method
    */
    @AuraEnabled
    public static String getListViewId(String strObjectType, String strListViewName) {
        String strListViewId =
            [SELECT Id, Name FROM ListView WHERE SobjectType = :strObjectType AND Name = :strListViewName LIMIT 1].Id;

        return strListViewId;
    }
}