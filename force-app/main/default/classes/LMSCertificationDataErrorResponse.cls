/*
 * @Author:Vaibhav
 * @Date:11 Mar 2021
 * @Description: DCP-42718 - LMS-DCP Course Completion Data Sync
 */ 
public class LMSCertificationDataErrorResponse {
 
 /*
 * @Description: Blank constructor to cover test class coverage.
 */ 
    public LMSCertificationDataErrorResponse(){}

    /*
 * @Description: Error detail wrapper.
 */ 
    public class ErrorDetail {
        public String code;
        public String message;
    }

    public String result;
    public ErrorDetail errorDetail;


}