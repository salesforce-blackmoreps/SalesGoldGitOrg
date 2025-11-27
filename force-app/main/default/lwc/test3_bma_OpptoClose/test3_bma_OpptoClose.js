import { LightningElement,api } from 'lwc';
import myLogo from '@salesforce/resourceUrl/myLogo';
import { getRecord } from 'lightning/uiRecordApi';
import getSections from '@salesforce/apex/BMA_AccelerateController.getSections';
import getSecttionDetail from '@salesforce/apex/BMA_AccelerateController.getSecttionDetail';

export default class Bma_OpptoClose extends LightningElement {
    recordId = 'a0sO1000003jmjVIAQ';
    // menuItems = [
    //     'Getting Started',
    //     'Company Info',
    //     'Users / Roles',
    //     'Lead Setup',
    //     'Account Setup',
    //     'Contact Setup',
    //     'Opportunity Setup',
    //     'Automation',
    //     'Reports / Dashboards',
    //     'Future Needs',
    //     'Finish / Schedule Call'
    // ];

    @api projectId;

    sections = [];
    completedSections = [];
    imageURL = myLogo;
    responses = [];
    currentSection = '';
    currentScreen = '';
    currentSectionScreenCount = 1;
    currentSectionOnScreen    = 1;
    sectionId = '';

    connectedCallback(){
        //this.projectId = '';
        //console.log(this.recordId);
        this.loadComponentData();
    } 

    loadComponentData(){
        getSections({ intakeId: this.recordId })
        .then(result => {
            this.sections = result.sections;
            console.log('this.sections',this.sections);

            this.sections.forEach(section => {
                this.totalScreenCount += section.screenCount;
            })

            this.sectionId = this.sections[0].Id;
            this.currentSection = this.sections[0].Id;
            this.currentSectionScreenCount = this.sections[0].screenCount;
            this.currentSectionOnScreen = 1;
            this.currentScreen = '1';
            this.resetSelectedSection();
            Promise.resolve().then(() => {
                const FirstButton = this.template.querySelector(`button[data-id="${this.sectionId}"]`);
                if (FirstButton) {
                FirstButton.classList.add('sidebar-button-selected');
                }
            });
            this.loadSectionByScreen();
        })
        .catch(error => {
            console.error('Error fetching data', error);            
        });
    }

    sectionClick(event){
        const sectionId = event.target.dataset.id; 
        const currenentSectionDetail = this.sections.find(item => item.Id === sectionId);
        console.log('currenentSectionDetail : ',currenentSectionDetail);
        this.sectionId = sectionId;
        this.currentSectionScreenCount = currenentSectionDetail.screenCount;

        this.currentSection = sectionId;
        //const savedScreen = this.sectionState[sectionId]?.screen || 1;
        this.currentSectionOnScreen = 1;
        this.currentScreen = this.currentSectionOnScreen.toString();

        this.loadSectionByScreen();
        this.resetSelectedSection();
        event.target.classList.add('sidebar-button-selected');
    }

    loadSectionByScreen(){
        getSecttionDetail({ sectionId: this.sectionId, intakeId: this.recordId,screen: this.currentScreen})
        .then(result => {
            this.responses = result
            .map(section => {
                const answerType = section.answerType?.toLowerCase(); 
                return {
                    ...section,
                    IsRadio: answerType === 'picklist',
                    IsCheckbox: answerType === 'multi-select',
                    IsText: answerType === 'text',
                    IsRichText: answerType === 'richtext',
                    IsEmbedded: answerType === 'embedded' 
                };
            });
            console.log('this.responses',this.responses);  
            console.log('result',result);
            console.log('resulttype',typeof(result));                         
        })
        .catch(error => {
            console.error('Error fetching data', error);            
        });
    }

    handleSaveAndNext(){
        if(this.currentSectionScreenCount > this.currentSectionOnScreen) {
            this.currentSectionOnScreen += 1;
            this.totalScreenCompleteCount += 1;
            console.log("currentSectionOnScreen" , this.currentSectionOnScreen);
            this.currentScreen = this.currentSectionOnScreen.toString();
            //this.sectionState[this.currentSection] = {screen: this.currentSectionOnScreen};
            this.loadSectionByScreen();
        }
        else {
            //this.sectionProgressBar = '0.00%';
            const currentSectionIndex = this.sections.findIndex(sec => sec.Id === this.currentSection);
            const nextSection = this.sections[currentSectionIndex + 1];

            if (nextSection) {
                this.totalScreenCompleteCount += 1;
                this.completedSections.push(this.sectionId);
                this.grayCompletedSections(this.completedSections); 

                this.currentSection = nextSection.Id;
                this.sectionId = nextSection.Id;
                this.currentSectionScreenCount = nextSection.screenCount;

                //const savedScreen = this.sectionState[nextSection.Id]?.screen || 1;
                this.currentSectionOnScreen = 1;
                this.currentScreen = this.currentSectionOnScreen.toString();

                this.resetSelectedSection();

                const nextButton = this.template.querySelector(`button[data-id="${nextSection.Id}"]`);
                if (nextButton) {
                    nextButton.classList.add('sidebar-button-selected');
                }
                this.loadSectionByScreen();
            } else {
                this.totalScreenCompleteCount += 1;
                this.completedSections.push(this.sectionId);
                this.grayCompletedSections(this.completedSections);
                this.resetSelectedSection();
            }   
        }
        
    }

    resetSelectedSection() {
        const allButtons = this.template.querySelectorAll('.sidebar-button-selected');
    
        allButtons.forEach(button => {       
                button.classList.remove('sidebar-button-selected');
        });
    }

    grayCompletedSections(completedSections){
        this.completedSections.forEach(section => {
            const sectionComplete = this.template.querySelector(`button[data-id="${section}"]`);
            sectionComplete.classList.add('sidebar-btn-completed');
        })
    }
}