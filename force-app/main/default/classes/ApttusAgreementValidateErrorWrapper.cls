/*
 * @Author: Kushagra Desai
 * @Date: 9-Jan-2020
 * @Description : Wrapper is used to deserialize the json and map the values to Agreeement Error object
*/
public with sharing class ApttusAgreementValidateErrorWrapper {
    /*
    * @Author: Kushagra Desai
    * @Description : Wrapper used to deserialize the following attributes that are mapped to Agreeement Error object
    */
    public class ValidateErrorWrapper{
		
		 /**  
        * @description : ValidateErrorWrapper default constuctor.
        */
        public ValidateErrorWrapper() { }//Added for Test Class Coverage.
		
        public ResultList EX_ReturnSet;
        public String AgreementNum;
        public String Status; 
    }
    /*
    * @Author: Kushagra Desai
    * @Description : Wrapper used to deserialize the following attributes that are mapped to Agreeement Error object
    */
    public class ResultList{
        public List<ReturnSet> results;
    }
    /*
    * @Author: Kushagra Desai
    * @Description : Wrapper used to deserialize the following attributes that are mapped to Agreeement Error object
    */
    public class ReturnSet{
        public String Type;
        public String MsgId;
        public String MsgNumber;
        public String Message;
        public String LineItemId;
    }
}