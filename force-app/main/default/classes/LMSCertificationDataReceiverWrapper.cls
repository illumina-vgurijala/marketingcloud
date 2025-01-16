/***************************************************************************************************************************************
* NAME         : LMSCertificationDataReceiverWrapper
* DESCRIPTION  : DCP-42718 - LMS-DCP Course Completion Data Sync
* @AUTHOR      : Vaibhav
* @DATE        : 11-Mar-2021  
* 
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
                                     
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public class LMSCertificationDataReceiverWrapper {

    public MetaData MetaData;
    public Content Content;

    /*
    * @Description: Metadata wrapper.
    */
    public class MetaData {
        public String EventCreatedDate;
    }

    /*
    * @Description: Content wrapper.
    */
    public class Content {
        public String Certification_Progress_Action_Date;
        public String Certification_Assignment_Created_On;
        public String Certification_Assignment_Updated_On;
        public String Person_Full_Name;
        public String Student_Certification_Status;
        public String Certification_Name;
        public String Certification_Version;
        public String Certification_ID;
        public String Student_Certification_Assigned_On;
        public String Student_Certification_Acquired_On;
        public String Student_Certification_Due_Date;
        public String Student_Certification_Expiration_Date;
        public String Person_Username;
        public String Person_Person_No;
        public String Person_SAM_Account;
        public String Person_Email;
        public String Person_Employee_Type;
        public String Person_Domain;
    }

    /*
    * @Description: method to parse incoming json.
    */
    public static LMSCertificationDataReceiverWrapper parse(String json) {
        return (LMSCertificationDataReceiverWrapper) System.JSON.deserialize(json, LMSCertificationDataReceiverWrapper.class);
    }

    

}