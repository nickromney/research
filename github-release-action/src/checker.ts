import * as github from '@actions/github';
import * as core from '@actions/core';
import * as semver from 'semver';

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
export async function getLatestRelease(options: CheckerOptions): Promise<ReleaseInfo> {
  const octokit = github.getOctokit(options.githubToken);
  const [owner, repo] = options.repository.split('/');

  if (!owner || !repo) {
    throw new Error(`Invalid repository format: ${options.repository}. Expected format: owner/repo`);
  }

  try {
    core.debug(`Fetching latest release for ${owner}/${repo}`);

    const { data: release } = await octokit.rest.repos.getLatestRelease({
      owner,
      repo
    });

    const version = semver.clean(release.tag_name) || release.tag_name;

    return {
      version,
      publishedAt: new Date(release.published_at || release.created_at),
      url: release.html_url,
      tagName: release.tag_name
    };
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(`Failed to fetch latest release for ${options.repository}: ${error.message}`);
    }
    throw error;
  }
}

/**
 * Fetches all releases from a GitHub repository
 * @param options Checker configuration options
 * @param limit Maximum number of releases to fetch (default: 100)
 * @returns Array of release information sorted by date (newest first)
 */
export async function getAllReleases(
  options: CheckerOptions,
  limit: number = 100
): Promise<ReleaseInfo[]> {
  const octokit = github.getOctokit(options.githubToken);
  const [owner, repo] = options.repository.split('/');

  if (!owner || !repo) {
    throw new Error(`Invalid repository format: ${options.repository}. Expected format: owner/repo`);
  }

  try {
    core.debug(`Fetching all releases for ${owner}/${repo}`);

    const releases: ReleaseInfo[] = [];
    let page = 1;
    const perPage = 100;

    while (releases.length < limit) {
      const { data } = await octokit.rest.repos.listReleases({
        owner,
        repo,
        per_page: Math.min(perPage, limit - releases.length),
        page
      });

      if (data.length === 0) {
        break;
      }

      for (const release of data) {
        // Skip drafts and pre-releases for cleaner version comparison
        if (release.draft || release.prerelease) {
          continue;
        }

        const version = semver.clean(release.tag_name) || release.tag_name;

        releases.push({
          version,
          publishedAt: new Date(release.published_at || release.created_at),
          url: release.html_url,
          tagName: release.tag_name
        });
      }

      if (data.length < perPage) {
        break;
      }

      page++;
    }

    // Sort by date, newest first
    releases.sort((a, b) => b.publishedAt.getTime() - a.publishedAt.getTime());

    return releases;
  } catch (error) {
    if (error instanceof Error) {
      throw new Error(`Failed to fetch releases for ${options.repository}: ${error.message}`);
    }
    throw error;
  }
}

/**
 * Validates a version string
 * @param version Version string to validate
 * @returns True if version is valid semver or can be cleaned to valid semver
 */
export function isValidVersion(version: string): boolean {
  return semver.valid(version) !== null || semver.clean(version) !== null;
}

/**
 * Compares two versions
 * @param version1 First version
 * @param version2 Second version
 * @returns -1 if version1 < version2, 0 if equal, 1 if version1 > version2
 */
export function compareVersions(version1: string, version2: string): number {
  const clean1 = semver.clean(version1);
  const clean2 = semver.clean(version2);

  if (!clean1 || !clean2) {
    // Fall back to string comparison if not valid semver
    return version1.localeCompare(version2);
  }

  return semver.compare(clean1, clean2);
}
