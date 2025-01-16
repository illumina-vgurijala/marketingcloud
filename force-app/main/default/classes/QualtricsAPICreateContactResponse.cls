/**
 *    @author Vaibhav
 *    @date   2 May 2021
 *    @description   DCP-46141 - QualtricsAPICreateContactResponse
 *    Modification Log:
 *    ------------------------------------------------------------------------------------
 *    Developer                         Date                     Description
 *    Vaibhav                       2 May 2021              Initial Version - DCP-46141 : Qualtrics Integration.
 * ---------------------------------------------------------------------------------------
 */
public class QualtricsAPICreateContactResponse {
/**
  * @description - This method is used to declare variables
  */
    public class Meta {
        public String httpStatus;
        public String requestId;
    }

    public Result result;
    public Meta meta;
/**
  * @description - This method is used to declare variable
  */
    public class Result {
        public String id;
    }

    /** @DESCRIPTION - prase json response **/
    public static QualtricsAPICreateContactResponse parse(String json) {
        return (QualtricsAPICreateContactResponse) System.JSON.deserialize(json, QualtricsAPICreateContactResponse.class);
    }
}