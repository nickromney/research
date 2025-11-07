export interface ReleaseInfo {
    version: string;
    publishedAt: Date;
    url: string;
    tagName: string;
}
export interface CheckerOptions {
    repository: string;
    githubToken: string;
}
/**
 * Fetches the latest release from a GitHub repository
 * @param options Checker configuration options
 * @returns Latest release information
 */
export declare function getLatestRelease(options: CheckerOptions): Promise<ReleaseInfo>;
/**
 * Fetches all releases from a GitHub repository
 * @param options Checker configuration options
 * @param limit Maximum number of releases to fetch (default: 100)
 * @returns Array of release information sorted by date (newest first)
 */
export declare function getAllReleases(options: CheckerOptions, limit?: number): Promise<ReleaseInfo[]>;
/**
 * Validates a version string
 * @param version Version string to validate
 * @returns True if version is valid semver or can be cleaned to valid semver
 */
export declare function isValidVersion(version: string): boolean;
/**
 * Compares two versions
 * @param version1 First version
 * @param version2 Second version
 * @returns -1 if version1 < version2, 0 if equal, 1 if version1 > version2
 */
export declare function compareVersions(version1: string, version2: string): number;
//# sourceMappingURL=checker.d.ts.map