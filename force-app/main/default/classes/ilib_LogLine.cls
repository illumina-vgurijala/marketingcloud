/**
*    @author Pranay   
*    @date          
*    @description   Class for Logline CMSI-11
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*  
*/

public with sharing class ilib_LogLine {
    
    public String message;
    public DateTime timeStamp;

    /**
     * @author
     * @description Constructor for base class
     */
    public ilib_LogLine(String message)
    {
        this.message = message;
        this.timeStamp = Datetime.now();
    }

}
