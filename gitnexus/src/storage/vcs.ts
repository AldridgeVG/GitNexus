/**
 * VCS Abstraction Layer
 *
 * Provides a unified interface for Git and SVN operations.
 * This allows GitNexus to work with both version control systems.
 */

import { execSync } from 'child_process';
import { statSync } from 'fs';
import path from 'path';

/**
 * VCS types supported by GitNexus
 */
export type VCSType = 'git' | 'svn' | 'none';

/**
 * Staleness information for a repository
 */
export interface StalenessInfo {
  isStale: boolean;
  commitsBehind: number;
  hint?: string;
}

/**
 * VCS Adapter interface
 *
 * All VCS implementations (Git, SVN) must implement this interface.
 */
export interface VCSAdapter {
  /** The type of VCS */
  readonly type: VCSType;

  /** The repository path */
  readonly repoPath: string;

  /**
   * Check if this is a valid repository
   */
  isValid(): boolean;

  /**
   * Get the current revision identifier
   * - Git: commit hash (e.g., "abc123...")
   * - SVN: revision number (e.g., "1234")
   */
  getCurrentRevision(): string;

  /**
   * Get the current commit hash (for backward compatibility)
   * - Git: same as getCurrentRevision()
   * - SVN: may return empty string or working copy info
   */
  getCurrentCommit(): string;

  /**
   * Check if a revision is an ancestor of another (Git-specific concept)
   * For SVN, this checks if revision numbers are sequential
   */
  isRevisionReachable(fromRev: string, toRev: string): boolean;

  /**
   * Get list of changed files between two revisions
   * Returns null if revisions are not comparable
   */
  getChangedFiles(fromRev: string, toRev: string): string[] | null;

  /**
   * Check staleness of the index compared to working copy
   */
  checkStaleness(lastRevision: string): StalenessInfo;
}

/**
 * Detect if a directory is a Git repository
 */
export function hasGitDir(dirPath: string): boolean {
  try {
    statSync(path.join(dirPath, '.git'));
    return true;
  } catch {
    return false;
  }
}

/**
 * Detect if a directory is an SVN working copy
 */
export function hasSVNDir(dirPath: string): boolean {
  try {
    // SVN uses .svn directory (root of working copy)
    statSync(path.join(dirPath, '.svn'));
    return true;
  } catch {
    return false;
  }
}

/**
 * Find the Git repository root from any path inside the repo
 */
export function getGitRoot(fromPath: string): string | null {
  try {
    const raw = execSync('git rev-parse --show-toplevel', { cwd: fromPath }).toString().trim();
    // On Windows, git returns /d/Projects/Foo — path.resolve normalizes to D:\Projects\Foo
    return path.resolve(raw);
  } catch {
    return null;
  }
}

/**
 * Find the SVN working copy root from any path inside
 */
export function getSVNRoot(fromPath: string): string | null {
  try {
    const raw = execSync('svn info --show-item working-copy-root-url', { cwd: fromPath })
      .toString()
      .trim();
    // Convert URL to local path if it's a file:// URL
    if (raw.startsWith('file://')) {
      return path.resolve(raw.replace('file://', ''));
    }
    // For working copy paths, we need the actual root
    const wcRoot = execSync('svn info --show-item wc-root', { cwd: fromPath }).toString().trim();
    return path.resolve(wcRoot);
  } catch {
    return null;
  }
}

/**
 * Detect VCS type for a given path
 */
export function detectVCSType(repoPath: string): VCSType {
  if (hasGitDir(repoPath)) return 'git';
  if (hasSVNDir(repoPath)) return 'svn';
  return 'none';
}
