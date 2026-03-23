const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');

module.exports = {
    ...jestConfig,
    modulePathIgnorePatterns: ['<rootDir>/.localdevserver'],
    moduleNameMapper: {
        '^lightning/refresh$': '<rootDir>/force-app/test/jest-mocks/lightning/refresh',
        ...jestConfig.moduleNameMapper
    }
};
