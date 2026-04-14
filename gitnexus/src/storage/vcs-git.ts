/**
 * Git VCS Adapter
 *
 * Git implementation of the VCSAdapter interface.
 */

import { execSync, execFileSync } from 'child_process';
import type { VCSAdapter, StalenessInfo, VCSType } from './vcs.js';

export class GitAdapter implements VCSAdapter {
  readonly type: VCSType = 'git';

  constructor(public readonly repoPath: string) {}

  /**
   * Check if this is a valid Git repository
   */
  isValid(): boolean {
    try {
      execSync('git rev-parse --is-inside-work-tree', { cwd: this.repoPath, stdio: 'ignore' });
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Get the current commit hash
   */
  getCurrentRevision(): string {
    try {
      return execSync('git rev-parse HEAD', { cwd: this.repoPath }).toString().trim();
    } catch {
      return '';
    }
  }

  /**
   * Alias for getCurrentRevision() for backward compatibility
   */
  getCurrentCommit(): string {
    return this.getCurrentRevision();
  }

  /**
   * Check if fromRev is an ancestor of toRev
   */
  isRevisionReachable(fromRev: string, toRev: string): boolean {
    try {
      execFileSync('git', ['merge-base', '--is-ancestor', fromRev, toRev], {
        cwd: this.repoPath,
        stdio: 'ignore',
      });
      return true;
    } catch {
      return false;
    }
  }

  /**
   * Get list of changed files between two commits
   */
  getChangedFiles(fromRev: string, toRev: string): string[] | null {
    try {
      const output = execFileSync('git', ['diff', `${fromRev}..${toRev}`, '--name-only'], {
        cwd: this.repoPath,
        encoding: 'utf-8',
      });
      return output.trim().split('\n').filter(Boolean);
    } catch {
      return null;
    }
  }

  /**
   * Check staleness of the index compared to HEAD
   */
  checkStaleness(lastRevision: string): StalenessInfo {
    try {
      const result = execFileSync('git', ['rev-list', '--count', `${lastRevision}..HEAD`], {
        cwd: this.repoPath,
        encoding: 'utf-8',
        stdio: ['pipe', 'pipe', 'pipe'],
      }).trim();

      const commitsBehind = parseInt(result, 10) || 0;

      if (commitsBehind > 0) {
        return {
          isStale: true,
          commitsBehind,
          hint: `⚠️ Index is ${commitsBehind} commit${commitsBehind > 1 ? 's' : ''} behind HEAD. Run analyze tool to update.`,
        };
      }

      return { isStale: false, commitsBehind: 0 };
    } catch {
      return { isStale: false, commitsBehind: 0 };
    }
  }
}
