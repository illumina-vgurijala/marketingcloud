/**
*    @author Pranay   
*    @date          
*    @description   Class for Logscope CMSI-11
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*  
*/
public with sharing class ilib_Logscope {

    private static final Integer INDENT_SIZE = 2;
    private static final String LOG_TOOL_NAME = 'ILMN PS LOG';
    private static final String DEFAULT_SCOPE_NAME = 'NO TITLE GIVEN';

    public ilib_Logscope parent;
    public String scope;
    public ilib_Limitz limitz;
    public DateTime timeStamp = Datetime.now();
    public List<Object> logEntries = new List<Object>();

    /**
     * @author
     * @description
     * @param List<String> logLines, Integer indent
     */
    public void flush(List<String> logLines, Integer indent)
    {
        for (Object logEntry : logEntries)
        {
            String spacePrefix = ''.rightPad(INDENT_SIZE * (indent - 1));
            if (logEntry instanceof ilib_Logscope)
            {
                ilib_Logscope logScope = (ilib_Logscope)logEntry;
                String formattedLimits = logScope.limitz.formattedForDebugLog();
                logLines.add(formatTimestamp(timeStamp) + spacePrefix + indent + ':' + logScope.scope + ' ' + formattedLimits);
                logScope.flush(logLines, indent + 1);
            }
            else if (logEntry instanceof ilib_LogQuery.Data)
            {
                ilib_LogQuery.Data queryData = (ilib_LogQuery.Data)logEntry;
                logLines.add(formatTimestamp(queryData.getTimestamp()) + spacePrefix + indent + ':' + queryData.flushToText());
            }
            else // instanceof LogLine
            {
                ilib_LogLine logLine = (ilib_LogLine)logEntry;
                logLines.add(formatTimestamp(logLine.timeStamp) + spacePrefix + indent + ':' + logLine.message);
            }
        }
    }
    
    /**
     * @author
     * @description
     * @param ilib_LogScope flushRoot
     */
    public static String flush(ilib_LogScope flushRoot)
    {
        List<String> logLines = new List<String>();
        logLines.add(LOG_TOOL_NAME);
        logLines.add('');

        if (flushRoot != null)
        {
            // if the user never set a title we have to watch out for some nulls
            Boolean hasScopeName = String.isNotBlank(flushRoot.scope) && flushRoot.limitz != null;
            String scopeName = hasScopeName ? flushRoot.scope : DEFAULT_SCOPE_NAME;
            String formattedTimestamp = hasScopeName ? formatTimestamp(flushRoot.limitz.startTimeStamp) : '';

            logLines.add(formattedTimestamp + scopeName);
            flushRoot.flush(logLines, 1);
            if (hasScopeName)
            {
                flushRoot.limitz.setEndTime(Datetime.now());
                logLines.add(formatTimestamp(flushRoot.limitz.endTimeStamp) + 'END ' + LOG_TOOL_NAME);
            }
            logLines.add('');
        }

        return String.join(logLines, '\n');
    }

    private static String formatTimestamp(Datetime timeStamp)
    {
        return '[' + timeStamp.time() + '] ';
    }
}
