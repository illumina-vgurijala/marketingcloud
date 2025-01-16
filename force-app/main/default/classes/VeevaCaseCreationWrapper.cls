
/***************************************************************************************************************************************
* NAME         : VeevaCaseCreationWrapper
* DESCRIPTION  : DCP-51201 : Wrapper class for Veeva Case Creation request
*                
*                    
* @AUTHOR      : Sagar Madkaikar
* @DATE        : 29-Aug-2022  
* @testclasses : TestVeevaCreateCaseDataSender
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* Sagar Madkaikar       29-Aug-2022         DCP-51201: Initial Version
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/

public class VeevaCaseCreationWrapper {
    
	
        public ContactDetails ContactDetail;
        public String CaseId;
        public String AccountName;
        public String Region;
        public String Subject;
        public String Description;
        public String ProductName;
        public String CaseNumber;
        public List<Email> Emails;
    

    public class ContactDetails{
        public String ContactFirstName;
        public String ContactLastName;
        public String ContactPhone;
        public String ContactEmail;
        public String Webmail;
    }

    public class Email{
        public String EmailBody;
    }
}
