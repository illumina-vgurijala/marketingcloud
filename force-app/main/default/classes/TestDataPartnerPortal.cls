/*@ author       : Prakhar Kumar
* @ date         : 26-09-2018
* @ Description  : Central class for creation of Test data for Partner community
*
* Modification Log:
* --------------------------------------------------------------------------------------------------------------------------------------
* Developer                Date                   Modification ID      Description
* ---------------------------------------------------------------------------------------------------------------------------------------
* Prakhar Kumar          17-08-2018                 US-4252             Initial version
* Prakhar Kumar          26-09-2019                 DCP-30062           SonarQube Fixes
* Saurav Bhanadri        06-03-2020                 DCP-32168           Added method getNewReagentRentalPartnerRequestforNewAccount
//SonarQube Fixes 10/12/2019		
*/

@isTest(seeAllData=false)
public with sharing class TestDataPartnerPortal{
    /*method to fetch Contact details*/
    public static List<Contact> getContactList(Integer intRecCount){
        List<Contact> lstContacts = new List<Contact>();
        for(Integer i=0; i< intRecCount; i++){
            Contact contact = new Contact();
            contact.FirstName = 'Test FirstName'+i;
            contact.LastName = 'Test LastName'+i;
            contact.Title = 'Test Title'+i;
            contact.Email = 'Test Email'+i;
            contact.Partner_Portal_Status__c = 'Active';
            lstContacts.add(contact);
        }
        return lstContacts;
    }
    /*method to fetch user details*/	
    public static List<User> getUserList(){
        List<User> lstUsers = new List<User>();
        User user1 = new User();
        user1.FirstName = 'Test FirstName';
        user1.LastName='Test LastName';
        user1.Email = 'test1@gmail.com';
        user1.Phone = '9999977777';
        user1.City = 'Test City';
        user1.Username = 'xxyzakh@gmail.com';
        user1.Alias = 'Test';
        user1.CommunityNickname = 'Test CommunityNickName';
        user1.TimeZoneSidKey = 'Asia/Colombo';
        user1.LocaleSidKey = 'en_US';
        user1.EmailEncodingKey = 'ISO-8859-1';
        Profile prId = [SELECT Id FROM Profile WHERE Name='system administrator' LIMIT 1];
        user1.ProfileId = prId.Id;
        user1.PortalRole = 'Operations_Manager';
        user1.LanguageLocaleKey= 'en_US';
        lstUsers.add(user1);
        return lstUsers;
    }
    /*method created to get sample data for Partner Request object*/
    public static List<Partner_Request__c> getNewPartnerRequest(Integer intRecCount){
        List<Partner_Request__c> lstPartnerRequest = new List<Partner_Request__c>();
        for(Integer i=0; i< intRecCount; i++){
            Partner_Request__c newObj = new Partner_Request__c();
            newObj.First_Name__c = 'Test FirstName'+i;
            newObj.Last_Name__c = 'Test LastName'+i;
            newObj.Status__c='Pending';
            
            lstPartnerRequest .add(newObj);
        }
        return lstPartnerRequest ;
    }
    
    
     /*method created to get sample data for Partner Request object*/
    public static List<Partner_Request__c> getNewPartnerRequestforNewAccount(Integer intRecCount){
        List<Partner_Request__c> lstPartnerRequest = new List<Partner_Request__c>();
        Id recordTypeIdPartnerReq = Schema.SObjectType.Partner_Request__c.getRecordTypeInfosByName().get('New Account Request').getRecordTypeId();
        for(Integer i=0; i< intRecCount; i++){
            Partner_Request__c newObj = new Partner_Request__c();
            newObj.First_Name__c = 'Test FirstName'+i;
            newObj.Last_Name__c = 'Test LastName'+i;
            newObj.Status__c='Pending';
            newObj.recordtypeid=recordTypeIdPartnerReq ;
            
            lstPartnerRequest .add(newObj);
        }
        return lstPartnerRequest ;
    }
	
	/*method created to get sample data for Reagent Rental Partner Request object*/
    public static Partner_Request__c getNewReagentRentalPartnerRequestforNewAccount(Integer intRecCount){
        Id recordTypeIdPartnerReq = Schema.SObjectType.Partner_Request__c.getRecordTypeInfosByName().get('Reagent Rental Request').getRecordTypeId();
        Partner_Request__c newObj = new Partner_Request__c();
        for(Integer i=0; i< intRecCount; i++){
            
            newObj.First_Name__c = 'Test FirstName'+i;
            newObj.Last_Name__c = 'Test LastName'+i;
            newObj.Status__c='Pending';
            newObj.Term_Length__c = '12 Months';
            newObj.Estimated_Instrument_Purchase_Date__c = System.today();
            newObj.Instrument_Requested__c = 'MiniSeq';
            newObj.Market_Segment__c = 'Agrigenomics';
            newObj.Number_of_Samples_Per_Year_Committed__c = 7;
            newObj.Strategy__c = 'Test Comments';
            newObj.Other_Comments__c = 'Test Comments';
            newObj.recordtypeid=recordTypeIdPartnerReq ;
            
        }
        return newObj ;
    }
    
    
    /*method created to get sample data for Partner Request object for Instructor Led Training*/
    public static List<Partner_Request__c> getNewPartnerRequestForInstructorLedTraining(Integer intRecCount){
        List<Partner_Request__c> lstPartnerRequest = new List<Partner_Request__c>();
        for(Integer i=0; i< intRecCount; i++){
            Partner_Request__c newObj = new Partner_Request__c();
            newObj.Requested_Courses__c = 'Course'+i;
            newObj.Timeframe_for_Attendance__c = 'Timeframe'+i;
            newObj.Course_Justification__c = 'Course Justification'+i;
            lstPartnerRequest.add(newObj);
        }
        return lstPartnerRequest ;
    }
    /*method created to fetch Instructor training catalog list.*/
    public static List<Instructor_Training_Catalog__c> getTrainingCatalogList(Integer intRecCount){
        List<Instructor_Training_Catalog__c> lstTrainingList = new List<Instructor_Training_Catalog__c>();
        for(Integer i=0; i< intRecCount; i++){
            Instructor_Training_Catalog__c newObj = new Instructor_Training_Catalog__c();
            newObj.Certification__c = 'Test Certification'+i;
            lstTrainingList .add(newObj);
        }
        return lstTrainingList ;
    }
    
    /*method for creating Slide object data*/
     public static List<Partner_Portal_Content__c> getNewSlides(integer intRecCount)
    {
        List <Partner_Portal_Content__c> lstCarousel=new List <Partner_Portal_Content__c>();
        for(integer i=0; i< intRecCount; i++)
        {
            Partner_Portal_Content__c newObj=new Partner_Portal_Content__c();
            Id recordTypeIdSlides = Schema.SObjectType.Partner_Portal_Content__c.getRecordTypeInfosByName().get('Slides').getRecordTypeId();
            newObj.recordtypeId=recordTypeIdSlides;
            newObj.Region__c='AMR';
            newObj.Active__c=true;
            newObj.Slide_Name__c='Slide'+i;
            newObj.Slide_Title__c='Banner'+i;
            newObj.Slide_Subtitle__c='Lorem ipsum dolor sit amet';
            newObj.Image_URL__c='www.google.com';
            newObj.Button_Text__c='Activate Now>';
            lstCarousel.add(newObj);
            
        }
        insert lstCarousel;   
        return lstCarousel;
        
    } 
 
}