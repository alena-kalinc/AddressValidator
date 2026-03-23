// force-app/test/jest-mocks/lightning/refresh.js
export class RefreshEvent extends CustomEvent {
    constructor() {
        super('lightning__refresh');
    }
}