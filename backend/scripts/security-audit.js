#!/usr/bin/env node
/**
 * Security Audit Script for AgriSmart CI
 * Tests authentication, authorization, and injection vulnerabilities
 */

const axios = require('axios');

const BASE_URL = 'http://localhost:3600/api/v1';
const colors = {
    reset: '\x1b[0m',
    green: '\x1b[32m',
    red: '\x1b[31m',
    yellow: '\x1b[33m',
    blue: '\x1b[34m',
};

// Test results storage
const results = {
    passed: 0,
    failed: 0,
    warnings: 0,
    tests: []
};

/**
 * Utility: Log test result
 */
function logTest(name, passed, message = '') {
    const status = passed ? `${colors.green}✓ PASS${colors.reset}` : `${colors.red}✗ FAIL${colors.reset}`;
    console.log(`  ${status} ${name}`);
    if (message) console.log(`    ${colors.yellow}${message}${colors.reset}`);

    results.tests.push({ name, passed, message });
    if (passed) results.passed++;
    else results.failed++;
}

/**
 * Utility: Log warning
 */
function logWarning(name, message) {
    console.log(`  ${colors.yellow}⚠ WARNING${colors.reset} ${name}`);
    console.log(`    ${message}`);
    results.warnings++;
}

/**
 * Test Suite 1: SQL Injection Testing
 */
async function testSQLInjection() {
    console.log(`\n${colors.blue}═══ SQL Injection Tests ═══${colors.reset}`);

    const injectionPayloads = [
        "' OR '1'='1",
        "'; DROP TABLE users; --",
        "1' UNION SELECT NULL, NULL, NULL--",
        "admin'--",
        "' OR 1=1--"
    ];

    for (const payload of injectionPayloads) {
        try {
            const response = await axios.post(`${BASE_URL}/auth/login`, {
                identifier: payload,
                password: payload
            }, { validateStatus: () => true });

            // Should return 400 or 401, NOT 500 (which could indicate SQL error)
            const safe = response.status !== 500 &&
                !response.data?.message?.toLowerCase().includes('sql') &&
                !response.data?.message?.toLowerCase().includes('syntax');

            logTest(
                `SQL Injection with payload: ${payload.substring(0, 20)}...`,
                safe,
                safe ? 'Properly rejected' : `Potential vulnerability: ${response.status}`
            );
        } catch (error) {
            logTest(`SQL Injection test with ${payload}`, false, error.message);
        }
    }
}

/**
 * Test Suite 2: Authentication Security
 */
async function testAuthentication() {
    console.log(`\n${colors.blue}═══ Authentication Security Tests ═══${colors.reset}`);

    // Test 1: Login with invalid credentials
    try {
        const response = await axios.post(`${BASE_URL}/auth/login`, {
            identifier: 'nonexistent@example.com',
            password: 'wrong_password'
        }, { validateStatus: () => true });

        logTest(
            'Invalid credentials rejected',
            response.status === 401 || response.status === 404 || response.status === 429,
            `Status: ${response.status}`
        );
    } catch (error) {
        logTest('Invalid credentials test', false, error.message);
    }

    // Test 2: Missing authentication header
    try {
        const response = await axios.get(`${BASE_URL}/auth/me`, {
            validateStatus: () => true
        });

        logTest(
            'Protected route requires authentication',
            response.status === 401,
            `Status: ${response.status}`
        );
    } catch (error) {
        logTest('Missing auth header test', false, error.message);
    }

    // Test 3: Invalid JWT token
    try {
        const response = await axios.get(`${BASE_URL}/auth/me`, {
            headers: { Authorization: 'Bearer invalid_token_here' },
            validateStatus: () => true
        });

        logTest(
            'Invalid JWT token rejected',
            response.status === 401,
            `Status: ${response.status}`
        );
    } catch (error) {
        logTest('Invalid JWT test', false, error.message);
    }

    // Test 4: Weak password acceptance
    try {
        const response = await axios.post(`${BASE_URL}/auth/register`, {
            nom: 'Test',
            prenoms: 'User',
            email: `test${Date.now()}@example.com`,
            telephone: `+225${Math.floor(Math.random() * 100000000)}`,
            password: '123'  // Weak password
        }, { validateStatus: () => true });

        logTest(
            'Weak password rejected',
            response.status === 400 || response.status === 422,
            (response.status === 400 || response.status === 422) ? 'Validation working' : 'WARNING: Weak password accepted!'
        );
    } catch (error) {
        logTest('Weak password test', false, error.message);
    }
}

/**
 * Test Suite 3: Authorization & Access Control
 */
async function testAuthorization() {
    console.log(`\n${colors.blue}═══ Authorization Tests ═══${colors.reset}`);

    // For this test, we need a valid token
    // We'll test without token first

    // Test 1: Access user list without admin rights
    try {
        const response = await axios.get(`${BASE_URL}/users`, {
            validateStatus: () => true
        });

        logTest(
            'Admin route requires authentication',
            response.status === 401,
            `Status: ${response.status}`
        );
    } catch (error) {
        logTest('Admin route protection', false, error.message);
    }
}

/**
 * Test Suite 4: Input Validation
 */
async function testInputValidation() {
    console.log(`\n${colors.blue}═══ Input Validation Tests ═══${colors.reset}`);

    // Test 1: XSS in user input
    try {
        const xssPayload = '<script>alert("XSS")</script>';
        const response = await axios.post(`${BASE_URL}/auth/register`, {
            nom: xssPayload,
            prenoms: 'Test',
            email: `test${Date.now()}@example.com`,
            telephone: `+225${Math.floor(Math.random() * 100000000)}`,
            password: 'ValidPass123!'
        }, { validateStatus: () => true });

        // Check if XSS is sanitized or blocked
        const safe = response.status === 400 ||
            (response.data?.data?.user?.nom !== xssPayload);

        logTest(
            'XSS payload in name field',
            safe,
            safe ? 'Input sanitized/rejected' : 'WARNING: XSS may be possible'
        );
    } catch (error) {
        logTest('XSS validation test', false, error.message);
    }

    // Test 2: Email validation
    try {
        const response = await axios.post(`${BASE_URL}/auth/register`, {
            nom: 'Test',
            prenoms: 'User',
            email: 'invalid-email',
            telephone: `+225${Math.floor(Math.random() * 100000000)}`,
            password: 'ValidPass123!'
        }, { validateStatus: () => true });

        logTest(
            'Invalid email format rejected',
            response.status === 400 || response.status === 422,
            `Status: ${response.status}`
        );
    } catch (error) {
        logTest('Email validation test', false, error.message);
    }
}

/**
 * Test Suite 5: Rate Limiting
 */
async function testRateLimiting() {
    console.log(`\n${colors.blue}═══ Rate Limiting Tests ═══${colors.reset}`);

    const requests = [];
    const limit = 15; // Send more than the auth limiter allows (10 in 15 min)

    for (let i = 0; i < limit; i++) {
        requests.push(
            axios.post(`${BASE_URL}/auth/login`, {
                identifier: 'test@example.com',
                password: 'password'
            }, { validateStatus: () => true })
        );
    }

    try {
        const responses = await Promise.all(requests);
        const blockedRequests = responses.filter(r => r.status === 429);

        logTest(
            'Rate limiting active on auth endpoints',
            blockedRequests.length > 0,
            `${blockedRequests.length}/${limit} requests blocked`
        );
    } catch {
        logWarning('Rate limiting test', 'Could not complete rate limit test');
    }
}

/**
 * Test Suite 6: Password Security
 */
async function testPasswordSecurity() {
    console.log(`\n${colors.blue}═══ Password Security Tests ═══${colors.reset}`);

    // We can't directly test bcrypt, but we can verify password requirements
    const weakPasswords = ['123', 'password', 'abc', '12345678'];

    for (const weakPass of weakPasswords) {
        try {
            const response = await axios.post(`${BASE_URL}/auth/register`, {
                nom: 'Test',
                prenoms: 'User',
                email: `test${Date.now()}@example.com`,
                telephone: `+225${Math.floor(Math.random() * 100000000)}`,
                password: weakPass
            }, { validateStatus: () => true });

            logTest(
                `Weak password "${weakPass}" rejected`,
                response.status === 400 || response.status === 422,
                (response.status === 400 || response.status === 422) ? 'Proper validation' : 'WARNING: Weak password accepted'
            );
        } catch (error) {
            logTest(`Password strength test for "${weakPass}"`, false, error.message);
        }
    }
}

/**
 * Test Suite 7: CORS Configuration
 */
async function testCORS() {
    console.log(`\n${colors.blue}═══ CORS Configuration Tests ═══${colors.reset}`);

    try {
        const response = await axios.get(`${BASE_URL}/health`, {
            headers: {
                'Origin': 'http://malicious-site.com'
            },
            validateStatus: () => true
        });

        // In production, should have proper CORS headers
        const hasCORS = response.headers['access-control-allow-origin'];

        if (hasCORS === '*') {
            logWarning(
                'CORS allows all origins',
                'In production, this should be restricted to specific domains'
            );
        } else {
            logTest(
                'CORS properly configured',
                true,
                `Allowed origin: ${hasCORS || 'None'}`
            );
        }
    } catch (error) {
        logTest('CORS configuration test', false, error.message);
    }
}

/**
 * Main execution
 */
async function runSecurityAudit() {
    console.log(`${colors.blue}╔═══════════════════════════════════════════╗${colors.reset}`);
    console.log(`${colors.blue}║   AgriSmart CI - Security Audit Suite    ║${colors.reset}`);
    console.log(`${colors.blue}╚═══════════════════════════════════════════╝${colors.reset}`);
    console.log(`\nTarget: ${BASE_URL}`);
    console.log(`Time: ${new Date().toISOString()}\n`);

    try {
        // Check if server is running
        await axios.get(`${BASE_URL.replace('/api/v1', '')}/health`);
        console.log(`${colors.green}✓ Server is running${colors.reset}\n`);
    } catch {
        console.log(`${colors.red}✗ Server is not accessible${colors.reset}`);
        console.log(`  Please start the server with: docker-compose up`);
        process.exit(1);
    }

    // Run all test suites
    await testSQLInjection();
    await testAuthentication();
    await testAuthorization();
    await testInputValidation();
    await testPasswordSecurity();
    await testRateLimiting();
    await testCORS();

    // Print summary
    console.log(`\n${colors.blue}═══════════════════════════════════════════${colors.reset}`);
    console.log(`${colors.blue}Summary:${colors.reset}`);
    console.log(`  ${colors.green}Passed: ${results.passed}${colors.reset}`);
    console.log(`  ${colors.red}Failed: ${results.failed}${colors.reset}`);
    console.log(`  ${colors.yellow}Warnings: ${results.warnings}${colors.reset}`);
    console.log(`  Total Tests: ${results.passed + results.failed}`);

    const successRate = ((results.passed / (results.passed + results.failed)) * 100).toFixed(1);
    console.log(`\n  Success Rate: ${successRate}%`);

    if (results.failed === 0 && results.warnings === 0) {
        console.log(`\n${colors.green}✓ All security tests passed!${colors.reset}\n`);
    } else if (results.failed === 0) {
        console.log(`\n${colors.yellow}⚠ All tests passed but there are warnings to address${colors.reset}\n`);
    } else {
        console.log(`\n${colors.red}✗ Some security tests failed - review and fix before deployment${colors.reset}\n`);
    }

    process.exit(results.failed > 0 ? 1 : 0);
}

// Run the audit
runSecurityAudit().catch(error => {
    console.error(`${colors.red}Fatal error:${colors.reset}`, error.message);
    process.exit(1);
});
