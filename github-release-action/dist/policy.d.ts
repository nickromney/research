export type VersionStatus = 'current' | 'warning' | 'critical' | 'expired';
export interface PolicyResult {
    status: VersionStatus;
    message: string;
    daysBehind?: number;
    versionsBehind?: number;
}
export interface DaysPolicyConfig {
    warningDays: number;
    criticalDays: number;
    expiredDays: number;
}
export interface VersionPolicyConfig {
    supportWindow: number;
}
/**
 * Evaluates version status based on a days-based policy
 * @param releaseDate Date of the latest release
 * @param currentVersion Current version being checked
 * @param latestVersion Latest available version
 * @param config Policy configuration
 * @returns PolicyResult with status and metadata
 */
export declare function evaluateDaysPolicy(releaseDate: Date, currentVersion: string | undefined, latestVersion: string, config: DaysPolicyConfig): PolicyResult;
/**
 * Evaluates version status based on a version-based policy (e.g., N-3 minor versions)
 * @param currentVersion Current version being checked
 * @param latestVersion Latest available version
 * @param allVersions All available versions (sorted newest to oldest)
 * @param config Policy configuration
 * @returns PolicyResult with status and metadata
 */
export declare function evaluateVersionPolicy(currentVersion: string | undefined, latestVersion: string, allVersions: string[], config: VersionPolicyConfig): PolicyResult;
//# sourceMappingURL=policy.d.ts.map