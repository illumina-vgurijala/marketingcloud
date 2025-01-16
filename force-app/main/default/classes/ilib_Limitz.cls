/**
*    @author Pranay   
*    @date          
*    @description   Class for Limitz CMSI-11
*    Modification Log:
*    ------------------------------------------------------------------------------------------------------------------------------------------------
*             Developer                      Date                Description
*  
*/

public with sharing class ilib_Limitz {

    public DateTime startTimeStamp = Datetime.now();
    public DateTime endTimeStamp;
    public Long elapsedTime;
    public Integer dml;
    public Integer soql;
    public Integer dmlRows;
    public Integer queryRows;
    public Integer cpu;
    public Integer heap;
    public Integer qJobs;
    public Integer callouts;
    public Integer futureCalls;

    /**
     * @author
     * @description Constructor for base class
     */
    public ilib_Limitz()
    {
        setCurrentValues();
    }

    /**
     * @author
     * @description Constructor for base class
     * @param ilib_Limitz currentLimitz
     */
    public ilib_Limitz(ilib_Limitz currentLimitz)
    {
        this.dml = Limits.getDMLStatements() - currentLimitz.dml;
        this.soql = Limits.getQueries() - currentLimitz.soql;
        this.dmlRows = Limits.getDMLRows() - currentLimitz.dmlRows;
        this.queryRows = Limits.getQueryRows() - currentLimitz.queryRows;
        this.cpu = Limits.getCpuTime() - currentLimitz.cpu;
        this.heap = Limits.getHeapSize() - currentLimitz.heap;
        this.qJobs = Limits.getQueueableJobs() - currentLimitz.qJobs;
        this.callouts = Limits.getCallouts() - currentLimitz.callouts;
        this.futureCalls = Limits.getFutureCalls() - currentLimitz.futureCalls;
    }

    /**
     * @author
     * @description Constructor for base class
     * @param Boolean allZeroValues
     */
    public ilib_Limitz(Boolean allZeroValues)
    {
        if (allZeroValues)
        {
            this.dml = 0;
            this.soql = 0;
            this.dmlRows = 0;
            this.queryRows = 0;
            this.cpu = 0;
            this.heap = 0;
            this.qJobs = 0;
            this.callouts = 0;
            this.futureCalls = 0;
        }
        else
        {
            setCurrentValues();
        }
    }

    /**
     * @author
     * @description Constructor for base class
     * @param ilib_LogQuery.Data q
     */
    public ilib_Limitz(ilib_LogQuery.Data q)
    {
        this.dml = 0;
        this.soql = 1;
        this.dmlRows = 0;
        this.queryRows = q.getRowCount();
        this.cpu = 0;
        this.heap = 0;
        this.qJobs = 0;
        this.callouts = 0;
        this.futureCalls = 0;
        this.startTimeStamp = q.getStartTime();
        this.setEndTime(q.getEndTime());
    }

    /**
     * @author
     * @description Method to set send time
     * @param DateTime endTimeStamp
     */
    public void setEndTime(DateTime endTimeStamp)
    {
        this.endTimeStamp = endTimeStamp;
        elapsedTime = endTimeStamp.getTime() - startTimeStamp.getTime();
    }

    /**
     * @author
     * @description in debug log just show dml and query counts
     */
    public String formattedForDebugLog()
    {
        List<String> limitDiffs = new List<String>();
        if (dml > 0)
            limitDiffs.add('DML ' + dml);
        if (soql > 0)
            limitDiffs.add('SOQL ' + soql);

        return (!limitDiffs.isEmpty()
            ? '(' + String.join(limitDiffs, ',') + ')'
            : '');
    }

    private void setCurrentValues()
    {
        this.dml = Limits.getDMLStatements();
        this.soql = Limits.getQueries();
        this.dmlRows = Limits.getDMLRows();
        this.queryRows = Limits.getQueryRows();
        this.cpu = Limits.getCpuTime();
        this.heap = Limits.getHeapSize();
        this.qJobs = Limits.getQueueableJobs();
        this.callouts = Limits.getCallouts();
        this.futureCalls = Limits.getFutureCalls();
    }
}
