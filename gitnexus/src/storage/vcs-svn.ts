/**
 * SVN VCS Adapter
 *
 * SVN implementation of the VCSAdapter interface.
 */

import { execSync, execFileSync } from 'child_process';
import type { VCSAdapter, StalenessInfo, VCSType } from './vcs.js';

export class SVNAdapter implements VCSAdapter {
  readonly type: VCSType = 'svn';

  constructor(public readonly repoPath: string) {}

  /**
   * Check if this is a valid SVN working copy
   */
  isValid(): boolean {
    try {
      execSync('svn info', { cwd: this.repoPath, stdio: 'ignore' });
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Get the current SVN revision number
   */
  getCurrentRevision(): string {
    try {
      return execSync('svn info --show-item revision', { cwd: this.repoPath }).toString().trim();
    } catch {
      return '';
    }
  }

  /**
   * For SVN, getCurrentCommit returns the same as getCurrentRevision
   * (the revision number as a string)
   */
  getCurrentCommit(): string {
    // SVN uses revision numbers, but we store it in lastCommit for compatibility
    // LastRevision will have the actual SVN revision
    return this.getCurrentRevision();
  }

  /**
   * Check if fromRev is an ancestor of toRev in SVN
   * SVN doesn't have the same ancestry concept as Git,
   * but we can check if fromRev < toRev numerically
   */
  isRevisionReachable(fromRev: string, toRev: string): boolean {
    const fromNum = parseInt(fromRev, 10);
    const toNum = parseInt(toRev, 10);

    // If either is not a valid number, we can't determine reachability
    if (isNaN(fromNum) || isNaN(toNum)) {
      return false;
    }

    // In SVN, lower revision numbers are ancestors of higher ones
    return fromNum <= toNum;
  }

  /**
   * Get list of changed files between two SVN revisions
   */
  getChangedFiles(fromRev: string, toRev: string): string[] | null {
    try {
      const output = execFileSync('svn', ['diff', '-r', `${fromRev}:${toRev}`, '--summarize'], {
        cwd: this.repoPath,
        encoding: 'utf-8',
      });

      // Parse SVN diff --summarize output
      // Format: "M       path/to/file" or "A       path/to/file" or "D       path/to/file"
      return output
        .trim()
        .split('\n')
        .filter(Boolean)
        .map((line) => {
          // Remove status prefix (first 8 characters typically contain status)
          const match = line.match(/^[AMD]\s+(.+)$/);
          return match ? match[1].trim() : line.trim();
        })
        .filter(Boolean);
    } catch {
      return null;
    }
  }

  /**
   * Check staleness of the index compared to repository HEAD
   */
  checkStaleness(lastRevision: string): StalenessInfo {
    try {
      const currentRev = this.getCurrentRevision();
      const lastRevNum = parseInt(lastRevision, 10);
      const currentRevNum = parseInt(currentRev, 10);

      if (isNaN(lastRevNum) || isNaN(currentRevNum)) {
        return { isStale: false, commitsBehind: 0 };
      }

      const revisionsBehind = currentRevNum - lastRevNum;

      if (revisionsBehind > 0) {
        return {
          isStale: true,
          commitsBehind: revisionsBehind,
          hint: `⚠️ Index is ${revisionsBehind} revision${revisionsBehind > 1 ? 's' : ''} behind HEAD. Run analyze tool to update.`,
        };
      }

      return { isStale: false, commitsBehind: 0 };
    } catch {
      return { isStale: false, commitsBehind: 0 };
    }
  }
}
