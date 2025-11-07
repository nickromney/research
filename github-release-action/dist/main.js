"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const core = __importStar(require("@actions/core"));
const checker_1 = require("./checker");
const policy_1 = require("./policy");
/**
 * Reads and validates action inputs
 */
function getInputs() {
    const repository = core.getInput('repository', { required: true });
    const currentVersion = core.getInput('current-version') || undefined;
    const policyType = core.getInput('policy-type') || 'days';
    const githubToken = core.getInput('github-token', { required: true });
    if (policyType !== 'days' && policyType !== 'version') {
        throw new Error(`Invalid policy-type: ${policyType}. Must be 'days' or 'version'`);
    }
    return {
        repository,
        currentVersion,
        policyType: policyType,
        daysWarning: parseInt(core.getInput('days-warning') || '12', 10),
        daysCritical: parseInt(core.getInput('days-critical') || '20', 10),
        daysExpired: parseInt(core.getInput('days-expired') || '30', 10),
        versionWindow: parseInt(core.getInput('version-window') || '3', 10),
        githubToken,
        failOnExpired: core.getInput('fail-on-expired') === 'true'
    };
}
/**
 * Sets action outputs based on policy result
 */
function setOutputs(result, latestVersion, latestDate) {
    core.setOutput('status', result.status);
    core.setOutput('latest-version', latestVersion);
    core.setOutput('latest-release-date', latestDate.toISOString());
    if (result.daysBehind !== undefined) {
        core.setOutput('days-behind', result.daysBehind.toString());
    }
    if (result.versionsBehind !== undefined) {
        core.setOutput('versions-behind', result.versionsBehind.toString());
    }
}
/**
 * Creates a summary for GitHub Actions
 */
function createSummary(inputs, result, latestVersion, latestDate) {
    let emoji = '✅';
    let color = 'green';
    switch (result.status) {
        case 'warning':
            emoji = '⚠️';
            color = 'yellow';
            break;
        case 'critical':
            emoji = '🔶';
            color = 'orange';
            break;
        case 'expired':
            emoji = '❌';
            color = 'red';
            break;
    }
    const summary = core.summary
        .addHeading(`${emoji} Release Version Check: ${result.status.toUpperCase()}`)
        .addRaw('\n')
        .addTable([
        [
            { data: 'Property', header: true },
            { data: 'Value', header: true }
        ],
        ['Repository', inputs.repository],
        ['Current Version', inputs.currentVersion || 'Not specified'],
        ['Latest Version', latestVersion],
        ['Latest Release Date', latestDate.toISOString().split('T')[0]],
        ['Status', `<span style="color: ${color}; font-weight: bold;">${result.status.toUpperCase()}</span>`],
        ['Policy Type', inputs.policyType]
    ])
        .addRaw('\n')
        .addRaw(`**Message:** ${result.message}`)
        .addRaw('\n');
    if (result.daysBehind !== undefined) {
        summary.addRaw(`\n**Days Behind:** ${result.daysBehind}`);
    }
    if (result.versionsBehind !== undefined) {
        summary.addRaw(`\n**Versions Behind:** ${result.versionsBehind}`);
    }
    summary.write();
}
/**
 * Adds annotations based on the result status
 */
function addAnnotations(result, inputs) {
    switch (result.status) {
        case 'warning':
            core.warning(result.message);
            break;
        case 'critical':
            core.warning(`CRITICAL: ${result.message}`);
            break;
        case 'expired':
            core.error(result.message);
            break;
        case 'current':
            core.info(result.message);
            break;
    }
}
/**
 * Main action entry point
 */
async function run() {
    try {
        const inputs = getInputs();
        core.info(`Checking release versions for ${inputs.repository}`);
        core.info(`Policy type: ${inputs.policyType}`);
        if (inputs.currentVersion) {
            core.info(`Current version: ${inputs.currentVersion}`);
        }
        // Fetch latest release
        const latestRelease = await (0, checker_1.getLatestRelease)({
            repository: inputs.repository,
            githubToken: inputs.githubToken
        });
        core.info(`Latest release: ${latestRelease.version} (published ${latestRelease.publishedAt.toISOString()})`);
        let result;
        if (inputs.policyType === 'days') {
            // Days-based policy
            result = (0, policy_1.evaluateDaysPolicy)(latestRelease.publishedAt, inputs.currentVersion, latestRelease.version, {
                warningDays: inputs.daysWarning,
                criticalDays: inputs.daysCritical,
                expiredDays: inputs.daysExpired
            });
        }
        else {
            // Version-based policy - need to fetch all releases
            core.info('Fetching all releases for version-based policy evaluation...');
            const allReleases = await (0, checker_1.getAllReleases)({
                repository: inputs.repository,
                githubToken: inputs.githubToken
            }, 100);
            const allVersions = allReleases.map(r => r.version);
            result = (0, policy_1.evaluateVersionPolicy)(inputs.currentVersion, latestRelease.version, allVersions, {
                supportWindow: inputs.versionWindow
            });
        }
        // Set outputs
        setOutputs(result, latestRelease.version, latestRelease.publishedAt);
        // Create summary
        createSummary(inputs, result, latestRelease.version, latestRelease.publishedAt);
        // Add annotations
        addAnnotations(result, inputs);
        // Fail action if expired and configured to do so
        if (result.status === 'expired' && inputs.failOnExpired) {
            core.setFailed(result.message);
        }
    }
    catch (error) {
        if (error instanceof Error) {
            core.setFailed(error.message);
        }
        else {
            core.setFailed('An unknown error occurred');
        }
    }
}
// Run the action
run();
//# sourceMappingURL=main.js.map