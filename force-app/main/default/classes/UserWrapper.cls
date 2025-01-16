/**
*    @author K Joshith
*    @date   
*    @description Wrapper used to deserialize the following attributes that are mapped to User object
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*             K Joshith                                         Initial Version
*             Himanshu                       31-03-2022         Code Scan Fixes
*    --------------------------------------------------------------------------------------------------------------------------------------------------
*                    
**/
public class UserWrapper {
    /**
    *    @author K Joshith  
    *    @description Wrapper that has attributes that are mapped to user object fields
    */
    public class UserFieldUpdates {
        public String PREFERRED_FIRST_NAME;
        public String PREFERRED_LAST_NAME;
        public String EMAIL;
        public String JOB_TITLE;
        public String DEPARTMENT_NAME;
        public String COSTCENTER_NAME;
        public String EMP_ID;
        public String MANAGER_OID;
        public String MANAGER_EMAIL;
        public String EMPLOYEEIDORIGINAL;
        public String COUNTRY;
        public String REGION;
        public String SUB_REGION;
        public String MANAGER;
        public String DESK_COUNTRY_CODE;
        public String DESK_AREA_CODE;
        public String DESK_PHONE_ONLY;
        public String WD_USER_NAME;
        public String COSTCENTER_NUMBER;
        public String FUNCTIONAL_AREA;
        public String Id;
        public String UNIQUE_ID;//TASK0573387
    }

    public List<UserFieldUpdates> Table;
    /**
    *    @author K Joshith  
    *    @description method to deserailze json
    *    @params String Json
    *    @return deserialized json
    */
    public static UserWrapper parse(String json) {
        return (UserWrapper) System.JSON.deserialize(json, UserWrapper.class);
    }
}