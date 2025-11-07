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
exports.evaluateDaysPolicy = evaluateDaysPolicy;
exports.evaluateVersionPolicy = evaluateVersionPolicy;
const semver = __importStar(require("semver"));
/**
 * Evaluates version status based on a days-based policy
 * @param releaseDate Date of the latest release
 * @param currentVersion Current version being checked
 * @param latestVersion Latest available version
 * @param config Policy configuration
 * @returns PolicyResult with status and metadata
 */
function evaluateDaysPolicy(releaseDate, currentVersion, latestVersion, config) {
    const now = new Date();
    const daysBehind = Math.floor((now.getTime() - releaseDate.getTime()) / (1000 * 60 * 60 * 24));
    // If no current version specified, just report on latest release age
    if (!currentVersion) {
        if (daysBehind < config.warningDays) {
            return {
                status: 'current',
                message: `Latest release ${latestVersion} is ${daysBehind} days old`,
                daysBehind
            };
        }
        else if (daysBehind < config.criticalDays) {
            return {
                status: 'warning',
                message: `Latest release ${latestVersion} is ${daysBehind} days old (warning threshold: ${config.warningDays} days)`,
                daysBehind
            };
        }
        else if (daysBehind < config.expiredDays) {
            return {
                status: 'critical',
                message: `Latest release ${latestVersion} is ${daysBehind} days old (critical threshold: ${config.criticalDays} days)`,
                daysBehind
            };
        }
        else {
            return {
                status: 'expired',
                message: `Latest release ${latestVersion} is ${daysBehind} days old (expired threshold: ${config.expiredDays} days)`,
                daysBehind
            };
        }
    }
    // If current version matches latest, we're current regardless of age
    const cleanCurrent = semver.clean(currentVersion);
    const cleanLatest = semver.clean(latestVersion);
    if (cleanCurrent && cleanLatest && semver.eq(cleanCurrent, cleanLatest)) {
        return {
            status: 'current',
            message: `Version ${currentVersion} is current (latest: ${latestVersion})`,
            daysBehind
        };
    }
    // Current version is behind, check how old the latest release is
    if (daysBehind < config.warningDays) {
        return {
            status: 'warning',
            message: `Version ${currentVersion} is behind latest ${latestVersion} (${daysBehind} days old)`,
            daysBehind
        };
    }
    else if (daysBehind < config.criticalDays) {
        return {
            status: 'critical',
            message: `Version ${currentVersion} is behind latest ${latestVersion} (${daysBehind} days old, critical threshold: ${config.criticalDays} days)`,
            daysBehind
        };
    }
    else {
        return {
            status: 'expired',
            message: `Version ${currentVersion} is behind latest ${latestVersion} (${daysBehind} days old, expired threshold: ${config.expiredDays} days)`,
            daysBehind
        };
    }
}
/**
 * Evaluates version status based on a version-based policy (e.g., N-3 minor versions)
 * @param currentVersion Current version being checked
 * @param latestVersion Latest available version
 * @param allVersions All available versions (sorted newest to oldest)
 * @param config Policy configuration
 * @returns PolicyResult with status and metadata
 */
function evaluateVersionPolicy(currentVersion, latestVersion, allVersions, config) {
    // If no current version specified, just report latest
    if (!currentVersion) {
        return {
            status: 'current',
            message: `Latest version is ${latestVersion}`,
            versionsBehind: 0
        };
    }
    const cleanCurrent = semver.clean(currentVersion);
    const cleanLatest = semver.clean(latestVersion);
    if (!cleanCurrent || !cleanLatest) {
        return {
            status: 'warning',
            message: `Unable to parse version strings: current=${currentVersion}, latest=${latestVersion}`,
            versionsBehind: 0
        };
    }
    // If current matches latest, we're current
    if (semver.eq(cleanCurrent, cleanLatest)) {
        return {
            status: 'current',
            message: `Version ${currentVersion} is current`,
            versionsBehind: 0
        };
    }
    // Count how many minor versions behind we are
    const currentParsed = semver.parse(cleanCurrent);
    const latestParsed = semver.parse(cleanLatest);
    if (!currentParsed || !latestParsed) {
        return {
            status: 'warning',
            message: `Unable to parse semantic versions: current=${currentVersion}, latest=${latestVersion}`,
            versionsBehind: 0
        };
    }
    // Count versions between current and latest
    const cleanedVersions = allVersions
        .map(v => semver.clean(v))
        .filter((v) => v !== null)
        .filter(v => semver.gte(v, cleanCurrent) && semver.lte(v, cleanLatest));
    const versionsBehind = cleanedVersions.length - 1; // Subtract 1 to not count current version
    // For version-based policy, count minor version differences
    let minorVersionsBehind = 0;
    if (currentParsed.major === latestParsed.major) {
        minorVersionsBehind = latestParsed.minor - currentParsed.minor;
    }
    else {
        // If major version differs, consider it as many minors behind as window + 1
        minorVersionsBehind = config.supportWindow + 1;
    }
    if (minorVersionsBehind === 0) {
        return {
            status: 'current',
            message: `Version ${currentVersion} is current (latest: ${latestVersion})`,
            versionsBehind
        };
    }
    else if (minorVersionsBehind <= Math.floor(config.supportWindow / 2)) {
        return {
            status: 'warning',
            message: `Version ${currentVersion} is ${minorVersionsBehind} minor version(s) behind ${latestVersion}`,
            versionsBehind
        };
    }
    else if (minorVersionsBehind <= config.supportWindow) {
        return {
            status: 'critical',
            message: `Version ${currentVersion} is ${minorVersionsBehind} minor version(s) behind ${latestVersion} (support window: N-${config.supportWindow})`,
            versionsBehind
        };
    }
    else {
        return {
            status: 'expired',
            message: `Version ${currentVersion} is ${minorVersionsBehind} minor version(s) behind ${latestVersion} (outside support window: N-${config.supportWindow})`,
            versionsBehind
        };
    }
}
//# sourceMappingURL=policy.js.map