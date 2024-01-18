import { LightningElement, api, track } from 'lwc';
import fetchData from '@salesforce/apex/DashboardComponentController.fetchData';
import filterData from '@salesforce/apex/DashboardComponentController.filterData';

export default class DashboardComponentLWC extends LightningElement {
    @track result;
    @track value;
    @track sortBy;
    @track sortDirection;

    isSpinner = true; 
        connectedCallback(){
            fetchData({
                    }).then( result=>{
                        console.log(JSON.stringify(result));
                        this.linkRecords(result);
                        this.isSpinner = false;
                    }).catch(
                        error => {
                        if(error && error.body && error.body.message) {
                            this.showToast('Error', 'error', error.body.message);
                        }
                    }
                );
        }

        get options() {
            return [
                     { label: 'All Records', value: 'allRecords' },
                     { label: 'My Records', value: 'myRecords' },
                     { label: 'This Year', value: 'thisYear' },
                     { label: 'This Month', value: 'thisMonth' },
                     { label: 'This Week', value: 'thisWeek' },
                     { label: 'Today', value: 'today' },
                   ];
        }
        
        handleChange(event) {
                this.value = event.detail.value;
                this.isSpinner = true;
                filterData({filter: this.value})
                .then( result=>{
                    this.linkRecords(result);
                    this.isSpinner = false;
                }).catch(
                    error => {
                    if(error && error.body && error.body.message) {
                        this.showToast('Error', 'error', error.body.message);
                    }
                }
            );
        }

        doSorting(event) {
            this.sortBy = event.detail.fieldName;
            this.sortDirection = event.detail.sortDirection;
            this.sortData(this.sortBy, this.sortDirection);
        }
    
        sortData(fieldname, direction) {
            let parseData;
            this.result.forEach(element => {
                console.log('element.records'+JSON.stringify(element.records));
                parseData = JSON.parse(JSON.stringify(element.records));
            
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
                element.records = JSON.parse(JSON.stringify(parseData));
            });
            console.log('parseData'+JSON.stringify(parseData));
        }   
    
    linkRecords(result){
        result.forEach(element =>{
            let Id;
            element.records.forEach(item2 =>{
                Id=item2.Id;
                item2.link  = '/' + Id;
            })
        })
        this.result = result;  
    }
}