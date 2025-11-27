import { LightningElement, track } from 'lwc';
import getIntakesByAccount from '@salesforce/apex/BMA_ApexPageController.getIntakesByAccount';

export default class AccountIntakeViewer extends LightningElement {
    intakes;
    error;
    @track selectedIntakeId;
    showSecondComponent = false;
    columns = [
        { label: 'Name', fieldName: 'Name', type: 'text' },
        { label: 'Cloud', fieldName: 'Cloud__c', type: 'text' },
        { label: 'Starter Type', fieldName: 'Starter_Type__c', type: 'text' }
    ];

    handleAccountChange(event) {
        const accountId = event.detail.recordId; 
        if (accountId) {
            getIntakesByAccount({ accountId })
                .then(result => {
                    this.intakes = result;
                    this.error = undefined;
                })
                .catch(error => {
                    this.error = error.body ? error.body.message : error.message;
                    this.intakes = undefined;
                });
        } else {
            this.intakes = undefined;
            this.error = 'Please select an account.';
        }
    }

    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;
        this.selectedIntakeId = selectedRows.length ? selectedRows[0].Id : undefined;
        console.log('selectedIntakeId',this.selectedIntakeId);
    }

    handleNext(){
        if (this.selectedIntakeId) {
            this.showSecondComponent = true; // Show the second component
        } else {
            alert('Please select an intake first.');
        }
    }
}