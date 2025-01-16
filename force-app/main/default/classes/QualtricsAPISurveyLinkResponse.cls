/**
 *    @author Vaibhav
 *    @date   2 May 2021
 *    @description   DCP-46141 - QualtricsAPISurveyLinkResponse
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *    Developer                         Date                     Description
 *    Vaibhav                       2 May 2021              Initial Version - DCP-46141 : Qualtrics Integration.
 * ---------------------------------------------------------------------------------------
 */
public class QualtricsAPISurveyLinkResponse {
/*
 *    @author Vaibhav
 *    @date   2 May 2021
 */
    public class Meta {
        public String httpStatus;
        public String requestId;
    }

    public Result result;
    public Meta meta;
/*
 *    @author Vaibhav
 *    @date   2 May 2021
 */
    public class Elements {
        public String contactId;
        public String transactionId;
        public String link;
        public String exceededContactFrequency;
        public String linkExpiration;
        public String status;
        public String lastName;
        public String firstName;
        public String externalDataReference;
        public String email;
        public String unsubscribed;
    }

     /** @DESCRIPTION - result wrapper **/
    public class Result {
        public List<Elements> elements;
        public String nextPage;
    }

     /** @DESCRIPTION - prase json response **/
    public static QualtricsAPISurveyLinkResponse parse(String json) {
        return (QualtricsAPISurveyLinkResponse) System.JSON.deserialize(json, QualtricsAPISurveyLinkResponse.class);
    }
}