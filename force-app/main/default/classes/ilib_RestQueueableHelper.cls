public class ilib_RestQueueableHelper implements Queueable {

    public ilib_RestReceiver objRestReceiver;

    // constructor requires rest receiver implementation which is used in execute()
    public ilib_RestQueueableHelper(ilib_RestReceiver objRestReceiver)
    {
        this.objRestReceiver = objRestReceiver;
    }

    // finish the transaction using the passed-in rest receiver
    public void execute(QueueableContext context)
    {
        ilib_LogEvent.rootTitle = objRestReceiver.interfaceDetails.name;
        ilib_LogEvent.push('queueable execute');

        objRestReceiver.finishTransaction();

        ilib_LogEvent.pop();
        ilib_LogEvent.emit();
    }

}