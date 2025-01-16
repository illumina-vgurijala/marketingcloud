import { LightningElement, track, api, wire } from 'lwc';
export default class CustomDatatable extends LightningElement {
    @api column;
    @api recordlist;
    @track sortBy;
    @track sortDirection;
    @track loadMoreStatus;
    @api infinityload;
    @track isLoading;


    handleRowAction(event){
        const actionName = event.detail.action.name;
        console.log('action name-->' + actionName);
        const TaskRow = event.detail.row;
        console.log('Task detail clicked--> ' + TaskRow.recordid);
        switch (actionName){
            case 'Edit Task':
                // Creates the event with the contact ID data.
                    const selectedEvent = new CustomEvent('editclick',
                    {
                        detail: event.detail.row
                    });

                    // Dispatches the event.
                    this.dispatchEvent(selectedEvent);
                    break;
            case 'Delete Task':
                    const selectedEvents = new CustomEvent('deleteclick',
                    {
                        detail: event.detail.row
                    });

                    // Dispatches the event.
                    this.dispatchEvent(selectedEvents);
                    break;
        }
    }
    // Sorting method
    handleSortdataDetail(event) {
        // field name
        this.sortBy = event.detail.fieldName;
        console.log('Sorting details ->'+JSON.stringify(event.detail));

        // sort direction 
        this.sortDirection = event.detail.sortDirection;

        // calling sortdata function to sort the data based on direction and selected field
        this.recordlist = this.sortData(this.recordlist,event.detail.fieldName, event.detail.sortDirection);
    }
    sortData(datalist,fieldname, direction) {
        // serialize the data before calling sort function
        let parseData = JSON.parse(JSON.stringify(datalist));

        // Return the value stored in the field
        let keyValue = (a) => {
            return a[fieldname];
        };

        // cheking reverse direction 
        let isReverse = direction === 'asc' ? 1: -1;

        // sorting data 
        parseData.sort((x, y) => {
            x = keyValue(x) ? keyValue(x) : ''; // handling null values
            y = keyValue(y) ? keyValue(y) : '';

            // sorting values based on direction
            return isReverse * ((x > y) - (y > x));
        });

        // set the sorted data to data table data
        return parseData;

    }

}