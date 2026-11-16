// Test-only values, set before the app loads. dotenv does not override them.
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = process.env.JWT_SECRET || 'test-secret-only-for-jest-0123456789abcdef';
process.env.MAIL_MODE = 'test';
