/***************************************************************************************************************************************
* NAME         : ilib_LogQuery
* DESCRIPTION  : 
* @AUTHOR      : Todd
* @DATE        : 
*  
* MODIFICATION LOG:  
* --------------------------------------------------------------------------------------------------------------------------------------
* DEVELOPER                DATE                DESCRIPTION 
* KD                    25-June-2021           DCP-46257 : added new constructor for code scan issue in Selector classes
* Anshaj                11-April-2022          CMSI-2  : added try catch functionality and isOn() check to see if framework is on/off
* Suraj                 05-May-2022            CMSI-9 : To publish query logs only if log Level is set to debug or fine
* --------------------------------------------------------------------------------------------------------------------------------------

****************************************************************************************************************************************/
public with sharing class ilib_LogQuery {

    private Data data;
   
    //DCP-46257
    
    /**
     * @author Illumina
     * @description Constructor
     */
    public ilib_LogQuery(){}

    /**
     * @author Illumina
     * @description Constructor
     */
    public ilib_LogQuery(String queryMethod)
    {
        //CMSI-2 added try catch functionality and isOn() check to see if framework is on/off
        try
        {
            //CMSI-9 To publish query logs only if log Level is set to debug or fine
           
            if(!ilib_LogEvent.isOn())return;
            data = new Data(queryMethod);
            data.start();
        }
        catch(Exception ex){system.debug('Exception: '+ ex);}
        
    }

    /**
     * @author Illumina
     * @description Constructor
     */
    
    public ilib_LogQuery(String queryMethod, String parameters)
    {
      //CMSI-2 added try catch functionality and isOn() check to see if framework is on/off  
      try
      {
        //CMSI-9 To publish query logs only if log Level is set to debug or fine
        
        if(!ilib_LogEvent.isOn() )return;
            data = new Data(queryMethod, parameters);
            data.start();
       }
        catch(Exception ex){system.debug('Exception :'+ ex);}
    }

    /**
     * @author Illumina
     * @description
     */
    public void stop()
    {
        //CMSI-2 added try catch functionality and isOn() check to see if framework is on/off
        try
        {
        //CMSI-9 To publish query logs only if log Level is set to debug or fine
        if(!ilib_LogEvent.isOn())return;
            data.stop();
            ilib_LogEvent.message(data);
        }
         catch(Exception ex){system.debug('Exception'+ ex);}
    }

    /**
     * @author Illumina
     * @description
     */
    public void stop(Integer rowCount)
    {
        //CMSI-2 added try catch functionality and isOn() check to see if framework is on/off
        try
        {
        //CMSI-9 To publish query logs only if log Level is set to debug or fine
        
        if(!ilib_LogEvent.isOn() )return;
            data.stop(rowCount);
            ilib_LogEvent.message(data);
        }
         
        catch(Exception ex){system.debug('Exception'+ ex);}
    }

    /**
     * @author Illumina
     * @description
     */
    public class Data {
        private final Integer EXECUTION_TIME_UNDEFINED = -1;
        private final Integer ROW_COUNT_UNDEFINED = -1;
    
        private DateTime startTime = DateTime.newInstance(2000, 1, 1);
        private DateTime endTime = DateTime.newInstance(2000, 1, 1);
        private Long executionTime = EXECUTION_TIME_UNDEFINED;

        private String queryMethod;
        private String parameters;
        private Integer rowCount;

        private Boolean safeToCalculate = false;

        /**
     * @author Illumina
     * @description
     */

        public Data(String queryMethod)
        {
            this.queryMethod = queryMethod;
        }

        /**
     * @author Illumina
     * @description
     */

        public Data(String queryMethod, String parameters)
        {
            this.queryMethod = queryMethod;
            this.parameters = parameters;
        }

        /**
     * @author Illumina
     * @description
     */

        public void start()
        {
            this.startTime = DateTime.now();
            safeToCalculate = true;
        }

        /**
     * @author Illumina
     * @description
     */
        

        public void stop()
        {
            stop(ROW_COUNT_UNDEFINED);
        }

        /**
     * @author Illumina
     * @description
     */

        public void stop(Integer rowCount)
        {
            this.endTime = DateTime.now();
            this.rowCount = rowCount;

            if (safeToCalculate)
            {
                this.executionTime = endTime.getTime() - startTime.getTime();
            }   
        }

        /**
     * @author Illumina
     * @description
     */

        public DateTime getTimestamp()
        {
            return this.endTime;
        }

        /**
     * @author Illumina
     * @description
     */

        public DateTime getStartTime()
        {
            return startTime;
        }

        /**
     * @author Illumina
     * @description
     */

        public DateTime getEndTime()
        {
            return endTime;
        }

        /**
     * @author Illumina
     * @description
     */

        public Long getExecutionTime()
        {
            return executionTime;
        }

        /**
     * @author Illumina
     * @description
     */

        public String getName()
        {
            return queryMethod;
        }

        /**
     * @author Illumina
     * @description
     */

        public Integer getRowCount()
        {
            return rowCount;
        }

        /**
     * @author Illumina
     * @description
     */

        public String flushToText()
        {
            String res = queryMethod;

            if (String.isNotBlank(parameters))
            {
                res += '(' + parameters + ')';
            }

            if (safeToCalculate)
            {
                res += ' ' + executionTime + 'ms';
            }

            if (rowCount != ROW_COUNT_UNDEFINED)
            {
                res += ', ' + rowCount + ' ' + (rowCount == 1 ? 'row' : 'rows');
            }

            return res;
        }
    }
}